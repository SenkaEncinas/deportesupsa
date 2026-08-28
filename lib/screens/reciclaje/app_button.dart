import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

/// Botón de la app con jerarquía Material 3 real por variante:
/// - primary: [FilledButton] (acción principal de la pantalla).
/// - secondary: [OutlinedButton] (acción alternativa).
/// - danger: [FilledButton] en rojo (acción destructiva).
/// - ghost: [TextButton] (acción terciaria, de bajo énfasis).
///
/// La API pública (AppButton.primary/secondary/danger/ghost con
/// text/onPressed/icon/loading/expanded/height) no cambió, así que
/// ningún llamador existente necesita tocarse.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;
  final bool expanded;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
    this.height,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.height,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.height,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.height,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.height,
  }) : variant = AppButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundColor();

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: foreground),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(color: foreground),
          ),
        ),
      ],
    );

    final effectiveOnPressed = loading ? null : onPressed;
    final minSize = Size(64, height ?? AppSizes.fieldHeight);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    );
    final padding = const EdgeInsets.symmetric(horizontal: 18);

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
            minimumSize: minSize,
            padding: padding,
            shape: shape,
          ),
          child: child,
        );

      case AppButtonVariant.danger:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
            minimumSize: minSize,
            padding: padding,
            shape: shape,
          ),
          child: child,
        );

      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.primary.withValues(alpha: 0.5),
            side: BorderSide(
              color: effectiveOnPressed == null
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.primary,
            ),
            minimumSize: minSize,
            padding: padding,
            shape: shape,
          ),
          child: child,
        );

      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            disabledForegroundColor: AppColors.textSecondary.withValues(
              alpha: 0.5,
            ),
            minimumSize: minSize,
            padding: padding,
            shape: shape,
          ),
          child: child,
        );
    }

    return SizedBox(
      height: height ?? AppSizes.fieldHeight,
      width: expanded ? double.infinity : null,
      child: button,
    );
  }

  Color _foregroundColor() {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return AppColors.white;
      case AppButtonVariant.secondary:
        return AppColors.primary;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }
}
