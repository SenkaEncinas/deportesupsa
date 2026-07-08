import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dark;

  const AppInfoLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? AppColors.white : AppColors.textPrimary;
    final muted = dark ? AppColors.white.withValues(alpha: 0.70) : AppColors.textSecondary;
    final iconBackground = dark ? AppColors.white.withValues(alpha: 0.14) : AppColors.primaryLight;
    final iconColor = dark ? AppColors.white : AppColors.primary;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.trim().isEmpty ? 'No definido' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}