import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One selectable spec row under a [ProductOptionCard]'s checklist, e.g.
/// "Cooling Capacity — 1 Ton". Only the AC page uses these in the
/// reference; other pages pass an empty [specs] list and the divider/row
/// is skipped entirely.
class ProductSpec {
  const ProductSpec({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

/// The big selectable plan card on a product listing page: badge, product
/// art, checklist, optional spec row, price and a "Continue" button.
class ProductOptionCard extends StatelessWidget {
  const ProductOptionCard({
    super.key,
    required this.badge,
    required this.title,
    required this.checklist,
    required this.art,
    required this.price,
    this.specs = const [],
    this.badgeColor = AppColors.purple,
    this.onContinue,
  });

  final String badge;
  final String title;
  final List<String> checklist;
  final Widget art;
  final String price;
  final List<ProductSpec> specs;
  final Color badgeColor;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
              SizedBox(
                width: AppTextStyles.fig(120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTextStyles.fig(10),
                        vertical: AppTextStyles.fig(5),
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.of(
                          figmaSize: 11,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: AppTextStyles.fig(12)),
                    Center(child: art),
                  ],
                ),
              ),
              SizedBox(width: AppTextStyles.fig(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.of(
                        figmaSize: 16,
                        weight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: AppTextStyles.fig(10)),
                    ...checklist.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: AppTextStyles.fig(7)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 13,
                              color: AppColors.check,
                            ),
                            SizedBox(width: AppTextStyles.fig(7)),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTextStyles.of(
                                  figmaSize: 11,
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
            ],
          ),
          if (specs.isNotEmpty) ...[
            SizedBox(height: AppTextStyles.fig(14)),
            Divider(height: 1, color: AppColors.divider),
            SizedBox(height: AppTextStyles.fig(14)),
            Row(
              children: specs
                  .map(
                    (s) => Expanded(
                      child: Row(
                        children: [
                          Icon(s.icon, size: 16, color: AppColors.purple),
                          SizedBox(width: AppTextStyles.fig(8)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.of(
                                    figmaSize: 10,
                                    weight: FontWeight.w400,
                                    color: AppColors.textGraySoft,
                                  ),
                                ),
                                Text(
                                  s.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.of(
                                    figmaSize: 13,
                                    weight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: AppTextStyles.fig(16)),
          Divider(height: 1, color: AppColors.divider),
          SizedBox(height: AppTextStyles.fig(14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Starting at',
                      style: AppTextStyles.of(
                        figmaSize: 11,
                        weight: FontWeight.w300,
                        color: AppColors.textGraySoft,
                      ),
                    ),
                    SizedBox(height: AppTextStyles.fig(2)),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: AppTextStyles.of(
                              figmaSize: 22,
                              weight: FontWeight.w700,
                              color: AppColors.purple,
                            ),
                          ),
                          TextSpan(
                            text: '/month',
                            style: AppTextStyles.of(
                              figmaSize: 13,
                              weight: FontWeight.w400,
                              color: AppColors.textGrayMed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+ GST',
                      style: AppTextStyles.of(
                        figmaSize: 11,
                        weight: FontWeight.w400,
                        color: AppColors.textGraySoft,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onContinue,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTextStyles.fig(22),
                    vertical: AppTextStyles.fig(13),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ctaPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style: AppTextStyles.of(
                          figmaSize: 14,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: AppTextStyles.fig(6)),
                      const Icon(
                        Icons.arrow_forward,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
