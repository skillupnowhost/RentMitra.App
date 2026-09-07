import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Full "rentmitra.app" lockup (mark + wordmark), rendered directly from the
/// exported logo image everywhere the brand appears — app bar, drawer,
/// onboarding, splash — instead of laying out the icon and text as separate
/// widgets. The two used to need pixel-fussy alignment tweaks to sit level
/// with each other (an image's box is its tight ink bounds, a same-height
/// [Text] widget's box is the font's looser line-height) that drifted out of
/// sync across contexts; one image sidesteps that entirely.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.figmaWidth = 340});

  /// Rendered width, in Figma px (converted via [AppTextStyles.fig]).
  final double figmaWidth;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_full.png',
      width: AppTextStyles.fig(figmaWidth),
      fit: BoxFit.contain,
    );
  }
}
