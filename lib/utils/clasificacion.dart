import '../models/tabla_posicion_model.dart';

/// Un equipo clasificado a la fase final.
///
/// [posicionEnGrupo] es el puesto con el que salió de su grupo (1 = ganó
/// el grupo, 2 = salió segundo...) y [porMejorTercero] marca a los que
/// entraron por el repechaje entre grupos y no por el corte directo.
class ClasificadoInfo {
  final TablaPosicionModel equipo;
  final bool porMejorTercero;
  final int posicionEnGrupo;

  const ClasificadoInfo({
    required this.equipo,
    required this.porMejorTercero,
    required this.posicionEnGrupo,
  });
}

/// Calcula quién clasifica de la fase de grupos a la fase eliminatoria y,
/// sobre todo, **en qué orden** queda la tabla general de clasificados.
///
/// El orden es por bloques, como se arma a mano:
///
/// 1. Arriba, todos los **primeros** de grupo, comparados entre sí.
/// 2. En el medio, todos los **segundos**, comparados entre sí.
/// 3. Abajo, los **mejores terceros** que entran por repechaje.
///
/// Dentro de cada bloque manda el puntaje, y si hay empate se mira la
/// diferencia (de goles o de sets según el deporte), después los goles a
/// favor, los goles en contra y por último el nombre. O sea: un segundo
/// nunca queda por encima de un primero aunque tenga más puntos, porque
/// ganar el grupo vale; pero entre segundos, el que hizo más puntos va
/// más arriba.
///
/// Este orden es el que define la siembra de la llave: el primero de la
/// lista cruza contra el último.
class Clasificacion {
  Clasificacion._();

  static int _compararTabla(TablaPosicionModel a, TablaPosicionModel b) {
    var compare = b.puntos.compareTo(a.puntos);
    if (compare != 0) return compare;

    compare = b.diferenciaGoles.compareTo(a.diferenciaGoles);
    if (compare != 0) return compare;

    compare = b.golesFavor.compareTo(a.golesFavor);
    if (compare != 0) return compare;

    compare = a.golesContra.compareTo(b.golesContra);
    if (compare != 0) return compare;

    return a.equipoNombre.compareTo(b.equipoNombre);
  }

  static List<ClasificadoInfo> calcular({
    required List<TablaPosicionModel> tabla,
    required int clasificanPorGrupo,
    required int mejoresTerceros,
  }) {
    if (clasificanPorGrupo <= 0) return const [];

    // Equipos agrupados por el puesto que ocupan en su grupo: en la
    // clave 1 quedan todos los primeros, en la 2 todos los segundos, etc.
    // Los que están fuera del corte directo (puesto clasificanPorGrupo+1)
    // van aparte porque compiten por los cupos de repechaje.
    final porPuesto = <int, List<TablaPosicionModel>>{};
    final candidatosRepechaje = <TablaPosicionModel>[];

    for (final item in tabla) {
      final grupo = item.grupoId;
      if (grupo == null || grupo.isEmpty) continue;

      if (item.posicion <= clasificanPorGrupo) {
        porPuesto.putIfAbsent(item.posicion, () => []).add(item);
      } else if (item.posicion == clasificanPorGrupo + 1) {
        candidatosRepechaje.add(item);
      }
    }

    final clasificados = <ClasificadoInfo>[];

    // Bloque por bloque: primero todos los 1ros ordenados entre sí,
    // después todos los 2dos, y así hasta el corte directo.
    for (var puesto = 1; puesto <= clasificanPorGrupo; puesto++) {
      final delPuesto = porPuesto[puesto];
      if (delPuesto == null) continue;

      delPuesto.sort(_compararTabla);

      clasificados.addAll(
        delPuesto.map(
          (equipo) => ClasificadoInfo(
            equipo: equipo,
            porMejorTercero: false,
            posicionEnGrupo: puesto,
          ),
        ),
      );
    }

    // Y al final los mejores terceros, también ordenados entre sí.
    if (mejoresTerceros > 0) {
      candidatosRepechaje.sort(_compararTabla);

      clasificados.addAll(
        candidatosRepechaje
            .take(mejoresTerceros)
            .map(
              (equipo) => ClasificadoInfo(
                equipo: equipo,
                porMejorTercero: true,
                posicionEnGrupo: clasificanPorGrupo + 1,
              ),
            ),
      );
    }

    return clasificados;
  }
}
