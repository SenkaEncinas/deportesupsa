import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppLogoMark extends StatelessWidget {
  final bool compact;
  final bool dark;

  const AppLogoMark({
    super.key,
    this.compact = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = dark ? AppColors.white.withValues(alpha: 0.12) : AppColors.white;
    final borderColor = dark ? AppColors.white.withValues(alpha: 0.18) : AppColors.border;

    return Container(
      height: compact ? 46 : 56,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Image.asset(
        'assets/images/logo_upsa.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_upsa_40.png',
                width: 30,
                height: 30,
                errorBuilder: (_, _, _) {
                  return Icon(
                    Icons.school_outlined,
                    color: dark ? AppColors.white : AppColors.primary,
                    size: 24,
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'UPSA',
                style: AppTextStyles.title.copyWith(
                  color: dark ? AppColors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}