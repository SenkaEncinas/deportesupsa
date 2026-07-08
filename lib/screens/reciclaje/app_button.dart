import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

enum AppButtonVariant {
  primary,
  secondary,
  danger,
  ghost,
}

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
    final colors = _colors();

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
              valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: 18,
            color: colors.foreground,
          ),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(
              color: colors.foreground,
            ),
          ),
        ),
      ],
    );

    final button = SizedBox(
      height: height ?? AppSizes.fieldHeight,
      width: expanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          disabledBackgroundColor: colors.background.withValues(alpha: 0.65),
          disabledForegroundColor: colors.foreground.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            side: BorderSide(color: colors.border),
          ),
        ),
        child: child,
      ),
    );

    return button;
  }

  _ButtonColors _colors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.white,
          border: AppColors.primary,
        );
      case AppButtonVariant.secondary:
        return const _ButtonColors(
          background: AppColors.white,
          foreground: AppColors.primary,
          border: AppColors.primary,
        );
      case AppButtonVariant.danger:
        return const _ButtonColors(
          background: AppColors.danger,
          foreground: AppColors.white,
          border: AppColors.danger,
        );
      case AppButtonVariant.ghost:
        return const _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.textSecondary,
          border: Colors.transparent,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}