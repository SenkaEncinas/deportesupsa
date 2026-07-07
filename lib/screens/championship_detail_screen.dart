import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/public_home_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_info_line.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_responsive_pair.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/championship_public_card.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

const Color _upsaGold = Color(0xFFD6A100);
const Color _upsaGreenDeep = Color(0xFF003D2D);
const Color _upsaGreenHero = Color(0xFF005C45);

class ChampionshipDetailScreen extends StatelessWidget {
  final CampeonatoModel campeonato;

  const ChampionshipDetailScreen({
    super.key,
    required this.campeonato,
  });

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
                  _HeroSection(
                    campeonato: campeonato,
                    estadoTexto: estadoTexto,
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
                      campeonatoId: campeonato.id,
                    ),
                    second: _ScorersSection(
                      service: service,
                      campeonatoId: campeonato.id,
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

class _HeroSection extends StatelessWidget {
  final CampeonatoModel campeonato;
  final String estadoTexto;

  const _HeroSection({
    required this.campeonato,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _upsaGreenDeep,
              _upsaGreenHero,
              AppColors.primary,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -42,
                top: -50,
                child: _DecorativeCircle(
                  size: isMobile ? 140 : 190,
                  opacity: 0.10,
                ),
              ),
              Positioned(
                right: isMobile ? 14 : 36,
                bottom: -38,
                child: _DecorativeCircle(
                  size: isMobile ? 90 : 130,
                  opacity: 0.08,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 22 : 30),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroText(
                            campeonato: campeonato,
                            estadoTexto: estadoTexto,
                          ),
                          const SizedBox(height: 20),
                          _HeroInfoBox(campeonato: campeonato),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _HeroText(
                              campeonato: campeonato,
                              estadoTexto: estadoTexto,
                            ),
                          ),
                          const SizedBox(width: 28),
                          _HeroInfoBox(campeonato: campeonato),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final CampeonatoModel campeonato;
  final String estadoTexto;

  const _HeroText({
    required this.campeonato,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppLogoMark(
              compact: isMobile,
              dark: false,
            ),
            AppBadge(
              text: estadoTexto,
              type: ChampionshipPublicCard.badgeType(campeonato.estado),
              icon: Icons.sports_soccer,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          campeonato.nombre,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: isMobile ? 26 : 34,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            campeonato.descripcion.trim().isEmpty
                ? 'Consulta la información pública del campeonato: partidos programados, resultados, tabla de posiciones y ranking de goleadores.'
                : campeonato.descripcion,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withOpacity(0.88),
              fontSize: isMobile ? 14 : 15,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroChip(
              icon: Icons.school_outlined,
              text: 'Universidad Privada de Santa Cruz',
            ),
            _HeroChip(
              icon: Icons.public_outlined,
              text: 'Vista pública',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.white),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoBox extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _HeroInfoBox({
    required this.campeonato,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: isMobile ? double.infinity : 305,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoLine(
            icon: Icons.place_outlined,
            label: 'Cancha',
            value: campeonato.cancha,
            dark: true,
          ),
          const SizedBox(height: 14),
          AppInfoLine(
            icon: Icons.category_outlined,
            label: 'Modalidad',
            value: ChampionshipPublicCard.formatLabel(campeonato.modalidad),
            dark: true,
          ),
          const SizedBox(height: 14),
          AppInfoLine(
            icon: Icons.account_tree_outlined,
            label: 'Formato',
            value: ChampionshipPublicCard.formatLabel(campeonato.tipoCampeonato),
            dark: true,
          ),
          const SizedBox(height: 14),
          AppInfoLine(
            icon: Icons.calendar_today_outlined,
            label: 'Temporada',
            value: campeonato.temporada,
            dark: true,
          ),
        ],
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
                    child: AppMatchCard(
                      partido: partido,
                      showResult: true,
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

class _TableSection extends StatelessWidget {
  final PublicHomeService service;
  final String campeonatoId;

  const _TableSection({
    required this.service,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TablaPosicionModel>>(
      stream: service.streamTabla(campeonatoId),
      builder: (context, snapshot) {
        final tabla = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: AppLoading(message: 'Cargando tabla...'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Tabla de posiciones',
              subtitle: 'Desempeño general de los equipos.',
            ),
            const SizedBox(height: 14),
            AppTableContainer(
              headers: const [
                '#',
                'Equipo',
                'PJ',
                'G',
                'E',
                'P',
                'GF',
                'GC',
                'DG',
                'Pts',
              ],
              rows: tabla.map((item) {
                return [
                  _PositionCell(position: item.posicion),
                  Text(
                    item.equipoNombre,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text('${item.partidosJugados}'),
                  Text('${item.partidosGanados}'),
                  Text('${item.partidosEmpatados}'),
                  Text('${item.partidosPerdidos}'),
                  Text('${item.golesFavor}'),
                  Text('${item.golesContra}'),
                  Text('${item.diferenciaGoles}'),
                  Text(
                    '${item.puntos}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ];
              }).toList(),
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

  const _PositionCell({
    required this.position,
  });

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
          color: isTop ? AppColors.primary.withOpacity(0.18) : AppColors.border,
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
  final String campeonatoId;

  const _ScorersSection({
    required this.service,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<RankingGoleadorModel>>(
        stream: service.streamRankingGoleadores(campeonatoId),
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
                    child: _ScorerTile(
                      position: index + 1,
                      item: item,
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

class _ScorerTile extends StatelessWidget {
  final int position;
  final RankingGoleadorModel item;

  const _ScorerTile({
    required this.position,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final retirado = item.jugadorEstado == 'retirado';
    final isTop = position <= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.primaryLight.withOpacity(0.65)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTop ? AppColors.primary.withOpacity(0.14) : AppColors.border,
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