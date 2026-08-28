import 'package:flutter/material.dart';

import '../../utils/clasificacion.dart';
import '../../utils/fixture_grouping.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_colors.dart';
import 'app_section_header.dart';
import 'app_text_styles.dart';

/// Lista de clasificados a la fase final de un campeonato de grupos +
/// eliminación: los que pasan directo por grupo y los mejores terceros,
/// junto con la ronda con la que arrancaría la llave (octavos, cuartos,
/// etc.) según cuántos clasifican en total.
class AppClasificadosCard extends StatelessWidget {
  final List<ClasificadoInfo> clasificados;
  final int totalEsperado;

  const AppClasificadosCard({
    super.key,
    required this.clasificados,
    required this.totalEsperado,
  });

  @override
  Widget build(BuildContext context) {
    final ronda = FixtureGrouping.rondaSegunEquipos(totalEsperado);
    final faltan = totalEsperado - clasificados.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: AppSectionHeader(
                  title: 'Clasificados a la fase final',
                  subtitle:
                      'Directos por grupo y mejores terceros, en vivo según los resultados actuales.',
                ),
              ),
              if (totalEsperado >= 2)
                AppBadge(text: ronda, type: AppBadgeType.primary),
            ],
          ),
          const SizedBox(height: 14),
          if (clasificados.isEmpty)
            Text(
              'Todavía no hay clasificados definidos: se calculan a medida que se juegan los partidos de grupos.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: clasificados.map((clasificado) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ClasificadoRow(clasificado: clasificado),
                );
              }).toList(),
            ),
          if (faltan > 0) ...[
            const SizedBox(height: 6),
            Text(
              faltan == 1
                  ? 'Falta 1 cupo por definir.'
                  : 'Faltan $faltan cupos por definir.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClasificadoRow extends StatelessWidget {
  final ClasificadoInfo clasificado;

  const _ClasificadoRow({required this.clasificado});

  @override
  Widget build(BuildContext context) {
    final equipo = clasificado.equipo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${equipo.posicion}',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              equipo.equipoNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (equipo.grupoId != null && equipo.grupoId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AppBadge(text: equipo.grupoId!, type: AppBadgeType.neutral),
            ),
          AppBadge(
            text: clasificado.porMejorTercero ? 'Mejor 3ro' : 'Directo',
            type: clasificado.porMejorTercero
                ? AppBadgeType.warning
                : AppBadgeType.success,
          ),
        ],
      ),
    );
  }
}
