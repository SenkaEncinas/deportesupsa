// Fase eliminatoria: que siempre haya forma de llegar a las llaves.
//
// Bugs que motivaron estos tests, vistos en los datos reales:
//
// 1. INTERCARRERAS 2/2026 se creó como "Fase de grupos" (solo grupos).
//    Ese formato no tiene segunda fase, así que "Activar fase
//    eliminatoria" nunca aparecía, y el formato no se podía editar.
// 2. En el vóley damas, BEREA vs CAMBRIDGE quedó con resultado cargado
//    pero `estado: programado`, porque reprogramar pisaba el estado. La
//    tabla (que solo contaba los finalizados) dejaba de sumar ese
//    partido.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/campeonato_service.dart';
import 'package:futsal/services/partido_service.dart';
import 'package:futsal/utils/tabla_calculo.dart';

Map<String, dynamic> _soloGrupos({String estado = CampeonatoEstado.activo}) {
  // Igual a como quedó guardado INTERCARRERAS SEMESTRE 2/2026.
  return {
    'nombre': 'INTERCARRERAS',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': TipoCampeonato.faseGrupos,
    'estado': estado,
    'configuracion': {
      'formato': 'grupos',
      'cantidadGrupos': 2,
      'clasificanPorGrupo': 0,
      'mejoresTerceros': 0,
      'generaFaseEliminatoria': false,
      'rondaEliminatoriaInicial': 'no_aplica',
      'cantidadJugadoresEnCancha': 5,
    },
  };
}

Map<String, dynamic> _partidoJugado({
  String estado = PartidoEstado.finalizado,
}) {
  return {
    'jornada': 1,
    'vuelta': 1,
    'grupoId': 'Grupo A',
    'equipoLocalId': 'a',
    'equipoLocalNombre': 'A',
    'equipoVisitanteId': 'b',
    'equipoVisitanteNombre': 'B',
    'estado': estado,
    'resultadoRegistrado': true,
    'golesLocal': 2,
    'golesVisitante': 0,
    'ganadorId': 'a',
    'generadoPorSistema': true,
  };
}

EquipoModel _equipo(String id) => EquipoModel(
  id: id,
  nombre: id,
  representante: 'rep',
  estado: EquipoEstado.activo,
  cantidadJugadoresRegistrados: 6,
  creadoPor: 'test',
  actualizadoPor: 'test',
);

