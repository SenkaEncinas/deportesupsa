part of '../championship_detail_screen.dart';

// Números del campeonato, próximos partidos, resultados y cuadro eliminatorio.

class _StatsSection extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;
  final String estadoTexto;

  const _StatsSection({
    required this.datos,
    required this.campeonato,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      StreamBuilder(
        stream: datos.equipos,
        builder: (context, snapshot) {
          return StatCard(
            title: 'Equipos',
            value: '${snapshot.data?.length ?? 0}',
            icon: Icons.groups_2_outlined,
            subtitle: 'Registrados',
            color: AppColors.primary,
          );
        },
      ),
      StreamBuilder<List<PartidoModel>>(
        stream: datos.partidos,
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return StatCard(
            title: 'Partidos',
            value: '${partidos.length}',
            icon: Icons.sports_soccer,
            subtitle: Etiquetas.tipoCampeonato(campeonato.tipoCampeonato),
            color: AppColors.secondary,
          );
        },
      ),
      // Para fútbol se muestran los goles registrados; para vóley y
      // básquet se muestran los partidos finalizados.
      //
      // El total sale de los partidos (golesLocal + golesVisitante), no
      // del ranking de goleadores: los resultados administrativos
      // (walkover/sanción) suman goles al marcador del partido pero no
      // generan goles por jugador, así que sumar solo el ranking
      // subcontaba el total real del campeonato.
      if (campeonato.esFutbol)
        StreamBuilder<List<PartidoModel>>(
          stream: datos.partidos,
          builder: (context, snapshot) {
            final partidos = snapshot.data ?? [];
            final totalGoles = partidos
                .where((p) => p.resultadoRegistrado)
                .fold<int>(
                  0,
                  (total, p) =>
                      total + (p.golesLocal ?? 0) + (p.golesVisitante ?? 0),
                );

            return StatCard(
              title: 'Goles',
              value: '$totalGoles',
              icon: Icons.emoji_events_outlined,
              subtitle: 'Registrados',
              color: AppColors.info,
            );
          },
        )
      else
        StreamBuilder<List<PartidoModel>>(
          stream: datos.partidos,
          builder: (context, snapshot) {
            final finalizados = (snapshot.data ?? [])
                .where((p) => p.resultadoRegistrado)
                .length;

            return StatCard(
              title: 'Finalizados',
              value: '$finalizados',
              icon: Icons.emoji_events_outlined,
              subtitle: 'Con resultado',
              color: AppColors.info,
            );
          },
        ),
      StatCard(
        title: 'Estado',
        value: estadoTexto,
        icon: Icons.verified_outlined,
        subtitle: 'Campeonato',
        color: AppColors.success,
      ),
    ];

    return AppResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      children: cards,
    );
  }
}

class _NextMatchesSection extends StatelessWidget {
  final DatosCampeonato datos;
  final String deporte;

