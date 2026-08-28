import 'model_helpers.dart';

class CampeonatoEstado {
  static const String inscripcion = 'inscripcion';
  static const String activo = 'activo';
  static const String finalizado = 'finalizado';
}

/// Deportes soportados. Los campeonatos antiguos sin campo `deporte`
/// se asumen como fútbol/futsal.
class DeporteTipo {
  static const String futbol = 'futbol';
  static const String volley = 'volley';
  static const String basket = 'basket';

  static const List<String> todos = [futbol, volley, basket];
}

/// Modalidades por deporte. `volley_mixto` y `basket_3x3` quedan
/// preparadas para una siguiente fase sin romper nada.
class ModalidadDeporte {
  static const String futsal = 'futsal';
  static const String futbol7 = 'futbol_7';
  static const String futbol11 = 'futbol_11';

  static const String volleySala = 'volley_sala';
  static const String volleyMixto = 'volley_mixto';

  static const String basket5 = 'basket_5';
  static const String basket3x3 = 'basket_3x3';

  static List<String> porDeporte(String deporte) {
    switch (deporte) {
      case DeporteTipo.volley:
        return const [volleySala, volleyMixto];
      case DeporteTipo.basket:
        return const [basket5, basket3x3];
      default:
        return const [futsal, futbol7, futbol11];
    }
  }
}

/// Cómo se registra el marcador de un partido según el deporte.
class SistemaResultado {
  static const String goles = 'goles';
  static const String sets = 'sets';
  static const String puntos = 'puntos';

  static String porDeporte(String deporte) {
    switch (deporte) {
      case DeporteTipo.volley:
        return sets;
      case DeporteTipo.basket:
        return puntos;
      default:
        return goles;
    }
  }
}

/// Etapa actual de un campeonato de "Grupos + eliminación": mientras
/// está en `grupos`, los cruces manuales solo pueden armarse entre
/// equipos del mismo grupo; el admin activa `eliminatoria` a mano
/// cuando decide, según la tabla, quién pasa a las llaves.
class FaseCampeonato {
  static const String grupos = 'grupos';
  static const String eliminatoria = 'eliminatoria';
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
  // Mejores equipos ubicados justo después del corte directo (los
  // clásicos "mejores terceros") que también clasifican a la fase
  // final, comparados entre todos los grupos con el mismo criterio de
  // desempate que la tabla de posiciones.
  final int mejoresTerceros;
  final int clasificadosPlayoffs;
  final bool idaYVueltaEnGrupos;
  final bool incluyeTercerLugar;
  final bool generaFaseEliminatoria;
  final bool fixtureManualPermitido;
  final String rondaEliminatoriaInicial;

