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
      padding: EdgeInsets.only(
        top: AppTextStyles.fig(14),
        bottom: AppTextStyles.fig(10),
      ),
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
                    size: AppTextStyles.fig(28),
                    color: active ? AppColors.purple : AppColors.textGraySoft,
                  ),
                  SizedBox(height: AppTextStyles.fig(4)),
                  Text(
                    label,
                    style: AppTextStyles.of(
                      figmaSize: 13,
                      weight: active ? FontWeight.w700 : FontWeight.w400,
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
