import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AdminDesign {
  AdminDesign._();
  static const double topBarHeight = 70;
  static const double topBarTitleSize = 30;
  static const double pageTitleSize = 42;
  static const double pageTitleMobileSize = 29;
  static const double pageDescriptionSize = 21;
  static const double filterHeight = 54;
  static const double filterTextSize = 21;
  static const double filterHintSize = 16;
  static const double filterRadius = 13;
  static const double tableHeaderHeight = 52;
  static const double tableRowMinHeight = 72;
  static const double tableRowMaxHeight = 82;
  static const double tableHorizontalMargin = 20;
  static const double tableColumnSpacing = 28;
  static const double tableHeaderTextSize = 16;
  static const double tablePrimaryTextSize = 22.5;
  static const double tableSecondaryTextSize = 18;
  static TextStyle text({required double figmaSize, FontWeight weight=FontWeight.w400, Color color=AppColors.navy, double? height, double? letterSpacing}) => AppTextStyles.of(figmaSize: figmaSize, weight: weight, color: color, height: height, letterSpacing: letterSpacing);
  static TextStyle display({required double figmaSize, FontWeight weight=FontWeight.w800, Color color=AppColors.navy, double? height, double? letterSpacing}) => AppTextStyles.of(figmaSize: figmaSize, weight: weight, color: color, height: height, letterSpacing: letterSpacing);
  static TextStyle pageTitle({Color color=AppColors.navy}) => text(figmaSize: pageTitleSize, weight: FontWeight.w800, color: color);
  static TextStyle pageDescription({Color color=Colors.grey}) => text(figmaSize: pageDescriptionSize, weight: FontWeight.w400, color: color);
  static TextStyle filterText({Color color=AppColors.navy}) => text(figmaSize: filterTextSize, color: color);
  static TextStyle filterHint({Color color=Colors.grey}) => text(figmaSize: filterHintSize, color: color);
  static TextStyle tableHeader({Color color=Colors.grey}) => text(figmaSize: tableHeaderTextSize, weight: FontWeight.w700, color: color);
  static TextStyle tablePrimary({Color color=AppColors.navy, FontWeight weight=FontWeight.w600}) => text(figmaSize: tablePrimaryTextSize, weight: weight, color: color);
  static TextStyle tableSecondary({Color color=Colors.grey}) => text(figmaSize: tableSecondaryTextSize, color: color);
}