  // Configuración por deporte. Todos tienen defaults seguros para
  // que los campeonatos antiguos (solo fútbol) sigan funcionando.
  final String deporte;
  final String modalidad;
  final String sistemaResultado;
  final int setsParaGanar;
  final int puntosSetNormal;
  final int puntosSetDecisivo;
  final int cantidadPeriodos;
  final bool permitePenales;
  final bool permiteProrroga;

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
    this.mejoresTerceros = 0,
    this.clasificadosPlayoffs = 0,
    this.idaYVueltaEnGrupos = false,
    this.incluyeTercerLugar = false,
    this.generaFaseEliminatoria = false,
    this.fixtureManualPermitido = true,
    this.rondaEliminatoriaInicial = 'no_aplica',
    this.deporte = DeporteTipo.futbol,
    this.modalidad = ModalidadDeporte.futsal,
    this.sistemaResultado = SistemaResultado.goles,
    this.setsParaGanar = 2,
    this.puntosSetNormal = 25,
    this.puntosSetDecisivo = 15,
    this.cantidadPeriodos = 0,
    this.permitePenales = false,
    this.permiteProrroga = false,
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
      generaCrucesAleatorios: boolFromJson(
        map['generaCrucesAleatorios'],
        defaultValue: true,
      ),
      generaGruposAleatorios: boolFromJson(
        map['generaGruposAleatorios'],
        defaultValue: false,
      ),
      permiteEmpate: boolFromJson(map['permiteEmpate'], defaultValue: true),
      generaTablaPosiciones: boolFromJson(
        map['generaTablaPosiciones'],
        defaultValue: true,
      ),
      cantidadJugadoresEnCancha: intFromJson(
        map['cantidadJugadoresEnCancha'],
        defaultValue: 5,
      ),
      cantidadMinimaJugadoresPorEquipo: intFromJson(
        map['cantidadMinimaJugadoresPorEquipo'],
        defaultValue: 5,
      ),
      cantidadMaximaJugadoresPorEquipo: intFromJson(
        map['cantidadMaximaJugadoresPorEquipo'],
        defaultValue: 12,
      ),
      cantidadGrupos: intFromJson(map['cantidadGrupos'], defaultValue: 0),
      clasificanPorGrupo: intFromJson(
        map['clasificanPorGrupo'],
        defaultValue: 0,
      ),
      mejoresTerceros: intFromJson(map['mejoresTerceros'], defaultValue: 0),
      clasificadosPlayoffs: intFromJson(
        map['clasificadosPlayoffs'],
        defaultValue: 0,
      ),
      idaYVueltaEnGrupos: boolFromJson(
        map['idaYVueltaEnGrupos'],
        defaultValue: false,
      ),
      incluyeTercerLugar: boolFromJson(
        map['incluyeTercerLugar'],
        defaultValue: false,
      ),
      generaFaseEliminatoria: boolFromJson(
        map['generaFaseEliminatoria'],
        defaultValue: false,
      ),
      fixtureManualPermitido: boolFromJson(
        map['fixtureManualPermitido'],
        defaultValue: true,
      ),
      rondaEliminatoriaInicial: stringFromJson(
        map['rondaEliminatoriaInicial'],
        defaultValue: 'no_aplica',
      ),
      // Campos nuevos: si el documento antiguo no los tiene,
      // se asume fútbol/futsal con resultado por goles.
      deporte: stringFromJson(map['deporte'], defaultValue: DeporteTipo.futbol),
      modalidad: stringFromJson(
        map['modalidad'],
        defaultValue: ModalidadDeporte.futsal,
      ),
      sistemaResultado: stringFromJson(
        map['sistemaResultado'],
        defaultValue: SistemaResultado.goles,
      ),
      setsParaGanar: intFromJson(map['setsParaGanar'], defaultValue: 2),
      puntosSetNormal: intFromJson(map['puntosSetNormal'], defaultValue: 25),
      puntosSetDecisivo: intFromJson(
        map['puntosSetDecisivo'],
        defaultValue: 15,
      ),
      cantidadPeriodos: intFromJson(map['cantidadPeriodos'], defaultValue: 0),
      permitePenales: boolFromJson(map['permitePenales'], defaultValue: false),
      permiteProrroga: boolFromJson(
        map['permiteProrroga'],
        defaultValue: false,
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
      'mejoresTerceros': mejoresTerceros,
      'clasificadosPlayoffs': clasificadosPlayoffs,
      'idaYVueltaEnGrupos': idaYVueltaEnGrupos,
      'incluyeTercerLugar': incluyeTercerLugar,
      'generaFaseEliminatoria': generaFaseEliminatoria,
      'fixtureManualPermitido': fixtureManualPermitido,
      'rondaEliminatoriaInicial': rondaEliminatoriaInicial,
      'deporte': deporte,
      'modalidad': modalidad,
      'sistemaResultado': sistemaResultado,
      'setsParaGanar': setsParaGanar,
      'puntosSetNormal': puntosSetNormal,
      'puntosSetDecisivo': puntosSetDecisivo,
      'cantidadPeriodos': cantidadPeriodos,
      'permitePenales': permitePenales,
      'permiteProrroga': permiteProrroga,
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
    return const ReglasPuntuacion(victoria: 3, empate: 1, derrota: 0);
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
    return {'victoria': victoria, 'empate': empate, 'derrota': derrota};
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
  final String faseActual;
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
    this.faseActual = FaseCampeonato.grupos,
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
      faseActual: stringFromJson(
        map['faseActual'],
        defaultValue: FaseCampeonato.grupos,
      ),
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
      'faseActual': faseActual,
      'fechaCreacion': dateToJson(fechaCreacion),
      'fechaActualizacion': dateToJson(fechaActualizacion),
      'creadoPor': creadoPor,
    };
  }

  bool get estaEnInscripcion => estado == CampeonatoEstado.inscripcion;
  bool get estaActivo => estado == CampeonatoEstado.activo;
  bool get estaFinalizado => estado == CampeonatoEstado.finalizado;

  /// Deporte efectivo: los campeonatos antiguos sin deporte son fútbol.
  String get deporteEfectivo =>
      deporte.trim().isEmpty ? DeporteTipo.futbol : deporte;

  bool get esFutbol => deporteEfectivo == DeporteTipo.futbol;
  bool get esVolley => deporteEfectivo == DeporteTipo.volley;
  bool get esBasket => deporteEfectivo == DeporteTipo.basket;

  /// Sistema de resultado efectivo, con compatibilidad hacia atrás:
  /// si la configuración no lo trae, se deduce del deporte.
  String get sistemaResultadoEfectivo {
    final sistema = configuracion.sistemaResultado.trim();
    if (sistema.isNotEmpty && !esFutbol) {
      // Config antigua puede traer 'goles' por default aunque el
      // campeonato sea vóley/básquet: en ese caso manda el deporte.
      if (sistema == SistemaResultado.goles) {
        return SistemaResultado.porDeporte(deporteEfectivo);
      }
      return sistema;
    }
    if (sistema.isEmpty) return SistemaResultado.porDeporte(deporteEfectivo);
    return sistema;
  }

  /// En fases eliminatorias, finales y playoffs no puede quedar empate.
  bool get formatoEliminaEmpates =>
      tipoCampeonato == TipoCampeonato.eliminacionDirecta;

  /// Solo "Grupos + eliminación" tiene dos etapas separadas: mientras no
  /// se active la fase eliminatoria a mano, los cruces manuales quedan
  /// limitados a equipos del mismo grupo (ver [PartidoService]).
  bool get tieneFasesSeparadas =>
      tipoCampeonato == TipoCampeonato.gruposEliminacion;

  /// Si los cruces manuales deberían limitarse a equipos del mismo
  /// grupo: siempre en "fase de grupos" puro (no hay otra etapa), y en
  /// "grupos + eliminación" mientras no se active la fase eliminatoria.
  bool get debeRestringirCrucesAlGrupo =>
      tipoCampeonato == TipoCampeonato.faseGrupos ||
      (tieneFasesSeparadas && faseActual != FaseCampeonato.eliminatoria);

  bool get estaEnFaseDeGrupos =>
      tieneFasesSeparadas && faseActual != FaseCampeonato.eliminatoria;

  bool get estaEnFaseEliminatoria =>
      tieneFasesSeparadas && faseActual == FaseCampeonato.eliminatoria;
}
