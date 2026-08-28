import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';

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

  Stream<List<TablaPosicionModel>> streamTabla(String campeonatoId) {
    return _campeonatos
        .doc(campeonatoId)
        .collection('tabla_posiciones')
        .orderBy('posicion')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return TablaPosicionModel.fromMap(doc.id, doc.data());
          }).toList();
        });
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
