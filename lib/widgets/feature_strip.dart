import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Four equal-width items — Free Delivery / Free Installation / Service &
/// Maintenance / Hassle-Free Cancellation — inside a single bordered strip
/// with thin vertical dividers between them, matching the Figma design
/// (one shared outline, not four separate shadow cards).
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
        vertical: AppTextStyles.fig(14),
        horizontal: AppTextStyles.fig(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i != 0)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTextStyles.fig(6),
                    vertical: AppTextStyles.fig(4),
                  ),
                  child: Container(width: 1, color: AppColors.divider),
                ),
              Expanded(
                child: _FeatureItem(icon: _items[i].$1, label: _items[i].$2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.purple),
        SizedBox(width: AppTextStyles.fig(10)),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.of(
              figmaSize: 10,
              weight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
