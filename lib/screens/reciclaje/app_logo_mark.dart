import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppLogoMark extends StatelessWidget {
  final bool compact;
  final bool dark;

  const AppLogoMark({super.key, this.compact = false, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = dark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.white;
    final borderColor = dark
        ? AppColors.white.withValues(alpha: 0.18)
        : AppColors.border;

    // El logo actual ("Copa UPSA" + búho) es prácticamente cuadrado, a
    // diferencia del wordmark horizontal anterior: la marca necesita una
    // caja cuadrada propia en vez de una altura fija con ancho libre,
    // que lo dejaba chiquito y perdido en el medio de una caja angosta.
    final size = compact ? 46.0 : 64.0;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(compact ? 6 : 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 13 : 16),
        border: Border.all(color: borderColor),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Image.asset(
        'assets/images/logo_upsa.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_upsa.png',
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
            ),
          );
        },
      ),
    );
  }
}
