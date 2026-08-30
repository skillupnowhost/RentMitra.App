import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/pricing_provider.dart';
import '../theme/app_colors.dart';
import '../utils/rent_pricing.dart';
import '../widgets/appliance_art.dart';
import '../widgets/combo_comparison_table.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

const _comboDescription = 'Complete appliance solutions designed for modern homes.';
const _comboFooterText =
    'All Combo Plans come with free delivery, free installation and maintenance & service included for every appliance — plus 18% GST applicable on every plan.';

// ============================================================
// SHARED APPLIANCE SPEC BULLETS
// ============================================================

const _acSpecs1Ton = [
  '1 Ton Capacity',
  'Energy Efficient',
  'Fast Cooling Technology',
  'Smart Temperature Control',
];
const _acSpecs1p5Ton = [
  '1.5 Ton Capacity',
  'Energy Efficient',
  'Fast Cooling Technology',
  'Smart Temperature Control',
];
const _fridgeSpecsDoubleDoor = [
  'Double Door Design',
  'Spacious Storage',
  'Energy Saving Technology',
];
const _washerSpecsFrontLoad = [
  'Front Loading Technology',
  'Advanced Cleaning System',
  'Low Noise Operation',
];
const _washerSpecsTopLoad = [
  'Top Loading Technology',
  'Easy Operation',
  'Powerful Washing Performance',
];

