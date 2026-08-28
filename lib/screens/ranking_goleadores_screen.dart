import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/ranking_goleador_model.dart';
import '../services/campeonato_service.dart';
import '../services/public_home_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';

class RankingGoleadoresScreen extends StatefulWidget {
  final String campeonatoId;

  const RankingGoleadoresScreen({super.key, required this.campeonatoId});

  @override
  State<RankingGoleadoresScreen> createState() =>
      _RankingGoleadoresScreenState();
}

class _RankingGoleadoresScreenState extends State<RankingGoleadoresScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campeonatoId = widget.campeonatoId;
    final campeonatoService = CampeonatoService();
    final publicService = PublicHomeService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<RankingGoleadorModel>>(
            stream: publicService.streamRankingGoleadores(campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando goleadores...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar ranking',
                  message: snapshot.error.toString(),
                );
              }

              final ranking = snapshot.data ?? [];

              // El ranking de goleadores solo aplica a fútbol/futsal.
              // Para vóley/básquet se muestra un mensaje claro hasta que
              // exista registro individual (preparado para otra fase).
              if (campeonato != null && !campeonato.esFutbol) {
                return SingleChildScrollView(
                  child: AppPage(
                    title: campeonato.esBasket
                        ? 'Anotadores'
                        : 'Estadísticas de jugadores',
                    subtitle: campeonato.nombre,
                    actions: [
                      AppButton.secondary(
                        text: 'Volver',
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    child: AppEmptyState(
                      icon: campeonato.esBasket
                          ? Icons.sports_basketball_outlined
                          : Icons.sports_volleyball_outlined,
                      title: 'Módulo en preparación',
                      message: campeonato.esBasket
                          ? 'El registro de puntos por jugador estará disponible próximamente. El marcador por equipo ya se registra en Resultados.'
                          : 'Las estadísticas por jugador de vóley estarán disponibles próximamente. La tabla ya considera sets y puntos por equipo.',
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Ranking de goleadores',
                  subtitle: campeonato == null
                      ? 'Mejores goleadores del campeonato.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                  child: ranking.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.sports_soccer,
                          title: 'No hay goles registrados',
                          message:
                              'Cuando se registren resultados normales con goles por jugador, aparecerá el ranking.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Buscar goleador',
                              hint: 'Nombre del jugador o del equipo...',
                              controller: _searchController,
                              prefixIcon: Icons.search_rounded,
                              onChanged: (value) {
                                setState(() => _search = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            Builder(
                              builder: (context) {
                                final entradas = ranking.asMap().entries.where((
                                  entry,
                                ) {
                                  final search = _search.trim().toLowerCase();
                                  if (search.isEmpty) return true;

                                  final searchable = [
                                    entry.value.jugadorNombre,
                                    entry.value.equipoNombre,
                                  ].join(' ').toLowerCase();

                                  return searchable.contains(search);
                                }).toList();

                                if (entradas.isEmpty) {
                                  return const AppInlineEmptyState(
                                    icon: Icons.search_off_rounded,
                                    text:
                                        'No hay goleadores que coincidan con la búsqueda.',
                                  );
                                }

                                return Column(
                                  children: entradas.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: AppCard(
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor:
                                                  AppColors.primaryLight,
                                              child: Text(
                                                '${index + 1}',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          item.jugadorNombre,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: AppTextStyles
                                                              .heading3,
                                                        ),
                                                      ),
                                                      if (item.jugadorEstado ==
                                                          'retirado') ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const AppBadge(
                                                          text: 'Retirado',
                                                          type: AppBadgeType
                                                              .danger,
                                                        ),
                                                      ],
                                                      if (item.jugadorEstado ==
                                                          'suspendido') ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const AppBadge(
                                                          text: 'Suspendido',
                                                          type: AppBadgeType
                                                              .warning,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.equipoNombre,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${item.partidosConGol} partidos con gol',
                                                    style: AppTextStyles.small,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${item.totalGoles}',
                                                  style: AppTextStyles.heading1
                                                      .copyWith(
                                                        color: AppColors
                                                            .primaryDark,
                                                      ),
                                                ),
                                                Text(
                                                  item.totalGoles == 1
                                                      ? 'gol'
                                                      : 'goles',
                                                  style: AppTextStyles.small,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
