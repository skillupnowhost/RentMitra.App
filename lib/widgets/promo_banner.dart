import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, this.onViewCombos});

  final VoidCallback? onViewCombos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(16)),
      decoration: BoxDecoration(
        color: AppColors.promoCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppTextStyles.fig(64),
            height: AppTextStyles.fig(64),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/promo_badge.png',
                  fit: BoxFit.contain,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '10%',
                      style: AppTextStyles.of(
                        figmaSize: 17,
                        weight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'OFF',
                      style: AppTextStyles.of(
                        figmaSize: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppTextStyles.fig(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save 10% on Appliance Combos',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(4)),
                Text(
                  'Starting at ₹1,887/month',
                  style: AppTextStyles.of(
                    figmaSize: 12,
                    weight: FontWeight.w400,
                    color: AppColors.textGrayMed,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppTextStyles.fig(10)),
          GestureDetector(
            onTap: onViewCombos,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTextStyles.fig(16),
                vertical: AppTextStyles.fig(10),
              ),
              decoration: BoxDecoration(
                color: AppColors.ctaPurple,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Combos',
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppTextStyles.fig(4)),
                  const Icon(
                    Icons.arrow_forward,
                    size: 13,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
