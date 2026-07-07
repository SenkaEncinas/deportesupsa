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
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_styles.dart';

class RankingGoleadoresScreen extends StatelessWidget {
  final String campeonatoId;

  const RankingGoleadoresScreen({
    super.key,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
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
                          children: List.generate(ranking.length, (index) {
                            final item = ranking[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      AppTextStyles.heading3,
                                                ),
                                              ),
                                              if (item.jugadorEstado ==
                                                  'retirado') ...[
                                                const SizedBox(width: 8),
                                                const AppBadge(
                                                  text: 'Retirado',
                                                  type: AppBadgeType.danger,
                                                ),
                                              ],
                                              if (item.jugadorEstado ==
                                                  'suspendido') ...[
                                                const SizedBox(width: 8),
                                                const AppBadge(
                                                  text: 'Suspendido',
                                                  type: AppBadgeType.warning,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.equipoNombre,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.textSecondary,
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
                                          style:
                                              AppTextStyles.heading1.copyWith(
                                            color: AppColors.primaryDark,
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
                          }),
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