import 'model_helpers.dart';

class GolModel {
  final String id;
  final String partidoId;
  final String equipoId;
  final String equipoNombre;
  final String jugadorId;
  final String jugadorNombre;
  final int cantidad;
  final DateTime? fechaRegistro;
  final String registradoPor;

  const GolModel({
    required this.id,
    required this.partidoId,
    required this.equipoId,
    required this.equipoNombre,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.cantidad,
    this.fechaRegistro,
    required this.registradoPor,
  });

  factory GolModel.fromMap(String id, Map<String, dynamic> map) {
    return GolModel(
      id: id,
      partidoId: stringFromJson(map['partidoId']),
      equipoId: stringFromJson(map['equipoId']),
      equipoNombre: stringFromJson(map['equipoNombre']),
      jugadorId: stringFromJson(map['jugadorId']),
      jugadorNombre: stringFromJson(map['jugadorNombre']),
      cantidad: intFromJson(map['cantidad']),
      fechaRegistro: dateFromJson(map['fechaRegistro']),
      registradoPor: stringFromJson(map['registradoPor']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partidoId': partidoId,
      'equipoId': equipoId,
      'equipoNombre': equipoNombre,
      'jugadorId': jugadorId,
      'jugadorNombre': jugadorNombre,
      'cantidad': cantidad,
      'fechaRegistro': dateToJson(fechaRegistro),
      'registradoPor': registradoPor,
    };
  }
}
