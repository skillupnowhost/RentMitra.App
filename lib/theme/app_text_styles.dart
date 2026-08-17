import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography on Inter (confirmed via the Figma text node `fontFamily`),
/// with weights/colors matching the extracted node styles.
///
/// Figma sizes were authored on a 592px-wide board (screenshot-derived, not
/// a device-point frame); the iOS "9:41" status bar glyph in that board is
/// 22px, and the real iOS status bar clock is 15pt, giving a board->logical
/// factor of ~1.5. [fig] applies that conversion so call sites can pass the
/// Figma font-size directly.
class AppTextStyles {
  AppTextStyles._();

  static double fig(double figmaPx) => figmaPx / 1.5;

  static TextStyle of({
    required double figmaSize,
    required FontWeight weight,
    Color color = AppColors.navy,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fig(figmaSize),
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Cinematic display face (Sora) reserved for splash/onboarding headlines —
  /// a geometric, futuristic counterpoint to the Inter body copy used
  /// everywhere else, per the brand's "premium onboarding" treatment.
  static TextStyle display({
    required double figmaSize,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.navy,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.sora(
      fontSize: fig(figmaSize),
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }
}
