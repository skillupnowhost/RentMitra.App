import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The large, centered "Need Help?" cover card — Home screen only, paired
/// with [PromoBanner] in an IntrinsicHeight + CrossAxisAlignment.stretch
/// row so both cards share one height and their buttons line up flush to
/// the bottom.
class HelpCardLarge extends StatelessWidget {
  const HelpCardLarge({super.key, this.onWhatsApp});

  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 215),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.helpCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.helpAccent,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/Need help.png',
              width: 20,
              height: 20,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Need Help?',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 15,
              weight: FontWeight.w700,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Our team is here to assist you.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 12,
              weight: FontWeight.w600,
              color: AppColors.textGrayMed,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onWhatsApp,
            child: Container(
              width: double.infinity,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.helpAccent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.helpAccent.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/whatsapp icon.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'WhatsApp Us',
                      style: AppTextStyles.of(
                        figmaSize: 12,
                        weight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward,
                      size: 13,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