  const _NextMatchesSection({required this.datos, required this.deporte});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: datos.proximos,
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          // Los de esta semana van primero, que son los que importan;
          // los de la semana que viene quedan debajo, en su propio bloque.
          final corte = PublicHomeService.rangoProximos(
            DateTime.now(),
          ).corteSemana;
          final estaSemana = partidos
              .where((p) => p.fechaHora != null && p.fechaHora!.isBefore(corte))
              .toList();
          final proximaSemana = partidos
              .where((p) => !estaSemana.contains(p))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Próximos partidos',
                subtitle: 'Programación de esta semana y la siguiente.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _MatchSkeletonColumn()
              else if (partidos.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.event_busy_outlined,
                  text: 'No hay partidos programados para estas dos semanas.',
                )
              else ...[
                _BloqueSemana(
                  titulo: 'ESTA SEMANA',
                  partidos: estaSemana,
                  deporte: deporte,
                  vacio: 'No quedan partidos esta semana.',
                ),
                if (proximaSemana.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BloqueSemana(
                    titulo: 'SEMANA QUE VIENE',
                    partidos: proximaSemana,
                    deporte: deporte,
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Un bloque de "Próximos partidos" ("Esta semana" o "Semana que
/// viene"): una etiqueta chica con la cantidad y los partidos debajo.
class _BloqueSemana extends StatelessWidget {
  final String titulo;
  final List<PartidoModel> partidos;
  final String deporte;

  /// Texto cuando el bloque no tiene partidos. Sin él, un bloque vacío
  /// no se dibuja.
  final String? vacio;

  const _BloqueSemana({
    required this.titulo,
    required this.partidos,
    required this.deporte,
    this.vacio,
  });

  @override
  Widget build(BuildContext context) {
    if (partidos.isEmpty && vacio == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (partidos.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${partidos.length}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (partidos.isEmpty)
          Text(
            vacio!,
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          )
        else
          ...List.generate(partidos.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < partidos.length - 1 ? 10 : 0,
              ),
              child: AppMatchCard(partido: partidos[index], deporte: deporte),
            );
          }),
      ],
    );
  }
}

class _LastResultsSection extends StatelessWidget {
  final DatosCampeonato datos;
  final String deporte;

  const _LastResultsSection({required this.datos, required this.deporte});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: datos.ultimosResultados,
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Últimos resultados',
                subtitle: 'Marcadores finales registrados.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _MatchSkeletonColumn()
              else if (partidos.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.scoreboard_outlined,
                  text: 'Todavía no hay resultados registrados.',
                )
              else
                ...List.generate(partidos.length, (index) {
                  final partido = partidos[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < partidos.length - 1 ? 10 : 0,
                    ),
                    child: AppMatchCard(
                      partido: partido,
                      showResult: true,
                      deporte: deporte,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

/// Fixture completo, público y de solo lectura. Según el formato del
/// campeonato separa dos cosas distintas:
/// - Los cruces de todos contra todos (liga o fase de grupos): lista
///   agrupada, igual que en la pantalla de administración.
/// - Los cruces de eliminación directa (octavos, cuartos, semifinal,
///   final...): una llave visual con `AppBracketView`, mucho más clara
///   que una lista de texto una vez que el torneo llega a esa etapa.
class _FixtureSection extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  /// En móvil la sección ya viene titulada por la pantalla (el nombre
  /// de la sección del sidebar), así que el encabezado propio sobra y
  /// solo repetiría el mismo texto dos veces seguidas.
  final bool conEncabezado;

  const _FixtureSection({
    required this.datos,
    required this.campeonato,
    this.conEncabezado = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PartidoModel>>(
      stream: datos.partidos,
      builder: (context, snapshot) {
        final partidos = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conEncabezado) ...[
                  const AppSectionHeader(
                    title: 'Llaves eliminatorias',
                    subtitle: 'De la ronda inicial hasta la gran final.',
                  ),
                  const SizedBox(height: 16),
                ],
                const _MatchSkeletonColumn(),
              ],
            ),
          );
        }

        // El listado plano "fixture por grupo" ya no se muestra acá: la
        // tabla de posiciones y los clasificados cubren esa información
        // de forma más útil. Esta sección queda solo para la llave
        // visual de la fase eliminatoria.
        // Los partidos con privilegio también van sin grupo, pero no son
        // parte de la fase final: se filtran aparte.
        final deFaseFinal = partidos.where(campeonato.esDeFaseFinal).toList();

        final rondasLlave = FixtureGrouping.rondasEliminatorias(deFaseFinal);

        // Cruces de fase final que todavía no entran en ningún cuadro.
        // No son una ronda, pero se juegan igual, así que el público los
        // tiene que ver con su fecha y su resultado.
        final sueltos = FixtureGrouping.crucesSueltos(deFaseFinal);

        if (rondasLlave.isEmpty && sueltos.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conEncabezado) ...[
                const AppSectionHeader(
                  title: 'Llaves eliminatorias',
                  subtitle: 'De la ronda inicial hasta la gran final.',
                ),
                const SizedBox(height: 16),
              ],
              const AppInlineEmptyState(
                icon: Icons.account_tree_outlined,
                text: 'Todavía no hay partidos de fase final.',
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conEncabezado) ...[
              const AppSectionHeader(
                title: 'Llaves eliminatorias',
                subtitle: 'De la ronda inicial hasta la gran final.',
              ),
              const SizedBox(height: 16),
            ],
            if (rondasLlave.isNotEmpty)
              AppBracketView(
                rondas: rondasLlave,
                deporte: campeonato.deporteEfectivo,
              ),
            if (sueltos.isNotEmpty) ...[
              if (rondasLlave.isNotEmpty) const SizedBox(height: 24),
              _PartidosFaseFinalSection(
                partidos: sueltos,
                deporte: campeonato.deporteEfectivo,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Partidos de fase final que todavía no forman parte del cuadro.
///
/// Pasa en los formatos que no se pueden generar solos (12 clasificados
/// con repechaje, por ejemplo): esas primeras rondas las carga el admin
/// a mano y no son una ronda del cuadro hasta que lo arme. Igual se
/// juegan, así que se muestran acá con su fecha y su resultado.
class _PartidosFaseFinalSection extends StatelessWidget {
  final List<PartidoModel> partidos;
  final String deporte;

  const _PartidosFaseFinalSection({
    required this.partidos,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    final ordenados = [...partidos]
      ..sort((a, b) {
        // Primero los que tienen fecha, en orden; los que todavía no se
        // programaron quedan al final.
        final fechaA = a.fechaHora;
        final fechaB = b.fechaHora;
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaA.compareTo(fechaB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Partidos de fase final',
          subtitle: 'Fixture y resultados de los cruces de fase final.',
        ),
        const SizedBox(height: 16),
        ...ordenados.map(
          (partido) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppMatchCard(
              partido: partido,
              deporte: deporte,
              // Sin esto la tarjeta mostraba solo la fecha, como si el
              // cruce todavía no se hubiera jugado.
              showResult: partido.resultadoRegistrado,
            ),
          ),
        ),
      ],
    );
  }
}
