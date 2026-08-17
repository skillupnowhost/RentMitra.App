import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'reveal_text.dart';

/// Data for one animated feature badge — mirrors [FeatureItem] but scoped to
/// this file since only the splash carousel needs the staggered entrance
/// treatment (the shared `FeatureItem` also renders on Home / product
/// screens, which don't replay an entrance).
class AnimatedFeatureData {
  const AnimatedFeatureData({
    required this.icon,
    required this.label,
    this.labelWeight = FontWeight.w700,
    this.figmaLabelSize = 13,
  });

  final IconData icon;
  final String label;
  final FontWeight labelWeight;
  final double figmaLabelSize;
}

/// Pill-shaped row of [AnimatedFeatureData] badges, each staggering in via
/// [FadeSlideIn] when [active].
class AnimatedFeatureRow extends StatelessWidget {
  const AnimatedFeatureRow({
    super.key,
    required this.items,
    required this.active,
  });

  final List<AnimatedFeatureData> items;
  final bool active;

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
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: FadeSlideIn(
                active: active,
                delay: Duration(milliseconds: 90 * i),
                child: _AnimatedFeatureItem(data: items[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedFeatureItem extends StatelessWidget {
  const _AnimatedFeatureItem({required this.data});

  final AnimatedFeatureData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.bgCardPurple,
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, size: 20, color: AppColors.purple),
        ),
        SizedBox(height: 40 * 0.14),
        SizedBox(
          width: double.infinity,
          child: Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: data.figmaLabelSize,
              weight: data.labelWeight,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }
}
