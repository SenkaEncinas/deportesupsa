import 'model_helpers.dart';

class EquipoEstado {
  static const String activo = 'activo';
  static const String inactivo = 'inactivo';
  static const String retirado = 'retirado';
  static const String descalificado = 'descalificado';
}

class EquipoModel {
  final String id;
  final String nombre;
  final String representante;
  final String? carrera;
  final String? facultad;
  final String estado;
  final int cantidadJugadoresRegistrados;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final String creadoPor;
  final String actualizadoPor;

  const EquipoModel({
    required this.id,
    required this.nombre,
    required this.representante,
    this.carrera,
    this.facultad,
    required this.estado,
    required this.cantidadJugadoresRegistrados,
    this.fechaCreacion,
    this.fechaActualizacion,
    required this.creadoPor,
    required this.actualizadoPor,
  });

  factory EquipoModel.fromMap(String id, Map<String, dynamic> map) {
    return EquipoModel(
      id: id,
      nombre: stringFromJson(map['nombre']),
      representante: stringFromJson(map['representante']),
      carrera: map['carrera'] == null ? null : stringFromJson(map['carrera']),
      facultad: map['facultad'] == null
          ? null
          : stringFromJson(map['facultad']),
      estado: stringFromJson(map['estado'], defaultValue: EquipoEstado.activo),
      cantidadJugadoresRegistrados: intFromJson(
        map['cantidadJugadoresRegistrados'],
      ),
      fechaCreacion: dateFromJson(map['fechaCreacion']),
      fechaActualizacion: dateFromJson(map['fechaActualizacion']),
      creadoPor: stringFromJson(map['creadoPor']),
      actualizadoPor: stringFromJson(map['actualizadoPor']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'representante': representante,
      'carrera': carrera,
      'facultad': facultad,
      'estado': estado,
      'cantidadJugadoresRegistrados': cantidadJugadoresRegistrados,
      'fechaCreacion': dateToJson(fechaCreacion),
      'fechaActualizacion': dateToJson(fechaActualizacion),
      'creadoPor': creadoPor,
      'actualizadoPor': actualizadoPor,
    };
  }
}
