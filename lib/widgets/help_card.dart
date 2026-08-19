import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HelpCard extends StatelessWidget {
  const HelpCard({super.key, this.onWhatsApp});

  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.helpCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgCardPurple,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/Need help.png',
              width: 16,
              height: 16,
              color: AppColors.purple,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Need Help?',
                  style: AppTextStyles.of(
                    figmaSize: 13,
                    weight: FontWeight.w700,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Our team is here to assist you.',
                  style: AppTextStyles.of(
                    figmaSize: 10,
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
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    width: 17,
                    height: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'WhatsApp Us',
                    style: AppTextStyles.of(
                      figmaSize: 12,
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
