import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import 'llaves.dart';

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

  /// Nombre de la ronda que tiene [cantidadPartidos] cruces: 1 es la
  /// final, 2 semifinales, 4 cuartos... Para tamaños que no son de un
  /// cuadro estándar cae a un nombre genérico.
  static String nombreRondaEliminatoria(int cantidadPartidos) {
    if (cantidadPartidos <= 0) return 'Llaves';

    final clave = RondaLlave.porCantidadDePartidos(cantidadPartidos);
    if (clave != RondaLlave.sinNombre) return RondaLlave.nombre(clave);

    return 'Ronda de ${cantidadPartidos * 2}';
  }

  /// Igual que [nombreRondaEliminatoria] pero a partir de la cantidad de
  /// equipos: 16 equipos arrancan en octavos (8 cruces).
  static String rondaSegunEquipos(int cantidadEquipos) {
    if (cantidadEquipos < 2) return 'Sin definir';
    return nombreRondaEliminatoria(cantidadEquipos ~/ 2);
  }

  /// Clave corta de la ronda con la que arrancaría una llave de
  /// [cantidadEquipos] clasificados, para guardar en
  /// `configuracion.rondaEliminatoriaInicial`.
  static String claveRondaSegunEquipos(int cantidadEquipos) {
    if (cantidadEquipos < 2) return 'no_aplica';
    return RondaLlave.porCantidadDePartidos(cantidadEquipos ~/ 2);
  }

  /// Si [n] es potencia de 2: un cuadro de ese tamaño no deja a nadie
  /// libre en la primera ronda.
  static bool esPotenciaDeDos(int n) => Llaves.esPotenciaDeDos(n);

  /// Arma la lista de rondas (nombre + partidos) de una llave eliminatoria
  /// a partir de sus partidos, agrupando por jornada y ordenando de la
  /// ronda con más partidos (la primera) a la final. Pensado para
  /// alimentar directamente a `AppBracketView`.
  static List<MapEntry<String, List<PartidoModel>>> rondasEliminatorias(
    List<PartidoModel> partidos,
  ) {
    if (partidos.isEmpty) return const [];

    // Cuadro generado por la app: la ronda y la posición de cada cruce
    // están guardadas en el partido, así que no hay nada que adivinar.
    if (partidos.every((partido) => partido.esDeLlave)) {
      final porRonda = <String, List<PartidoModel>>{};

      for (final partido in partidos) {
        porRonda.putIfAbsent(partido.rondaLlave!, () => []).add(partido);
      }

      final claves = porRonda.keys.toList()
        ..sort((a, b) => RondaLlave.orden(a).compareTo(RondaLlave.orden(b)));

      return claves.map((clave) {
        // `ordenLlave` es la posición de arriba hacia abajo en el
        // dibujo: ordenada así, cada par de cruces consecutivos es
        // justo el que alimenta al mismo cruce de la ronda siguiente,
        // y los conectores salen derechos.
        final lista = porRonda[clave]!
          ..sort((a, b) {
            final orden = (a.ordenLlave ?? 0).compareTo(b.ordenLlave ?? 0);
            if (orden != 0) return orden;
            return (a.llave ?? 0).compareTo(b.llave ?? 0);
          });

        return MapEntry(RondaLlave.nombre(clave), lista);
      }).toList();
    }

    // Cruces viejos o armados a mano: no tienen ronda guardada, así que
    // se agrupan por jornada y la ronda se deduce de cuántos son.
    final porJornada = <int, List<PartidoModel>>{};

    for (final partido in partidos) {
      porJornada.putIfAbsent(partido.jornada, () => []).add(partido);
    }

    final jornadas = porJornada.keys.toList()..sort();

    return jornadas.map((jornada) {
      // Se respeta el orden en que se crearon los cruces (no alfabético):
      // ese orden es el que define qué ganador de una llave pasa a
      // enfrentar a cuál en la siguiente ronda.
      final lista = porJornada[jornada]!
        ..sort((a, b) {
          final fechaA = a.fechaCreacion ?? DateTime(1900);
          final fechaB = b.fechaCreacion ?? DateTime(1900);
          return fechaA.compareTo(fechaB);
        });

      return MapEntry(nombreRondaEliminatoria(lista.length), lista);
    }).toList();
  }
}
