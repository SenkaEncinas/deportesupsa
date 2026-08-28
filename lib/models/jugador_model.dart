import 'model_helpers.dart';

class JugadorEstado {
  static const String activo = 'activo';
  static const String suspendido = 'suspendido';
  static const String retirado = 'retirado';
}

class JugadorModel {
  final String id;
  final String equipoId;
  final String equipoNombre;
  final String codigoEstudiante;
  final String nombreCompleto;
  final String estado;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;
  final String creadoPor;
  final String actualizadoPor;
  final String? ultimaObservacion;

  const JugadorModel({
    required this.id,
    required this.equipoId,
    required this.equipoNombre,
    required this.codigoEstudiante,
    required this.nombreCompleto,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
    required this.creadoPor,
    required this.actualizadoPor,
    this.ultimaObservacion,
  });

  factory JugadorModel.fromMap(String id, Map<String, dynamic> map) {
    return JugadorModel(
      id: id,
      equipoId: stringFromJson(map['equipoId']),
      equipoNombre: stringFromJson(map['equipoNombre']),
      codigoEstudiante: stringFromJson(map['codigoEstudiante']),
      nombreCompleto: stringFromJson(map['nombreCompleto']),
      estado: stringFromJson(map['estado'], defaultValue: JugadorEstado.activo),
      fechaRegistro: dateFromJson(map['fechaRegistro']),
      fechaActualizacion: dateFromJson(map['fechaActualizacion']),
      creadoPor: stringFromJson(map['creadoPor']),
      actualizadoPor: stringFromJson(map['actualizadoPor']),
      ultimaObservacion: map['ultimaObservacion'] == null
          ? null
          : stringFromJson(map['ultimaObservacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipoId': equipoId,
      'equipoNombre': equipoNombre,
      'codigoEstudiante': codigoEstudiante,
      'nombreCompleto': nombreCompleto,
      'estado': estado,
      'fechaRegistro': dateToJson(fechaRegistro),
      'fechaActualizacion': dateToJson(fechaActualizacion),
      'creadoPor': creadoPor,
      'actualizadoPor': actualizadoPor,
      'ultimaObservacion': ultimaObservacion,
    };
  }

  bool get estaActivo => estado == JugadorEstado.activo;
  bool get estaSuspendido => estado == JugadorEstado.suspendido;
  bool get estaRetirado => estado == JugadorEstado.retirado;
}
