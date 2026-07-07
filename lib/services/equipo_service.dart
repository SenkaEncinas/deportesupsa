import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipo_model.dart';
import '../models/historial_cambio_model.dart';
import '../models/tabla_posicion_model.dart';

class EquipoService {
  EquipoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _equipos(String campeonatoId) {
    return _db
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> _tabla(String campeonatoId) {
    return _db
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('tabla_posiciones');
  }

  Stream<List<EquipoModel>> streamEquipos(String campeonatoId) {
    return _equipos(campeonatoId).orderBy('nombre').snapshots().map((snap) {
      return snap.docs.map((doc) {
        return EquipoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<EquipoModel>> getEquipos(String campeonatoId) async {
    final snap = await _equipos(campeonatoId).orderBy('nombre').get();

    return snap.docs.map((doc) {
      return EquipoModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<EquipoModel?> getEquipo({
    required String campeonatoId,
    required String equipoId,
  }) async {
    final doc = await _equipos(campeonatoId).doc(equipoId).get();

    if (!doc.exists || doc.data() == null) return null;

    return EquipoModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> crearEquipo({
    required String campeonatoId,
    required String nombre,
    required String representante,
    String? carrera,
    String? facultad,
    required String usuarioId,
  }) async {
    final equipoDoc = _equipos(campeonatoId).doc();

    final carreraLimpia = carrera?.trim();
    final facultadLimpia = facultad?.trim();

    final batch = _db.batch();

    batch.set(equipoDoc, {
      'nombre': nombre.trim(),
      'representante': representante.trim(),
      'carrera': carreraLimpia == null || carreraLimpia.isEmpty
          ? null
          : carreraLimpia,
      'facultad': facultadLimpia == null || facultadLimpia.isEmpty
          ? null
          : facultadLimpia,
      'estado': EquipoEstado.activo,
      'cantidadJugadoresRegistrados': 0,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'creadoPor': usuarioId,
      'actualizadoPor': usuarioId,
    });

    final tablaInicial = TablaPosicionModel.empty(
      equipoId: equipoDoc.id,
      equipoNombre: nombre.trim(),
    );

    batch.set(
      _tabla(campeonatoId).doc(equipoDoc.id),
      tablaInicial.toMap(),
    );

    await batch.commit();

    return equipoDoc.id;
  }

  Future<void> editarEquipo({
    required String campeonatoId,
    required String equipoId,
    required Map<String, dynamic> cambios,
    required String observacion,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    if (observacion.trim().isEmpty) {
      throw Exception('La observación es obligatoria para editar la planilla.');
    }

    final equipoRef = _equipos(campeonatoId).doc(equipoId);
    final equipoDoc = await equipoRef.get();

    if (!equipoDoc.exists || equipoDoc.data() == null) {
      throw Exception('El equipo no existe.');
    }

    final datosAnteriores = Map<String, dynamic>.from(equipoDoc.data()!);

    cambios.remove('sigla');
    cambios.remove('colorPrincipal');

    final datosNuevos = {
      ...cambios,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': usuarioId,
    };

    await equipoRef.update(datosNuevos);

    final historial = HistorialCambioModel(
      id: '',
      accion: 'editar_planilla_equipo',
      datosAnteriores: datosAnteriores,
      datosNuevos: cambios,
      observacion: observacion.trim(),
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fecha: DateTime.now(),
    );

    await equipoRef.collection('historial_planilla').add(historial.toMap());
  }

  Future<void> cambiarEstadoEquipo({
    required String campeonatoId,
    required String equipoId,
    required String estado,
    required String observacion,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    await editarEquipo(
      campeonatoId: campeonatoId,
      equipoId: equipoId,
      cambios: {'estado': estado},
      observacion: observacion,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
    );
  }
}