void main() {
  group('Agregar fase eliminatoria a un campeonato de "Fase de grupos"', () {
    late FakeFirebaseFirestore db;
    late CampeonatoService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = CampeonatoService(firestore: db);
    });

    Future<CampeonatoModel> leer() async =>
        (await service.getCampeonato('c1'))!;

    test(
      'sin convertir, el formato no permite activar la eliminatoria',
      () async {
        await db.collection('campeonatos').doc('c1').set(_soloGrupos());
        final campeonato = await leer();

        expect(campeonato.tieneFasesSeparadas, isFalse);
        expect(campeonato.estaEnFaseRegular, isFalse);
        expect(
          () => service.activarFaseEliminatoria(campeonato),
          throwsException,
        );
      },
    );

    test('convierte a "Grupos + eliminación" y deja activar la fase', () async {
      await db.collection('campeonatos').doc('c1').set(_soloGrupos());

      await service.agregarFaseEliminatoria(
        campeonato: await leer(),
        clasificanPorGrupo: 2,
        mejoresTerceros: 0,
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
      );

      final convertido = await leer();
      expect(convertido.tipoCampeonato, TipoCampeonato.gruposEliminacion);
      expect(convertido.configuracion.clasificanPorGrupo, 2);
      expect(convertido.configuracion.generaFaseEliminatoria, isTrue);
      expect(convertido.configuracion.rondaEliminatoriaInicial, 'semifinal');
      expect(convertido.totalClasificados, 4);
      // El resto de la configuración no se pierde.
      expect(convertido.configuracion.cantidadGrupos, 2);
      expect(convertido.configuracion.cantidadJugadoresEnCancha, 5);
      // Queda en grupos: aparece "Activar fase eliminatoria".
      expect(convertido.estaEnFaseRegular, isTrue);

      // Los partidos ya jugados tienen grupo: siguen sumando a la tabla.
      final jugado = PartidoModel.fromMap('p1', _partidoJugado());
      expect(convertido.esDeFaseFinal(jugado), isFalse);

      await service.activarFaseEliminatoria(convertido);
      final activado = await leer();
      expect(activado.estaEnFaseEliminatoria, isTrue);
      expect(activado.muestraLlave, isTrue);

      final auditoria = await db
          .collection('campeonatos')
          .doc('c1')
          .collection('auditoria')
          .get();
      expect(auditoria.docs, isNotEmpty);
    });

    test('rechaza configuraciones que no arman una fase final', () async {
      await db.collection('campeonatos').doc('c1').set(_soloGrupos());
      final campeonato = await leer();

      Future<void> intentar(int clasifican, int terceros) =>
          service.agregarFaseEliminatoria(
            campeonato: campeonato,
            clasificanPorGrupo: clasifican,
            mejoresTerceros: terceros,
            usuarioId: 'admin',
            usuarioNombre: 'Admin',
          );

      expect(() => intentar(0, 0), throwsException);
      expect(() => intentar(1, -1), throwsException);
      expect(() => intentar(1, 3), throwsException); // solo hay 2 grupos
    });

    test(
      'no se aplica a otros formatos ni a campeonatos finalizados',
      () async {
        await db.collection('campeonatos').doc('c1').set({
          ..._soloGrupos(),
          'tipoCampeonato': TipoCampeonato.gruposEliminacion,
        });
        expect(
          () async => service.agregarFaseEliminatoria(
            campeonato: await leer(),
            clasificanPorGrupo: 2,
            mejoresTerceros: 0,
            usuarioId: 'admin',
            usuarioNombre: 'Admin',
          ),
          throwsException,
        );

        await db
            .collection('campeonatos')
            .doc('c1')
            .set(_soloGrupos(estado: CampeonatoEstado.finalizado));
        expect(
          () async => service.agregarFaseEliminatoria(
            campeonato: await leer(),
            clasificanPorGrupo: 2,
            mejoresTerceros: 0,
            usuarioId: 'admin',
            usuarioNombre: 'Admin',
          ),
          throwsException,
        );
      },
    );
  });

  group('Reprogramar un partido ya jugado', () {
    test('cambia la fecha pero el partido sigue finalizado', () async {
      final db = FakeFirebaseFirestore();
      final ref = db
          .collection('campeonatos')
          .doc('c1')
          .collection('partidos')
          .doc('p1');
      await ref.set(_partidoJugado());

      await PartidoService(firestore: db).programarPartido(
        campeonatoId: 'c1',
        partidoId: 'p1',
        fechaHora: DateTime(2026, 11, 20, 18),
      );

      final data = (await ref.get()).data()!;
      expect(data['estado'], PartidoEstado.finalizado);
      expect(data['resultadoRegistrado'], isTrue);
    });

    test('un partido sin resultado pasa a programado', () async {
      final db = FakeFirebaseFirestore();
      final ref = db
          .collection('campeonatos')
          .doc('c1')
          .collection('partidos')
          .doc('p1');
      await ref.set({
        ..._partidoJugado(estado: PartidoEstado.pendienteProgramacion),
        'resultadoRegistrado': false,
        'golesLocal': null,
        'golesVisitante': null,
      });

      await PartidoService(firestore: db).programarPartido(
        campeonatoId: 'c1',
        partidoId: 'p1',
        fechaHora: DateTime(2026, 11, 20, 18),
      );

      expect((await ref.get()).data()!['estado'], PartidoEstado.programado);
    });

    test(
      'la tabla suma los partidos ya dañados (resultado + "programado")',
      () {
        final campeonato = CampeonatoModel.fromMap('c1', _soloGrupos());
        final danado = PartidoModel.fromMap(
          'p1',
          _partidoJugado(estado: PartidoEstado.programado),
        );

        expect(danado.estadoEfectivo, PartidoEstado.finalizado);

        final tabla = TablaCalculo.calcular(
          campeonato: campeonato,
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [danado],
        );
        final a = tabla.firstWhere((fila) => fila.equipoId == 'a');
        expect(a.partidosJugados, 1);
        expect(a.puntos, 3);
      },
    );
  });

  group('Cruces cargados con privilegio (INTERCARRERAS)', () {
    Future<(FakeFirebaseFirestore, CampeonatoModel)> preparar() async {
      final db = FakeFirebaseFirestore();
      final datos = {
        ..._soloGrupos(),
        'tipoCampeonato': TipoCampeonato.gruposEliminacion,
        'faseActual': FaseCampeonato.eliminatoria,
      };
      await db.collection('campeonatos').doc('c1').set(datos);
      await db
          .collection('campeonatos')
          .doc('c1')
          .collection('partidos')
          .doc('p1')
          .set({
            ..._partidoJugado(estado: PartidoEstado.programado),
            'grupoId': null,
            'privilegio': true,
            'resultadoRegistrado': false,
            'golesLocal': null,
            'golesVisitante': null,
            'ganadorId': null,
            'generadoPorSistema': false,
          });
      return (db, CampeonatoModel.fromMap('c1', datos));
    }

    test('con privilegio un empate no pide penales', () async {
      final (db, campeonato) = await preparar();
      final doc = await db.doc('campeonatos/c1/partidos/p1').get();
      final partido = PartidoModel.fromMap(doc.id, doc.data()!);
      expect(campeonato.requiereGanador(partido), isFalse);
    });

    test('al pasarlo a la fase final pide penales', () async {
      final (db, campeonato) = await preparar();

      final cambiados = await PartidoService(
        firestore: db,
      ).pasarPrivilegiosAFaseFinal(campeonato: campeonato, partidoIds: ['p1']);
      expect(cambiados, 1);

      final doc = await db.doc('campeonatos/c1/partidos/p1').get();
      final partido = PartidoModel.fromMap(doc.id, doc.data()!);
      expect(partido.privilegio, isFalse);
      expect(campeonato.esDeFaseFinal(partido), isTrue);
      expect(campeonato.requiereGanador(partido), isTrue);
    });

    test('no pasa un partido que ya tiene resultado', () async {
      final (db, campeonato) = await preparar();
      await db.doc('campeonatos/c1/partidos/p1').update({
        'resultadoRegistrado': true,
        'golesLocal': 2,
        'golesVisitante': 2,
      });

      expect(
        () => PartidoService(firestore: db).pasarPrivilegiosAFaseFinal(
          campeonato: campeonato,
          partidoIds: ['p1'],
        ),
        throwsException,
      );
    });
  });
}
