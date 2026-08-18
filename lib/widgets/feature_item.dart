import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A single "Free Delivery / Free Installation / Service & Maintenance"
/// item: circular icon badge above a two-line centered label.
///
/// Sizes to whatever width its parent gives it (wrap call sites in
/// [Expanded]/[Flexible]) rather than forcing a fixed label width, so it
/// never overflows a tight Row.
class FeatureItem extends StatelessWidget {
  const FeatureItem({
    super.key,
    required this.icon,
    required this.label,
    this.figmaLabelSize = 15,
    this.badgeSize = 40,
    this.iconSize = 20,
    this.labelWeight = FontWeight.w700,
    this.maxLines = 2,
  });

  final IconData icon;
  final String label;
  final double figmaLabelSize;
  final double badgeSize;
  final double iconSize;
  final FontWeight labelWeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: const BoxDecoration(
            color: AppColors.bgCardPurple,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: iconSize, color: AppColors.purple),
        ),
        SizedBox(height: badgeSize * 0.14),
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: figmaLabelSize,
              weight: labelWeight,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped bordered container that hosts three [FeatureItem]s (splash),
/// each given an equal, bounded share of the row so labels wrap instead of
/// overflowing.
class FeatureRow extends StatelessWidget {
  const FeatureRow({super.key, required this.items});

  final List<FeatureItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTextStyles.fig(18),
        horizontal: AppTextStyles.fig(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppTextStyles.fig(35)),
      ),
      child: Row(children: items.map((item) => Expanded(child: item)).toList()),
    );
  }
}
