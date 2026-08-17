import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FeatureStrip extends StatelessWidget {
  const FeatureStrip({super.key});

  static const _items = [
    (Icons.local_shipping_outlined, 'Free\nDelivery'),
    (Icons.build_outlined, 'Free\nInstallation'),
    (Icons.verified_user_outlined, 'Service &\nMaintenance'),
    (Icons.cancel_outlined, 'Hassle Free\nCancellation'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTextStyles.fig(20),
        horizontal: AppTextStyles.fig(8),
      ),
      decoration: BoxDecoration(
        color: AppColors.featureStripBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: List.generate(_items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return SizedBox(
              height: AppTextStyles.fig(21),
              child: VerticalDivider(
                color: AppColors.divider,
                thickness: 1,
                width: AppTextStyles.fig(20),
              ),
            );
          }
          final (icon, label) = _items[i ~/ 2];
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppTextStyles.fig(28),
                  color: AppColors.purple,
                ),
                SizedBox(height: AppTextStyles.fig(8)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.of(
                    figmaSize: 12,
                    weight: FontWeight.w700,
                    color: AppColors.textGrayMed,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
