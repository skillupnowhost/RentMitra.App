import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.price,
    required this.iconColor,
    required this.priceColor,
    required this.bgColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String price;
  final Color iconColor;
  final Color priceColor;
  final Color bgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppTextStyles.fig(16),
          horizontal: AppTextStyles.fig(10),
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: AppTextStyles.fig(28)),
            SizedBox(height: AppTextStyles.fig(10)),
            Text(
              title,
              maxLines: 2,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w400,
                color: AppColors.textGrayMed,
              ),
            ),
            SizedBox(height: AppTextStyles.fig(14)),
            Text(
              'Starting at',
              style: AppTextStyles.of(
                figmaSize: 9,
                weight: FontWeight.w300,
                color: AppColors.textGraySoft,
              ),
            ),
            SizedBox(height: AppTextStyles.fig(4)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: AppTextStyles.of(
                      figmaSize: 19,
                      weight: FontWeight.w500,
                      color: priceColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '/month',
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w400,
                      color: priceColor.withValues(alpha: 0.75),
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
    );
  }
}
