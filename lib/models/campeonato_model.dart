import 'model_helpers.dart';

class CampeonatoEstado {
  static const String inscripcion = 'inscripcion';
  static const String activo = 'activo';
  static const String finalizado = 'finalizado';
}

class TipoCampeonato {
  static const String soloIda = 'solo_ida';
  static const String idaVuelta = 'ida_vuelta';
  static const String eliminacionDirecta = 'eliminacion_directa';
  static const String faseGrupos = 'fase_grupos';
  static const String gruposEliminacion = 'grupos_eliminacion';

  static const String ligaFinal = 'liga_final';
  static const String ligaPlayoffs = 'liga_playoffs';

  static const List<String> todos = [
    soloIda,
    idaVuelta,
    ligaFinal,
    ligaPlayoffs,
    faseGrupos,
    gruposEliminacion,
    eliminacionDirecta,
  ];
}

class CampeonatoConfig {
  final String formato;
  final int cantidadVueltas;
  final bool idaYVuelta;
  final bool generaCrucesAleatorios;
  final bool generaGruposAleatorios;
  final bool permiteEmpate;
  final bool generaTablaPosiciones;
  final int cantidadJugadoresEnCancha;
  final int cantidadMinimaJugadoresPorEquipo;
  final int cantidadMaximaJugadoresPorEquipo;

  final int cantidadGrupos;
  final int clasificanPorGrupo;
  final int clasificadosPlayoffs;
  final bool idaYVueltaEnGrupos;
  final bool incluyeTercerLugar;
  final bool generaFaseEliminatoria;
  final bool fixtureManualPermitido;
  final String rondaEliminatoriaInicial;

  const CampeonatoConfig({
    required this.formato,
    required this.cantidadVueltas,
    required this.idaYVuelta,
    required this.generaCrucesAleatorios,
    required this.generaGruposAleatorios,
    required this.permiteEmpate,
    required this.generaTablaPosiciones,
    required this.cantidadJugadoresEnCancha,
    required this.cantidadMinimaJugadoresPorEquipo,
    required this.cantidadMaximaJugadoresPorEquipo,
    this.cantidadGrupos = 0,
    this.clasificanPorGrupo = 0,
    this.clasificadosPlayoffs = 0,
    this.idaYVueltaEnGrupos = false,
    this.incluyeTercerLugar = false,
    this.generaFaseEliminatoria = false,
    this.fixtureManualPermitido = true,
    this.rondaEliminatoriaInicial = 'no_aplica',
  });

  factory CampeonatoConfig.futsalIdaVuelta() {
    return const CampeonatoConfig(
      formato: 'liga',
      cantidadVueltas: 2,
      idaYVuelta: true,
      generaCrucesAleatorios: true,
      generaGruposAleatorios: false,
      permiteEmpate: true,
      generaTablaPosiciones: true,
      cantidadJugadoresEnCancha: 5,
      cantidadMinimaJugadoresPorEquipo: 5,
      cantidadMaximaJugadoresPorEquipo: 12,
      cantidadGrupos: 0,
      clasificanPorGrupo: 0,
      clasificadosPlayoffs: 0,
      idaYVueltaEnGrupos: false,
      incluyeTercerLugar: false,
      generaFaseEliminatoria: false,
      fixtureManualPermitido: true,
      rondaEliminatoriaInicial: 'no_aplica',
    );
  }

  factory CampeonatoConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CampeonatoConfig.futsalIdaVuelta();
    }

    return CampeonatoConfig(
      formato: stringFromJson(map['formato'], defaultValue: 'liga'),
      cantidadVueltas: intFromJson(map['cantidadVueltas'], defaultValue: 2),
      idaYVuelta: boolFromJson(map['idaYVuelta'], defaultValue: true),
      generaCrucesAleatorios:
          boolFromJson(map['generaCrucesAleatorios'], defaultValue: true),
      generaGruposAleatorios:
          boolFromJson(map['generaGruposAleatorios'], defaultValue: false),
      permiteEmpate: boolFromJson(map['permiteEmpate'], defaultValue: true),
      generaTablaPosiciones:
          boolFromJson(map['generaTablaPosiciones'], defaultValue: true),
      cantidadJugadoresEnCancha:
          intFromJson(map['cantidadJugadoresEnCancha'], defaultValue: 5),
      cantidadMinimaJugadoresPorEquipo:
          intFromJson(map['cantidadMinimaJugadoresPorEquipo'], defaultValue: 5),
      cantidadMaximaJugadoresPorEquipo:
          intFromJson(map['cantidadMaximaJugadoresPorEquipo'], defaultValue: 12),
      cantidadGrupos: intFromJson(map['cantidadGrupos'], defaultValue: 0),
      clasificanPorGrupo:
          intFromJson(map['clasificanPorGrupo'], defaultValue: 0),
      clasificadosPlayoffs:
          intFromJson(map['clasificadosPlayoffs'], defaultValue: 0),
      idaYVueltaEnGrupos:
          boolFromJson(map['idaYVueltaEnGrupos'], defaultValue: false),
      incluyeTercerLugar:
          boolFromJson(map['incluyeTercerLugar'], defaultValue: false),
      generaFaseEliminatoria:
          boolFromJson(map['generaFaseEliminatoria'], defaultValue: false),
      fixtureManualPermitido:
          boolFromJson(map['fixtureManualPermitido'], defaultValue: true),
      rondaEliminatoriaInicial: stringFromJson(
        map['rondaEliminatoriaInicial'],
        defaultValue: 'no_aplica',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'formato': formato,
      'cantidadVueltas': cantidadVueltas,
      'idaYVuelta': idaYVuelta,
      'generaCrucesAleatorios': generaCrucesAleatorios,
      'generaGruposAleatorios': generaGruposAleatorios,
      'permiteEmpate': permiteEmpate,
      'generaTablaPosiciones': generaTablaPosiciones,
      'cantidadJugadoresEnCancha': cantidadJugadoresEnCancha,
      'cantidadMinimaJugadoresPorEquipo': cantidadMinimaJugadoresPorEquipo,
      'cantidadMaximaJugadoresPorEquipo': cantidadMaximaJugadoresPorEquipo,
      'cantidadGrupos': cantidadGrupos,
      'clasificanPorGrupo': clasificanPorGrupo,
      'clasificadosPlayoffs': clasificadosPlayoffs,
      'idaYVueltaEnGrupos': idaYVueltaEnGrupos,
      'incluyeTercerLugar': incluyeTercerLugar,
      'generaFaseEliminatoria': generaFaseEliminatoria,
      'fixtureManualPermitido': fixtureManualPermitido,
      'rondaEliminatoriaInicial': rondaEliminatoriaInicial,
    };
  }
}

