import '../models/tabla_posicion_model.dart';

/// Un equipo clasificado a la fase final, y si llegó ahí directo (top N
/// de su grupo) o como uno de los "mejores terceros" entre grupos.
class ClasificadoInfo {
  final TablaPosicionModel equipo;
  final bool porMejorTercero;

  const ClasificadoInfo({
    required this.equipo,
    required this.porMejorTercero,
  });
}

/// Calcula quién clasifica de la fase de grupos a la fase eliminatoria:
/// los primeros [clasificanPorGrupo] de cada grupo, más los
/// [mejoresTerceros] equipos mejor ubicados entre los que quedaron justo
/// debajo del corte directo en cada grupo (el clásico "mejores
/// terceros"), comparados con el mismo criterio de desempate que la
/// tabla de posiciones: puntos, diferencia de goles, goles a favor,
/// goles en contra y nombre.
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

    final porGrupo = <String, List<TablaPosicionModel>>{};

    for (final item in tabla) {
      final grupo = item.grupoId;
      if (grupo == null || grupo.isEmpty) continue;
      porGrupo.putIfAbsent(grupo, () => []).add(item);
    }

    final directos = <TablaPosicionModel>[];
    final candidatos = <TablaPosicionModel>[];

    final claves = porGrupo.keys.toList()..sort();

    for (final clave in claves) {
      final lista = porGrupo[clave]!
        ..sort((a, b) => a.posicion.compareTo(b.posicion));

      for (final item in lista) {
        if (item.posicion <= clasificanPorGrupo) {
          directos.add(item);
        } else if (item.posicion == clasificanPorGrupo + 1) {
          candidatos.add(item);
        }
      }
    }

    candidatos.sort(_compararTabla);
    final terceros = mejoresTerceros > 0
        ? candidatos.take(mejoresTerceros)
        : const <TablaPosicionModel>[];

    return [
      ...directos.map(
        (equipo) => ClasificadoInfo(equipo: equipo, porMejorTercero: false),
      ),
      ...terceros.map(
        (equipo) => ClasificadoInfo(equipo: equipo, porMejorTercero: true),
      ),
    ];
  }
}
