import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'My Rentals'),
    (Icons.person_rounded, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_tabs.length, (i) {
            final (filled, outline, label) = _tabs[i];
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? filled : outline,
                    size: 26,
                    color: active ? AppColors.purple : AppColors.textGraySoft,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: AppTextStyles.of(
                      figmaSize: 18,
                      weight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.purple : AppColors.textGraySoft,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
