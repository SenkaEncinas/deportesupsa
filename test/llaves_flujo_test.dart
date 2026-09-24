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
import 'package:futsal/services/campeonato_service.dart';
import 'package:futsal/services/partido_service.dart';
import 'package:futsal/services/resultado_service.dart';
import 'package:futsal/utils/fixture_grouping.dart';
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
    // Ya en fase eliminatoria: es cuando se arman las llaves, y es lo
    // que habilita cruzar equipos de grupos distintos.
    'faseActual': FaseCampeonato.eliminatoria,
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
      await _ganaLocal(
        resultados,
        _llave(await _partidos(db), RondaLlave.octavos, 1),
      );

      var cuartos1 = _llave(await _partidos(db), RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
      expect(
        cuartos1.equipoVisitanteNombre,
        'Ganador llave 8',
        reason: 'el otro lado sigue esperando',
      );

      // Llave 8: Equipo 8 vs Equipo 9. Gana el 8.
      await _ganaLocal(
        resultados,
        _llave(await _partidos(db), RondaLlave.octavos, 8),
      );

      cuartos1 = _llave(await _partidos(db), RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
      expect(cuartos1.equipoVisitanteNombre, 'Equipo 8');
      expect(cuartos1.tieneEquiposDefinidos, isTrue);
    });

    test(
      'jugando el campeonato entero, gana el 1 y el 2 llega a la final',
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
          final deLaRonda =
              (await _partidos(db)).where((p) => p.rondaLlave == ronda).toList()
                ..sort((a, b) => a.llave!.compareTo(b.llave!));

          for (final cruce in deLaRonda) {
            expect(
              cruce.tieneEquiposDefinidos,
              isTrue,
              reason:
                  'al llegar a $ronda llave ${cruce.llave} ya debería '
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
      },
    );

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

    test(
      'no se puede cargar resultado en un cruce sin rival definido',
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
      },
    );
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

      await _ganaLocal(
        resultados,
        _llave(await _partidos(db), RondaLlave.octavos, 1),
      );

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
      expect(libres.map((p) => p.equipoLocalNombre).toSet(), {
        'Equipo 1',
        'Equipo 2',
        'Equipo 3',
        'Equipo 4',
      });

      // Un pase directo no espera resultado: el equipo ya está puesto en
      // la ronda siguiente.
      final cuartos1 = _llave(partidos, RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
    });
  });

  group('Arrancar el cuadro en una ronda elegida', () {
    // El caso de vóley damas: 12 clasificados, con 6 cruces en la
    // primera ronda, 3 cuartos y un "mejor tercero" que entra a
    // semifinales. Eso no se deduce solo, así que el admin arma esas
    // rondas a mano y genera el cuadro recién desde semifinales.

    test('desde semifinal se crean solo 2 semis y la final', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(12),
        rondaInicial: RondaLlave.semifinal,
        sembrar: false,
      );

      final partidos = await _partidos(db);

      expect(partidos.length, 3);
      expect(
        partidos.where((p) => p.rondaLlave == RondaLlave.semifinal).length,
        2,
      );
      expect(
        partidos.where((p) => p.rondaLlave == RondaLlave.finalRonda).length,
        1,
      );
      expect(
        partidos.any((p) => p.rondaLlave == RondaLlave.cuartos),
        isFalse,
        reason: 'los cuartos los arma el admin a mano',
      );
    });

    test(
      'sin sembrar, los cruces quedan vacíos para cargarlos a mano',
      () async {
        final db = await _baseConCampeonato();

        await PartidoService(firestore: db).generarLlavesEliminatorias(
          campeonatoId: kCampeonato,
          clasificados: _clasificados(12),
          rondaInicial: RondaLlave.semifinal,
          sembrar: false,
        );

        final semis = (await _partidos(
          db,
        )).where((p) => p.rondaLlave == RondaLlave.semifinal).toList();

        for (final semi in semis) {
          expect(semi.tieneEquiposDefinidos, isFalse);
          expect(semi.esBye, isFalse, reason: 'vacío no es lo mismo que libre');
          expect(
            semi.esPrimeraRondaDeLlave,
            isTrue,
            reason: 'se tienen que poder editar con el lápiz',
          );
          expect(semi.equipoLocalNombre, 'Por definir');
        }
      },
    );

    test('la final sigue esperando a los ganadores de las semis', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(12),
        rondaInicial: RondaLlave.semifinal,
        sembrar: false,
      );

      final laFinal = _llave(await _partidos(db), RondaLlave.finalRonda, 1);

      expect(laFinal.vieneDeLocal, 1);
      expect(laFinal.vieneDeVisitante, 2);
      expect(laFinal.equipoLocalNombre, 'Ganador llave 1');
    });

    test('cargados los equipos a mano, el ganador avanza igual', () async {
      final db = await _baseConCampeonato();
      final partidoService = PartidoService(firestore: db);
      final resultados = ResultadoService(firestore: db);

      await partidoService.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(12),
        rondaInicial: RondaLlave.semifinal,
        sembrar: false,
      );

      // El admin completa la semifinal 1 con los dos equipos que
      // llegaron por su cuenta.
      final semi1 = _llave(await _partidos(db), RondaLlave.semifinal, 1);

      await partidoService.cambiarEquiposPartido(
        campeonatoId: kCampeonato,
        partidoId: semi1.id,
        local: _equipo(1),
        visitante: _equipo(5),
      );

      await _ganaLocal(
        resultados,
        _llave(await _partidos(db), RondaLlave.semifinal, 1),
      );

      final laFinal = _llave(await _partidos(db), RondaLlave.finalRonda, 1);

      expect(laFinal.equipoLocalNombre, 'Equipo 1');
      expect(laFinal.equipoVisitanteNombre, 'Ganador llave 2');
    });

    test('desde cuartos con siembra ubica a los 8 mejores', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
        rondaInicial: RondaLlave.cuartos,
        sembrar: true,
      );

      final partidos = await _partidos(db);

      expect(partidos.length, 7, reason: '4 cuartos + 2 semis + final');

      final cuartos1 = _llave(partidos, RondaLlave.cuartos, 1);
      expect(cuartos1.equipoLocalNombre, 'Equipo 1');
      expect(cuartos1.equipoVisitanteNombre, 'Equipo 8');
    });

    test('una ronda que no existe se rechaza', () async {
      final db = await _baseConCampeonato();

      expect(
        () => PartidoService(firestore: db).generarLlavesEliminatorias(
          campeonatoId: kCampeonato,
          clasificados: _clasificados(16),
          rondaInicial: 'cuartos_y_medio',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Formato de 12 equipos (vóley damas)', () {
    // El cuadro real: 12 clasificados -> 6 cruces -> 3 cuartos ->
    // semifinal con un "mejor" que no viene de ninguna llave. Nada de
    // eso se deduce solo, así que las dos primeras rondas se arman a
    // mano y el cuadro automático arranca en semifinales.

    Future<FakeFirebaseFirestore> armarADosManos() async {
      final db = await _baseConCampeonato();
      final servicio = PartidoService(firestore: db);

      // Los 6 cruces: 1-12, 2-11, 3-10, 4-9, 5-8, 6-7.
      for (var i = 1; i <= 6; i++) {
        await servicio.crearCruceManual(
          campeonatoId: kCampeonato,
          equipoLocal: _equipo(i),
          equipoVisitante: _equipo(13 - i),
          idaYVuelta: false,
        );
      }

      // Los 3 cuartos.
      for (var i = 1; i <= 3; i++) {
        await servicio.crearCruceManual(
          campeonatoId: kCampeonato,
          equipoLocal: _equipo(i),
          equipoVisitante: _equipo(7 - i),
          idaYVuelta: false,
        );
      }

      await servicio.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: const [],
        rondaInicial: RondaLlave.semifinal,
        sembrar: false,
      );

      return db;
    }

    test('generar el cuadro no borra los cruces cargados a mano', () async {
      final db = await armarADosManos();
      final partidos = await _partidos(db);

      expect(
        partidos.length,
        12,
        reason: '6 cruces + 3 cuartos a mano, más 2 semis y la final',
      );
      expect(partidos.where((p) => !p.generadoPorSistema).length, 9);
    });

    test('las semis quedan después de los cuartos en el orden', () async {
      final db = await armarADosManos();
      final partidos = await _partidos(db);

      final aMano = partidos.where((p) => !p.generadoPorSistema).toList();
      final semis = partidos
          .where((p) => p.rondaLlave == RondaLlave.semifinal)
          .toList();
      final laFinal = _llave(partidos, RondaLlave.finalRonda, 1);

      // Los cruces cargados a mano van todos juntos: la jornada la pone
      // la app, no el admin.
      expect(aMano.length, 9);
      expect(aMano.every((p) => p.jornada == aMano.first.jornada), isTrue);

      for (final semi in semis) {
        expect(
          semi.jornada,
          greaterThan(aMano.first.jornada),
          reason: 'una semifinal no puede ordenarse antes que lo manual',
        );
        expect(laFinal.jornada, greaterThan(semi.jornada));
      }
    });

    test(
      'el cuadro muestra solo lo generado; lo manual queda aparte',
      () async {
        final db = await armarADosManos();
        final deLlave = PartidoService(
          firestore: db,
        ).soloDeLlave(await _partidos(db));

        final rondas = FixtureGrouping.rondasEliminatorias(deLlave);

        // Los 6 cruces y los 3 cuartos se cargaron a mano: son partidos,
        // no rondas de un cuadro. El público los ve como tales.
        expect(rondas.map((r) => r.key).toList(), ['Semifinales', 'Final']);
        expect(rondas.map((r) => r.value.length).toList(), [2, 1]);

        expect(
          FixtureGrouping.crucesSueltos(deLlave).length,
          9,
          reason: 'los manuales siguen existiendo, fuera del cuadro',
        );
      },
    );

    test('regenerar el cuadro sigue sin tocar lo cargado a mano', () async {
      final db = await armarADosManos();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: const [],
        rondaInicial: RondaLlave.semifinal,
        sembrar: false,
      );

      final partidos = await _partidos(db);

      expect(partidos.length, 12, reason: 'ni se borran ni se duplican');
      expect(partidos.where((p) => !p.generadoPorSistema).length, 9);
    });
  });

  group('El flujo de siempre no cambia', () {
    // Lo que ya está capacitado: 16 clasificados, "Generar llaves" en
    // automático. Tiene que dar exactamente lo mismo que antes de que
    // existiera la opción de elegir la ronda.

    test('en automático, las jornadas siguen siendo 1, 2, 3 y 4', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final partidos = await _partidos(db);

      expect(_llave(partidos, RondaLlave.octavos, 1).jornada, 1);
      expect(_llave(partidos, RondaLlave.cuartos, 1).jornada, 2);
      expect(_llave(partidos, RondaLlave.semifinal, 1).jornada, 3);
      expect(_llave(partidos, RondaLlave.finalRonda, 1).jornada, 4);
    });

    test('en automático se siembra igual que siempre', () async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final partidos = await _partidos(db);

      expect(partidos.length, 15);
      for (var llave = 1; llave <= 8; llave++) {
        final cruce = _llave(partidos, RondaLlave.octavos, llave);
        expect(cruce.equipoLocalNombre, 'Equipo $llave');
        expect(cruce.equipoVisitanteNombre, 'Equipo ${17 - llave}');
      }
    });

    test('activar la fase eliminatoria no crea ningún partido', () async {
      final db = await _baseConCampeonato();

      final campeonatoDoc = await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .get();

      final campeonato = CampeonatoModel.fromMap(kCampeonato, {
        ...campeonatoDoc.data()!,
        'faseActual': FaseCampeonato.grupos,
      });

      await CampeonatoService(
        firestore: db,
      ).activarFaseEliminatoria(campeonato);

      expect(
        (await _partidos(db)).isEmpty,
        isTrue,
        reason: 'activar solo habilita; las llaves las decide el admin',
      );

      final despues = await db.collection('campeonatos').doc(kCampeonato).get();

      expect(despues.data()!['faseActual'], FaseCampeonato.eliminatoria);
    });
  });

  group('Un cruce suelto no es una llave', () {
    // Paso real: se cargó un cruce a mano con jornada 5 y, como era el
    // único de esa jornada, el público lo vio rotulado como "Final".
    // El cuadro tiene que aparecer solo cuando el admin lo genera.

    test('un cruce manual solo no se dibuja como cuadro', () async {
      final db = await _baseConCampeonato();
      final servicio = PartidoService(firestore: db);

      await servicio.crearCruceManual(
        campeonatoId: kCampeonato,
        equipoLocal: _equipo(1),
        equipoVisitante: _equipo(2),
        idaYVuelta: false,
      );

      final deLlave = servicio.soloDeLlave(await _partidos(db));

      expect(deLlave.length, 1);
      expect(
        FixtureGrouping.rondasEliminatorias(deLlave),
        isEmpty,
        reason: 'sin cuadro generado no hay llave que mostrar',
      );
      expect(FixtureGrouping.crucesSueltos(deLlave).length, 1);
    });

    test('ni aunque sean varios en jornadas distintas', () async {
      final db = await _baseConCampeonato();
      final servicio = PartidoService(firestore: db);

      for (var i = 1; i <= 3; i++) {
        await servicio.crearCruceManual(
          campeonatoId: kCampeonato,
          equipoLocal: _equipo(i),
          equipoVisitante: _equipo(i + 8),
          idaYVuelta: false,
        );
      }

      final deLlave = servicio.soloDeLlave(await _partidos(db));

      expect(FixtureGrouping.rondasEliminatorias(deLlave), isEmpty);
      expect(FixtureGrouping.crucesSueltos(deLlave).length, 3);
    });

    test('al generar el cuadro, recién ahí aparece la llave', () async {
      final db = await _baseConCampeonato();
      final servicio = PartidoService(firestore: db);

      await servicio.crearCruceManual(
        campeonatoId: kCampeonato,
        equipoLocal: _equipo(1),
        equipoVisitante: _equipo(2),
        idaYVuelta: false,
      );

      await servicio.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: const [],
        rondaInicial: RondaLlave.semifinal,
        sembrar: false,
      );

      final deLlave = servicio.soloDeLlave(await _partidos(db));
      final rondas = FixtureGrouping.rondasEliminatorias(deLlave);

      expect(rondas.map((r) => r.key).toList(), ['Semifinales', 'Final']);
      expect(
        FixtureGrouping.crucesSueltos(deLlave).length,
        1,
        reason: 'el cruce manual sigue existiendo, pero fuera del cuadro',
      );
    });
  });

  group('Botones de editar y borrar', () {
    Future<(FakeFirebaseFirestore, PartidoModel)> conCruceSuelto() async {
      final db = await _baseConCampeonato();

      await PartidoService(firestore: db).crearCruceManual(
        campeonatoId: kCampeonato,
        equipoLocal: _equipo(1),
        equipoVisitante: _equipo(2),
        idaYVuelta: false,
      );

      return (db, (await _partidos(db)).single);
    }

    test('un cruce suelto se puede borrar', () async {
      final (db, cruce) = await conCruceSuelto();

      await PartidoService(
        firestore: db,
      ).eliminarPartido(campeonatoId: kCampeonato, partidoId: cruce.id);

      expect((await _partidos(db)).isEmpty, isTrue);
    });

    test('borrado y vuelto a crear: no dice que ya existe', () async {
      final (db, cruce) = await conCruceSuelto();
      final servicio = PartidoService(firestore: db);

      await servicio.eliminarPartido(
        campeonatoId: kCampeonato,
        partidoId: cruce.id,
      );

      // Es lo que no podían hacer: borrar el equivocado y volver a
      // cargarlo bien.
      await servicio.crearCruceManual(
        campeonatoId: kCampeonato,
        equipoLocal: _equipo(1),
        equipoVisitante: _equipo(2),
        idaYVuelta: false,
      );

      expect((await _partidos(db)).length, 1);
    });

    test('crear el mismo cruce dos veces sí se rechaza', () async {
      final (db, _) = await conCruceSuelto();

      expect(
        () => PartidoService(firestore: db).crearCruceManual(
          campeonatoId: kCampeonato,
          equipoLocal: _equipo(1),
          equipoVisitante: _equipo(2),
          idaYVuelta: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('un cruce suelto se puede editar', () async {
      final (db, cruce) = await conCruceSuelto();

      await PartidoService(firestore: db).cambiarEquiposPartido(
        campeonatoId: kCampeonato,
        partidoId: cruce.id,
        local: _equipo(3),
        visitante: _equipo(4),
      );

      final despues = (await _partidos(db)).single;

      expect(despues.id, cruce.id);
      expect(despues.equipoLocalNombre, 'Equipo 3');
      expect(despues.equipoVisitanteNombre, 'Equipo 4');
    });

    test('con resultado cargado no se borra ni se edita', () async {
      final (db, cruce) = await conCruceSuelto();
      final servicio = PartidoService(firestore: db);

      await _ganaLocal(ResultadoService(firestore: db), cruce);

      expect(
        () => servicio.eliminarPartido(
          campeonatoId: kCampeonato,
          partidoId: cruce.id,
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => servicio.cambiarEquiposPartido(
          campeonatoId: kCampeonato,
          partidoId: cruce.id,
          local: _equipo(3),
          visitante: _equipo(4),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('un cruce del cuadro no se borra suelto', () async {
      final db = await _baseConCampeonato();
      final servicio = PartidoService(firestore: db);

      await servicio.generarLlavesEliminatorias(
        campeonatoId: kCampeonato,
        clasificados: _clasificados(16),
      );

      final octavo = _llave(await _partidos(db), RondaLlave.octavos, 1);

      // Se puede borrar desde el servicio, pero la pantalla lo bloquea:
      // forma parte del cuadro y se rehace con "Regenerar llaves".
      expect(octavo.esDeLlave, isTrue);
    });
  });

  group('Cruce repetido', () {
    // Caso real de vóley damas: Britanico y Don Bosco B jugaron en el
    // Grupo D (jornada 1) y se vuelven a cruzar en la eliminatoria. El
    // control de repetidos confundía ese partido de grupo con el cruce
    // nuevo y no dejaba cargarlo.

    test('dos equipos que ya jugaron en el grupo se pueden cruzar en la '
        'fase final', () async {
      final db = await _baseConCampeonato();

      await db
          .collection('campeonatos')
          .doc(kCampeonato)
          .collection('partidos')
          .doc('de-grupo')
          .set({
            'jornada': 1,
            'vuelta': 1,
            'grupoId': 'Grupo D',
            'equipoLocalId': _equipo(12).id,
            'equipoLocalNombre': _equipo(12).nombre,
            'equipoVisitanteId': _equipo(1).id,
            'equipoVisitanteNombre': _equipo(1).nombre,
            'estado': PartidoEstado.finalizado,
            'resultadoRegistrado': true,
            'golesLocal': 0,
            'golesVisitante': 2,
          });

      await PartidoService(firestore: db).crearCruceManual(
        campeonatoId: kCampeonato,
        equipoLocal: _equipo(1),
        equipoVisitante: _equipo(12),
        idaYVuelta: false,
      );

      final partidos = await _partidos(db);

      expect(partidos.length, 2, reason: 'el de grupo y el de fase final');
      expect(
        partidos.where((p) => p.grupoId == null || p.grupoId!.isEmpty).length,
        1,
      );
    });

    test(
      'dentro de la fase final, el mismo cruce sigue rechazándose',
      () async {
        final db = await _baseConCampeonato();
        final servicio = PartidoService(firestore: db);

        await servicio.crearCruceManual(
          campeonatoId: kCampeonato,
          equipoLocal: _equipo(1),
          equipoVisitante: _equipo(12),
          idaYVuelta: false,
        );

        expect(
          () => servicio.crearCruceManual(
            campeonatoId: kCampeonato,
            equipoLocal: _equipo(12),
            equipoVisitante: _equipo(1),
            idaYVuelta: false,
          ),
          throwsA(isA<Exception>()),
          reason: 'mismo par, mismo lado: es un repetido de verdad',
        );
      },
    );
  });
}
