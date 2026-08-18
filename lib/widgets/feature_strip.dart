import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Four equal-width, equal-height cards — Free Delivery / Free Installation /
/// Service & Maintenance / Hassle-Free Cancellation — each its own white
/// rounded card with a soft shadow, rather than one bordered strip with
/// dividers, so they read as distinct feature highlights.
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i != 0) SizedBox(width: AppTextStyles.fig(8)),
            Expanded(child: _FeatureCard(icon: _items[i].$1, label: _items[i].$2)),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTextStyles.fig(14),
        horizontal: AppTextStyles.fig(6),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgCardPurple,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.purple),
          ),
          SizedBox(height: AppTextStyles.fig(8)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 13,
              weight: FontWeight.w600,
              color: AppColors.textGrayMed,
            ),
          ),
        ],
      ),
    );
  }
}
