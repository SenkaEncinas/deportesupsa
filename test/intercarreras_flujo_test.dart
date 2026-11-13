// INTERCARRERAS 2/2026 de punta a punta, como quedó en la base real y
// como se tiene que terminar: igual que el vóley damas (cruces a mano en
// la primera ronda y después el cuadro desde semifinales).
//
// Situación real al empezar:
// - Formato "Fase de grupos" (solo grupos): Grupo A con 5, Grupo B con 4.
// - Los 3 cruces de eliminación se cargaron como "privilegio" (amistosos)
//   porque no había forma de activar la eliminatoria. Ya tienen resultado,
//   goles y tarjetas, y dos son empates sin penales (1-1 y 2-2).
// - Clasifican 6 (3 por grupo).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/campeonato_service.dart';
import 'package:futsal/services/partido_service.dart';
import 'package:futsal/services/resultado_service.dart';
import 'package:futsal/utils/fixture_grouping.dart';
import 'package:futsal/utils/llaves.dart';

const String kCamp = 'intercarreras';

EquipoModel _equipo(String id) => EquipoModel(
  id: id,
  nombre: id.toUpperCase(),
  representante: 'rep',
  estado: EquipoEstado.activo,
  cantidadJugadoresRegistrados: 11,
  creadoPor: 'test',
  actualizadoPor: 'test',
);

