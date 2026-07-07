import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campeonato_model.dart';
import '../models/historial_cambio_model.dart';
import '../models/jugador_model.dart';

class JugadorService {
  JugadorService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _campeonato(String campeonatoId) {
    return _db.collection('campeonatos').doc(campeonatoId);
  }

  CollectionReference<Map<String, dynamic>> _jugadores(String campeonatoId) {
    return _campeonato(campeonatoId).collection('jugadores');
  }

  CollectionReference<Map<String, dynamic>> _equipos(String campeonatoId) {
    return _campeonato(campeonatoId).collection('equipos');
  }

  String _normalizarCodigo(String codigo) {
    return codigo.trim().toUpperCase();
  }

  String _docIdFromCodigo(String codigo) {
    return _normalizarCodigo(codigo).replaceAll(RegExp(r'[^A-Z0-9_-]'), '_');
  }

  Stream<List<JugadorModel>> streamJugadores(String campeonatoId) {
    return _jugadores(campeonatoId).orderBy('nombreCompleto').snapshots().map(
      (snap) {
        return snap.docs.map((doc) {
          return JugadorModel.fromMap(doc.id, doc.data());
        }).toList();
      },
    );
  }

  Stream<List<JugadorModel>> streamJugadoresPorEquipo({
    required String campeonatoId,
    required String equipoId,
  }) {
    return _jugadores(campeonatoId)
        .where('equipoId', isEqualTo: equipoId)
        .orderBy('nombreCompleto')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return JugadorModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<JugadorModel>> getJugadoresPorEquipo({
    required String campeonatoId,
    required String equipoId,
  }) async {
    final snap = await _jugadores(campeonatoId)
        .where('equipoId', isEqualTo: equipoId)
        .orderBy('nombreCompleto')
        .get();

    return snap.docs.map((doc) {
      return JugadorModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<String> crearJugador({
    required String campeonatoId,
    required String equipoId,
    required String equipoNombre,
    required String codigoEstudiante,
    required String nombreCompleto,
    required String usuarioId,
    required String usuarioNombre,
    String? observacion,
  }) async {
    final codigoNormalizado = _normalizarCodigo(codigoEstudiante);
    final jugadorId = _docIdFromCodigo(codigoNormalizado);

    if (codigoNormalizado.isEmpty) {
      throw Exception('El código de estudiante es obligatorio.');
    }

    if (nombreCompleto.trim().isEmpty) {
      throw Exception('El nombre completo es obligatorio.');
    }

    final campeonatoDoc = await _campeonato(campeonatoId).get();
    if (!campeonatoDoc.exists || campeonatoDoc.data() == null) {
      throw Exception('El campeonato no existe.');
    }

    final campeonato = CampeonatoModel.fromMap(
      campeonatoDoc.id,
      campeonatoDoc.data()!,
    );

    if (campeonato.estaFinalizado) {
      throw Exception('No se pueden registrar jugadores en un campeonato finalizado.');
    }

    if (campeonato.estaActivo && (observacion == null || observacion.trim().isEmpty)) {
      throw Exception(
        'La observación es obligatoria para modificar la planilla con el campeonato activo.',
      );
    }

    final jugadorRef = _jugadores(campeonatoId).doc(jugadorId);
    final equipoRef = _equipos(campeonatoId).doc(equipoId);

    await _db.runTransaction((transaction) async {
      final jugadorDoc = await transaction.get(jugadorRef);
      if (jugadorDoc.exists) {
        throw Exception(
          'Ya existe un jugador con ese código en este campeonato.',
        );
      }

      final equipoDoc = await transaction.get(equipoRef);
      if (!equipoDoc.exists || equipoDoc.data() == null) {
        throw Exception('El equipo no existe.');
      }

      final cantidadActual =
          (equipoDoc.data()?['cantidadJugadoresRegistrados'] ?? 0) as int;

      if (cantidadActual >= campeonato.configuracion.cantidadMaximaJugadoresPorEquipo) {
        throw Exception(
          'El equipo ya alcanzó la cantidad máxima de jugadores permitida.',
        );
      }

      transaction.set(jugadorRef, {
        'equipoId': equipoId,
        'equipoNombre': equipoNombre,
        'codigoEstudiante': codigoNormalizado,
        'codigoNormalizado': codigoNormalizado,
        'nombreCompleto': nombreCompleto.trim(),
        'estado': JugadorEstado.activo,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'creadoPor': usuarioId,
        'actualizadoPor': usuarioId,
        'ultimaObservacion': observacion?.trim(),
      });

      transaction.update(equipoRef, {
        'cantidadJugadoresRegistrados': FieldValue.increment(1),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': usuarioId,
      });
    });

    if (campeonato.estaActivo && observacion != null && observacion.trim().isNotEmpty) {
      await jugadorRef.collection('historial_cambios').add({
        'accion': 'agregar_jugador_con_campeonato_activo',
        'datosAnteriores': {},
        'datosNuevos': {
          'equipoId': equipoId,
          'equipoNombre': equipoNombre,
          'codigoEstudiante': codigoNormalizado,
          'nombreCompleto': nombreCompleto.trim(),
          'estado': JugadorEstado.activo,
        },
        'observacion': observacion.trim(),
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'fecha': FieldValue.serverTimestamp(),
      });
    }

    return jugadorId;
  }

  Future<void> editarJugador({
    required String campeonatoId,
    required String jugadorId,
    required Map<String, dynamic> cambios,
    required String observacion,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    if (observacion.trim().isEmpty) {
      throw Exception('La observación es obligatoria para editar un jugador.');
    }

    final jugadorRef = _jugadores(campeonatoId).doc(jugadorId);
    final jugadorDoc = await jugadorRef.get();

    if (!jugadorDoc.exists || jugadorDoc.data() == null) {
      throw Exception('El jugador no existe.');
    }

    final datosAnteriores = Map<String, dynamic>.from(jugadorDoc.data()!);

    if (cambios.containsKey('codigoEstudiante')) {
      final nuevoCodigo = _normalizarCodigo(cambios['codigoEstudiante']);

      final repetido = await _jugadores(campeonatoId)
          .where('codigoNormalizado', isEqualTo: nuevoCodigo)
          .get();

      for (final doc in repetido.docs) {
        if (doc.id != jugadorId) {
          throw Exception(
            'Ya existe otro jugador con ese código en este campeonato.',
          );
        }
      }

      cambios['codigoEstudiante'] = nuevoCodigo;
      cambios['codigoNormalizado'] = nuevoCodigo;
    }

    cambios.remove('posicion');
    cambios.remove('numeroCamiseta');

    final datosNuevos = {
      ...cambios,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': usuarioId,
      'ultimaObservacion': observacion.trim(),
    };

    await jugadorRef.update(datosNuevos);

    final historial = HistorialCambioModel(
      id: '',
      accion: 'editar_jugador',
      datosAnteriores: datosAnteriores,
      datosNuevos: cambios,
      observacion: observacion.trim(),
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fecha: DateTime.now(),
    );

    await jugadorRef.collection('historial_cambios').add(historial.toMap());
  }

  Future<void> cambiarEstadoJugador({
    required String campeonatoId,
    required String jugadorId,
    required String estado,
    required String observacion,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    await editarJugador(
      campeonatoId: campeonatoId,
      jugadorId: jugadorId,
      cambios: {'estado': estado},
      observacion: observacion,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
    );
  }
}