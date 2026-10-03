import '../models/campeonato_model.dart';
import '../models/partido_model.dart';

/// Cómo se le muestran al usuario los valores que se guardan en la base
/// (`grupos_eliminacion`, `volley_sala`, `pendiente_programacion`...).
///
/// Estaban copiados en seis archivos, y no todas las copias decían lo
/// mismo: las tarjetas de campeonato mostraban "Volley Sala" y "Grupos
/// Eliminacion", sin tildes ni el "+", porque solo reemplazaban los
/// guiones bajos. Ahora hay una sola versión de cada texto.
class Etiquetas {
  Etiquetas._();

  static String estadoCampeonato(String estado) {
    switch (estado) {
      case CampeonatoEstado.inscripcion:
        return 'Inscripción';
      case CampeonatoEstado.activo:
        return 'Activo';
      case CampeonatoEstado.finalizado:
        return 'Finalizado';
      default:
        return formatear(estado);
    }
  }

  static String tipoCampeonato(String tipo) {
    switch (tipo) {
      case TipoCampeonato.soloIda:
        return 'Liga solo ida';
      case TipoCampeonato.idaVuelta:
        return 'Liga ida y vuelta';
      case TipoCampeonato.eliminacionDirecta:
        return 'Eliminación directa';
      case TipoCampeonato.faseGrupos:
        return 'Fase de grupos';
      case TipoCampeonato.gruposEliminacion:
        return 'Grupos + eliminación';
      case TipoCampeonato.ligaFinal:
        return 'Liga + final';
      case TipoCampeonato.ligaPlayoffs:
        return 'Liga + playoffs';
      default:
        return formatear(tipo);
    }
  }

  /// Versión corta de [tipoCampeonato], para lugares angostos como las
  /// tarjetas de números.
  static String tipoCampeonatoCorto(String tipo) {
    switch (tipo) {
      case TipoCampeonato.soloIda:
        return 'Solo ida';
      case TipoCampeonato.idaVuelta:
        return 'Ida/vuelta';
      case TipoCampeonato.eliminacionDirecta:
        return 'Eliminación';
      case TipoCampeonato.faseGrupos:
        return 'Grupos';
      case TipoCampeonato.gruposEliminacion:
        return 'Grupos + llaves';
      case TipoCampeonato.ligaFinal:
        return 'Liga + final';
      case TipoCampeonato.ligaPlayoffs:
        return 'Playoffs';
      default:
        return formatear(tipo);
    }
  }

  /// Qué significa cada formato, en una frase.
  static String descripcionFormato(String tipo) {
    switch (tipo) {
      case TipoCampeonato.soloIda:
        return 'Todos los equipos juegan entre sí una sola vez. La tabla de posiciones define el orden final.';
      case TipoCampeonato.idaVuelta:
        return 'Todos los equipos juegan entre sí dos veces, invirtiendo la localía en la segunda vuelta.';
      case TipoCampeonato.ligaFinal:
        return 'Primero se juega una liga general. Luego los dos mejores disputan una final.';
      case TipoCampeonato.ligaPlayoffs:
        return 'Primero se juega una liga general. Luego los mejores clasifican a una fase final.';
      case TipoCampeonato.faseGrupos:
        return 'Los equipos se dividen en grupos. Cada grupo maneja su propia tabla de posiciones.';
      case TipoCampeonato.gruposEliminacion:
        return 'Primero se juega una fase de grupos. Luego los clasificados pasan a llaves eliminatorias.';
      case TipoCampeonato.eliminacionDirecta:
        return 'Los equipos juegan llaves eliminatorias. El perdedor queda fuera del campeonato.';
      default:
        return 'Formato personalizado guardado para este campeonato.';
    }
  }

  static String modalidad(String modalidad) {
    switch (modalidad) {
      case ModalidadDeporte.futsal:
        return 'Futsal';
      case ModalidadDeporte.futbol7:
        return 'Fútbol 7';
      case ModalidadDeporte.futbol11:
        return 'Fútbol 11';
      case ModalidadDeporte.volleySala:
        return 'Vóley sala';
      case ModalidadDeporte.volleyMixto:
        return 'Vóley mixto';
      case ModalidadDeporte.basket5:
        return 'Básquet 5';
      case ModalidadDeporte.basket3x3:
        return 'Básquet 3x3';
      default:
        return formatear(modalidad);
    }
  }

  static String deporte(String deporte) {
    switch (deporte) {
      case DeporteTipo.volley:
        return 'Vóley';
      case DeporteTipo.basket:
        return 'Básquet';
      default:
        return 'Fútbol / Futsal';
    }
  }

  static String estadoPartido(String estado) {
    switch (estado) {
      case PartidoEstado.pendienteProgramacion:
        return 'Sin programar';
      case PartidoEstado.programado:
        return 'Programado';
      case PartidoEstado.finalizado:
        return 'Finalizado';
      case PartidoEstado.suspendido:
        return 'Suspendido';
      default:
        return formatear(estado);
    }
  }

  static String tipoResultado(String tipo) {
    switch (tipo) {
      case TipoResultado.normal:
        return 'Normal';
      case TipoResultado.walkover:
        return 'Walkover';
      case TipoResultado.sancion:
        return 'Sanción';
      default:
        return formatear(tipo);
    }
  }

  /// Acción registrada en la auditoría. Las más viejas se guardaron como
  /// clave (`editar_planilla_equipo`) y las nuevas como frase ("Editar
  /// equipo"): las dos se muestran como frase.
  static String accion(String accion) {
    const conTilde = {'igualacion': 'Igualación'};
    final limpio = accion.trim();
    if (conTilde.containsKey(limpio)) return conTilde[limpio]!;
    if (limpio.isEmpty) return 'Sin acción';

    final frase = limpio.replaceAll('_', ' ');
    return '${frase[0].toUpperCase()}${frase.substring(1)}';
  }

  /// Último recurso para un valor que no tiene texto propio:
  /// `algo_nuevo` → "Algo Nuevo".
  static String formatear(String valor) {
    final limpio = valor.trim();

    if (limpio.isEmpty) return 'No definido';

    return limpio
        .replaceAll('_', ' ')
        .split(' ')
        .where((palabra) => palabra.trim().isNotEmpty)
        .map((palabra) {
          if (palabra.length == 1) return palabra.toUpperCase();

          return '${palabra[0].toUpperCase()}${palabra.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
