import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/feature_strip.dart';
import '../widgets/help_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/location_selector.dart';
import '../widgets/product_option_card.dart';

typedef ProductFeature = (IconData icon, String label);

/// Shared scaffold for the AC / Refrigerator / Washing Machine / Combo
/// listing pages: back header, hero panel, a 4-badge feature row, the
/// selectable [ProductOptionCard]s, a service-coverage banner and the
/// feature strip — reused as-is across all four pages since the
/// reference screenshots for AC and Refrigerator are structurally
/// identical, differing only in copy, art and pricing.
class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({
    super.key,
    required this.title,
    required this.description,
    required this.heroArt,
    required this.badgeFeatures,
    required this.sectionTitle,
    required this.options,
    required this.footerText,
    required this.footerImage,
    this.footerImageWidth = 170,
    this.footerImageHeight = 115,
    this.footerImageBleedRight = 0,
    this.heroBlobImage,
    this.trailingSection,
  });

  final String title;
  final String description;
  final Widget heroArt;
  final List<ProductFeature> badgeFeatures;
  final String sectionTitle;
  final List<ProductOptionCard> options;
  final String footerText;
  final String footerImage;

  /// Size of [footerImage] in the service-coverage banner. Defaults match
  /// the AC/Washer/Combo art; Fridge passes smaller values.
  final double footerImageWidth;
  final double footerImageHeight;

  /// Extra rightward push (in figma px) for [footerImage], shifting it past
  /// the banner's normal right inset so it sits flush against — or slightly
  /// over — the card's right edge instead of matching the AC/Fridge/Combo
  /// inset. Defaults to 0 (no change); Washer passes a positive value.
  final double footerImageBleedRight;
  /// Optional Figma "background shape" blob to draw behind [heroArt]
  /// instead of the default pair of plain translucent circles. Opt-in per
  /// screen so existing pages keep their current look unless they pass this.
  final String? heroBlobImage;

  /// Optional extra content rendered after the option cards and before the
  /// service-coverage banner — e.g. Combo's "Compare Combo Plans" table.
  /// Null (the default) renders nothing extra, so AC/Fridge/Washer are
  /// unaffected.
  final Widget? trailingSection;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                _Header(title: title),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(12),
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroPanel(
                              title: title,
                              description: description,
                              art: heroArt,
                              blobImage: heroBlobImage,
                            )
                            .animate()
                            .fadeIn(duration: 420.ms)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              duration: 420.ms,
                              curve: Curves.easeOut,
                            ),
                        SizedBox(height: AppTextStyles.fig(14)),
                        _FeatureBadgeRow(features: badgeFeatures)
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 380.ms)
                            .slideY(
                              begin: 0.12,
                              end: 0,
                              delay: 100.ms,
                              duration: 380.ms,
                              curve: Curves.easeOut,
                            ),
                        SizedBox(height: AppTextStyles.fig(24)),
                        _SectionHeading(title: sectionTitle)
                            .animate()
                            .fadeIn(delay: 160.ms, duration: 380.ms),
                        SizedBox(height: AppTextStyles.fig(16)),
                        for (final (i, option) in options.indexed) ...[
                          option
                              .animate()
                              .fadeIn(
                                delay: (220 + i * 90).ms,
                                duration: 380.ms,
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                delay: (220 + i * 90).ms,
                                duration: 380.ms,
                                curve: Curves.easeOut,
                              ),
                          if (i != options.length - 1)
                            SizedBox(height: AppTextStyles.fig(16)),
                        ],
                        if (trailingSection != null) ...[
                          SizedBox(height: AppTextStyles.fig(20)),
                          trailingSection!.animate().fadeIn(
                            delay: 340.ms,
                            duration: 380.ms,
                          ),
                        ],
                        SizedBox(height: AppTextStyles.fig(8)),
                        _ServiceBanner(
                              text: footerText,
                              image: footerImage,
                              imageWidth: footerImageWidth,
                              imageHeight: footerImageHeight,
                              imageBleedRight: footerImageBleedRight,
                            )
                            .animate()
                            .fadeIn(delay: 380.ms, duration: 380.ms),
                        SizedBox(height: AppTextStyles.fig(20)),
                        const FeatureStrip().animate().fadeIn(
                          delay: 440.ms,
                          duration: 380.ms,
                        ),
                        SizedBox(height: AppTextStyles.fig(20)),
                        HelpCard(
                          onWhatsApp: launchSupportWhatsAppChat,
                        ).animate().fadeIn(delay: 500.ms, duration: 380.ms),
                      ],
                    ),
                  ),
                ),
                AppBottomNavBar(
                  currentIndex: 0,
                  onTap: (i) {
                    if (i == 0) {
                      context.go('/home');
                    } else if (i == 1) {
                      context.go('/my-rentals');
                    } else {
                      context.go('/profile');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(16),
        AppTextStyles.fig(14),
        AppTextStyles.fig(16),
        AppTextStyles.fig(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.navy,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              title.replaceAll('\n', ' '),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.of(
                figmaSize: 17,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          ValueListenableBuilder<String>(
            valueListenable: LocationController.instance.city,
            builder: (context, city, _) {
              return ValueListenableBuilder<LocationStatus>(
                valueListenable: LocationController.instance.status,
                builder: (context, status, _) {
                  return LocationSelector(
                    city: city,
                    status: status,
                    onTap: () => LocationPickerSheet.show(context),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.description,
    required this.art,
    this.blobImage,
  });
  final String title;
  final String description;
  final Widget art;
  final String? blobImage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(AppTextStyles.fig(20)),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.heroBanner,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (blobImage == null) ...[
              Positioned(
                right: AppTextStyles.fig(-70),
                top: AppTextStyles.fig(-70),
                child:
                    Container(
                          width: AppTextStyles.fig(320),
                          height: AppTextStyles.fig(320),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 1,
                          end: 1.06,
                          duration: 2600.ms,
                          curve: Curves.easeInOut,
                        )
                        .fade(
                          begin: 0.75,
                          end: 1,
                          duration: 2600.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
              Positioned(
                right: AppTextStyles.fig(10),
                top: AppTextStyles.fig(30),
                child:
                    Container(
                          width: AppTextStyles.fig(140),
                          height: AppTextStyles.fig(140),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 1.05,
                          end: 1,
                          duration: 3200.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.of(
                          figmaSize: 26,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(10)),
                      Text(
                        description,
                        style: AppTextStyles.of(
                          figmaSize: 13,
                          weight: FontWeight.w400,
                          color: AppColors.textGray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppTextStyles.fig(12)),
                // Same background-shape treatment as the option cards below —
                // a shape sized and nudged relative to the product photo
                // itself, not anchored to the panel's outer corner.
                if (blobImage != null)
                  SizedBox(
                    height: AppTextStyles.fig(146),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: const Alignment(-0.2, 0.35),
                          child: Opacity(
                            opacity: 0.65,
                            child: Image.asset(
                              blobImage!,
                              width: AppTextStyles.fig(220),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Soft grounding shadow under the hero product photo,
                        // per the Figma reference — same treatment as the
                        // option cards below.
                        Positioned(
                          bottom: AppTextStyles.fig(2),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 3),
                            child: Container(
                              width: AppTextStyles.fig(66),
                              height: AppTextStyles.fig(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        art,
                      ],
                    ),
                  )
                else
                  art,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBadgeRow extends StatelessWidget {
  const _FeatureBadgeRow({required this.features});
  final List<ProductFeature> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTextStyles.fig(14),
        horizontal: AppTextStyles.fig(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < features.length; i++) ...[
              if (i != 0)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTextStyles.fig(6),
                    vertical: AppTextStyles.fig(4),
                  ),
                  child: Container(width: 1, color: AppColors.divider),
                ),
              Expanded(
                child: _FeatureBadgeItem(
                  icon: features[i].$1,
                  label: features[i].$2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureBadgeItem extends StatelessWidget {
  const _FeatureBadgeItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppTextStyles.fig(36),
          height: AppTextStyles.fig(36),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple, AppColors.ctaPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        SizedBox(width: AppTextStyles.fig(7)),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            style: AppTextStyles.of(
              figmaSize: 10.5,
              weight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.of(
            figmaSize: 19,
            weight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        SizedBox(height: AppTextStyles.fig(6)),
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 14,
              color: AppColors.checkGreen,
            ),
            SizedBox(width: AppTextStyles.fig(5)),
            Text(
              'Free Installation',
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w700,
                color: AppColors.textGray,
              ),
            ),
            SizedBox(width: AppTextStyles.fig(6)),
            Text(
              '|',
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w400,
                color: AppColors.divider,
              ),
            ),
            SizedBox(width: AppTextStyles.fig(6)),
            Expanded(
              child: Text(
                'Maintenance & Service Included',
                style: AppTextStyles.of(
                  figmaSize: 12,
                  weight: FontWeight.w400,
                  color: AppColors.textGraySoft,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceBanner extends StatelessWidget {
  const _ServiceBanner({
    required this.text,
    required this.image,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageBleedRight,
  });
  final String text;
  final String image;
  final double imageWidth;
  final double imageHeight;
  final double imageBleedRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(18),
        AppTextStyles.fig(10),
        AppTextStyles.fig(18),
        AppTextStyles.fig(18),
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppTextStyles.fig(48),
                height: AppTextStyles.fig(48),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppColors.purple,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: AppTextStyles.fig(14)),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: AppTextStyles.of(
                    figmaSize: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textGray,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppTextStyles.fig(8)),
            Transform.translate(
              offset: Offset(AppTextStyles.fig(imageBleedRight), 0),
              child: Image.asset(
                image,
                width: AppTextStyles.fig(imageWidth),
                height: AppTextStyles.fig(imageHeight),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
