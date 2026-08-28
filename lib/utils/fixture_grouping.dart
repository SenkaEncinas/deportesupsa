import '../models/campeonato_model.dart';
import '../models/partido_model.dart';

/// Agrupa y nombra las secciones del fixture según el formato del
/// campeonato (liga, grupos, eliminación, grupos + eliminación...). Se
/// usa tanto en el fixture del admin como en la vista pública, para que
/// ambas pantallas etiqueten las rondas exactamente igual.
class FixtureGrouping {
  FixtureGrouping._();

  /// Agrupa [partidos] (ya filtrados para mostrar) en secciones con
  /// nombre. [todos] es la lista completa sin filtrar y se usa solo para
  /// calcular cuántos partidos tiene cada jornada eliminatoria, así la
  /// ronda (octavos, cuartos, semifinal, final) no cambia según el
  /// filtro que tenga activo la pantalla.
  static Map<String, List<PartidoModel>> agrupar({
    required List<PartidoModel> partidos,
    required List<PartidoModel> todos,
    required String? tipoCampeonato,
  }) {
    final secciones = <String, List<PartidoModel>>{};

    final tieneGrupos = todos.any(
      (p) => p.grupoId != null && p.grupoId!.isNotEmpty,
    );
    final tieneVarias = todos.any((p) => p.vuelta > 1);
    final esEliminacion = tipoCampeonato == TipoCampeonato.eliminacionDirecta;

    // Cantidad de partidos por jornada entre los que NO tienen grupo
    // (llaves eliminatorias puras o fase final de grupos+eliminación):
    // sirve para deducir el nombre de la ronda (4tos, 8vos, semis...).
    final partidosPorJornadaFinal = <int, int>{};
    for (final partido in todos) {
      if (partido.grupoId != null && partido.grupoId!.isNotEmpty) continue;
      partidosPorJornadaFinal[partido.jornada] =
          (partidosPorJornadaFinal[partido.jornada] ?? 0) + 1;
    }

    for (final partido in partidos) {
      String clave;

      if (tieneGrupos) {
        if (partido.grupoId == null || partido.grupoId!.isEmpty) {
          final ronda = nombreRondaEliminatoria(
            partidosPorJornadaFinal[partido.jornada] ?? 1,
          );
          clave = 'Fase final · $ronda';
        } else {
          clave = partido.grupoId!;
        }
      } else if (esEliminacion) {
        clave = nombreRondaEliminatoria(
          partidosPorJornadaFinal[partido.jornada] ?? 1,
        );
      } else if (tieneVarias) {
        clave = 'Vuelta ${partido.vuelta}';
      } else {
        clave = 'Partidos';
      }

      secciones.putIfAbsent(clave, () => []).add(partido);
    }

    for (final lista in secciones.values) {
      lista.sort((a, b) {
        final vuelta = a.vuelta.compareTo(b.vuelta);
        if (vuelta != 0) return vuelta;
        return a.jornada.compareTo(b.jornada);
      });
    }

    return secciones;
  }

  /// Nombre de la ronda eliminatoria según la cantidad de partidos que
  /// tiene esa jornada: 1 partido es la final, 2 semifinales, 4 cuartos,
  /// 8 octavos, 16 dieciseisavos; cualquier otro valor cae a un nombre
  /// genérico basado en la cantidad de equipos que arrancan la ronda.
  static String nombreRondaEliminatoria(int cantidadPartidos) {
    switch (cantidadPartidos) {
      case 1:
        return 'Final';
      case 2:
        return 'Semifinales';
      case 4:
        return 'Cuartos de final';
      case 8:
        return 'Octavos de final';
      case 16:
        return 'Dieciseisavos de final';
      default:
        return cantidadPartidos <= 0
            ? 'Llaves'
            : 'Ronda de ${cantidadPartidos * 2}';
    }
  }

  /// Igual que [nombreRondaEliminatoria] pero a partir de la cantidad de
  /// equipos clasificados (no de partidos): por ejemplo 16 equipos
  /// arrancan en octavos de final (8 partidos).
  static String rondaSegunEquipos(int cantidadEquipos) {
    if (cantidadEquipos < 2) return 'Sin definir';
    return nombreRondaEliminatoria(cantidadEquipos ~/ 2);
  }

  /// Clave corta (para guardar en `configuracion.rondaEliminatoriaInicial`)
  /// de la ronda con la que arrancaría una llave de [cantidadEquipos]
  /// clasificados. Cae a 'llaves' cuando no calza con un tamaño estándar
  /// (no es necesario que sea potencia de 2: los cruces siguientes se
  /// arman igual con "cruce manual").
  static String claveRondaSegunEquipos(int cantidadEquipos) {
    if (cantidadEquipos < 2) return 'no_aplica';

    switch (cantidadEquipos ~/ 2) {
      case 1:
        return 'final';
      case 2:
        return 'semifinal';
      case 4:
        return 'cuartos';
      case 8:
        return 'octavos';
      case 16:
        return 'dieciseisavos';
      default:
        return 'llaves';
    }
  }

  /// Si [n] es potencia de 2 (2, 4, 8, 16, 32...): una llave eliminatoria
  /// de ese tamaño no deja ningún equipo sin cruce en la primera ronda.
  static bool esPotenciaDeDos(int n) => n > 0 && (n & (n - 1)) == 0;

  /// Arma la lista de rondas (nombre + partidos) de una llave eliminatoria
  /// a partir de sus partidos, agrupando por jornada y ordenando de la
  /// ronda con más partidos (la primera) a la final. Pensado para
  /// alimentar directamente a `AppBracketView`.
  static List<MapEntry<String, List<PartidoModel>>> rondasEliminatorias(
    List<PartidoModel> partidos,
  ) {
    final porJornada = <int, List<PartidoModel>>{};

    for (final partido in partidos) {
      porJornada.putIfAbsent(partido.jornada, () => []).add(partido);
    }

    final jornadas = porJornada.keys.toList()..sort();

    return jornadas.map((jornada) {
      // Se respeta el orden en que se crearon los cruces (no alfabético):
      // ese orden es el que define qué ganador de una llave pasa a
      // enfrentar a cuál en la siguiente ronda.
      final lista = porJornada[jornada]!..sort((a, b) {
        final fechaA = a.fechaCreacion ?? DateTime(1900);
        final fechaB = b.fechaCreacion ?? DateTime(1900);
        return fechaA.compareTo(fechaB);
      });

      return MapEntry(nombreRondaEliminatoria(lista.length), lista);
    }).toList();
  }
}
