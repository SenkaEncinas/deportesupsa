// Prueba del flujo completo de la fase eliminatoria, de punta a punta y
// contra un Firestore de mentira: generar el cuadro, programar los
// cruces, cargar resultados y ver cómo van avanzando los ganadores.
//
// Es la contraparte de `llaves_test.dart`: aquel verifica la forma del
// cuadro (quién juega contra quién); este verifica que el botón
// "Generar llaves" haga realmente lo que promete.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/partido_service.dart';
import 'package:futsal/services/resultado_service.dart';
import 'package:futsal/utils/llaves.dart';

const String kCampeonato = 'camp-1';

EquipoModel _equipo(int siembra) {
  return EquipoModel(
    id: 'e$siembra',
    nombre: 'Equipo $siembra',
    representante: 'Rep $siembra',
    estado: EquipoEstado.activo,
    cantidadJugadoresRegistrados: 11,
    creadoPor: 'test',
    actualizadoPor: 'test',
  );
}

/// Los clasificados de mejor a peor, que es como los entrega la tabla.
List<EquipoModel> _clasificados(int cantidad) {
  return List.generate(cantidad, (i) => _equipo(i + 1));
}

Future<FakeFirebaseFirestore> _baseConCampeonato() async {
  final db = FakeFirebaseFirestore();

  await db.collection('campeonatos').doc(kCampeonato).set({
    'nombre': 'Copa de prueba',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
    'configuracion': {
      'formato': TipoCampeonato.gruposEliminacion,
      'clasificanPorGrupo': 2,
      'mejoresTerceros': 4,
      'permiteEmpate': true,
      'generaFaseEliminatoria': true,
    },
  });

  for (final equipo in _clasificados(16)) {
    await db
        .collection('campeonatos')
        .doc(kCampeonato)
        .collection('equipos')
        .doc(equipo.id)
        .set({'nombre': equipo.nombre, 'estado': EquipoEstado.activo});
  }

  return db;
}

Future<List<PartidoModel>> _partidos(FakeFirebaseFirestore db) async {
  final snap = await db
      .collection('campeonatos')
      .doc(kCampeonato)
      .collection('partidos')
      .get();

  return snap.docs.map((d) => PartidoModel.fromMap(d.id, d.data())).toList();
}

/// El cruce de una ronda y número de llave concretos.
PartidoModel _llave(List<PartidoModel> partidos, String ronda, int llave) {
  return partidos.firstWhere(
    (p) => p.rondaLlave == ronda && p.llave == llave,
    orElse: () => throw StateError('no existe $ronda llave $llave'),
  );
}

/// Carga un resultado haciendo ganar al local por 2-0.
Future<void> _ganaLocal(
  ResultadoService resultados,
  PartidoModel partido,
) async {
  await resultados.registrarResultado(
    campeonatoId: kCampeonato,
    partidoId: partido.id,
    golesLocal: 2,
    golesVisitante: 0,
    golesJugadores: [
      GolJugadorInput(
        equipoId: partido.equipoLocalId,
        equipoNombre: partido.equipoLocalNombre,
        jugadorId: 'j-${partido.equipoLocalId}',
        jugadorNombre: 'Jugador',
        cantidad: 2,
      ),
    ],
    usuarioId: 'admin',
    usuarioNombre: 'Admin',
  );
}

