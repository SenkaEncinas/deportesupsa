import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/public_home_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_responsive_pair.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_standing_card.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/championship_public_card.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

const Color _upsaGold = Color(0xFFD6A100);

class ChampionshipDetailScreen extends StatelessWidget {
  final CampeonatoModel campeonato;

  const ChampionshipDetailScreen({super.key, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final service = PublicHomeService();
    final estadoTexto = ChampionshipPublicCard.estadoTexto(campeonato.estado);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF5F1),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppPage(
              title: campeonato.nombre,
              subtitle: 'Información pública del campeonato.',
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeroCard(
                    title: campeonato.nombre,
                    description: campeonato.descripcion.trim().isEmpty
                        ? 'Consulta la información pública del campeonato: partidos programados, resultados, tabla de posiciones y ranking de goleadores.'
                        : campeonato.descripcion,
                    badges: [
                      AppBadge(
                        text: estadoTexto,
                        type: ChampionshipPublicCard.badgeType(
                          campeonato.estado,
                        ),
                        icon: Icons.sports_soccer,
                      ),
                    ],
                    chips: const [
                      AppHeroChipData(
                        icon: Icons.school_outlined,
                        text: 'Universidad Privada de Santa Cruz',
                      ),
                      AppHeroChipData(
                        icon: Icons.public_outlined,
                        text: 'Vista pública',
                      ),
                    ],
                    infoItems: [
                      AppHeroInfoItem(
                        icon: Icons.place_outlined,
                        label: 'Cancha',
                        value: campeonato.cancha,
                      ),
                      AppHeroInfoItem(
                        icon: Icons.category_outlined,
                        label: 'Modalidad',
                        value: ChampionshipPublicCard.formatLabel(
                          campeonato.modalidad,
                        ),
                      ),
                      AppHeroInfoItem(
                        icon: Icons.account_tree_outlined,
                        label: 'Formato',
                        value: ChampionshipPublicCard.formatLabel(
                          campeonato.tipoCampeonato,
                        ),
                      ),
                      AppHeroInfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Temporada',
                        value: campeonato.temporada,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _StatsSection(
                    service: service,
                    campeonato: campeonato,
                    estadoTexto: estadoTexto,
                  ),
                  const SizedBox(height: 24),
                  AppResponsivePair(
                    first: _NextMatchesSection(
                      service: service,
                      campeonatoId: campeonato.id,
                    ),
                    second: _LastResultsSection(
                      service: service,
                      campeonatoId: campeonato.id,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppResponsivePair(
                    firstFlex: 3,
                    secondFlex: 2,
                    first: _TableSection(
                      service: service,
                      campeonato: campeonato,
                    ),
                    second: _ScorersSection(
                      service: service,
                      campeonato: campeonato,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;
  final String estadoTexto;

  const _StatsSection({
    required this.service,
    required this.campeonato,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      StreamBuilder(
        stream: service.streamEquipos(campeonato.id),
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
        stream: service.streamPartidos(campeonato.id),
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return StatCard(
            title: 'Partidos',
            value: '${partidos.length}',
            icon: Icons.sports_soccer,
            subtitle: ChampionshipPublicCard.formatLabel(
              campeonato.tipoCampeonato,
            ),
            color: _upsaGold,
          );
        },
      ),
      // Para fútbol se muestran los goles registrados; para vóley y
      // básquet se muestran los partidos finalizados.
      if (campeonato.esFutbol)
        StreamBuilder<List<RankingGoleadorModel>>(
          stream: service.streamRankingGoleadores(campeonato.id),
          builder: (context, snapshot) {
            final ranking = snapshot.data ?? [];
            final totalGoles = ranking.fold<int>(
              0,
              (total, item) => total + item.totalGoles,
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
          stream: service.streamPartidos(campeonato.id),
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
  final PublicHomeService service;
  final String campeonatoId;

  const _NextMatchesSection({
    required this.service,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: service.streamProximosPartidos(campeonatoId),
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Próximos partidos',
                subtitle: 'Programación oficial del campeonato.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const AppLoading(message: 'Cargando partidos...')
              else if (partidos.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.event_busy_outlined,
                  text: 'Todavía no hay partidos programados.',
                )
              else
                ...List.generate(partidos.length, (index) {
                  final partido = partidos[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < partidos.length - 1 ? 10 : 0,
                    ),
                    child: AppMatchCard(partido: partido),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _LastResultsSection extends StatelessWidget {
  final PublicHomeService service;
  final String campeonatoId;

  const _LastResultsSection({
    required this.service,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: service.streamUltimosResultados(campeonatoId),
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
                const AppLoading(message: 'Cargando resultados...')
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
                    child: AppMatchCard(partido: partido, showResult: true),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _TableSection extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _TableSection({required this.service, required this.campeonato});

  /// Encabezados según el deporte:
  /// - Fútbol: PJ, G, E, P, GF, GC, DG, Pts.
  /// - Vóley: PJ, G, P, SF, SC, DS, PF, PC, DP, Pts (sets y puntos).
  /// - Básquet: PJ, G, P, PF, PC, DP, Pts.
  List<String> _headers() {
    if (campeonato.esVolley) {
      return const [
        '#',
        'Equipo',
        'PJ',
        'G',
        'P',
        'SF',
        'SC',
        'DS',
        'PF',
        'PC',
        'DP',
        'Pts',
      ];
    }

    if (campeonato.esBasket) {
      return const ['#', 'Equipo', 'PJ', 'G', 'P', 'PF', 'PC', 'DP', 'Pts'];
    }

    return const ['#', 'Equipo', 'PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'Pts'];
  }

  /// Estadísticas por equipo para la card compacta de móvil, sin
  /// posición/nombre/puntos (esos van en la cabecera de la card).
  List<MapEntry<String, String>> _statsCompactos(TablaPosicionModel item) {
    if (campeonato.esVolley) {
      return [
        MapEntry('PJ', '${item.partidosJugados}'),
        MapEntry('G', '${item.partidosGanados}'),
        MapEntry('P', '${item.partidosPerdidos}'),
        MapEntry('SF', '${item.golesFavor}'),
        MapEntry('SC', '${item.golesContra}'),
        MapEntry('DS', '${item.diferenciaGoles}'),
        MapEntry('PF', '${item.puntosFavor}'),
        MapEntry('PC', '${item.puntosContra}'),
        MapEntry('DP', '${item.diferenciaPuntos}'),
      ];
    }

    if (campeonato.esBasket) {
      return [
        MapEntry('PJ', '${item.partidosJugados}'),
        MapEntry('G', '${item.partidosGanados}'),
        MapEntry('P', '${item.partidosPerdidos}'),
        MapEntry('PF', '${item.golesFavor}'),
        MapEntry('PC', '${item.golesContra}'),
        MapEntry('DP', '${item.diferenciaGoles}'),
      ];
    }

    return [
      MapEntry('PJ', '${item.partidosJugados}'),
      MapEntry('G', '${item.partidosGanados}'),
      MapEntry('E', '${item.partidosEmpatados}'),
      MapEntry('P', '${item.partidosPerdidos}'),
      MapEntry('GF', '${item.golesFavor}'),
      MapEntry('GC', '${item.golesContra}'),
      MapEntry('DG', '${item.diferenciaGoles}'),
    ];
  }

  List<Widget> _row(TablaPosicionModel item) {
    final posicion = _PositionCell(position: item.posicion);
    // maxWidth acotado: sin esto, TextOverflow.ellipsis no recorta nada
    // porque DataCell le da a su contenido ancho intrínseco (ilimitado).
    final nombre = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Text(
        item.equipoNombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium,
      ),
    );
    final puntos = Text(
      '${item.puntos}',
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w900,
      ),
    );

    if (campeonato.esVolley) {
      // En vóley golesFavor/golesContra guardan sets a favor/en contra.
      return [
        posicion,
        nombre,
        Text('${item.partidosJugados}'),
        Text('${item.partidosGanados}'),
        Text('${item.partidosPerdidos}'),
        Text('${item.golesFavor}'),
        Text('${item.golesContra}'),
        Text('${item.diferenciaGoles}'),
        Text('${item.puntosFavor}'),
        Text('${item.puntosContra}'),
        Text('${item.diferenciaPuntos}'),
        puntos,
      ];
    }

    if (campeonato.esBasket) {
      return [
        posicion,
        nombre,
        Text('${item.partidosJugados}'),
        Text('${item.partidosGanados}'),
        Text('${item.partidosPerdidos}'),
        Text('${item.golesFavor}'),
        Text('${item.golesContra}'),
        Text('${item.diferenciaGoles}'),
        puntos,
      ];
    }

    return [
      posicion,
      nombre,
      Text('${item.partidosJugados}'),
      Text('${item.partidosGanados}'),
      Text('${item.partidosEmpatados}'),
      Text('${item.partidosPerdidos}'),
      Text('${item.golesFavor}'),
      Text('${item.golesContra}'),
      Text('${item.diferenciaGoles}'),
      puntos,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return StreamBuilder<List<TablaPosicionModel>>(
      stream: service.streamTabla(campeonato.id),
      builder: (context, snapshot) {
        final tabla = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(child: AppLoading(message: 'Cargando tabla...'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Tabla de posiciones',
              subtitle: campeonato.esVolley
                  ? 'Partidos, sets y puntos de cada equipo.'
                  : 'Desempeño general de los equipos.',
            ),
            const SizedBox(height: 14),
            // En móvil una DataTable con hasta 12 columnas obliga a un
            // scroll horizontal poco descubrible y filas muy angostas.
            // Se reemplaza por una card por equipo con sus estadísticas
            // en una grilla compacta, igual que se hizo con AppHeroCard.
            if (isMobile)
              tabla.isEmpty
                  ? AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Todavía no hay tabla de posiciones.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: tabla.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppStandingCard(
                            item: item,
                            stats: _statsCompactos(item),
                          ),
                        );
                      }).toList(),
                    )
            else
              AppTableContainer(
                headers: _headers(),
                rows: tabla.map(_row).toList(),
                emptyMessage: 'Todavía no hay tabla de posiciones.',
              ),
          ],
        );
      },
    );
  }
}

class _PositionCell extends StatelessWidget {
  final int position;

  const _PositionCell({required this.position});

  @override
  Widget build(BuildContext context) {
    final isTop = position <= 3;

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop ? AppColors.primaryLight : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Text(
        '$position',
        style: AppTextStyles.small.copyWith(
          color: isTop ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScorersSection extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _ScorersSection({required this.service, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    // El ranking individual solo existe para fútbol/futsal.
    // Vóley y básquet quedan preparados para estadísticas de jugadores
    // en una siguiente fase.
    if (campeonato.esVolley) {
      return const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Estadísticas',
              subtitle: 'Estadísticas individuales de vóley.',
            ),
            SizedBox(height: 16),
            AppInlineEmptyState(
              icon: Icons.sports_volleyball_outlined,
              text:
                  'Las estadísticas por jugador de vóley estarán disponibles próximamente. Mientras tanto revisa la tabla con sets y puntos.',
            ),
          ],
        ),
      );
    }

    if (campeonato.esBasket) {
      return const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Anotadores',
              subtitle: 'Ranking individual de puntos.',
            ),
            SizedBox(height: 16),
            AppInlineEmptyState(
              icon: Icons.sports_basketball_outlined,
              text:
                  'El registro de puntos por jugador estará disponible próximamente. El marcador por equipo ya se registra en Resultados.',
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: StreamBuilder<List<RankingGoleadorModel>>(
        stream: service.streamRankingGoleadores(campeonato.id),
        builder: (context, snapshot) {
          final ranking = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Goleadores',
                subtitle: 'Ranking de mejores anotadores.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const AppLoading(message: 'Cargando goleadores...')
              else if (ranking.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.sports_soccer_outlined,
                  text: 'Todavía no hay goles registrados.',
                )
              else
                ...List.generate(ranking.length, (index) {
                  final item = ranking[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < ranking.length - 1 ? 10 : 0,
                    ),
                    child: _ScorerTile(position: index + 1, item: item),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ScorerTile extends StatelessWidget {
  final int position;
  final RankingGoleadorModel item;

  const _ScorerTile({required this.position, required this.item});

  @override
  Widget build(BuildContext context) {
    final retirado = item.jugadorEstado == 'retirado';
    final isTop = position <= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.primaryLight.withValues(alpha: 0.65)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTop
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTop ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              position.toString(),
              style: AppTextStyles.small.copyWith(
                color: isTop ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jugadorNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.equipoNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ),
                    if (retirado) ...[
                      const SizedBox(width: 8),
                      const AppBadge(
                        text: 'Retirado',
                        type: AppBadgeType.danger,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalGoles}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.totalGoles == 1 ? 'gol' : 'goles',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
