import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../utils/tabla_calculo.dart';

class PublicHomeService {
  PublicHomeService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _campeonatos =>
      _db.collection('campeonatos');

  Stream<List<CampeonatoModel>> streamCampeonatosPublicos() {
    return _campeonatos
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) {
          final campeonatos = snap.docs
              .map((doc) => CampeonatoModel.fromMap(doc.id, doc.data()))
              .toList();

          campeonatos.sort((a, b) {
            final estadoCompare = _estadoPriority(
              a.estado,
            ).compareTo(_estadoPriority(b.estado));

            if (estadoCompare != 0) return estadoCompare;

            final fechaA = a.fechaCreacion ?? DateTime(1900);
            final fechaB = b.fechaCreacion ?? DateTime(1900);

            return fechaB.compareTo(fechaA);
          });

          return campeonatos;
        });
  }

  Stream<CampeonatoModel?> streamCampeonatoPrincipal() {
    return streamCampeonatosPublicos().map((campeonatos) {
      if (campeonatos.isEmpty) return null;

      for (final campeonato in campeonatos) {
        if (campeonato.estado == CampeonatoEstado.activo) {
          return campeonato;
        }
      }

      for (final campeonato in campeonatos) {
        if (campeonato.estado == CampeonatoEstado.inscripcion) {
          return campeonato;
        }
      }

      return campeonatos.first;
    });
  }

  Stream<List<EquipoModel>> streamEquipos(String campeonatoId) {
    return _campeonatos
        .doc(campeonatoId)
        .collection('equipos')
        .orderBy('nombre')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return EquipoModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<PartidoModel>> streamPartidos(String campeonatoId) {
    return _campeonatos
        .doc(campeonatoId)
        .collection('partidos')
        .orderBy('vuelta')
        .orderBy('jornada')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return PartidoModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  /// Rango de fechas de "Próximos partidos": desde el comienzo de hoy
  /// hasta el final de la semana que viene (semanas de lunes a domingo).
  ///
  /// Antes la semana se cortaba el sábado a las 14:00, y los partidos
  /// del sábado a la tarde no aparecían hasta que pasaba ese corte. Ahora
  /// se ve todo lo programado de esta semana y de la siguiente. No más
  /// allá: cuando el profe programa el campeonato entero de una, la lista
  /// no se llena con partidos de dentro de un mes.
  ///
  /// [corteSemana] separa "esta semana" de "la semana que viene"; la
  /// pantalla lo usa para mostrar primero los de esta semana.
  static ({DateTime desde, DateTime corteSemana, DateTime hasta}) rangoProximos(
    DateTime ahora,
  ) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    // Se arma con DateTime(...) y no sumando Duration: así un cambio de
    // horario no corre el lunes a las 23:00 del domingo.
    final lunes = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));

    return (
      desde: hoy,
      corteSemana: DateTime(lunes.year, lunes.month, lunes.day + 7),
      hasta: DateTime(lunes.year, lunes.month, lunes.day + 14),
    );
  }

  /// Partidos programados de esta semana y la siguiente, por fecha (ver
  /// [rangoProximos]). Arranca a principio del día y no "desde ahora"
  /// para que el partido de hoy siga a la vista mientras se juega: sale
  /// de la lista cuando se carga su resultado y deja de estar
  /// programado.
  Stream<List<PartidoModel>> streamProximosPartidos(String campeonatoId) {
    final rango = rangoProximos(DateTime.now());

    return _campeonatos
        .doc(campeonatoId)
        .collection('partidos')
        .where('estado', isEqualTo: PartidoEstado.programado)
        .where(
          'fechaHora',
          isGreaterThanOrEqualTo: Timestamp.fromDate(rango.desde),
        )
        .where('fechaHora', isLessThan: Timestamp.fromDate(rango.hasta))
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return PartidoModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<PartidoModel>> streamUltimosResultados(String campeonatoId) {
    return _campeonatos
        .doc(campeonatoId)
        .collection('partidos')
        .where('estado', isEqualTo: PartidoEstado.finalizado)
        .snapshots()
        .map((snap) {
          final partidos = snap.docs.map((doc) {
            return PartidoModel.fromMap(doc.id, doc.data());
          }).toList();

          partidos.sort((a, b) {
            final fechaA =
                a.fechaActualizacion ?? a.fechaHora ?? DateTime(1900);
            final fechaB =
                b.fechaActualizacion ?? b.fechaHora ?? DateTime(1900);
            return fechaB.compareTo(fechaA);
          });

          return partidos.take(5).toList();
        });
  }

  /// La tabla de posiciones, calculada en vivo.
  ///
  /// No se lee de `tabla_posiciones`: se arma con [TablaCalculo] a
  /// partir del campeonato, los equipos y los partidos, y se rehace sola
  /// cada vez que cambia cualquiera de los tres. Así un resultado nuevo,
  /// una igualación o un cambio de reglas se ven en el momento.
  ///
  /// Leerla de la colección guardada era el origen de un problema feo:
  /// esa copia solo se reescribía al registrar un resultado, así que
  /// quedaba mostrando números viejos indefinidamente. La colección
  /// sigue existiendo, pero como registro, no como fuente de verdad.
  Stream<List<TablaPosicionModel>> streamTabla(String campeonatoId) {
    return _combinar3(
      _campeonatos.doc(campeonatoId).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : CampeonatoModel.fromMap(doc.id, data);
      }),
      streamEquipos(campeonatoId),
      streamPartidos(campeonatoId),
      (campeonato, equipos, partidos) {
        if (campeonato == null) return <TablaPosicionModel>[];

        return TablaCalculo.calcular(
          campeonato: campeonato,
          equipos: equipos,
          partidos: partidos,
        );
      },
    );
  }

  /// Combina tres streams: emite cada vez que cambia cualquiera de
  /// ellos, una vez que los tres dieron al menos un valor.
  ///
  /// Dart no trae un `combineLatest` y no vale la pena sumar una
  /// dependencia por esto.
  static Stream<R> _combinar3<A, B, C, R>(
    Stream<A> a,
    Stream<B> b,
    Stream<C> c,
    R Function(A, B, C) combinar,
  ) {
    late final StreamController<R> control;
    final subs = <StreamSubscription<dynamic>>[];

    late A ultimoA;
    late B ultimoB;
    late C ultimoC;
    var hayA = false;
    var hayB = false;
    var hayC = false;

    void emitir() {
      if (hayA && hayB && hayC) {
        control.add(combinar(ultimoA, ultimoB, ultimoC));
      }
    }

    control = StreamController<R>(
      onListen: () {
        subs.add(
          a.listen((valor) {
            ultimoA = valor;
            hayA = true;
            emitir();
          }, onError: control.addError),
        );
        subs.add(
          b.listen((valor) {
            ultimoB = valor;
            hayB = true;
            emitir();
          }, onError: control.addError),
        );
        subs.add(
          c.listen((valor) {
            ultimoC = valor;
            hayC = true;
            emitir();
          }, onError: control.addError),
        );
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        subs.clear();
      },
    );

    return control.stream;
  }

  Stream<List<RankingGoleadorModel>> streamRankingGoleadores(
    String campeonatoId,
  ) {
    return _campeonatos
        .doc(campeonatoId)
        .collection('ranking_goleadores')
        .orderBy('totalGoles', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return RankingGoleadorModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  int _estadoPriority(String estado) {
    switch (estado) {
      case CampeonatoEstado.activo:
        return 0;
      case CampeonatoEstado.inscripcion:
        return 1;
      case CampeonatoEstado.finalizado:
        return 2;
      default:
        return 3;
    }
  }
}