void main() {
  group('El botón "Generar llaves"', () {
    test('crea el cuadro completo: 8 + 4 + 2 + 1', () async {
      final db = await _baseConCampeonato();
      final partidoService = PartidoService(firestore: db);

      await partidoService.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final partidos = await _partidos(db);

      expect(partidos.length, 15);
      expect(
        partidos.where((p) => p.rondaLlave == RondaLlave.octavos).length,
        8,
      );
      expect(
        partidos.where((p) => p.rondaLlave == RondaLlave.cuartos).length,
        4,
      );
      expect(
        partidos.where((p) => p.rondaLlave == RondaLlave.semifinal).length,
        2,
      );
      expect(
        partidos.where((p) => p.rondaLlave == RondaLlave.finalRonda).length,
        1,
      );
    });

    test('siembra los octavos 1-16, 2-15, ... 8-9', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final partidos = await _partidos(db);

      for (var llave = 1; llave <= 8; llave++) {
        final cruce = _llave(partidos, RondaLlave.octavos, llave);

        expect(cruce.equipoLocalNombre, 'Equipo $llave');
        expect(cruce.equipoVisitanteNombre, 'Equipo ${17 - llave}');
      }
    });

    test('deja las rondas siguientes esperando al ganador', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final partidos = await _partidos(db);
      final cuartos1 = _llave(partidos, RondaLlave.cuartos, 1);

      expect(cuartos1.equipoLocalNombre, 'Ganador llave 1');
      expect(cuartos1.equipoVisitanteNombre, 'Ganador llave 8');
      expect(cuartos1.tieneEquiposDefinidos, isFalse);

      final laFinal = _llave(partidos, RondaLlave.finalRonda, 1);
      expect(laFinal.equipoLocalNombre, 'Ganador llave 1');
      expect(laFinal.equipoVisitanteNombre, 'Ganador llave 2');
    });

    test('todos los cruces se pueden programar', () async {
      final db = await _baseConCampeonato();
      final partidoService = PartidoService(firestore: db);

      await partidoService.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      var fecha = DateTime(2026, 10, 1, 18, 0);

      for (final partido in await _partidos(db)) {
        await partidoService.programarPartido(
          campeonatoId: kCampeonato,
          partidoId: partido.id,
          fechaHora: fecha,
        );
        fecha = fecha.add(const Duration(hours: 2));
      }

      final programados = await _partidos(db);

      expect(programados.length, 15);
      expect(
        programados.every((p) => p.estado == PartidoEstado.programado),
        isTrue,
        reason: 'hasta la final se puede dejar con fecha desde el arranque',
      );
    });
  });

  group('Cargar resultados hace avanzar al ganador', () {
    test('el ganador de un octavo aparece en su cuarto', () async {
      final db = await _baseConCampeonato();
      final resultados = ResultadoService(firestore: db);

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      // Llave 1: Equipo 1 vs Equipo 16. Gana el 1.
      await _ganaLocal(resultados, _llave(await _partidos(db), RondaLlave.octavos, 1));

      var cuartos1 = _llave(await _partidos(db), RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
      expect(
        cuartos1.equipoVisitanteNombre,
        'Ganador llave 8',
        reason: 'el otro lado sigue esperando',
      );

      // Llave 8: Equipo 8 vs Equipo 9. Gana el 8.
      await _ganaLocal(resultados, _llave(await _partidos(db), RondaLlave.octavos, 8));

      cuartos1 = _llave(await _partidos(db), RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
      expect(cuartos1.equipoVisitanteNombre, 'Equipo 8');
      expect(cuartos1.tieneEquiposDefinidos, isTrue);
    });

    test('jugando el campeonato entero, gana el 1 y el 2 llega a la final',
        () async {
      final db = await _baseConCampeonato();
      final resultados = ResultadoService(firestore: db);

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      // Siempre gana el mejor sembrado, que en cada cruce es el local.
      for (final ronda in [
        RondaLlave.octavos,
        RondaLlave.cuartos,
        RondaLlave.semifinal,
        RondaLlave.finalRonda,
      ]) {
        final deLaRonda = (await _partidos(db))
            .where((p) => p.rondaLlave == ronda)
            .toList()
          ..sort((a, b) => a.llave!.compareTo(b.llave!));

        for (final cruce in deLaRonda) {
          expect(
            cruce.tieneEquiposDefinidos,
            isTrue,
            reason: 'al llegar a $ronda llave ${cruce.llave} ya debería '
                'tener sus dos equipos',
          );
          await _ganaLocal(resultados, cruce);
        }
      }

      final laFinal = _llave(await _partidos(db), RondaLlave.finalRonda, 1);

      expect(laFinal.equipoLocalNombre, 'Equipo 1');
      expect(
        laFinal.equipoVisitanteNombre,
        'Equipo 2',
        reason: 'el 1° y el 2° solo se cruzan en la final',
      );
      expect(laFinal.ganadorId, 'e1');
    });

    test('corregir un resultado corrige la ronda siguiente', () async {
      final db = await _baseConCampeonato();
      final resultados = ResultadoService(firestore: db);

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final octavo1 = _llave(await _partidos(db), RondaLlave.octavos, 1);

      await _ganaLocal(resultados, octavo1);
      expect(
        _llave(await _partidos(db), RondaLlave.cuartos, 1).equipoLocalNombre,
        'Equipo 1',
      );

      // Se rehace el resultado al revés: ahora gana el visitante.
      await resultados.registrarResultado(
        campeonatoId: kCampeonato,
        partidoId: octavo1.id,
        golesLocal: 0,
        golesVisitante: 3,
        golesJugadores: [
          GolJugadorInput(
            equipoId: octavo1.equipoVisitanteId,
            equipoNombre: octavo1.equipoVisitanteNombre,
            jugadorId: 'j-visita',
            jugadorNombre: 'Jugador',
            cantidad: 3,
          ),
        ],
        usuarioId: 'admin',
        usuarioNombre: 'Admin',
      );

      expect(
        _llave(await _partidos(db), RondaLlave.cuartos, 1).equipoLocalNombre,
        'Equipo 16',
        reason: 'el cuarto tiene que seguir al nuevo ganador',
      );
    });

    test('no se puede cargar resultado en un cruce sin rival definido',
        () async {
      final db = await _baseConCampeonato();
      final resultados = ResultadoService(firestore: db);

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final cuartos1 = _llave(await _partidos(db), RondaLlave.cuartos, 1);

      expect(
        () => _ganaLocal(resultados, cuartos1),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Regenerar el cuadro', () {
    test('no borra la programación ya cargada', () async {
      final db = await _baseConCampeonato();
      final partidoService = PartidoService(firestore: db);

      await partidoService.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final octavo3 = _llave(await _partidos(db), RondaLlave.octavos, 3);
      final fecha = DateTime(2026, 9, 30, 18, 30);

      await partidoService.programarPartido(
        campeonatoId: kCampeonato,
        partidoId: octavo3.id,
        fechaHora: fecha,
      );

      await partidoService.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final despues = _llave(await _partidos(db), RondaLlave.octavos, 3);

      expect(despues.id, octavo3.id, reason: 'es el mismo partido');
      expect(despues.fechaHora, fecha);
      expect(despues.estado, PartidoEstado.programado);
      expect((await _partidos(db)).length, 15, reason: 'sin duplicados');
    });

    test('se niega a pisar una llave que ya se jugó', () async {
      final db = await _baseConCampeonato();
      final partidoService = PartidoService(firestore: db);
      final resultados = ResultadoService(firestore: db);

      await partidoService.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      await _ganaLocal(resultados, _llave(await _partidos(db), RondaLlave.octavos, 1));

      expect(
        () => partidoService.generarLlavesEliminatorias(
          campeonatoId: kCampeonato,
          clasificados: _clasificados(16),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Cuadros que no se llenan', () {
    test('con 12 clasificados, los 4 mejores pasan directo', () async {
      final db = FakeFirebaseFirestore();

      await db.collection('campeonatos').doc(kCampeonato).set({
        'nombre': 'Copa de prueba',
        'deporte': DeporteTipo.futbol,
        'tipoCampeonato': TipoCampeonato.gruposEliminacion,
        'estado': CampeonatoEstado.activo,
        'configuracion': {'formato': TipoCampeonato.gruposEliminacion},
      });

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(12),
      );

      final partidos = await _partidos(db);
      final libres = partidos.where((p) => p.esBye).toList();

      expect(libres.length, 4);
      expect(
        libres.map((p) => p.equipoLocalNombre).toSet(),
        {'Equipo 1', 'Equipo 2', 'Equipo 3', 'Equipo 4'},
      );

      // Un pase directo no espera resultado: el equipo ya está puesto en
      // la ronda siguiente.
      final cuartos1 = _llave(partidos, RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
    });
  });
}
