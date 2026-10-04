import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../utils/stream_compartido.dart';
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
  ///
  /// Se calcula sobre la lista de partidos que la pantalla ya tiene
  /// abierta, en vez de hacer otra consulta a Firestore.
  static List<PartidoModel> proximos(
    List<PartidoModel> partidos,
    DateTime ahora,
  ) {
    final rango = rangoProximos(ahora);

    return partidos.where((partido) {
      final fecha = partido.fechaHora;
      return partido.estado == PartidoEstado.programado &&
          fecha != null &&
          !fecha.isBefore(rango.desde) &&
          fecha.isBefore(rango.hasta);
    }).toList()..sort((a, b) => a.fechaHora!.compareTo(b.fechaHora!));
  }

  /// Los últimos 5 resultados cargados, el más reciente primero. Igual
  /// que [proximos], sale de la lista de partidos ya abierta.
  static List<PartidoModel> ultimosResultados(List<PartidoModel> partidos) {
    DateTime fecha(PartidoModel p) =>
        p.fechaActualizacion ?? p.fechaHora ?? DateTime(1900);

    return (partidos
            .where((partido) => partido.estado == PartidoEstado.finalizado)
            .toList()
          ..sort((a, b) => fecha(b).compareTo(fecha(a))))
        .take(5)
        .toList();
  }

  Stream<CampeonatoModel?> streamCampeonato(String campeonatoId) {
    return _campeonatos.doc(campeonatoId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : CampeonatoModel.fromMap(doc.id, data);
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
    return tablaDesde(
      streamCampeonato(campeonatoId),
      streamEquipos(campeonatoId),
      streamPartidos(campeonatoId),
    );
  }

  /// La tabla armada a partir de las tres fuentes que la definen. La usa
  /// [streamTabla] y también [DatosCampeonato], que le pasa las fuentes
  /// que ya tiene abiertas en vez de abrir otras.
  static Stream<List<TablaPosicionModel>> tablaDesde(
    Stream<CampeonatoModel?> campeonato,
    Stream<List<EquipoModel>> equipos,
    Stream<List<PartidoModel>> partidos,
  ) {
    return combinarUltimos3(campeonato, equipos, partidos, (
      campeonato,
      equipos,
      partidos,
    ) {
      if (campeonato == null) return <TablaPosicionModel>[];

      return TablaCalculo.calcular(
        campeonato: campeonato,
        equipos: equipos,
        partidos: partidos,
      );
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
