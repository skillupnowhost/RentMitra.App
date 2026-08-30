import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/help_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/location_selector.dart';

/// The "Product Details" step of the continuous flow: Product Listing →
/// here → Rent Now → Checkout. Shows the full picture of the variant the
/// user tapped (already carried in [product]) with a single sticky "Rent
/// Now" CTA, instead of jumping straight from the listing card to checkout.
/// No [AppBottomNavBar] — this is a funnel step, matching the existing
/// Checkout/Payment screens, which also don't show it.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

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
                _Header(title: product.title),
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
                        _HeroPanel(product: product),
                        SizedBox(height: AppTextStyles.fig(20)),
                        Text(
                          "What's included",
                          style: AppTextStyles.of(
                            figmaSize: 17,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(10)),
                        if (product.applianceBreakdown.isNotEmpty)
                          ...product.applianceBreakdown.map(
                            (appliance) => _ApplianceBreakdownCard(
                              title: appliance.$1,
                              art: appliance.$2,
                              specs: appliance.$3,
                            ),
                          )
                        else
                          ...product.checklist.map(
                            (item) => Padding(
                              padding: EdgeInsets.only(
                                bottom: AppTextStyles.fig(9),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 15,
                                    color: AppColors.check,
                                  ),
                                  SizedBox(width: AppTextStyles.fig(8)),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: AppTextStyles.of(
                                        figmaSize: 13,
                                        weight: FontWeight.w400,
                                        color: AppColors.textGrayMed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (product.specs.isNotEmpty) ...[
                          SizedBox(height: AppTextStyles.fig(6)),
                          Container(
                            padding: EdgeInsets.all(AppTextStyles.fig(16)),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: product.specs
                                  .map(
                                    (s) => Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            s.icon,
                                            size: 16,
                                            color: AppColors.purple,
                                          ),
                                          SizedBox(width: AppTextStyles.fig(8)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  s.label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.of(
                                                    figmaSize: 10,
                                                    weight: FontWeight.w400,
                                                    color:
                                                        AppColors.textGraySoft,
                                                  ),
                                                ),
                                                Text(
                                                  s.value,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.of(
                                                    figmaSize: 13,
                                                    weight: FontWeight.w600,
                                                    color: AppColors.navy,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                        if (product.footerText != null) ...[
                          SizedBox(height: AppTextStyles.fig(20)),
                          Container(
                            padding: EdgeInsets.all(AppTextStyles.fig(16)),
                            decoration: BoxDecoration(
                              color: AppColors.bgCardPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  color: AppColors.purple,
                                  size: 22,
                                ),
                                SizedBox(width: AppTextStyles.fig(12)),
                                Expanded(
                                  child: Text(
                                    product.footerText!,
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
                          ),
                        ],
                        SizedBox(height: AppTextStyles.fig(20)),
                        HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                      ],
                    ),
                  ),
                ),
                _RentNowBar(product: product),
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
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.navy,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              'Product Details',
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
  const _HeroPanel({required this.product});
  final Product product;

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
            Positioned(
              right: AppTextStyles.fig(-30),
              top: AppTextStyles.fig(-30),
              child: Container(
                width: AppTextStyles.fig(180),
                height: AppTextStyles.fig(180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
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
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.badge,
                          style: AppTextStyles.of(
                            figmaSize: 11,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(10)),
                      Text(
                        product.title,
                        style: AppTextStyles.of(
                          figmaSize: 22,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(8)),
                      Text(
                        product.description,
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
                product.art,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RentNowBar extends StatelessWidget {
  const _RentNowBar({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(16),
        AppTextStyles.fig(12),
        AppTextStyles.fig(16),
        AppTextStyles.fig(12) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.originalPrice != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.originalPrice!,
                        style: AppTextStyles.of(
                          figmaSize: 12,
                          weight: FontWeight.w500,
                          color: AppColors.textGraySoft,
                        ).copyWith(decoration: TextDecoration.lineThrough),
                      ),
                      if (product.discountBadge != null) ...[
                        SizedBox(width: AppTextStyles.fig(6)),
                        Text(
                          product.discountBadge!,
                          style: AppTextStyles.of(
                            figmaSize: 11,
                            weight: FontWeight.w700,
                            color: AppColors.checkGreen,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    'Starting at',
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w300,
                      color: AppColors.textGraySoft,
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: product.price,
                        style: AppTextStyles.of(
                          figmaSize: 22,
                          weight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                      TextSpan(
                        text: '/month + GST',
                        style: AppTextStyles.of(
                          figmaSize: 12,
                          weight: FontWeight.w400,
                          color: AppColors.textGrayMed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                context.push('/checkout', extra: product.checkoutProduct),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTextStyles.fig(26),
                vertical: AppTextStyles.fig(15),
              ),
              decoration: BoxDecoration(
                color: AppColors.ctaPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.ctaLabel,
                    style: AppTextStyles.of(
                      figmaSize: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppTextStyles.fig(6)),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
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

/// One appliance's showcase within a combo's "What's included" section —
/// its product photo alongside a short spec checklist, e.g. "Air
/// Conditioner" + 1 Ton/1.5 Ton AC image + Energy Efficient/Fast Cooling/
/// Smart Temperature Control bullets. See [Product.applianceBreakdown].
class _ApplianceBreakdownCard extends StatelessWidget {
  const _ApplianceBreakdownCard({
    required this.title,
    required this.art,
    required this.specs,
  });

  final String title;
  final Widget art;
  final List<String> specs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTextStyles.fig(12)),
      padding: EdgeInsets.all(AppTextStyles.fig(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed box (not just width) so every appliance — regardless of
          // its source photo's native aspect ratio, or which combo it's
          // in — renders at the exact same visual size here.
          SizedBox(
            width: AppTextStyles.fig(112),
            height: AppTextStyles.fig(132),
            child: Center(child: art),
          ),
          SizedBox(width: AppTextStyles.fig(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(6)),
                ...specs.map(
                  (spec) => Padding(
                    padding: EdgeInsets.only(bottom: AppTextStyles.fig(4)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.check,
                        ),
                        SizedBox(width: AppTextStyles.fig(6)),
                        Expanded(
                          child: Text(
                            spec,
                            style: AppTextStyles.of(
                              figmaSize: 12,
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
            ),
          ),
        ],
      ),
    );
  }
}
