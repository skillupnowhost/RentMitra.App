import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/feature_strip.dart';
import '../widgets/help_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/location_selector.dart';
import '../widgets/product_option_card.dart';

typedef ProductFeature = (IconData icon, String label);

/// Shared scaffold for the AC / Refrigerator / Washing Machine / Combo
/// listing pages: back header, hero panel, a 4-badge feature row, the
/// selectable [ProductOptionCard]s, a service-coverage banner, the feature
/// strip and help card — reused as-is across all four pages since the
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
  });

  final String title;
  final String description;
  final Widget heroArt;
  final List<ProductFeature> badgeFeatures;
  final String sectionTitle;
  final List<ProductOptionCard> options;
  final String footerText;

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
                        ),
                        SizedBox(height: AppTextStyles.fig(14)),
                        _FeatureBadgeRow(features: badgeFeatures),
                        SizedBox(height: AppTextStyles.fig(24)),
                        _SectionHeading(title: sectionTitle),
                        SizedBox(height: AppTextStyles.fig(16)),
                        for (final option in options) ...[
                          option,
                          SizedBox(height: AppTextStyles.fig(16)),
                        ],
                        SizedBox(height: AppTextStyles.fig(8)),
                        _ServiceBanner(text: footerText),
                        SizedBox(height: AppTextStyles.fig(20)),
                        const FeatureStrip(),
                        SizedBox(height: AppTextStyles.fig(18)),
                        HelpCard(onWhatsApp: () {}),
                      ],
                    ),
                  ),
                ),
                AppBottomNavBar(
                  currentIndex: 0,
                  onTap: (i) {
                    if (i == 0) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      final label = i == 1 ? 'My Rentals' : 'Profile';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label — coming soon')),
                      );
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
  });
  final String title;
  final String description;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroBanner,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
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
          art,
        ],
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
        vertical: AppTextStyles.fig(16),
        horizontal: AppTextStyles.fig(8),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: features.map((f) {
          final (icon, label) = f;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTextStyles.fig(40),
                  height: AppTextStyles.fig(40),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCardPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: AppColors.purple),
                ),
                SizedBox(height: AppTextStyles.fig(8)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.of(
                    figmaSize: 10,
                    weight: FontWeight.w600,
                    color: AppColors.textGrayMed,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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
            const Icon(Icons.check_circle, size: 14, color: AppColors.check),
            SizedBox(width: AppTextStyles.fig(5)),
            Text(
              'Free Installation',
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w600,
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
  const _ServiceBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(18)),
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
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
          SizedBox(width: AppTextStyles.fig(14)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w400,
                color: AppColors.textGray,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
