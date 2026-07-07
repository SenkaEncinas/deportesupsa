import 'model_helpers.dart';

class AdminModel {
  final String id;
  final String nombre;
  final String email;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? ultimaConexion;

  const AdminModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.activo,
    this.fechaCreacion,
    this.ultimaConexion,
  });

  factory AdminModel.fromMap(String id, Map<String, dynamic> map) {
    return AdminModel(
      id: id,
      nombre: stringFromJson(map['nombre']),
      email: stringFromJson(map['email']),
      activo: boolFromJson(map['activo'], defaultValue: true),
      fechaCreacion: dateFromJson(map['fechaCreacion']),
      ultimaConexion: dateFromJson(map['ultimaConexion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'activo': activo,
      'fechaCreacion': dateToJson(fechaCreacion),
      'ultimaConexion': dateToJson(ultimaConexion),
    };
  }

  AdminModel copyWith({
    String? id,
    String? nombre,
    String? email,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? ultimaConexion,
  }) {
    return AdminModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimaConexion: ultimaConexion ?? this.ultimaConexion,
    );
  }
}