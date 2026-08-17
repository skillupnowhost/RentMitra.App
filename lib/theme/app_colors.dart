import 'package:flutter/material.dart';

/// Palette sampled directly from the Figma file (fills of the real text and
/// shape nodes), not eyeballed from the screenshot. Two shades of navy /
/// purple show up in the source (logo mark vs. body headline) — both are
/// kept since they read as intentional hierarchy, not drift.
class AppColors {
  AppColors._();

  static const Color navyDeep = Color(0xFF11115A);
  static const Color navy = Color(0xFF2A2A5E);
  static const Color purple = Color(0xFF6847EA);
  static const Color purpleSoft = Color(0xFF8B76C9);
  static const Color ctaPurple = Color(0xFF4205F7);

  static const Color textGray = Color(0xFF65657F);
  static const Color textGrayMed = Color(0xFF7C7C90);
  static const Color textGraySoft = Color(0xFF9A9AA8);

  static const Color pricePurple = Color(0xFF7B62C1);
  static const Color priceGreen = Color(0xFF639C75);
  static const Color priceOrange = Color(0xFFCB7660);

  static const Color titleBlue = Color(0xFF7693C3);
  static const Color titleGreen = Color(0xFF73A680);
  static const Color titleTerracotta = Color(0xFFD28A79);

  static const Color bgCardPurple = Color(0xFFF8F9FD);
  static const Color bgCardNeutral = Color(0xFFF8F8F7);
  static const Color bgCardPeach = Color(0xFFFDF8F6);
  static const Color bgCardLavender = Color(0xFFF7F7FC);

  static const Color background = Color(0xFFF7F6FC);
  static const Color surface = Colors.white;
  static const Color promoCardBg = Color(0xFFF7F6FB);
  static const Color helpCardBg = Color(0xFFF4F4FB);
  static const Color featureStripBg = Color(0xFFFDFDFC);
  static const Color divider = Color(0xFFEDEDF5);
  static const Color check = Color(0xFF63B37B);

  static const List<Color> splashBackground = [
    Color(0xFFFCFBFF),
    Color(0xFFF1EDFE),
    Color(0xFFE1D3F9),
  ];

  static const List<Color> heroBanner = [Color(0xFFF3F1FC), Color(0xFFEBE6FA)];
}
