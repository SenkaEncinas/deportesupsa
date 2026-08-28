import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTableContainer extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final String? emptyMessage;

  /// Versión más densa (menos espacio entre columnas, texto más chico):
  /// para tablas con muchas columnas (ej. tabla de posiciones) que
  /// necesitan entrar sin scroll horizontal en anchos típicos de
  /// tablet/desktop.
  final bool compact;

  const AppTableContainer({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyMessage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              emptyMessage ?? 'No hay datos disponibles.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceSoft),
            dividerThickness: 1,
            columnSpacing: compact ? 16 : 56,
            horizontalMargin: compact ? 12 : 24,
            headingRowHeight: compact ? 38 : 56,
            dataRowMinHeight: compact ? 36 : 48,
            dataRowMaxHeight: compact ? 40 : 56,
            headingTextStyle: compact
                ? AppTextStyles.tableHeader.copyWith(fontSize: 12)
                : AppTextStyles.tableHeader,
            dataTextStyle: compact
                ? AppTextStyles.tableCell.copyWith(fontSize: 12)
                : AppTextStyles.tableCell,
            columns: headers
                .map((header) => DataColumn(label: Text(header)))
                .toList(),
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: row.map((cell) => DataCell(cell)).toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
