import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipo_model.dart';
import '../models/partido_model.dart';

class PartidoService {
  PartidoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _campeonato(String campeonatoId) {
    return _db.collection('campeonatos').doc(campeonatoId);
  }

  CollectionReference<Map<String, dynamic>> _equipos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> _partidos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('partidos');
  }

  Stream<List<PartidoModel>> streamPartidos(String campeonatoId) {
    return _partidos(campeonatoId)
        .orderBy('vuelta')
        .orderBy('jornada')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return PartidoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<PartidoModel>> streamPartidosProgramados(String campeonatoId) {
    return _partidos(campeonatoId)
        .where('estado', isEqualTo: PartidoEstado.programado)
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return PartidoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<PartidoModel>> getPartidos(String campeonatoId) async {
    final snap = await _partidos(campeonatoId)
        .orderBy('vuelta')
        .orderBy('jornada')
        .get();

    return snap.docs.map((doc) {
      return PartidoModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<void> generarFixtureIdaVueltaAleatorio({
    required String campeonatoId,
  }) async {
    final partidosExistentes = await _partidos(campeonatoId).limit(1).get();

    if (partidosExistentes.docs.isNotEmpty) {
      throw Exception(
        'Este campeonato ya tiene partidos generados. No se puede generar otro fixture encima.',
      );
    }

    final equiposSnap = await _equipos(campeonatoId)
        .where('estado', isEqualTo: EquipoEstado.activo)
        .get();

    final equipos = equiposSnap.docs.map((doc) {
      return EquipoModel.fromMap(doc.id, doc.data());
    }).toList();

    if (equipos.length < 2) {
      throw Exception('Debe existir al menos 2 equipos activos.');
    }

    final random = Random();
    final equiposAleatorios = [...equipos]..shuffle(random);

    List<EquipoModel?> lista = [...equiposAleatorios];

    if (lista.length.isOdd) {
      lista.add(null);
    }

    final cantidadEquipos = lista.length;
    final cantidadJornadas = cantidadEquipos - 1;
    final partidosPorJornada = cantidadEquipos ~/ 2;

    final batch = _db.batch();

    final partidosVueltaUno = <Map<String, dynamic>>[];

    for (int jornada = 1; jornada <= cantidadJornadas; jornada++) {
      for (int i = 0; i < partidosPorJornada; i++) {
        final equipoA = lista[i];
        final equipoB = lista[cantidadEquipos - 1 - i];

        if (equipoA == null || equipoB == null) continue;

        final alternarLocalia = (jornada + i).isOdd;

        final local = alternarLocalia ? equipoB : equipoA;
        final visitante = alternarLocalia ? equipoA : equipoB;

        partidosVueltaUno.add({
          'jornada': jornada,
          'vuelta': 1,
          'grupoId': null,
          'equipoLocalId': local.id,
          'equipoLocalNombre': local.nombre,
          'equipoVisitanteId': visitante.id,
          'equipoVisitanteNombre': visitante.nombre,
        });
      }

      final fijo = lista.first;
      final resto = lista.sublist(1);
      final ultimo = resto.removeLast();

      lista = [
        fijo,
        ultimo,
        ...resto,
      ];
    }

    for (final partido in partidosVueltaUno) {
      final doc = _partidos(campeonatoId).doc();

      batch.set(doc, {
        ...partido,
        'fechaHora': null,
        'estado': PartidoEstado.pendienteProgramacion,
        'golesLocal': null,
        'golesVisitante': null,
        'ganadorId': null,
        'empate': false,
        'resultadoRegistrado': false,
        'generadoPorSistema': true,
        'tipoResultado': TipoResultado.normal,
        'observacionResultado': null,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    }

    for (final partido in partidosVueltaUno) {
      final doc = _partidos(campeonatoId).doc();

      batch.set(doc, {
        'jornada': partido['jornada'],
        'vuelta': 2,
        'grupoId': null,
        'equipoLocalId': partido['equipoVisitanteId'],
        'equipoLocalNombre': partido['equipoVisitanteNombre'],
        'equipoVisitanteId': partido['equipoLocalId'],
        'equipoVisitanteNombre': partido['equipoLocalNombre'],
        'fechaHora': null,
        'estado': PartidoEstado.pendienteProgramacion,
        'golesLocal': null,
        'golesVisitante': null,
        'ganadorId': null,
        'empate': false,
        'resultadoRegistrado': false,
        'generadoPorSistema': true,
        'tipoResultado': TipoResultado.normal,
        'observacionResultado': null,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> crearCruceManual({
    required String campeonatoId,
    required EquipoModel equipoLocal,
    required EquipoModel equipoVisitante,
    required int jornada,
    required bool idaYVuelta,
  }) async {
    if (equipoLocal.id == equipoVisitante.id) {
      throw Exception('Un equipo no puede jugar contra sí mismo.');
    }

    if (jornada <= 0) {
      throw Exception('La jornada debe ser mayor a cero.');
    }

    final existentesSnap = await _partidos(campeonatoId)
        .where('jornada', isEqualTo: jornada)
        .get();

    for (final doc in existentesSnap.docs) {
      final partido = PartidoModel.fromMap(doc.id, doc.data());

      final mismoCruce =
          (partido.equipoLocalId == equipoLocal.id &&
                  partido.equipoVisitanteId == equipoVisitante.id) ||
              (partido.equipoLocalId == equipoVisitante.id &&
                  partido.equipoVisitanteId == equipoLocal.id);

      if (mismoCruce) {
        throw Exception(
          'Ese cruce ya existe en la jornada $jornada.',
        );
      }
    }

    final batch = _db.batch();

    final idaDoc = _partidos(campeonatoId).doc();

    batch.set(idaDoc, {
      'jornada': jornada,
      'vuelta': 1,
      'grupoId': null,
      'equipoLocalId': equipoLocal.id,
      'equipoLocalNombre': equipoLocal.nombre,
      'equipoVisitanteId': equipoVisitante.id,
      'equipoVisitanteNombre': equipoVisitante.nombre,
      'fechaHora': null,
      'estado': PartidoEstado.pendienteProgramacion,
      'golesLocal': null,
      'golesVisitante': null,
      'ganadorId': null,
      'empate': false,
      'resultadoRegistrado': false,
      'generadoPorSistema': false,
      'tipoResultado': TipoResultado.normal,
      'observacionResultado': null,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (idaYVuelta) {
      final vueltaDoc = _partidos(campeonatoId).doc();

      batch.set(vueltaDoc, {
        'jornada': jornada,
        'vuelta': 2,
        'grupoId': null,
        'equipoLocalId': equipoVisitante.id,
        'equipoLocalNombre': equipoVisitante.nombre,
        'equipoVisitanteId': equipoLocal.id,
        'equipoVisitanteNombre': equipoLocal.nombre,
        'fechaHora': null,
        'estado': PartidoEstado.pendienteProgramacion,
        'golesLocal': null,
        'golesVisitante': null,
        'ganadorId': null,
        'empate': false,
        'resultadoRegistrado': false,
        'generadoPorSistema': false,
        'tipoResultado': TipoResultado.normal,
        'observacionResultado': null,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> programarPartido({
    required String campeonatoId,
    required String partidoId,
    required DateTime fechaHora,
  }) async {
    final mismaFecha = await _partidos(campeonatoId)
        .where('fechaHora', isEqualTo: Timestamp.fromDate(fechaHora))
        .get();

    for (final doc in mismaFecha.docs) {
      if (doc.id != partidoId) {
        throw Exception(
          'Ya existe otro partido programado exactamente en esa fecha y hora.',
        );
      }
    }

    await _partidos(campeonatoId).doc(partidoId).update({
      'fechaHora': Timestamp.fromDate(fechaHora),
      'estado': PartidoEstado.programado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> suspenderPartido({
    required String campeonatoId,
    required String partidoId,
    required String observacion,
  }) async {
    if (observacion.trim().isEmpty) {
      throw Exception('La observación es obligatoria para suspender un partido.');
    }

    await _partidos(campeonatoId).doc(partidoId).update({
      'estado': PartidoEstado.suspendido,
      'observacionResultado': observacion.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reprogramarPartido({
    required String campeonatoId,
    required String partidoId,
    required DateTime nuevaFechaHora,
  }) async {
    await programarPartido(
      campeonatoId: campeonatoId,
      partidoId: partidoId,
      fechaHora: nuevaFechaHora,
    );
  }
}