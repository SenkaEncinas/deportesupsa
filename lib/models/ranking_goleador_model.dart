import 'model_helpers.dart';

class RankingGoleadorModel {
  final String jugadorId;
  final String jugadorNombre;
  final String jugadorEstado;
  final String equipoId;
  final String equipoNombre;
  final int totalGoles;
  final int partidosConGol;
  final DateTime? fechaActualizacion;

  const RankingGoleadorModel({
    required this.jugadorId,
    required this.jugadorNombre,
    required this.jugadorEstado,
    required this.equipoId,
    required this.equipoNombre,
    required this.totalGoles,
    required this.partidosConGol,
    this.fechaActualizacion,
  });

  factory RankingGoleadorModel.fromMap(String id, Map<String, dynamic> map) {
    return RankingGoleadorModel(
      jugadorId: stringFromJson(map['jugadorId'], defaultValue: id),
      jugadorNombre: stringFromJson(map['jugadorNombre']),
      jugadorEstado: stringFromJson(
        map['jugadorEstado'],
        defaultValue: 'activo',
      ),
      equipoId: stringFromJson(map['equipoId']),
      equipoNombre: stringFromJson(map['equipoNombre']),
      totalGoles: intFromJson(map['totalGoles']),
      partidosConGol: intFromJson(map['partidosConGol']),
      fechaActualizacion: dateFromJson(map['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jugadorId': jugadorId,
      'jugadorNombre': jugadorNombre,
      'jugadorEstado': jugadorEstado,
      'equipoId': equipoId,
      'equipoNombre': equipoNombre,
      'totalGoles': totalGoles,
      'partidosConGol': partidosConGol,
      'fechaActualizacion': dateToJson(fechaActualizacion),
    };
  }
}
