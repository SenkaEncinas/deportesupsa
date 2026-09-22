// Puntos de vóley y walkover, ejercitando el servicio de verdad contra
// un Firestore de mentira.
//
// La versión anterior de este archivo repetía la regla dentro del propio
// test, así que pasaba aunque el servicio hiciera otra cosa — y de hecho
// la hacía: la tabla se guardaba con 3/1/0 y los walkover viejos
// aportaban 2 de diferencia en vez de 50.
//
// Reglas que se fijan acá:
//
// - Vóley: victoria 2 puntos, derrota 1 punto, sin empates.
// - Walkover: 25-0 por set (50 a 0 con dos sets para ganar) y el que no
//   se presentó no cobra el punto por perder.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/models/tabla_posicion_model.dart';
import 'package:futsal/services/resultado_service.dart';

const String kCampeonato = 'camp-volley';

/// Arma un campeonato de vóley con dos equipos y un partido entre ellos.
///
/// [reglasViejas] guarda a propósito la puntuación de fútbol (3/1/0),
/// que es lo que tienen los campeonatos creados antes de que existieran
/// las reglas por deporte: la tabla igual tiene que salir 2/0/1.
Future<FakeFirebaseFirestore> _baseVolley({bool reglasViejas = true}) async {
  final db = FakeFirebaseFirestore();

  await db.collection('campeonatos').doc(kCampeonato).set({
    'nombre': 'CopaUpsa Voleibol',
    'deporte': DeporteTipo.volley,
    'modalidad': ModalidadDeporte.volleySala,
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
    if (reglasViejas)
      'reglasPuntuacion': {'victoria': 3, 'empate': 1, 'derrota': 0},
    'configuracion': {
      'formato': TipoCampeonato.gruposEliminacion,
      'deporte': DeporteTipo.volley,
      'sistemaResultado': SistemaResultado.sets,
      'setsParaGanar': 2,
      'puntosSetNormal': 25,
      'puntosSetDecisivo': 15,
    },
  });

  for (final id in ['casa', 'visita']) {
    await db
        .collection('campeonatos')
        .doc(kCampeonato)
        .collection('equipos')
        .doc(id)
        .set({'nombre': id, 'estado': EquipoEstado.activo});
  }

  await db
      .collection('campeonatos')
      .doc(kCampeonato)
      .collection('partidos')
      .doc('p1')
      .set({
        'jornada': 1,
        'vuelta': 1,
        'grupoId': 'Grupo A',
        'equipoLocalId': 'casa',
        'equipoLocalNombre': 'casa',
        'equipoVisitanteId': 'visita',
        'equipoVisitanteNombre': 'visita',
        'estado': PartidoEstado.programado,
        'resultadoRegistrado': false,
      });

  return db;
}

Future<Map<String, TablaPosicionModel>> _tabla(FakeFirebaseFirestore db) async {
  final snap = await db
      .collection('campeonatos')
      .doc(kCampeonato)
      .collection('tabla_posiciones')
      .get();

  return {
    for (final d in snap.docs)
      d.id: TablaPosicionModel.fromMap(d.id, d.data()),
  };
}

