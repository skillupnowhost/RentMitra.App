import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HelpCard extends StatelessWidget {
  const HelpCard({super.key, this.onWhatsApp});

  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(18)),
      decoration: BoxDecoration(
        color: AppColors.helpCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: AppTextStyles.fig(42),
            height: AppTextStyles.fig(42),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgCardPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          SizedBox(width: AppTextStyles.fig(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Need Help?',
                  style: AppTextStyles.of(
                    figmaSize: 15,
                    weight: FontWeight.w700,
                    color: AppColors.textGray,
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(4)),
                Text(
                  'Our team is here to assist you.',
                  style: AppTextStyles.of(
                    figmaSize: 9,
                    weight: FontWeight.w400,
                    color: AppColors.textGrayMed,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onWhatsApp,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTextStyles.fig(16),
                vertical: AppTextStyles.fig(11),
              ),
              decoration: BoxDecoration(
                color: AppColors.ctaPurple,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WhatsApp Us',
                    style: AppTextStyles.of(
                      figmaSize: 14,
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
