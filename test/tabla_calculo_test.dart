// La tabla de posiciones: que salga bien para cada deporte y que se
// rehaga sola cuando cambian los datos.
//
// El bug que motivó estos tests: la tabla solo existía guardada en
// Firestore y se reescribía únicamente al registrar un resultado. Si
// cambiaba una regla, seguía mostrando los números viejos para siempre.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/models/tabla_posicion_model.dart';
import 'package:futsal/services/public_home_service.dart';
import 'package:futsal/utils/tabla_calculo.dart';

CampeonatoModel _campeonato({
  required String deporte,
  Map<String, dynamic>? reglasGuardadas,
  Map<String, dynamic> igualaciones = const {},
}) {
  return CampeonatoModel.fromMap('camp-1', {
    'nombre': 'Copa de prueba',
    'deporte': deporte,
    'tipoCampeonato': TipoCampeonato.faseGrupos,
    'estado': CampeonatoEstado.activo,
    'reglasPuntuacion': ?reglasGuardadas,
    'igualaciones': igualaciones,
    'configuracion': {
      'formato': TipoCampeonato.faseGrupos,
      'deporte': deporte,
      'setsParaGanar': 2,
      'puntosSetNormal': 25,
    },
  });
}

EquipoModel _equipo(String id) {
  return EquipoModel(
    id: id,
    nombre: id,
    representante: 'rep',
    estado: EquipoEstado.activo,
    cantidadJugadoresRegistrados: 6,
    creadoPor: 'test',
    actualizadoPor: 'test',
  );
}

PartidoModel _partido({
  required String local,
  required String visitante,
  required int golesLocal,
  required int golesVisitante,
  String grupo = 'Grupo A',
  String tipoResultado = TipoResultado.normal,
  List<Map<String, int>> sets = const [],
}) {
  return PartidoModel.fromMap('p-$local-$visitante', {
    'jornada': 1,
    'vuelta': 1,
    'grupoId': grupo,
    'equipoLocalId': local,
    'equipoLocalNombre': local,
    'equipoVisitanteId': visitante,
    'equipoVisitanteNombre': visitante,
    'estado': PartidoEstado.finalizado,
    'resultadoRegistrado': true,
    'golesLocal': golesLocal,
    'golesVisitante': golesVisitante,
    'tipoResultado': tipoResultado,
    'sets': sets,
  });
}

Map<String, TablaPosicionModel> _porEquipo(List<TablaPosicionModel> tabla) {
  return {for (final fila in tabla) fila.equipoId: fila};
}

