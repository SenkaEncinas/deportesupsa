import 'model_helpers.dart';

class PartidoEstado {
  static const String pendienteProgramacion = 'pendiente_programacion';
  static const String programado = 'programado';
  static const String finalizado = 'finalizado';
  static const String suspendido = 'suspendido';
}

class TipoResultado {
  static const String normal = 'normal';
  static const String walkover = 'walkover';
  static const String sancion = 'sancion';
}

class PartidoModel {
  final String id;
  final int jornada;
  final int vuelta;
  final String? grupoId;
  final String equipoLocalId;
  final String equipoLocalNombre;
  final String equipoVisitanteId;
  final String equipoVisitanteNombre;
  final DateTime? fechaHora;
  final String estado;
  final int? golesLocal;
  final int? golesVisitante;
  final String? ganadorId;
  final bool empate;
  final bool resultadoRegistrado;
  final bool generadoPorSistema;
  final String tipoResultado;
  final String? observacionResultado;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const PartidoModel({
    required this.id,
    required this.jornada,
    required this.vuelta,
    this.grupoId,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    this.fechaHora,
    required this.estado,
    this.golesLocal,
    this.golesVisitante,
    this.ganadorId,
    required this.empate,
    required this.resultadoRegistrado,
    required this.generadoPorSistema,
    required this.tipoResultado,
    this.observacionResultado,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory PartidoModel.fromMap(String id, Map<String, dynamic> map) {
    return PartidoModel(
      id: id,
      jornada: intFromJson(map['jornada']),
      vuelta: intFromJson(map['vuelta'], defaultValue: 1),
      grupoId: map['grupoId'] == null ? null : stringFromJson(map['grupoId']),
      equipoLocalId: stringFromJson(map['equipoLocalId']),
      equipoLocalNombre: stringFromJson(map['equipoLocalNombre']),
      equipoVisitanteId: stringFromJson(map['equipoVisitanteId']),
      equipoVisitanteNombre: stringFromJson(map['equipoVisitanteNombre']),
      fechaHora: dateFromJson(map['fechaHora']),
      estado: stringFromJson(
        map['estado'],
        defaultValue: PartidoEstado.pendienteProgramacion,
      ),
      golesLocal: map['golesLocal'] == null ? null : intFromJson(map['golesLocal']),
      golesVisitante: map['golesVisitante'] == null
          ? null
          : intFromJson(map['golesVisitante']),
      ganadorId:
          map['ganadorId'] == null ? null : stringFromJson(map['ganadorId']),
      empate: boolFromJson(map['empate']),
      resultadoRegistrado: boolFromJson(map['resultadoRegistrado']),
      generadoPorSistema: boolFromJson(
        map['generadoPorSistema'],
        defaultValue: true,
      ),
      tipoResultado: stringFromJson(
        map['tipoResultado'],
        defaultValue: TipoResultado.normal,
      ),
      observacionResultado: map['observacionResultado'] == null
          ? null
          : stringFromJson(map['observacionResultado']),
      fechaCreacion: dateFromJson(map['fechaCreacion']),
      fechaActualizacion: dateFromJson(map['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jornada': jornada,
      'vuelta': vuelta,
      'grupoId': grupoId,
      'equipoLocalId': equipoLocalId,
      'equipoLocalNombre': equipoLocalNombre,
      'equipoVisitanteId': equipoVisitanteId,
      'equipoVisitanteNombre': equipoVisitanteNombre,
      'fechaHora': dateToJson(fechaHora),
      'estado': estado,
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'ganadorId': ganadorId,
      'empate': empate,
      'resultadoRegistrado': resultadoRegistrado,
      'generadoPorSistema': generadoPorSistema,
      'tipoResultado': tipoResultado,
      'observacionResultado': observacionResultado,
      'fechaCreacion': dateToJson(fechaCreacion),
      'fechaActualizacion': dateToJson(fechaActualizacion),
    };
  }

  bool get estaPendienteProgramacion =>
      estado == PartidoEstado.pendienteProgramacion;

  bool get estaProgramado => estado == PartidoEstado.programado;

  bool get estaFinalizado => estado == PartidoEstado.finalizado;

  bool get estaSuspendido => estado == PartidoEstado.suspendido;
}