void main() {
  late FakeFirebaseFirestore db;
  late CampeonatoService campeonatos;
  late PartidoService partidos;
  late ResultadoService resultados;

  CollectionReference<Map<String, dynamic>> col(String nombre) =>
      db.collection('campeonatos').doc(kCamp).collection(nombre);

  Future<CampeonatoModel> campeonato() async =>
      (await campeonatos.getCampeonato(kCamp))!;

  Future<List<PartidoModel>> todos() => partidos.getPartidos(kCamp);

  setUp(() async {
    db = FakeFirebaseFirestore();
    campeonatos = CampeonatoService(firestore: db);
    resultados = ResultadoService(firestore: db);
    partidos = PartidoService(firestore: db, resultadoService: resultados);

    await db.collection('campeonatos').doc(kCamp).set({
      'nombre': 'INTERCARRERAS SEMESTRE 2/2026',
      'deporte': DeporteTipo.futbol,
      'tipoCampeonato': TipoCampeonato.faseGrupos,
      'estado': CampeonatoEstado.activo,
      'configuracion': {
        'formato': 'grupos',
        'cantidadGrupos': 2,
        'clasificanPorGrupo': 0,
        'mejoresTerceros': 0,
        'generaFaseEliminatoria': false,
      },
    });

    for (final id in [
      'financiera',
      'civil',
      'arquitectura',
      'derecho',
      'administrativo',
      'comercial',
    ]) {
      await col('equipos').doc(id).set(_equipo(id).toMap());
    }

    // Uno de los cruces cargados con privilegio, con su 2-2 sin penales,
    // sus goles y sus tarjetas.
    await col('partidos').doc('priv-1').set({
      'jornada': 1,
      'vuelta': 1,
      'grupoId': null,
      'privilegio': true,
      'generadoPorSistema': false,
      'equipoLocalId': 'comercial',
      'equipoLocalNombre': 'COMERCIAL',
      'equipoVisitanteId': 'derecho',
      'equipoVisitanteNombre': 'DERECHO',
      'estado': PartidoEstado.finalizado,
      'resultadoRegistrado': true,
      'golesLocal': 2,
      'golesVisitante': 2,
      'empate': true,
    });
    await col('goles').add({'partidoId': 'priv-1', 'cantidad': 2});
    await col('tarjetas').add({'partidoId': 'priv-1'});
  });

  test('flujo completo: convertir, activar, borrar privilegios, cruces a '
      'mano con penales y cuadro desde semifinales', () async {
    // 1. Sin convertir no hay eliminatoria posible.
    expect((await campeonato()).tieneFasesSeparadas, isFalse);

    // 2. "Agregar fase eliminatoria": 3 por grupo, sin terceros = 6.
    await campeonatos.agregarFaseEliminatoria(
      campeonato: await campeonato(),
      clasificanPorGrupo: 3,
      mejoresTerceros: 0,
      usuarioId: 'admin',
      usuarioNombre: 'Admin',
    );
    expect((await campeonato()).totalClasificados, 6);

    // 3. "Activar fase eliminatoria".
    await campeonatos.activarFaseEliminatoria(await campeonato());
    expect((await campeonato()).estaEnFaseEliminatoria, isTrue);

    // 4. Borrar el cruce con privilegio, aunque ya tenga resultado: se va
    //    con sus goles y tarjetas.
    await resultados.eliminarPartidoManual(
      campeonatoId: kCamp,
      partidoId: 'priv-1',
      usuarioId: 'admin',
      usuarioNombre: 'Admin',
    );
    expect((await todos()).where((p) => p.id == 'priv-1'), isEmpty);
    expect((await col('goles').get()).docs, isEmpty);
    expect((await col('tarjetas').get()).docs, isEmpty);

    // 5. Volver a cargarlo como cruce manual: ya no es privilegio, es de
    //    la fase final.
    await partidos.crearCruceManual(
      campeonatoId: kCamp,
      equipoLocal: _equipo('comercial'),
      equipoVisitante: _equipo('derecho'),
      idaYVuelta: false,
    );
    final cruce = (await todos()).single;
    final camp = await campeonato();
    expect(cruce.privilegio, isFalse);
    expect(cruce.tieneGrupo, isFalse);
    expect(camp.esDeFaseFinal(cruce), isTrue);
    expect(camp.requiereGanador(cruce), isTrue);

    // 6. Un empate sin penales se rechaza; con penales queda el ganador.
    Future<void> cargar({int? penLocal, int? penVisitante}) =>
        resultados.registrarResultado(
          campeonatoId: kCamp,
          partidoId: cruce.id,
          golesLocal: 0,
          golesVisitante: 0,
          golesJugadores: const [],
          usuarioId: 'admin',
          usuarioNombre: 'Admin',
          penalesLocal: penLocal,
          penalesVisitante: penVisitante,
        );

    await expectLater(cargar(), throwsException);
    await cargar(penLocal: 4, penVisitante: 3);

    final jugado = (await todos()).single;
    expect(jugado.resultadoRegistrado, isTrue);
    expect(jugado.definidoPorPenales, isTrue);
    expect(jugado.ganadorId, 'comercial');

    // 7. El cuadro desde semifinales, vacío para completarlo a mano, igual
    //    que en el vóley damas. El cruce manual no se toca.
    await partidos.generarLlavesEliminatorias(
      campeonatoId: kCamp,
      clasificados: [
        for (final id in [
          'financiera',
          'derecho',
          'civil',
          'administrativo',
          'arquitectura',
          'comercial',
        ])
          _equipo(id),
      ],
      rondaInicial: RondaLlave.semifinal,
      sembrar: false,
    );

    final despues = await todos();
    expect(despues.where((p) => p.id == cruce.id), hasLength(1));

    final rondas = FixtureGrouping.rondasEliminatorias(
      despues.where((p) => p.esDeLlave).toList(),
    );
    expect(rondas.map((r) => r.value.length).toList(), [2, 1]);

    final semis = despues
        .where((p) => p.rondaLlave == RondaLlave.semifinal)
        .toList();
    expect(semis.every((p) => !p.tieneEquiposDefinidos), isTrue);
    expect(semis.every((p) => p.esPrimeraRondaDeLlave), isTrue);

    // 8. Completar una semifinal con el lápiz.
    await partidos.cambiarEquiposPartido(
      campeonatoId: kCamp,
      partidoId: semis.first.id,
      local: _equipo('financiera'),
      visitante: _equipo('comercial'),
    );
    final semi = (await todos()).firstWhere((p) => p.id == semis.first.id);
    expect(semi.tieneEquiposDefinidos, isTrue);
    expect((await campeonato()).requiereGanador(semi), isTrue);
  });

  test('no se borra un partido del fixture generado ni del cuadro', () async {
    await col('partidos').doc('gen').set({
      'jornada': 1,
      'vuelta': 1,
      'grupoId': 'Grupo A',
      'generadoPorSistema': true,
      'equipoLocalId': 'civil',
      'equipoVisitanteId': 'financiera',
      'estado': PartidoEstado.programado,
    });

    expect(
      () => resultados.eliminarPartidoManual(
        campeonatoId: kCamp,
        partidoId: 'gen',
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
      ),
      throwsException,
    );
  });
}
