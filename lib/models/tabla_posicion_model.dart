import 'model_helpers.dart';

class TablaPosicionModel {
  final String equipoId;
  final String equipoNombre;
  final int partidosJugados;
  final int partidosGanados;
  final int partidosEmpatados;
  final int partidosPerdidos;
  final int golesFavor;
  final int golesContra;
  final int diferenciaGoles;
  final int puntos;
  final int posicion;
  final DateTime? fechaActualizacion;

  // Campos preparados para vóley/básquet. En vóley, golesFavor/Contra
  // guardan sets ganados/perdidos y estos campos guardan los puntos
  // jugados dentro de los sets. En básquet, guardan los puntos anotados.
  final int puntosFavor;
  final int puntosContra;
  final int diferenciaPuntos;

  const TablaPosicionModel({
    required this.equipoId,
    required this.equipoNombre,
    required this.partidosJugados,
    required this.partidosGanados,
    required this.partidosEmpatados,
    required this.partidosPerdidos,
    required this.golesFavor,
    required this.golesContra,
    required this.diferenciaGoles,
    required this.puntos,
    required this.posicion,
    this.fechaActualizacion,
    this.puntosFavor = 0,
    this.puntosContra = 0,
    this.diferenciaPuntos = 0,
  });

  factory TablaPosicionModel.empty({
    required String equipoId,
    required String equipoNombre,
  }) {
    return TablaPosicionModel(
      equipoId: equipoId,
      equipoNombre: equipoNombre,
      partidosJugados: 0,
      partidosGanados: 0,
      partidosEmpatados: 0,
      partidosPerdidos: 0,
      golesFavor: 0,
      golesContra: 0,
      diferenciaGoles: 0,
      puntos: 0,
      posicion: 0,
      fechaActualizacion: DateTime.now(),
    );
  }

  factory TablaPosicionModel.fromMap(String id, Map<String, dynamic> map) {
    return TablaPosicionModel(
      equipoId: stringFromJson(map['equipoId'], defaultValue: id),
      equipoNombre: stringFromJson(map['equipoNombre']),
      partidosJugados: intFromJson(map['partidosJugados']),
      partidosGanados: intFromJson(map['partidosGanados']),
      partidosEmpatados: intFromJson(map['partidosEmpatados']),
      partidosPerdidos: intFromJson(map['partidosPerdidos']),
      golesFavor: intFromJson(map['golesFavor']),
      golesContra: intFromJson(map['golesContra']),
      diferenciaGoles: intFromJson(map['diferenciaGoles']),
      puntos: intFromJson(map['puntos']),
      posicion: intFromJson(map['posicion']),
      fechaActualizacion: dateFromJson(map['fechaActualizacion']),
      puntosFavor: intFromJson(map['puntosFavor']),
      puntosContra: intFromJson(map['puntosContra']),
      diferenciaPuntos: intFromJson(map['diferenciaPuntos']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipoId': equipoId,
      'equipoNombre': equipoNombre,
      'partidosJugados': partidosJugados,
      'partidosGanados': partidosGanados,
      'partidosEmpatados': partidosEmpatados,
      'partidosPerdidos': partidosPerdidos,
      'golesFavor': golesFavor,
      'golesContra': golesContra,
      'diferenciaGoles': diferenciaGoles,
      'puntos': puntos,
      'posicion': posicion,
      'fechaActualizacion': dateToJson(fechaActualizacion),
      'puntosFavor': puntosFavor,
      'puntosContra': puntosContra,
      'diferenciaPuntos': diferenciaPuntos,
    };
  }
}