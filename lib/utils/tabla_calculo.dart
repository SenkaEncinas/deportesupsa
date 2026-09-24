import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/tabla_posicion_model.dart';

/// Arma la tabla de posiciones a partir de los partidos jugados.
///
/// Es una función pura a propósito: no toca Firestore, no guarda nada y
/// siempre devuelve lo mismo para los mismos datos. Así el mismo cálculo
/// sirve para dos cosas que antes vivían separadas y se desincronizaban:
///
/// - Lo que se muestra en pantalla, que se recalcula en vivo cada vez
///   que cambia un resultado o una igualación.
/// - Lo que se guarda en `tabla_posiciones`, que queda como registro.
///
/// Antes la tabla solo existía guardada, y se escribía únicamente al
/// registrar un resultado. Si entre medio cambiaba una regla (los puntos
/// de vóley, por ejemplo), la tabla seguía mostrando los números viejos
/// hasta que alguien volviera a cargar un partido.
class TablaCalculo {
  TablaCalculo._();

  /// Puntos con los que se da por ganado un walkover en básquet: 20-0,
  /// como marca el reglamento.
  static const int puntosWalkoverBasket = 20;

  /// La tabla completa, ya ordenada y con la posición de cada equipo.
  ///
  /// En los formatos con grupos cada grupo lleva su propia tabla, así que
  /// la posición va de 1 a N **dentro del grupo**, y los partidos de la
  /// fase final (los que no tienen grupo) no suman.
  static List<TablaPosicionModel> calcular({
    required CampeonatoModel campeonato,
    required List<EquipoModel> equipos,
    required List<PartidoModel> partidos,
  }) {
    final usaGrupos =
        campeonato.tipoCampeonato == TipoCampeonato.faseGrupos ||
        campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion;

    // Grupo de cada equipo: se deduce de cualquier partido (jugado o no)
    // que tenga grupoId, para que el equipo aparezca en su grupo desde
    // que se inscribe, no recién cuando juega su primer partido.
    final equipoGrupo = <String, String>{};

    for (final partido in partidos) {
      if (!partido.tieneGrupo) continue;
      equipoGrupo[partido.equipoLocalId] = partido.grupoId!;
      equipoGrupo[partido.equipoVisitanteId] = partido.grupoId!;
    }

    final acumulados = <String, _Acumulado>{
      for (final equipo in equipos)
        equipo.id: _Acumulado(
          equipoId: equipo.id,
          equipoNombre: equipo.nombre,
          grupoId: usaGrupos ? equipoGrupo[equipo.id] : null,
        ),
    };

    final reglas = campeonato.reglasPuntuacionEfectivas;

    for (final partido in partidos) {
      if (!_cuentaParaLaTabla(partido, usaGrupos)) continue;

      final local = acumulados[partido.equipoLocalId];
      final visitante = acumulados[partido.equipoVisitanteId];

      if (local == null || visitante == null) continue;

      local.partidosJugados++;
      visitante.partidosJugados++;

      local.golesFavor += partido.golesLocal!;
      local.golesContra += partido.golesVisitante!;
      visitante.golesFavor += partido.golesVisitante!;
      visitante.golesContra += partido.golesLocal!;

      final puntos = _puntosDelPartido(campeonato, partido);

      local.puntosFavor += puntos.local;
      local.puntosContra += puntos.visitante;
      visitante.puntosFavor += puntos.visitante;
      visitante.puntosContra += puntos.local;

      // El punto por perder (vóley y básquet: 1) es por presentarse y
      // jugar, así que un walkover no lo paga: el que no se presentó
      // suma 0.
      final puntosPerdedor = partido.tipoResultado == TipoResultado.walkover
          ? 0
          : reglas.derrota;

      if (partido.golesLocal! > partido.golesVisitante!) {
        local.partidosGanados++;
        visitante.partidosPerdidos++;
        local.puntos += reglas.victoria;
        visitante.puntos += puntosPerdedor;
      } else if (partido.golesLocal! < partido.golesVisitante!) {
        visitante.partidosGanados++;
        local.partidosPerdidos++;
        visitante.puntos += reglas.victoria;
        local.puntos += puntosPerdedor;
      } else {
        local.partidosEmpatados++;
        visitante.partidosEmpatados++;
        local.puntos += reglas.empate;
        visitante.puntos += reglas.empate;
      }
    }

    for (final item in acumulados.values) {
      item.diferenciaGoles = item.golesFavor - item.golesContra;
      item.diferenciaPuntos = item.puntosFavor - item.puntosContra;

      // Igualación: puntos cargados a mano por el admin para compensar a
      // los grupos con menos equipos. Se suman al final, ya con todos los
      // partidos contados, y entran en el orden como cualquier otro punto.
      item.puntosIgualacion = campeonato.igualacionDe(item.equipoId);
      item.puntos += item.puntosIgualacion;
    }

    return _ordenar(acumulados.values.toList(), usaGrupos: usaGrupos);
  }

