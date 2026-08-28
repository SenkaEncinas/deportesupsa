import 'model_helpers.dart';

class GrupoModel {
  final String id;
  final String nombre;
  final int orden;
  final List<String> equipoIds;
  final bool generadoPorSistema;
  final DateTime? fechaCreacion;

  const GrupoModel({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.equipoIds,
    required this.generadoPorSistema,
    this.fechaCreacion,
  });

  factory GrupoModel.fromMap(String id, Map<String, dynamic> map) {
    return GrupoModel(
      id: id,
      nombre: stringFromJson(map['nombre']),
      orden: intFromJson(map['orden']),
      equipoIds: stringListFromJson(map['equipoIds']),
      generadoPorSistema: boolFromJson(
        map['generadoPorSistema'],
        defaultValue: true,
      ),
      fechaCreacion: dateFromJson(map['fechaCreacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'orden': orden,
      'equipoIds': equipoIds,
      'generadoPorSistema': generadoPorSistema,
      'fechaCreacion': dateToJson(fechaCreacion),
    };
  }
}