/// One combo's badge/breakdown data — the single source of truth shared by
/// [ComboScreen]'s "Choose Your Combo" list and [OffersScreen]'s offer
/// list, so the two stay in sync instead of hand-copied duplicates drifting
/// apart. Pricing itself isn't stored here — [buildComboOptionCards] looks
/// it up live from [PricingProvider] by [checkoutProduct]'s variant id.
class ComboOffer {
  const ComboOffer({
    required this.badge,
    this.badgeColor = AppColors.purple,
    required this.title,
    required this.checklist,
    required this.checkoutProduct,
    required this.applianceBreakdown,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final List<String> checklist;
  final CheckoutProduct checkoutProduct;
  final List<ApplianceBreakdown> applianceBreakdown;
}

final List<ComboOffer> comboOffers = [
  ComboOffer(
    badge: 'Best Value Combo',
    badgeColor: AppColors.comboBlueBright,
    title: 'Smart Living Combo',
    checklist: const [
      '1 Ton Smart Inverter Split AC',
      'Double Door Refrigerator',
      'Front Load Washing Machine',
      'Free installation for all 3 appliances',
    ],
    checkoutProduct: CheckoutProduct.smartLivingCombo,
    applianceBreakdown: [
      ('Air Conditioner', const AcProductImage(width: 130), _acSpecs1Ton),
      (
        'Refrigerator',
        const FridgeDoubleDoorProductImage(width: 130),
        _fridgeSpecsDoubleDoor,
      ),
      (
        'Washing Machine',
        const WasherFrontLoadImage(width: 130),
        _washerSpecsFrontLoad,
      ),
    ],
  ),
  ComboOffer(
    badge: 'Most Popular',
    badgeColor: AppColors.checkGreen,
    title: 'Family Essentials Combo',
    checklist: const [
      '1 Ton Smart Inverter Split AC',
      'Double Door Refrigerator',
      'Top Load Washing Machine',
      'Free installation for all 3 appliances',
    ],
    checkoutProduct: CheckoutProduct.familyEssentialsCombo,
    applianceBreakdown: [
      ('Air Conditioner', const AcProductImage(width: 130), _acSpecs1Ton),
      (
        'Refrigerator',
        const FridgeDoubleDoorProductImage(width: 130),
        _fridgeSpecsDoubleDoor,
      ),
      (
        'Washing Machine',
        const WasherTopLoadImage(width: 130),
        _washerSpecsTopLoad,
      ),
    ],
  ),
  ComboOffer(
    badge: 'Premium Choice',
    title: 'Premium Family Combo',
    checklist: const [
      '1.5 Ton Smart Inverter Split AC',
      'Double Door Refrigerator',
      'Top Load Washing Machine',
      'Free installation for all 3 appliances',
    ],
    checkoutProduct: CheckoutProduct.premiumFamilyCombo,
    applianceBreakdown: [
      ('Air Conditioner', const AcProductImage(width: 130), _acSpecs1p5Ton),
      (
        'Refrigerator',
        const FridgeDoubleDoorProductImage(width: 130),
        _fridgeSpecsDoubleDoor,
      ),
      (
        'Washing Machine',
        const WasherTopLoadImage(width: 130),
        _washerSpecsTopLoad,
      ),
    ],
  ),
  ComboOffer(
    badge: 'Luxury Home Package',
    badgeColor: AppColors.comboBlueDeep,
    title: 'Ultimate Premium Combo',
    checklist: const [
      '1.5 Ton Smart Inverter Split AC',
      'Double Door Refrigerator',
      'Front Load Washing Machine',
      'Free installation for all 3 appliances',
    ],
    checkoutProduct: CheckoutProduct.ultimatePremiumCombo,
    applianceBreakdown: [
      ('Air Conditioner', const AcProductImage(width: 130), _acSpecs1p5Ton),
      (
        'Refrigerator',
        const FridgeDoubleDoorProductImage(width: 130),
        _fridgeSpecsDoubleDoor,
      ),
      (
        'Washing Machine',
        const WasherFrontLoadImage(width: 130),
        _washerSpecsFrontLoad,
      ),
    ],
  ),
];

/// Backend `products.product_id` for "Combo Plan" (see
/// `rentmitra-backend/scripts/add-combo-variants.js`'s `COMBO_PRODUCT_ID`).
const _comboProductId = 4;

/// Lowest live rent across every active variant of the Combo product — used
/// for "Starting at ₹X" promo copy on Home/Offers ([PromoBanner]). This
/// looks at the whole product, not just [comboOffers]'s four current cards,
/// so an older combo tier that's still active in the backend (kept for
/// existing orders after the lineup was redesigned) still counts if it's
/// the cheapest — matching whatever the backend actually reports.
num? lowestComboRent(PricingProvider pricing) {
  return pricing.lowestRentForProduct(_comboProductId);
}

/// Builds one selectable [ProductOptionCard] per [comboOffers] entry, wired
/// to push its full [Product] onto `/product-details`. Shared by
/// [ComboScreen] and [OffersScreen] so both list the same combos.
List<ProductOptionCard> buildComboOptionCards(BuildContext context) {
  final pricing = context.watch<PricingProvider>();

  return comboOffers
      .map(
        (offer) {
          final rent = pricing.rentFor(offer.checkoutProduct.variantId);
          final breakdown = rent == null
              ? null
              : RentBreakdown.fromRent(rent, isCombo: true);

          final price = breakdown == null
              ? '₹—'
              : formatRupees(breakdown.afterDiscount);
          final originalPrice = breakdown == null
              ? null
              : formatRupees(breakdown.beforeDiscount);
          final discountBadge = breakdown == null
              ? null
              : '${(kComboDiscountRate * 100).round()}% OFF';

          return ProductOptionCard(
            badge: offer.badge,
            badgeColor: offer.badgeColor,
            title: offer.title,
            checklist: offer.checklist,
            art: const ApplianceClusterImage(width: 90),
            originalPrice: originalPrice,
            discountBadge: discountBadge,
            price: price,
            ctaLabel: 'Rent This Combo',
            onContinue: () => context.push(
              '/product-details',
              extra: Product(
                badge: offer.badge,
                title: offer.title,
                description: _comboDescription,
                checklist: offer.checklist,
                art: const ApplianceClusterImage(width: 140),
                originalPrice: originalPrice,
                discountBadge: discountBadge,
                price: price,
                checkoutProduct: offer.checkoutProduct,
                footerText: _comboFooterText,
                ctaLabel: 'Rent This Combo',
                applianceBreakdown: offer.applianceBreakdown,
              ),
            ),
          );
        },
      )
      .toList();
}

class ComboScreen extends StatelessWidget {
  const ComboScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pricing = context.watch<PricingProvider>();

    final comboBreakdowns = comboOffers.map((offer) {
      final rent = pricing.rentFor(offer.checkoutProduct.variantId);
      return rent == null ? null : RentBreakdown.fromRent(rent, isCombo: true);
    }).toList();

    final monthlyRentalValues = comboBreakdowns
        .map((b) => b == null ? '₹—' : formatRupees(b.afterDiscount))
        .toList();
    final youSaveValues = comboBreakdowns
        .map((b) => b == null ? '₹—' : formatRupees(b.discount))
        .toList();

    return ProductListingScreen(
      title: 'Choose Your Perfect Home Combo',

      description: _comboDescription,

      heroArt: const ApplianceClusterImage(width: 130),

      badgeFeatures: const [
        (Icons.local_shipping_outlined, 'Free\nDelivery'),
        (Icons.build_outlined, 'Free\nInstallation'),
        (Icons.verified_user_outlined, 'Service &\nMaintenance'),
        (Icons.percent, 'Save\n10%'),
      ],

      sectionTitle: 'Choose Your Combo',

      footerText: _comboFooterText,
      footerImage: 'assets/images/All install.png',

      trailingSection: ComboComparisonTable(
        headers: const [
          'Smart\nLiving',
          'Family\nEssentials',
          'Premium\nFamily',
          'Ultimate\nPremium',
        ],
        rows: [
          const ComboComparisonRow(
            label: 'AC Capacity',
            values: ['1 Ton', '1 Ton', '1.5 Ton', '1.5 Ton'],
          ),
          const ComboComparisonRow(
            label: 'Fridge Type',
            values: [
              'Double Door',
              'Double Door',
              'Double Door',
              'Double Door',
            ],
          ),
          const ComboComparisonRow(
            label: 'Washer Type',
            values: ['Front Load', 'Top Load', 'Top Load', 'Front Load'],
          ),
          ComboComparisonRow(
            label: 'Monthly Rental',
            values: monthlyRentalValues,
          ),
          ComboComparisonRow(
            label: 'You Save',
            values: youSaveValues,
          ),
        ],
      ),

      options: buildComboOptionCards(context),
    );
  }
}