  /// Un partido suma para la tabla si ya se jugó y pertenece a la fase
  /// regular. En los formatos con grupos, los cruces de la fase final no
  /// tienen grupo y quedan afuera: son eliminatoria, no puntos.
  static bool _cuentaParaLaTabla(PartidoModel partido, bool usaGrupos) {
    if (partido.estado != PartidoEstado.finalizado ||
        !partido.resultadoRegistrado) {
      return false;
    }
    if (partido.golesLocal == null || partido.golesVisitante == null) {
      return false;
    }
    if (usaGrupos && !partido.tieneGrupo) {
      return false;
    }
    return true;
  }

  /// Puntos a favor y en contra que deja un partido, que es el criterio
  /// de desempate en vóley y básquet.
  ///
  /// - Vóley: los puntos de cada set.
  /// - Básquet y fútbol: el marcador.
  /// - Walkover y sanciones: lo que fija el reglamento, sin mirar lo
  ///   guardado en el partido. Los cargados antes de que la app armara
  ///   el detalle quedaron sin sets, y leerlos tal cual daría 2 de
  ///   diferencia (los sets) en vez de los 50 puntos que corresponden.
  static ({int local, int visitante}) _puntosDelPartido(
    CampeonatoModel campeonato,
    PartidoModel partido,
  ) {
    final administrativos = puntosPorNoPresentarse(campeonato, partido);
    if (administrativos != null) return administrativos;

    if (partido.sets.isNotEmpty) {
      var local = 0;
      var visitante = 0;

      for (final set in partido.sets) {
        local += set.local;
        visitante += set.visitante;
      }

      return (local: local, visitante: visitante);
    }

    return (local: partido.golesLocal!, visitante: partido.golesVisitante!);
  }

  /// El marcador con el que se da por ganado un walkover o una sanción,
  /// según el reglamento del deporte. Devuelve `null` en fútbol, donde
  /// no hay un marcador fijo y vale el que cargue el admin.
  ///
  /// Lo usa el registro de resultados para guardar siempre lo mismo, sin
  /// importar quién lo cargue.
  static ({int golesLocal, int golesVisitante, List<SetPartido> sets})?
  marcadorPorNoPresentarse({
    required CampeonatoModel campeonato,
    required bool ganaLocal,
  }) {
    switch (campeonato.sistemaResultadoEfectivo) {
      case SistemaResultado.sets:
        final sets = campeonato.configuracion.setsParaGanar;
        final porSet = campeonato.configuracion.puntosSetNormal;

        return (
          golesLocal: ganaLocal ? sets : 0,
          golesVisitante: ganaLocal ? 0 : sets,
          sets: List.generate(
            sets,
            (_) => SetPartido(
              local: ganaLocal ? porSet : 0,
              visitante: ganaLocal ? 0 : porSet,
            ),
          ),
        );

      case SistemaResultado.puntos:
        return (
          golesLocal: ganaLocal ? puntosWalkoverBasket : 0,
          golesVisitante: ganaLocal ? 0 : puntosWalkoverBasket,
          sets: const [],
        );

      default:
        return null;
    }
  }

  /// Los puntos que deja un walkover o una sanción, derivados del mismo
  /// marcador reglamentario que se guarda en el partido. Devuelve `null`
  /// si el partido no es administrativo o si el deporte no fija un
  /// marcador (fútbol).
  static ({int local, int visitante})? puntosPorNoPresentarse(
    CampeonatoModel campeonato,
    PartidoModel partido,
  ) {
    if (partido.tipoResultado == TipoResultado.normal) return null;
    if (partido.golesLocal == null || partido.golesVisitante == null) {
      return null;
    }

    final marcador = marcadorPorNoPresentarse(
      campeonato: campeonato,
      ganaLocal: partido.golesLocal! > partido.golesVisitante!,
    );

    if (marcador == null) return null;

    // En vóley los puntos son los de los sets; en básquet, el marcador.
    if (marcador.sets.isEmpty) {
      return (local: marcador.golesLocal, visitante: marcador.golesVisitante);
    }

    var local = 0;
    var visitante = 0;

    for (final set in marcador.sets) {
      local += set.local;
      visitante += set.visitante;
    }

    return (local: local, visitante: visitante);
  }