class ReglasPuntuacion {
  final int victoria;
  final int empate;
  final int derrota;

  const ReglasPuntuacion({
    required this.victoria,
    required this.empate,
    required this.derrota,
  });

  factory ReglasPuntuacion.defaultRules() {
    return const ReglasPuntuacion(
      victoria: 3,
      empate: 1,
      derrota: 0,
    );
  }

  factory ReglasPuntuacion.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ReglasPuntuacion.defaultRules();

    return ReglasPuntuacion(
      victoria: intFromJson(map['victoria'], defaultValue: 3),
      empate: intFromJson(map['empate'], defaultValue: 1),
      derrota: intFromJson(map['derrota'], defaultValue: 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'victoria': victoria,
      'empate': empate,
      'derrota': derrota,
    };
  }
}

class CampeonatoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String deporte;
  final String modalidad;
  final String tipoCampeonato;
  final String estado;
  final String temporada;
  final String cancha;
  final CampeonatoConfig configuracion;
  final ReglasPuntuacion reglasPuntuacion;
  final List<String> reglasDesempate;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final String creadoPor;

  const CampeonatoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.deporte,
    required this.modalidad,
    required this.tipoCampeonato,
    required this.estado,
    required this.temporada,
    required this.cancha,
    required this.configuracion,
    required this.reglasPuntuacion,
    required this.reglasDesempate,
    this.fechaCreacion,
    this.fechaActualizacion,
    required this.creadoPor,
  });

  factory CampeonatoModel.fromMap(String id, Map<String, dynamic> map) {
    return CampeonatoModel(
      id: id,
      nombre: stringFromJson(map['nombre']),
      descripcion: stringFromJson(map['descripcion']),
      deporte: stringFromJson(map['deporte'], defaultValue: 'futbol'),
      modalidad: stringFromJson(map['modalidad'], defaultValue: 'futsal'),
      tipoCampeonato: stringFromJson(
        map['tipoCampeonato'],
        defaultValue: TipoCampeonato.idaVuelta,
      ),
      estado: stringFromJson(
        map['estado'],
        defaultValue: CampeonatoEstado.inscripcion,
      ),
      temporada: stringFromJson(map['temporada']),
      cancha: stringFromJson(map['cancha'], defaultValue: 'Cancha UPSA'),
      configuracion: CampeonatoConfig.fromMap(
        map['configuracion'] as Map<String, dynamic>?,
      ),
      reglasPuntuacion: ReglasPuntuacion.fromMap(
        map['reglasPuntuacion'] as Map<String, dynamic>?,
      ),
      reglasDesempate: stringListFromJson(map['reglasDesempate']),
      fechaCreacion: dateFromJson(map['fechaCreacion']),
      fechaActualizacion: dateFromJson(map['fechaActualizacion']),
      creadoPor: stringFromJson(map['creadoPor']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'deporte': deporte,
      'modalidad': modalidad,
      'tipoCampeonato': tipoCampeonato,
      'estado': estado,
      'temporada': temporada,
      'cancha': cancha,
      'configuracion': configuracion.toMap(),
      'reglasPuntuacion': reglasPuntuacion.toMap(),
      'reglasDesempate': reglasDesempate,
      'fechaCreacion': dateToJson(fechaCreacion),
      'fechaActualizacion': dateToJson(fechaActualizacion),
      'creadoPor': creadoPor,
    };
  }

  bool get estaEnInscripcion => estado == CampeonatoEstado.inscripcion;
  bool get estaActivo => estado == CampeonatoEstado.activo;
  bool get estaFinalizado => estado == CampeonatoEstado.finalizado;
}