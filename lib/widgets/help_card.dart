import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HelpCard extends StatelessWidget {
  const HelpCard({super.key, this.onWhatsApp});

  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.helpCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgCardPurple,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/Need help.png',
              width: 22,
              height: 22,
              color: AppColors.purple,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Need Help?',
                  style: AppTextStyles.of(
                    figmaSize: 17,
                    weight: FontWeight.w700,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our team is here to assist you.',
                  style: AppTextStyles.of(
                    figmaSize: 12,
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.ctaPurple],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ctaPurple.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/whatsapp icon.png',
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WhatsApp Us',
                    style: AppTextStyles.of(
                      figmaSize: 16,
                      weight: FontWeight.w500,
                      color: Colors.white,
                    ),
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