void main() {
  group('Puntos de vóley', () {
    test('ganar da 2 puntos y perder da 1, aunque el campeonato tenga '
        'guardadas las reglas de fútbol', () async {
      final db = await _baseVolley();

      await ResultadoService(firestore: db).registrarResultado(
        campeonatoId: kCampeonato,
        partidoId: 'p1',
        golesLocal: 2,
        golesVisitante: 1,
        golesJugadores: const [],
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
        sets: const [
          SetPartido(local: 25, visitante: 20),
          SetPartido(local: 22, visitante: 25),
          SetPartido(local: 15, visitante: 10),
        ],
      );

      final tabla = await _tabla(db);

      expect(tabla['casa']!.puntos, 2, reason: 'el que gana suma 2');
      expect(tabla['visita']!.puntos, 1, reason: 'el que pierde suma 1');
    });

    test('las reglas de vóley no dependen de lo guardado', () {
      final reglas = ReglasPuntuacion.voley();

      expect(reglas.victoria, 2);
      expect(reglas.derrota, 1);
      expect(reglas.empate, 0);
    });
  });

  group('Walkover en vóley', () {
    Future<FakeFirebaseFirestore> conWalkover() async {
      final db = await _baseVolley();

      await ResultadoService(firestore: db).registrarResultado(
        campeonatoId: kCampeonato,
        partidoId: 'p1',
        golesLocal: 1,
        golesVisitante: 0,
        golesJugadores: const [],
        tipoResultado: TipoResultado.walkover,
        observacionResultado: 'La visita no se presentó.',
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
      );

      return db;
    }

    test('se guarda 25-0 en cada set', () async {
      final db = await conWalkover();

      final doc = await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('partidos')
          .doc('p1')
          .get();

      final partido = PartidoModel.fromMap('p1', doc.data()!);

      expect(partido.golesLocal, 2, reason: 'se gana por 2 sets a 0');
      expect(partido.golesVisitante, 0);
      expect(partido.sets.length, 2);
      expect(partido.sets.every((s) => s.local == 25 && s.visitante == 0), isTrue);
    });

    test('da 50 puntos de diferencia al que se presentó', () async {
      final db = await conWalkover();
      final tabla = await _tabla(db);

      expect(tabla['casa']!.puntosFavor, 50);
      expect(tabla['casa']!.puntosContra, 0);
      expect(tabla['casa']!.diferenciaPuntos, 50);

      expect(tabla['visita']!.puntosFavor, 0);
      expect(tabla['visita']!.puntosContra, 50);
      expect(tabla['visita']!.diferenciaPuntos, -50);
    });

    test('el que no se presentó suma 0, no el punto por perder', () async {
      final db = await conWalkover();
      final tabla = await _tabla(db);

      expect(tabla['casa']!.puntos, 2);
      expect(
        tabla['visita']!.puntos,
        0,
        reason: 'el punto de consuelo es por presentarse y jugar',
      );
    });

    test('un walkover viejo, sin sets guardados, igual cuenta 50', () async {
      // Reproduce los partidos cargados antes de que la app armara el
      // detalle de sets: quedaron con el marcador 2-0 y `sets` vacío.
      // La tabla tiene que aplicar la regla igual, sin obligar a
      // recargar el resultado a mano.
      final db = await _baseVolley();

      await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('partidos')
          .doc('p1')
          .update({
            'estado': PartidoEstado.finalizado,
            'resultadoRegistrado': true,
            'tipoResultado': TipoResultado.walkover,
            'golesLocal': 2,
            'golesVisitante': 0,
            'ganadorId': 'casa',
            'empate': false,
            'sets': const [],
          });

      await ResultadoService(firestore: db).recalcularTablaYRanking(kCampeonato);

      final tabla = await _tabla(db);

      expect(tabla['casa']!.diferenciaPuntos, 50);
      expect(tabla['visita']!.diferenciaPuntos, -50);
      expect(tabla['visita']!.puntos, 0);
    });
  });

  group('Walkover en básquet', () {
    test('se guarda 20-0', () async {
      final db = FakeFirebaseFirestore();

      await db.collection('campeonatos').doc(kCampeonato).set({
        'nombre': 'Copa básquet',
        'deporte': DeporteTipo.basket,
        'tipoCampeonato': TipoCampeonato.faseGrupos,
        'estado': CampeonatoEstado.activo,
        'configuracion': {
          'formato': TipoCampeonato.faseGrupos,
          'deporte': DeporteTipo.basket,
          'sistemaResultado': SistemaResultado.puntos,
        },
      });

      for (final id in ['casa', 'visita']) {
        await db
            .collection('campeonatos')
            .doc(kCampeonato)
            .collection('equipos')
            .doc(id)
            .set({'nombre': id, 'estado': EquipoEstado.activo});
      }

      await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('partidos')
          .doc('p1')
          .set({
            'jornada': 1,
            'vuelta': 1,
            'grupoId': 'Grupo A',
            'equipoLocalId': 'casa',
            'equipoLocalNombre': 'casa',
            'equipoVisitanteId': 'visita',
            'equipoVisitanteNombre': 'visita',
            'estado': PartidoEstado.programado,
            'resultadoRegistrado': false,
          });

      await ResultadoService(firestore: db).registrarResultado(
        campeonatoId: kCampeonato,
        partidoId: 'p1',
        golesLocal: 1,
        golesVisitante: 0,
        golesJugadores: const [],
        tipoResultado: TipoResultado.walkover,
        observacionResultado: 'No se presentaron.',
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
      );

      final doc = await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('partidos')
          .doc('p1')
          .get();

      expect(kPuntosWalkoverBasket, 20);
      expect(doc.data()!['golesLocal'], 20);
      expect(doc.data()!['golesVisitante'], 0);
    });
  });

  group('Tabla vieja', () {
    test('recalcular corrige los puntos guardados con las reglas de fútbol',
        () async {
      // Es lo que pasó con los campeonatos de vóley: la tabla se calculó
      // con 3/1/0 antes de que existieran las reglas por deporte y quedó
      // congelada ahí, mostrando 9 y 6 puntos donde correspondían 6 y 4.
      final db = await _baseVolley();

      await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('partidos')
          .doc('p1')
          .update({
            'estado': PartidoEstado.finalizado,
            'resultadoRegistrado': true,
            'tipoResultado': TipoResultado.normal,
            'golesLocal': 2,
            'golesVisitante': 0,
            'ganadorId': 'casa',
            'empate': false,
            'sets': const [
              {'local': 25, 'visitante': 20},
              {'local': 25, 'visitante': 18},
            ],
          });

      // Tabla guardada con los números viejos, en una fila suelta como
      // las que dejaban las versiones anteriores.
      await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('tabla_posiciones')
          .doc('fila-vieja')
          .set({'equipoId': 'casa', 'equipoNombre': 'casa', 'puntos': 9});

      await ResultadoService(firestore: db).recalcularTablaYRanking(kCampeonato);

      final tabla = await _tabla(db);

      expect(tabla['casa']!.puntos, 2, reason: 'ganar en vóley son 2 puntos');
      expect(tabla['visita']!.puntos, 1, reason: 'perder son 1');
      expect(
        tabla.containsKey('fila-vieja'),
        isFalse,
        reason: 'la fila vieja no puede quedar dando vueltas',
      );
    });
  });
}
