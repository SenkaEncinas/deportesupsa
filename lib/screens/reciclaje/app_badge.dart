import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

enum AppBadgeType { success, warning, danger, info, neutral, primary }

class AppBadge extends StatelessWidget {
  final String text;
  final AppBadgeType type;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.type = AppBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.foreground),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _colors() {
    switch (type) {
      case AppBadgeType.success:
        return const _BadgeColors(
          background: AppColors.successLight,
          foreground: AppColors.success,
        );
      case AppBadgeType.warning:
        return const _BadgeColors(
          background: AppColors.warningLight,
          foreground: AppColors.warning,
        );
      case AppBadgeType.danger:
        return const _BadgeColors(
          background: AppColors.dangerLight,
          foreground: AppColors.danger,
        );
      case AppBadgeType.info:
        return const _BadgeColors(
          background: AppColors.infoLight,
          foreground: AppColors.info,
        );
      case AppBadgeType.primary:
        return const _BadgeColors(
          background: AppColors.primaryLight,
          foreground: AppColors.primary,
        );
      case AppBadgeType.neutral:
        return const _BadgeColors(
          background: AppColors.surfaceSoft,
          foreground: AppColors.textSecondary,
        );
    }
  }

  static AppBadgeType typeFromEstado(String estado) {
    switch (estado) {
      case 'activo':
      case 'finalizado':
      case 'programado':
      case 'inscripcion':
        return AppBadgeType.success;
      case 'pendiente_programacion':
      case 'suspendido':
      case 'suspendido_temporal':
        return AppBadgeType.warning;
      case 'retirado':
      case 'descalificado':
      case 'cancelado':
        return AppBadgeType.danger;
      default:
        return AppBadgeType.neutral;
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;

  const _BadgeColors({required this.background, required this.foreground});
}
