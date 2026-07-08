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

/// Cómo se definió el ganador del partido.
class TipoDefinicion {
  static const String normal = 'normal';
  static const String penales = 'penales';
  static const String prorroga = 'prorroga';
  static const String walkover = 'walkover';
  static const String sancion = 'sancion';
}

/// Resultado de un set individual (vóley). Se guarda embebido en el
/// documento del partido para no crear colecciones nuevas.
class SetPartido {
  final int local;
  final int visitante;

  const SetPartido({
    required this.local,
    required this.visitante,
  });

  factory SetPartido.fromMap(Map<String, dynamic> map) {
    return SetPartido(
      local: intFromJson(map['local']),
      visitante: intFromJson(map['visitante']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'visitante': visitante,
    };
  }
}

List<SetPartido> _setsFromJson(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => SetPartido.fromMap(Map<String, dynamic>.from(item)))
      .toList();
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

  // Campos opcionales para definiciones (penales, prórroga) y
  // deportes por sets. Los partidos antiguos usan los defaults.
  final int? penalesLocal;
  final int? penalesVisitante;
  final bool definidoPorPenales;
  final bool definidoPorProrroga;
  final String tipoDefinicion;
  final List<SetPartido> sets;

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
    this.penalesLocal,
    this.penalesVisitante,
    this.definidoPorPenales = false,
    this.definidoPorProrroga = false,
    this.tipoDefinicion = TipoDefinicion.normal,
    this.sets = const [],
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
      // Campos nuevos con defaults: los partidos antiguos no los tienen.
      penalesLocal:
          map['penalesLocal'] == null ? null : intFromJson(map['penalesLocal']),
      penalesVisitante: map['penalesVisitante'] == null
          ? null
          : intFromJson(map['penalesVisitante']),
      definidoPorPenales:
          boolFromJson(map['definidoPorPenales'], defaultValue: false),
      definidoPorProrroga:
          boolFromJson(map['definidoPorProrroga'], defaultValue: false),
      tipoDefinicion: stringFromJson(
        map['tipoDefinicion'],
        defaultValue: TipoDefinicion.normal,
      ),
      sets: _setsFromJson(map['sets']),
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
      'penalesLocal': penalesLocal,
      'penalesVisitante': penalesVisitante,
      'definidoPorPenales': definidoPorPenales,
      'definidoPorProrroga': definidoPorProrroga,
      'tipoDefinicion': tipoDefinicion,
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  bool get estaPendienteProgramacion =>
      estado == PartidoEstado.pendienteProgramacion;

  bool get estaProgramado => estado == PartidoEstado.programado;

  bool get estaFinalizado => estado == PartidoEstado.finalizado;

  bool get estaSuspendido => estado == PartidoEstado.suspendido;

  /// Marcador legible: "1 - 1 (4 - 3 pen.)", "2 - 1" (sets) o "Sin resultado".
  String get marcadorTexto {
    if (golesLocal == null || golesVisitante == null) return 'Sin resultado';

    final base = '$golesLocal - $golesVisitante';

    if (definidoPorPenales && penalesLocal != null && penalesVisitante != null) {
      return '$base ($penalesLocal - $penalesVisitante pen.)';
    }

    if (definidoPorProrroga) {
      return '$base (prórroga)';
    }

    return base;
  }

  /// Detalle de sets para vóley: "25-20 · 23-25 · 15-12".
  String get setsTexto {
    if (sets.isEmpty) return '';
    return sets.map((set) => '${set.local}-${set.visitante}').join(' · ');
  }
}