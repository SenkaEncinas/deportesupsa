import 'package:flutter/material.dart';

import 'responsive.dart';

class AppResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 14,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.isMobile(context)
            ? (mobileColumns ?? 1)
            : Responsive.isTablet(context)
                ? (tabletColumns ?? 2)
                : (desktopColumns ?? 3);

        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}