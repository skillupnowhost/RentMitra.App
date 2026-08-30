import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One selectable spec row under a [ProductOptionCard]'s checklist, e.g.
/// "Cooling Capacity — 1 Ton". Only the AC page uses these in the
/// reference; other pages pass an empty [specs] list and the divider/row
/// is skipped entirely.
class ProductSpec {
  const ProductSpec({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

/// The big selectable plan card on a product listing page: badge, product
/// art, checklist, optional spec row, price and a "Continue" button.
class ProductOptionCard extends StatelessWidget {
  const ProductOptionCard({
    super.key,
    required this.badge,
    required this.title,
    required this.checklist,
    required this.art,
    required this.price,
    this.specs = const [],
    this.artColumnWidth = 120,
    this.badgeColor = AppColors.purple,
    this.onContinue,
    this.originalPrice,
    this.discountBadge,
    this.ctaLabel = 'Continue',
  });

  final String badge;
  final String title;
  final List<String> checklist;
  final Widget art;
  final String price;
  final List<ProductSpec> specs;
  final double artColumnWidth;
  final Color badgeColor;
  final VoidCallback? onContinue;

  /// Pre-discount price shown struck through next to [price], e.g.
  /// "₹2,597". Null (the default) hides the strikethrough/discount pill —
  /// every existing caller (AC/Fridge/Washer) is unaffected.
  final String? originalPrice;

  /// Discount pill text next to [originalPrice], e.g. "10% OFF".
  final String? discountBadge;

  /// Continue-button label. Defaults to "Continue"; combos pass "Rent
  /// This Combo".
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    // The "Background shape.png" backdrop behind the product art, per the
    // Figma reference — shown at its native shape (no clipping), large
    // enough to peek out past the art on all sides.
    final blobSize = artColumnWidth * 1.15;

    // Section 1: badge + product art — shared by both layouts below.
    final artSection = SizedBox(
      width: AppTextStyles.fig(artColumnWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTextStyles.fig(10),
              vertical: AppTextStyles.fig(5),
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: AppTextStyles.of(
                figmaSize: 11,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: AppTextStyles.fig(10)),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // AC cards keep a plain product shot with no backdrop, per
                // the Figma reference — only fridge/washer/combo get the
                // decorative background shape.
                if (specs.isEmpty)
                  Image.asset(
                    'assets/images/Background shape.png',
                    width: AppTextStyles.fig(blobSize),
                    height: AppTextStyles.fig(blobSize),
                    fit: BoxFit.contain,
                  ),
                // The product photo, with a soft grounding shadow tucked
                // just beneath it. The shadow is positioned relative to the
                // art's own box (an inner Stack) rather than the larger
                // backdrop shape above — the art's rendered size varies
                // with each photo's aspect ratio, so anchoring to it
                // directly keeps the shadow close to the product for every
                // variant instead of drifting based on backdrop size.
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    art
                        .animate()
                        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.88, 0.88),
                          end: const Offset(1, 1),
                          duration: 380.ms,
                          curve: Curves.easeOut,
                        ),
                    if (specs.isEmpty)
                      Positioned(
                        bottom: -AppTextStyles.fig(8),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 2),
                          child: Container(
                            width: AppTextStyles.fig(artColumnWidth * 0.34),
                            height: AppTextStyles.fig(artColumnWidth * 0.07),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Title + checklist — shared by both layouts below.
    final titleAndChecklist = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.of(
            figmaSize: 16,
            weight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        SizedBox(height: AppTextStyles.fig(8)),
        ...checklist.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: AppTextStyles.fig(6)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 13, color: AppColors.check),
                SizedBox(width: AppTextStyles.fig(7)),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w400,
                      color: AppColors.textGrayMed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: specs.isNotEmpty
          // AC layout: the spec row (cooling capacity / power consumption)
          // needs the full card width to fit both specs + divider + price +
          // button, so it stays below the image+text row, edge to edge.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artSection,
                    SizedBox(width: AppTextStyles.fig(14)),
                    Expanded(child: titleAndChecklist),
                  ],
                ),
                SizedBox(height: AppTextStyles.fig(16)),
                Divider(height: 1, color: AppColors.divider),
                SizedBox(height: AppTextStyles.fig(14)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < specs.length; i++) ...[
                      if (i > 0) SizedBox(width: AppTextStyles.fig(14)),
                      _SpecItem(spec: specs[i]),
                    ],
                    SizedBox(width: AppTextStyles.fig(10)),
                    Container(
                      width: 1,
                      height: AppTextStyles.fig(36),
                      color: AppColors.divider,
                    ),
                    SizedBox(width: AppTextStyles.fig(10)),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _PriceBlock(
                              price: price,
                              priceSize: 18,
                              monthSize: 11,
                              metaSize: 9,
                              originalPrice: originalPrice,
                              discountBadge: discountBadge,
                            ),
                          ),
                          _ContinueButton(
                            onTap: onContinue,
                            label: ctaLabel,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          // Fridge / washing machine / combo layout: no specs row, so
          // everything but the image nests together in one right-hand
          // section — title, checklist, divider, price and Continue button.
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                artSection,
                SizedBox(width: AppTextStyles.fig(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleAndChecklist,
                      SizedBox(height: AppTextStyles.fig(8)),
                      Divider(height: 1, color: AppColors.divider),
                      SizedBox(height: AppTextStyles.fig(12)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _PriceBlock(
                              price: price,
                              originalPrice: originalPrice,
                              discountBadge: discountBadge,
                            ),
                          ),
                          _ContinueButton(onTap: onContinue, label: ctaLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// One icon + label/value pair in the spec row, e.g. the snowflake icon next
/// to "Cooling Capacity" / "1 Ton". The label column is a fixed width so
/// both specs wrap onto two lines the same way ("Cooling" / "Capacity",
/// "Power" / "Consumption") instead of one wrapping and the other not.
class _SpecItem extends StatelessWidget {
  const _SpecItem({required this.spec});

  final ProductSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(spec.icon, size: 18, color: AppColors.purple),
        SizedBox(width: AppTextStyles.fig(6)),
        SizedBox(
          width: AppTextStyles.fig(76),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spec.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 10,
                  weight: FontWeight.w400,
                  color: AppColors.textGraySoft,
                  height: 1.25,
                ),
              ),
              SizedBox(height: AppTextStyles.fig(3)),
              Text(
                spec.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 12,
                  weight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.price,
    this.priceSize = 22,
    this.monthSize = 13,
    this.metaSize = 11,
    this.originalPrice,
    this.discountBadge,
  });

  final String price;
  final double priceSize;
  final double monthSize;
  final double metaSize;
  final String? originalPrice;
  final String? discountBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (originalPrice != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                originalPrice!,
                style: AppTextStyles.of(
                  figmaSize: metaSize + 2,
                  weight: FontWeight.w500,
                  color: AppColors.textGraySoft,
                ).copyWith(decoration: TextDecoration.lineThrough),
              ),
              if (discountBadge != null) ...[
                SizedBox(width: AppTextStyles.fig(6)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTextStyles.fig(6),
                    vertical: AppTextStyles.fig(2),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.checkGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    discountBadge!,
                    style: AppTextStyles.of(
                      figmaSize: metaSize,
                      weight: FontWeight.w700,
                      color: AppColors.checkGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppTextStyles.fig(2)),
        ] else ...[
          Text(
            'Starting at',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: metaSize,
              weight: FontWeight.w300,
              color: AppColors.textGraySoft,
            ),
          ),
          SizedBox(height: AppTextStyles.fig(2)),
        ],
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: price,
                style: AppTextStyles.of(
                  figmaSize: priceSize,
                  weight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
              TextSpan(
                text: '/month',
                style: AppTextStyles.of(
                  figmaSize: monthSize,
                  weight: FontWeight.w400,
                  color: AppColors.textGrayMed,
                ),
              ),
            ],
          ),
        ),
        Text(
          '+ GST',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.of(
            figmaSize: metaSize,
            weight: FontWeight.w400,
            color: AppColors.textGraySoft,
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.onTap,
    this.compact = false,
    this.label = 'Continue',
  });

  final VoidCallback? onTap;
  final bool compact;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTextStyles.fig(compact ? 10 : 22),
          vertical: AppTextStyles.fig(compact ? 10 : 13),
        ),
        decoration: BoxDecoration(
          color: AppColors.ctaPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.of(
                figmaSize: compact ? 12 : 14,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: AppTextStyles.fig(5)),
            Icon(
              Icons.arrow_forward,
              size: compact ? 13 : 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
