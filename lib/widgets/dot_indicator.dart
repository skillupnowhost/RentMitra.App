import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DotIndicator extends StatelessWidget {
  const DotIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeColor = AppColors.purple,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? activeColor : activeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
