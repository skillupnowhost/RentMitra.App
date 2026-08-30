import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One metric row in a [ComboComparisonTable], e.g. ("AC Capacity", ["1
/// Ton", "1 Ton", "1.5 Ton", "1.5 Ton"]) — [values] must be in the same
/// order as the table's `headers`.
class ComboComparisonRow {
  const ComboComparisonRow({required this.label, required this.values});
  final String label;
  final List<String> values;
}

/// The Combo Plans page's "Compare Combo Plans" section — a compact,
/// horizontally-scrollable spec table so a user can see all 4 combos'
/// AC/fridge/washer capacity, rental and discount at a glance without
/// re-reading every card above.
class ComboComparisonTable extends StatelessWidget {
  const ComboComparisonTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<ComboComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare Combo Plans',
            style: AppTextStyles.of(
              figmaSize: 17,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: AppTextStyles.fig(4)),
          Text(
            'See how each combo stacks up at a glance',
            style: AppTextStyles.of(
              figmaSize: 11,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
          SizedBox(height: AppTextStyles.fig(14)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: FixedColumnWidth(AppTextStyles.fig(92)),
                for (var i = 0; i < headers.length; i++)
                  i + 1: FixedColumnWidth(AppTextStyles.fig(108)),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: 1.5),
                    ),
                  ),
                  children: [
                    _cell(''),
                    for (final h in headers) _cell(h, header: true),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    children: [
                      _cell(row.label, isLabel: true),
                      for (final v in row.values) _cell(v),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool header = false, bool isLabel = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppTextStyles.fig(10),
        horizontal: AppTextStyles.fig(6),
      ),
      child: Text(
        text,
        textAlign: isLabel ? TextAlign.left : TextAlign.center,
        maxLines: 2,
        style: AppTextStyles.of(
          figmaSize: 11,
          weight: header || isLabel ? FontWeight.w700 : FontWeight.w500,
          color: header
              ? AppColors.purple
              : (isLabel ? AppColors.navy : AppColors.textGrayMed),
        ),
      ),
    );
  }
}
