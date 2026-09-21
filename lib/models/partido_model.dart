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

  const SetPartido({required this.local, required this.visitante});

  factory SetPartido.fromMap(Map<String, dynamic> map) {
    return SetPartido(
      local: intFromJson(map['local']),
      visitante: intFromJson(map['visitante']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'local': local, 'visitante': visitante};
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

  /// Partido especial creado con "PRIVILEGIO": queda fuera de los grupos
  /// a propósito (no suma para la tabla) y tampoco forma parte de la
  /// llave eliminatoria, aunque comparta con ella el no tener grupo.
  final bool privilegio;

  // ---- Ubicación dentro de la llave eliminatoria ----
  //
  // Los partidos de grupos y los de privilegio no los tienen (quedan en
  // null). Los cruces viejos, creados a mano antes de que existiera el
  // generador de llaves, tampoco: para esos se sigue deduciendo la
  // ronda contando cuántos partidos hay en la jornada.

  /// Ronda de la llave: 'octavos', 'cuartos', 'semifinal', 'final'...
  /// (ver `RondaLlave`). `null` si el partido no es de la llave.
  final String? rondaLlave;

  /// Número de llave dentro de la ronda (1..n), igual que en el cuadro:
  /// en octavos la llave 1 es 1° vs 16°, la llave 8 es 8° vs 9°.
  final int? llave;

  /// Posición de arriba hacia abajo al dibujar la ronda. No es lo mismo
  /// que [llave]: el dibujo se reordena para que los conectores no se
  /// crucen.
  final int? ordenLlave;

  /// Número de llave de la ronda anterior de donde sale cada equipo.
  /// Solo en rondas posteriores a la primera.
  final int? vieneDeLocal;
  final int? vieneDeVisitante;

  /// Cruce sin rival porque el cuadro no se llenó (12 clasificados en un
  /// cuadro de 16, por ejemplo): el equipo pasa directo a la siguiente
  /// ronda y este partido no se juega.
  final bool esBye;

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
    this.privilegio = false,
    this.rondaLlave,
    this.llave,
    this.ordenLlave,
    this.vieneDeLocal,
    this.vieneDeVisitante,
    this.esBye = false,
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
      golesLocal: map['golesLocal'] == null
          ? null
          : intFromJson(map['golesLocal']),
      golesVisitante: map['golesVisitante'] == null
          ? null
          : intFromJson(map['golesVisitante']),
      ganadorId: map['ganadorId'] == null
          ? null
          : stringFromJson(map['ganadorId']),
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
      penalesLocal: map['penalesLocal'] == null
          ? null
          : intFromJson(map['penalesLocal']),
      penalesVisitante: map['penalesVisitante'] == null
          ? null
          : intFromJson(map['penalesVisitante']),
      definidoPorPenales: boolFromJson(
        map['definidoPorPenales'],
        defaultValue: false,
      ),
      definidoPorProrroga: boolFromJson(
        map['definidoPorProrroga'],
        defaultValue: false,
      ),
      tipoDefinicion: stringFromJson(
        map['tipoDefinicion'],
        defaultValue: TipoDefinicion.normal,
      ),
      sets: _setsFromJson(map['sets']),
      privilegio: boolFromJson(map['privilegio']),
      rondaLlave: map['rondaLlave'] == null
          ? null
          : stringFromJson(map['rondaLlave']),
      llave: map['llave'] == null ? null : intFromJson(map['llave']),
      ordenLlave: map['ordenLlave'] == null
          ? null
          : intFromJson(map['ordenLlave']),
      vieneDeLocal: map['vieneDeLocal'] == null
          ? null
          : intFromJson(map['vieneDeLocal']),
      vieneDeVisitante: map['vieneDeVisitante'] == null
          ? null
          : intFromJson(map['vieneDeVisitante']),
      esBye: boolFromJson(map['esBye']),
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
      'privilegio': privilegio,
      'rondaLlave': rondaLlave,
      'llave': llave,
      'ordenLlave': ordenLlave,
      'vieneDeLocal': vieneDeLocal,
      'vieneDeVisitante': vieneDeVisitante,
      'esBye': esBye,
    };
  }

  /// El partido forma parte del cuadro eliminatorio generado por la app
  /// (tiene ronda y número de llave asignados).
  bool get esDeLlave => rondaLlave != null && llave != null;

  /// Los dos equipos ya están definidos: no es un cruce esperando al
  /// ganador de la ronda anterior ni un "libre".
  bool get tieneEquiposDefinidos =>
      equipoLocalId.isNotEmpty && equipoVisitanteId.isNotEmpty;

  /// Se puede cargar un resultado: hace falta que haya dos equipos y que
  /// no sea un pase directo.
  bool get admiteResultado => tieneEquiposDefinidos && !esBye;

  bool get estaPendienteProgramacion =>
      estado == PartidoEstado.pendienteProgramacion;

  bool get estaProgramado => estado == PartidoEstado.programado;

  bool get estaFinalizado => estado == PartidoEstado.finalizado;

  bool get estaSuspendido => estado == PartidoEstado.suspendido;

  /// Marcador legible: "1 - 1 (4 - 3 pen.)", "2 - 1" (sets) o "Sin resultado".
  String get marcadorTexto {
    if (golesLocal == null || golesVisitante == null) return 'Sin resultado';

    final base = '$golesLocal - $golesVisitante';

    if (definidoPorPenales &&
        penalesLocal != null &&
        penalesVisitante != null) {
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
