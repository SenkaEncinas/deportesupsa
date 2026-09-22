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

  /// Partidos programados que faltan jugar esta semana: desde ahora
  /// hasta el próximo lunes 00:00 (fin de la semana en curso). Antes
  /// mostraba simplemente "los próximos 5", sin importar si eran de
  /// dentro de un mes; el usuario pidió que sea la agenda de la semana.
  Stream<List<PartidoModel>> streamProximosPartidos(String campeonatoId) {
    final ahora = DateTime.now();

    // La "semana" pública termina el sábado a las 14:00: hasta esa hora
    // se muestran los partidos de esta semana, y pasadas las 14:00 ya se
    // muestran los de la semana siguiente (hasta el próximo sábado 14:00).
    final diasHastaSabado = (DateTime.saturday - ahora.weekday) % 7;
    var finSemana = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      14,
    ).add(Duration(days: diasHastaSabado));

    if (ahora.isAfter(finSemana)) {
      finSemana = finSemana.add(const Duration(days: 7));
    }

    return _campeonatos
        .doc(campeonatoId)
        .collection('partidos')
        .where('estado', isEqualTo: PartidoEstado.programado)
        .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(ahora))
        .where('fechaHora', isLessThan: Timestamp.fromDate(finSemana))
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
