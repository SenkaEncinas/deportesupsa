import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';
import 'responsive.dart';

class AppPage extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool centerContent;
  final EdgeInsetsGeometry? padding;

  const AppPage({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.centerContent = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final pagePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 24,
        );

    final content = Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || subtitle != null || actions.isNotEmpty) ...[
            _Header(title: title, subtitle: subtitle, actions: actions),
            const SizedBox(height: 22),
          ],
          child,
        ],
      ),
    );

    if (!centerContent) return content;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
        child: content,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> actions;

  const _Header({this.title, this.subtitle, required this.actions});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final titleWidget = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) Text(title!, style: AppTextStyles.heading2),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [titleWidget]),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        titleWidget,
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 16),
          // Wrap necesita un ancho acotado para poder pasar los botones a
          // una segunda línea; sin Flexible, Row le da ancho ilimitado y
          // termina empujando el título a un ancho casi nulo (el texto se
          // parte letra por letra) cuando hay muchos botones de acción.
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ),
        ],
      ],
    );
  }
}
