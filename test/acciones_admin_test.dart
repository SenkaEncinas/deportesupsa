// Acciones que el admin necesita para corregir errores sin ayuda:
// anular un resultado, borrar el fixture, eliminar un equipo, y que
// generar las llaves pase el campeonato a la fase eliminatoria.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/campeonato_service.dart';
import 'package:futsal/services/equipo_service.dart';
import 'package:futsal/services/partido_service.dart';
import 'package:futsal/services/resultado_service.dart';

const _camp = 'camp-1';

EquipoModel _equipo(int n) => EquipoModel(
  id: 'e$n',
  nombre: 'Equipo $n',
  representante: 'rep',
  estado: EquipoEstado.activo,
  cantidadJugadoresRegistrados: 0,
  creadoPor: 'test',
  actualizadoPor: 'test',
);

Future<FakeFirebaseFirestore> _base() async {
  final db = FakeFirebaseFirestore();
  final camp = db.collection('campeonatos').doc(_camp);
  await camp.set({
    'nombre': 'Copa',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
    'faseActual': FaseCampeonato.grupos,
    'configuracion': {
      'formato': TipoCampeonato.gruposEliminacion,
      'clasificanPorGrupo': 2,
    },
  });
  for (var i = 1; i <= 4; i++) {
    final e = _equipo(i);
    await camp.collection('equipos').doc(e.id).set({
      'nombre': e.nombre,
      'representante': 'rep',
      'estado': EquipoEstado.activo,
    });
  }
  return db;
}

Future<List<PartidoModel>> _partidos(FakeFirebaseFirestore db) async {
  final snap = await db
      .collection('campeonatos')
      .doc(_camp)
      .collection('partidos')
      .get();
  return snap.docs.map((d) => PartidoModel.fromMap(d.id, d.data())).toList();
}

Future<void> _generarCuadro(FakeFirebaseFirestore db) {
  return PartidoService(firestore: db).generarLlavesEliminatorias(
    campeonatoId: _camp,
    clasificados: [for (var i = 1; i <= 4; i++) _equipo(i)],
  );
}

Future<void> _gana(ResultadoService r, PartidoModel p) {
  return r.registrarResultado(
    campeonatoId: _camp,
    partidoId: p.id,
    golesLocal: 1,
    golesVisitante: 0,
    golesJugadores: [
      GolJugadorInput(
        equipoId: p.equipoLocalId,
        equipoNombre: p.equipoLocalNombre,
        jugadorId: 'j',
        jugadorNombre: 'J',
        cantidad: 1,
      ),
    ],
    usuarioId: 'admin',
    usuarioNombre: 'Admin',
  );
}

Future<void> _anular(ResultadoService r, PartidoModel p) {
  return r.anularResultado(
    campeonatoId: _camp,
    partidoId: p.id,
    motivo: 'marcador cargado al reves',
    usuarioId: 'admin',
    usuarioNombre: 'Admin',
  );
}

void main() {
  test('generar llaves pasa el campeonato a la fase eliminatoria', () async {
    final db = await _base();
    await _generarCuadro(db);

    final camp = await CampeonatoService(firestore: db).getCampeonato(_camp);
    expect(camp!.estaEnFaseEliminatoria, isTrue);
  });

  test('un cuadro generado sin activar la fase se repara solo', () async {
    final db = await _base();
    await db.collection('campeonatos').doc(_camp).collection('partidos').add({
      'rondaLlave': 'final',
      'llave': 1,
    });

    final service = CampeonatoService(firestore: db);
    final cambio = await service.activarFaseSiHayCuadro(_camp);
    final camp = await service.getCampeonato(_camp);

    expect(cambio, isTrue);
    expect(camp!.estaEnFaseEliminatoria, isTrue);
  });

  group('Anular resultado', () {
    test('el cruce queda sin jugar y libera la ronda siguiente', () async {
      final db = await _base();
      await _generarCuadro(db);
      final resultados = ResultadoService(firestore: db);
      final semi = (await _partidos(
        db,
      )).firstWhere((p) => p.rondaLlave == 'semifinal' && p.llave == 1);

      await _gana(resultados, semi);
      await _anular(resultados, semi);

      final partidos = await _partidos(db);
      final anulado = partidos.firstWhere((p) => p.id == semi.id);
      final finalCruce = partidos.firstWhere((p) => p.rondaLlave == 'final');

      expect(anulado.resultadoRegistrado, isFalse);
      expect(anulado.golesLocal, isNull);
      expect(finalCruce.equipoLocalId, isEmpty);
      expect(finalCruce.equipoLocalNombre, 'Ganador llave 1');
    });

    test('no se puede si el ganador ya jugó la ronda siguiente', () async {
      final db = await _base();
      await _generarCuadro(db);
      final resultados = ResultadoService(firestore: db);
      for (final p in (await _partidos(
        db,
      )).where((p) => p.rondaLlave == 'semifinal')) {
        await _gana(resultados, p);
      }
      final finalCruce = (await _partidos(
        db,
      )).firstWhere((p) => p.rondaLlave == 'final');
      await _gana(resultados, finalCruce);

      final semi = (await _partidos(
        db,
      )).firstWhere((p) => p.rondaLlave == 'semifinal');
      expect(() => _anular(resultados, semi), throwsException);
    });
  });

  group('Borrar fixture', () {
    test('borra los partidos si ninguno tiene resultado', () async {
      final db = await _base();
      final partidos = db
          .collection('campeonatos')
          .doc(_camp)
          .collection('partidos');
      await partidos.add({'equipoLocalId': 'e1', 'equipoVisitanteId': 'e2'});
      await partidos.add({'equipoLocalId': 'e3', 'equipoVisitanteId': 'e4'});

      final borrados = await PartidoService(firestore: db).borrarFixture(_camp);

      expect(borrados, 2);
      expect(await _partidos(db), isEmpty);
    });

    test('no deja borrar si hay resultados', () async {
      final db = await _base();
      await db.collection('campeonatos').doc(_camp).collection('partidos').add({
        'equipoLocalId': 'e1',
        'equipoVisitanteId': 'e2',
        'resultadoRegistrado': true,
      });

      expect(
        () => PartidoService(firestore: db).borrarFixture(_camp),
        throwsException,
      );
    });
  });

  group('Eliminar equipo', () {
    test('borra el equipo y sus jugadores si no está en el fixture', () async {
      final db = await _base();
      final camp = db.collection('campeonatos').doc(_camp);
      await camp.collection('jugadores').add({'equipoId': 'e1'});
      await camp.collection('jugadores').add({'equipoId': 'e2'});

      await EquipoService(firestore: db).eliminarEquipo(
        campeonatoId: _camp,
        equipoId: 'e1',
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
      );

      final equipo = await camp.collection('equipos').doc('e1').get();
      final jugadores = await camp.collection('jugadores').get();
      expect(equipo.exists, isFalse);
      expect(jugadores.docs.map((d) => d['equipoId']), ['e2']);
    });

    test('no deja borrar un equipo que ya está en el fixture', () async {
      final db = await _base();
      await db.collection('campeonatos').doc(_camp).collection('partidos').add({
        'equipoLocalId': 'e1',
        'equipoVisitanteId': 'e2',
      });

      expect(
        () => EquipoService(firestore: db).eliminarEquipo(
          campeonatoId: _camp,
          equipoId: 'e1',
          usuarioId: 'admin',
          usuarioNombre: 'Admin',
        ),
        throwsException,
      );
    });
  });
}
