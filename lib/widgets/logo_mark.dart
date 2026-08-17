import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The real "RM" logo mark exported from the Figma file (arc swoosh + R/M
/// monogram), used at every size instead of a hand-drawn approximation.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.width = 64});

  final double width;

  @override
  Widget build(BuildContext context) {
    // Native asset is 473x356 (ratio ~1.328 : 1).
    return Image.asset(
      'assets/images/logo_mark.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}

/// Full wordmark: logo mark + "Rent" (navy) + "Mitra" (purple) + optional
/// ".app" pill badge and "RENT MADE EASY" tagline.
///
/// Sizes are Figma px converted via [AppTextStyles.fig]; [figmaWordmarkSize]
/// is the splash value (78/75px) by default — pass the app-bar value (27px)
/// for the compact header usage.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.figmaWordmarkSize = 78,
    this.figmaLogoWidth = 197,
    this.showTagline = true,
    this.showAppBadge = true,
  });

  final double figmaWordmarkSize;
  final double figmaLogoWidth;
  final bool showTagline;
  final bool showAppBadge;

  @override
  Widget build(BuildContext context) {
    final logoWidth = AppTextStyles.fig(figmaLogoWidth);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LogoMark(width: logoWidth),
            SizedBox(width: logoWidth * 0.08),
            Text(
              'Rent',
              style: AppTextStyles.of(
                figmaSize: figmaWordmarkSize,
                weight: FontWeight.w700,
                color: AppColors.navyDeep,
              ),
            ),
            Text(
              'Mitra',
              style: AppTextStyles.of(
                figmaSize: figmaWordmarkSize * 0.96,
                weight: FontWeight.w700,
                color: AppColors.purple,
              ),
            ),
            if (showAppBadge) ...[
              SizedBox(width: logoWidth * 0.03),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTextStyles.fig(figmaWordmarkSize * 0.22),
                  vertical: AppTextStyles.fig(figmaWordmarkSize * 0.09),
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '.app',
                  style: AppTextStyles.of(
                    figmaSize: figmaWordmarkSize * 0.28,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: AppTextStyles.fig(figmaWordmarkSize * 0.13)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dash(figmaWordmarkSize),
              SizedBox(width: AppTextStyles.fig(figmaWordmarkSize * 0.13)),
              Text(
                'RENT MADE EASY',
                style: AppTextStyles.of(
                  figmaSize: figmaWordmarkSize * 0.27,
                  weight: FontWeight.w600,
                  color: AppColors.textGrayMed,
                  letterSpacing: 2.6,
                ),
              ),
              SizedBox(width: AppTextStyles.fig(figmaWordmarkSize * 0.13)),
              _dash(figmaWordmarkSize),
            ],
          ),
        ],
      ],
    );
  }

  Widget _dash(double figmaWordmarkSize) {
    return Container(
      width: AppTextStyles.fig(figmaWordmarkSize * 0.6),
      height: 1.2,
      color: AppColors.purple.withValues(alpha: 0.55),
    );
  }
}
