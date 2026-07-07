import 'model_helpers.dart';

class AuditoriaModel {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final String accion;
  final String modulo;
  final String documentoAfectado;
  final DateTime? fecha;
  final String detalle;
  final String? observacion;

  const AuditoriaModel({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.accion,
    required this.modulo,
    required this.documentoAfectado,
    this.fecha,
    required this.detalle,
    this.observacion,
  });

  factory AuditoriaModel.fromMap(String id, Map<String, dynamic> map) {
    return AuditoriaModel(
      id: id,
      usuarioId: stringFromJson(map['usuarioId']),
      usuarioNombre: stringFromJson(map['usuarioNombre']),
      accion: stringFromJson(map['accion']),
      modulo: stringFromJson(map['modulo']),
      documentoAfectado: stringFromJson(map['documentoAfectado']),
      fecha: dateFromJson(map['fecha']),
      detalle: stringFromJson(map['detalle']),
      observacion:
          map['observacion'] == null ? null : stringFromJson(map['observacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'accion': accion,
      'modulo': modulo,
      'documentoAfectado': documentoAfectado,
      'fecha': dateToJson(fecha),
      'detalle': detalle,
      'observacion': observacion,
    };
  }
}