void main() {
  group('Puntos según el deporte', () {
    test('fútbol: 3 por ganar, 1 por empatar, 0 por perder', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(deporte: DeporteTipo.futbol),
          equipos: [_equipo('a'), _equipo('b'), _equipo('c')],
          partidos: [
            _partido(local: 'a', visitante: 'b', golesLocal: 2, golesVisitante: 0),
            _partido(local: 'b', visitante: 'c', golesLocal: 1, golesVisitante: 1),
          ],
        ),
      );

      expect(tabla['a']!.puntos, 3);
      expect(tabla['b']!.puntos, 1);
      expect(tabla['c']!.puntos, 1);
    });

    test('vóley: 2 por ganar y 1 por perder, aunque el campeonato tenga '
        'guardadas las reglas de fútbol', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(
            deporte: DeporteTipo.volley,
            reglasGuardadas: {'victoria': 3, 'empate': 1, 'derrota': 0},
          ),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            _partido(
              local: 'a',
              visitante: 'b',
              golesLocal: 2,
              golesVisitante: 0,
              sets: [
                {'local': 25, 'visitante': 20},
                {'local': 25, 'visitante': 18},
              ],
            ),
          ],
        ),
      );

      expect(tabla['a']!.puntos, 2);
      expect(tabla['b']!.puntos, 1);
    });

    test('básquet: 2 por ganar y 1 por perder, como manda la FIBA', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(
            deporte: DeporteTipo.basket,
            reglasGuardadas: {'victoria': 3, 'empate': 1, 'derrota': 0},
          ),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            _partido(local: 'a', visitante: 'b', golesLocal: 78, golesVisitante: 65),
          ],
        ),
      );

      expect(tabla['a']!.puntos, 2);
      expect(tabla['b']!.puntos, 1);
    });

    test('básquet: la diferencia son los puntos del partido', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(deporte: DeporteTipo.basket),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            _partido(local: 'a', visitante: 'b', golesLocal: 78, golesVisitante: 65),
          ],
        ),
      );

      expect(tabla['a']!.puntosFavor, 78);
      expect(tabla['a']!.puntosContra, 65);
      expect(tabla['a']!.diferenciaPuntos, 13);
      expect(tabla['b']!.diferenciaPuntos, -13);
    });
  });

  group('Walkover', () {
    test('vóley: 50-0 y el que no se presentó suma 0', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(deporte: DeporteTipo.volley),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            // Sin sets guardados, como los cargados por versiones viejas.
            _partido(
              local: 'a',
              visitante: 'b',
              golesLocal: 2,
              golesVisitante: 0,
              tipoResultado: TipoResultado.walkover,
            ),
          ],
        ),
      );

      expect(tabla['a']!.diferenciaPuntos, 50);
      expect(tabla['a']!.puntos, 2);
      expect(tabla['b']!.diferenciaPuntos, -50);
      expect(tabla['b']!.puntos, 0, reason: 'no cobra el punto por perder');
    });

    test('básquet: 20-0 y el que no se presentó suma 0', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(deporte: DeporteTipo.basket),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            _partido(
              local: 'a',
              visitante: 'b',
              golesLocal: 20,
              golesVisitante: 0,
              tipoResultado: TipoResultado.walkover,
            ),
          ],
        ),
      );

      expect(TablaCalculo.puntosWalkoverBasket, 20);
      expect(tabla['a']!.diferenciaPuntos, 20);
      expect(tabla['a']!.puntos, 2);
      expect(tabla['b']!.puntos, 0);
    });
  });

  group('Igualación', () {
    test('los puntos cargados a mano se suman a los ganados', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(
            deporte: DeporteTipo.volley,
            igualaciones: {'b': 2},
          ),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            _partido(local: 'a', visitante: 'b', golesLocal: 2, golesVisitante: 0),
          ],
        ),
      );

      expect(tabla['a']!.puntos, 2);
      expect(tabla['b']!.puntos, 3, reason: '1 por perder + 2 de igualación');
      expect(tabla['b']!.puntosIgualacion, 2);
      expect(
        tabla['b']!.posicion,
        1,
        reason: 'la igualación lo deja arriba en la tabla',
      );
    });
  });

  group('Qué partidos cuentan', () {
    test('los que todavía no se jugaron no suman', () {
      final pendiente = PartidoModel.fromMap('pend', {
        'grupoId': 'Grupo A',
        'equipoLocalId': 'a',
        'equipoVisitanteId': 'b',
        'estado': PartidoEstado.programado,
        'resultadoRegistrado': false,
      });

      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: _campeonato(deporte: DeporteTipo.futbol),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [pendiente],
        ),
      );

      expect(tabla['a']!.partidosJugados, 0);
      expect(tabla['a']!.puntos, 0);
    });

    test('en formatos con grupos, la fase final no suma para la tabla', () {
      final tabla = _porEquipo(
        TablaCalculo.calcular(
          campeonato: CampeonatoModel.fromMap('camp-1', {
            'nombre': 'Copa',
            'deporte': DeporteTipo.futbol,
            'tipoCampeonato': TipoCampeonato.gruposEliminacion,
            'estado': CampeonatoEstado.activo,
            'configuracion': {'formato': TipoCampeonato.gruposEliminacion},
          }),
          equipos: [_equipo('a'), _equipo('b')],
          partidos: [
            _partido(local: 'a', visitante: 'b', golesLocal: 1, golesVisitante: 0),
            // Cruce de llave: sin grupo.
            _partido(
              local: 'a',
              visitante: 'b',
              golesLocal: 5,
              golesVisitante: 0,
              grupo: '',
            ),
          ],
        ),
      );

      expect(tabla['a']!.partidosJugados, 1);
      expect(tabla['a']!.golesFavor, 1, reason: 'el 5-0 de la llave no cuenta');
    });
  });

  group('La tabla se rehace sola', () {
    /// Prepara un campeonato de vóley con un partido sin jugar.
    Future<FakeFirebaseFirestore> base() async {
      final db = FakeFirebaseFirestore();

      await db.collection('campeonatos').doc('camp-1').set({
        'nombre': 'Copa vóley',
        'deporte': DeporteTipo.volley,
        'tipoCampeonato': TipoCampeonato.faseGrupos,
        'estado': CampeonatoEstado.activo,
        'reglasPuntuacion': {'victoria': 3, 'empate': 1, 'derrota': 0},
        'configuracion': {
          'formato': TipoCampeonato.faseGrupos,
          'deporte': DeporteTipo.volley,
          'setsParaGanar': 2,
          'puntosSetNormal': 25,
        },
      });

      for (final id in ['a', 'b']) {
        await db
            .collection('campeonatos')
            .doc('camp-1')
            .collection('equipos')
            .doc(id)
            .set({'nombre': id, 'estado': EquipoEstado.activo});
      }

      return db;
    }

    test('no lee la copia guardada: la calcula', () async {
      final db = await base();

      // Una tabla guardada con números inventados, que no se tienen que
      // ver por ningún lado.
      await db
          .collection('campeonatos')
          .doc('camp-1')
          .collection('tabla_posiciones')
          .doc('a')
          .set({
            'equipoId': 'a',
            'equipoNombre': 'a',
            'puntos': 99,
            'posicion': 1,
          });

      final tabla = await PublicHomeService(firestore: db)
          .streamTabla('camp-1')
          .first;

      expect(tabla.length, 2);
      expect(
        _porEquipo(tabla)['a']!.puntos,
        0,
        reason: 'todavía no se jugó nada, los 99 guardados son basura vieja',
      );
    });

    test('al cargar un resultado, la tabla cambia sin recargar nada',
        () async {
      final db = await base();
      final service = PublicHomeService(firestore: db);

      final emisiones = <List<TablaPosicionModel>>[];
      final sub = service.streamTabla('camp-1').listen(emisiones.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emisiones.last.every((f) => f.puntos == 0), isTrue);

      await db
          .collection('campeonatos')
          .doc('camp-1')
          .collection('partidos')
          .doc('p1')
          .set({
            'jornada': 1,
            'vuelta': 1,
            'grupoId': 'Grupo A',
            'equipoLocalId': 'a',
            'equipoLocalNombre': 'a',
            'equipoVisitanteId': 'b',
            'equipoVisitanteNombre': 'b',
            'estado': PartidoEstado.finalizado,
            'resultadoRegistrado': true,
            'golesLocal': 2,
            'golesVisitante': 0,
            'tipoResultado': TipoResultado.normal,
            'sets': const [
              {'local': 25, 'visitante': 20},
              {'local': 25, 'visitante': 18},
            ],
          });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final ultima = _porEquipo(emisiones.last);
      expect(ultima['a']!.puntos, 2);
      expect(ultima['b']!.puntos, 1);

      await sub.cancel();
    });

    test('al cambiar una igualación, la tabla cambia sola', () async {
      final db = await base();
      final service = PublicHomeService(firestore: db);

      final emisiones = <List<TablaPosicionModel>>[];
      final sub = service.streamTabla('camp-1').listen(emisiones.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await db.collection('campeonatos').doc('camp-1').update({
        'igualaciones': {'b': 3},
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(_porEquipo(emisiones.last)['b']!.puntos, 3);

      await sub.cancel();
    });
  });
}
