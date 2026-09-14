import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auditoria_model.dart';

/// Registra acciones administrativas visibles en la pantalla de
/// Auditoría. Se llama desde los services que ya piden una observación
/// (jugadores, equipos, resultados) para que esa nota quede reflejada
/// ahí, no solo en el historial propio de cada documento.
class AuditoriaService {
  AuditoriaService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> registrar({
    required String campeonatoId,
    required String usuarioId,
    required String usuarioNombre,
    required String accion,
    required String modulo,
    required String documentoAfectado,
    required String detalle,
    String? observacion,
  }) async {
    final auditoria = AuditoriaModel(
      id: '',
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      accion: accion,
      modulo: modulo,
      documentoAfectado: documentoAfectado,
      fecha: DateTime.now(),
      detalle: detalle,
      observacion: (observacion == null || observacion.trim().isEmpty)
          ? null
          : observacion.trim(),
    );

    await _db
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('auditoria')
        .add(auditoria.toMap());
  }
}
