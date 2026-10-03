import 'package:flutter/material.dart';

import '../../models/campeonato_model.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_colors.dart';
import 'app_match_card.dart';
import 'app_text_styles.dart';
import '../../utils/etiquetas.dart';

class ChampionshipPublicCard extends StatelessWidget {
  final CampeonatoModel campeonato;
  final VoidCallback onTap;

  const ChampionshipPublicCard({
    super.key,
    required this.campeonato,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SportIcon(deporte: campeonato.deporteEfectivo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  campeonato.nombre.trim().isEmpty
                      ? 'Campeonato sin nombre'
                      : campeonato.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                text: Etiquetas.estadoCampeonato(campeonato.estado),
                type: badgeType(campeonato.estado),
              ),
              AppBadge(
                text: Etiquetas.modalidad(campeonato.modalidad),
                type: AppBadgeType.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            campeonato.descripcion.trim().isEmpty
                ? 'Consulta fixture, resultados, tabla de posiciones y ranking de goleadores.'
                : campeonato.descripcion,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: campeonato.temporada.trim().isEmpty
                ? 'Temporada no definida'
                : campeonato.temporada,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.account_tree_outlined,
            text: Etiquetas.tipoCampeonato(campeonato.tipoCampeonato),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.place_outlined,
            text: campeonato.cancha.trim().isEmpty
                ? 'Cancha no definida'
                : campeonato.cancha,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Ver campeonato',
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static AppBadgeType badgeType(String estado) {
    switch (estado) {
      case CampeonatoEstado.inscripcion:
        return AppBadgeType.info;
      case CampeonatoEstado.activo:
        return AppBadgeType.success;
      case CampeonatoEstado.finalizado:
        return AppBadgeType.neutral;
      default:
        return AppBadge.typeFromEstado(estado);
    }
  }
}

class _SportIcon extends StatelessWidget {
  final String deporte;

  const _SportIcon({required this.deporte});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(deporteIcono(deporte), color: AppColors.primary, size: 25),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
