import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'reveal_text.dart';

/// Data for one animated feature badge — mirrors [FeatureItem] but scoped to
/// this file since only the splash carousel needs the perpetual pulse/float
/// micro-interaction (the shared `FeatureItem` also renders on Home /
/// product screens, where a constantly-pulsing icon would be noise).
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
/// [FadeSlideIn] when [active] and idling with a soft pulse + glow.
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
                child: _AnimatedFeatureItem(
                  data: items[i],
                  pulseDelay: Duration(milliseconds: 260 * i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedFeatureItem extends StatefulWidget {
  const _AnimatedFeatureItem({
    required this.data,
    this.pulseDelay = Duration.zero,
  });

  final AnimatedFeatureData data;
  final Duration pulseDelay;

  @override
  State<_AnimatedFeatureItem> createState() => _AnimatedFeatureItemState();
}

class _AnimatedFeatureItemState extends State<_AnimatedFeatureItem>
    with SingleTickerProviderStateMixin {
  // Starts partway through its cycle (rather than delaying the start) so
  // badges settle into a staggered pulse without needing a Timer.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
    value: (widget.pulseDelay.inMilliseconds % 2200) / 2200,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: curved,
          builder: (context, child) {
            final scale = 1.0 + curved.value * 0.1;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgCardPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(
                        alpha: 0.18 * curved.value,
                      ),
                      blurRadius: 10 + 8 * curved.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  widget.data.icon,
                  size: 20,
                  color: AppColors.purple,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 40 * 0.14),
        SizedBox(
          width: double.infinity,
          child: Text(
            widget.data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: widget.data.figmaLabelSize,
              weight: widget.data.labelWeight,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }
}
