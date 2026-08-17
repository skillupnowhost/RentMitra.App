import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One of the "Smart Inverter Split AC / Refrigerator / Washing Machine"
/// cards: pastel title, checklist, product photo, and a plain segmented
/// size/type label row (not an interactive filled toggle — the source file
/// renders both options in the same muted weight).
class ProductDetailCard extends StatelessWidget {
  const ProductDetailCard({
    super.key,
    required this.title,
    required this.titleColor,
    required this.checklist,
    required this.options,
    required this.art,
    this.onTap,
  });

  final String title;
  final Color titleColor;
  final List<String> checklist;
  final List<String> options;
  final Widget art;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(16),
        AppTextStyles.fig(16),
        AppTextStyles.fig(16),
        AppTextStyles.fig(14),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.of(
                        figmaSize: 14,
                        weight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: AppTextStyles.fig(14)),
                    ...checklist.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: AppTextStyles.fig(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: AppColors.check,
                            ),
                            SizedBox(width: AppTextStyles.fig(6)),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTextStyles.of(
                                  figmaSize: 9,
                                  weight: FontWeight.w400,
                                  color: AppColors.textGrayMed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppTextStyles.fig(10)),
              art,
            ],
          ),
          SizedBox(height: AppTextStyles.fig(20)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppTextStyles.fig(11),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        options[0],
                        style: AppTextStyles.of(
                          figmaSize: 11,
                          weight: FontWeight.w400,
                          color: AppColors.textGrayMed,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: AppTextStyles.fig(13),
                        color: AppColors.divider,
                      ),
                      Text(
                        options[1],
                        style: AppTextStyles.of(
                          figmaSize: 10,
                          weight: FontWeight.w400,
                          color: AppColors.textGrayMed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppTextStyles.fig(10)),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: AppTextStyles.fig(35),
                  height: AppTextStyles.fig(35),
                  decoration: BoxDecoration(
                    color: titleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right, color: titleColor, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
