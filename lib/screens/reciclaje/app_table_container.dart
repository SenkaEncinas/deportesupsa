import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTableContainer extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final String? emptyMessage;

  const AppTableContainer({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyMessage,
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
            headingTextStyle: AppTextStyles.tableHeader,
            dataTextStyle: AppTextStyles.tableCell,
            columns: headers
                .map(
                  (header) => DataColumn(
                    label: Text(header),
                  ),
                )
                .toList(),
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: row
                        .map(
                          (cell) => DataCell(cell),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}