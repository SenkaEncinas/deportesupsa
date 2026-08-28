import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    final background = backgroundColor ?? AppColors.surface;

    final inner = Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: showBorder ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );

    // El splash/ripple se recorta con ClipRRect + Material a las esquinas
    // redondeadas; el BoxShadow vive en un Container por fuera del recorte
    // para que no se corte junto con el ripple.
    final clipped = ClipRRect(
      borderRadius: radius,
      child: Material(
        color: background,
        child: onTap == null
            ? inner
            : InkWell(
                onTap: onTap,
                hoverColor: AppColors.primary.withValues(alpha: 0.03),
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: inner,
              ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        // Sombra en dos capas (una ajustada + una ambiental) para una
        // sensación de elevación más "diseñada" que un solo blur grande.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: clipped,
    );
  }
}
