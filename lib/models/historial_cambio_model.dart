import 'model_helpers.dart';

class HistorialCambioModel {
  final String id;
  final String accion;
  final Map<String, dynamic> datosAnteriores;
  final Map<String, dynamic> datosNuevos;
  final String observacion;
  final String usuarioId;
  final String usuarioNombre;
  final DateTime? fecha;

  const HistorialCambioModel({
    required this.id,
    required this.accion,
    required this.datosAnteriores,
    required this.datosNuevos,
    required this.observacion,
    required this.usuarioId,
    required this.usuarioNombre,
    this.fecha,
  });

  factory HistorialCambioModel.fromMap(String id, Map<String, dynamic> map) {
    return HistorialCambioModel(
      id: id,
      accion: stringFromJson(map['accion']),
      datosAnteriores: Map<String, dynamic>.from(map['datosAnteriores'] ?? {}),
      datosNuevos: Map<String, dynamic>.from(map['datosNuevos'] ?? {}),
      observacion: stringFromJson(map['observacion']),
      usuarioId: stringFromJson(map['usuarioId']),
      usuarioNombre: stringFromJson(map['usuarioNombre']),
      fecha: dateFromJson(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accion': accion,
      'datosAnteriores': datosAnteriores,
      'datosNuevos': datosNuevos,
      'observacion': observacion,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'fecha': dateToJson(fecha),
    };
  }
}