  /// Ordena y numera. Con grupos, cada uno se ordena por separado para
  /// que la posición sea el puesto dentro del grupo.
  static List<TablaPosicionModel> _ordenar(
    List<_Acumulado> items, {
    required bool usaGrupos,
  }) {
    final filas = items.map((item) => item.aModelo()).toList();

    // Sin grupos, una sola tabla. Con grupos, una por grupo: la posición
    // es el puesto dentro del grupo, no contra todo el campeonato.
    final bloques = <List<TablaPosicionModel>>[];

    if (usaGrupos) {
      final porGrupo = <String?, List<TablaPosicionModel>>{};

      for (final fila in filas) {
        porGrupo.putIfAbsent(fila.grupoId, () => []).add(fila);
      }

      // Los equipos sin grupo van al final.
      final claves = porGrupo.keys.toList()
        ..sort((a, b) {
          if (a == null || b == null) return a == null ? 1 : -1;
          return a.compareTo(b);
        });

      bloques.addAll(claves.map((clave) => porGrupo[clave]!));
    } else {
      bloques.add(filas);
    }

    return [
      for (final bloque in bloques)
        ...(bloque..sort(comparar)).indexed.map(
          (par) => par.$2.conPosicion(par.$1 + 1),
        ),
    ];
  }

  /// Orden de la tabla: puntos, y si hay empate la diferencia de puntos.
  ///
  /// Es el único criterio de desempate del sistema: lo usa la tabla de
  /// cada grupo y también la siembra de la llave (ver `Clasificacion`).
  static int comparar(TablaPosicionModel a, TablaPosicionModel b) {
    var compare = b.puntos.compareTo(a.puntos);
    if (compare != 0) return compare;

    // Diferencia de PUNTOS, no de goles/sets.
    //
    // En fútbol y básquet da lo mismo: los puntos a favor son el
    // marcador del partido. En vóley no: `golesFavor` son los sets
    // ganados y `puntosFavor` los puntos de cada set. El desempate mira
    // los puntos, que es lo que hace que un walkover (50-0) pese de
    // verdad; si mirara sets, un walkover valdría +2 y los 50 puntos no
    // servirían para nada.
    compare = b.diferenciaPuntos.compareTo(a.diferenciaPuntos);
    if (compare != 0) return compare;

    compare = b.puntosFavor.compareTo(a.puntosFavor);
    if (compare != 0) return compare;

    compare = a.puntosContra.compareTo(b.puntosContra);
    if (compare != 0) return compare;

    return a.equipoNombre.compareTo(b.equipoNombre);
  }
}

class _Acumulado {
  final String equipoId;
  final String equipoNombre;
  final String? grupoId;

  int partidosJugados = 0;
  int partidosGanados = 0;
  int partidosEmpatados = 0;
  int partidosPerdidos = 0;
  int golesFavor = 0;
  int golesContra = 0;
  int diferenciaGoles = 0;
  int puntos = 0;
  int puntosFavor = 0;
  int puntosContra = 0;
  int diferenciaPuntos = 0;
  int puntosIgualacion = 0;

  _Acumulado({
    required this.equipoId,
    required this.equipoNombre,
    this.grupoId,
  });

  TablaPosicionModel aModelo() {
    return TablaPosicionModel(
      equipoId: equipoId,
      equipoNombre: equipoNombre,
      grupoId: grupoId,
      partidosJugados: partidosJugados,
      partidosGanados: partidosGanados,
      partidosEmpatados: partidosEmpatados,
      partidosPerdidos: partidosPerdidos,
      golesFavor: golesFavor,
      golesContra: golesContra,
      diferenciaGoles: diferenciaGoles,
      puntos: puntos,
      posicion: 0,
      fechaActualizacion: DateTime.now(),
      puntosFavor: puntosFavor,
      puntosContra: puntosContra,
      diferenciaPuntos: diferenciaPuntos,
      puntosIgualacion: puntosIgualacion,
    );
  }
}
