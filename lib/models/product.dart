import 'package:flutter/widgets.dart';

import '../screens/checkout_screen.dart' show CheckoutProduct;
import '../widgets/product_option_card.dart' show ProductSpec;

/// One appliance's showcase within a combo's "what's included" breakdown on
/// [ProductDetailsScreen] — its own product photo plus a short list of
/// spec checkmarks, e.g. ("Air Conditioner", AcProductImage(...), ["Energy
/// Efficient", "Fast Cooling Technology", ...]). Combo-only; single-item
/// listings (AC/Fridge/Washer) keep using the flat [Product.checklist].
typedef ApplianceBreakdown = (String title, Widget art, List<String> specs);

/// The data behind one selectable [ProductOptionCard] on a listing screen
/// (e.g. "AC — 1 Ton"), carried forward as the GoRouter `extra` from the
/// listing screen through [ProductDetailsScreen] to [CheckoutScreen]. This
/// is a display/navigation bridge, not a source of truth — its fields
/// mirror what the listing screens already hardcode per variant, and
/// [checkoutProduct] is what lets the funnel hand off to the existing,
/// untouched checkout flow.
class Product {
  const Product({
    required this.badge,
    required this.title,
    required this.description,
    required this.checklist,
    required this.art,
    required this.price,
    required this.checkoutProduct,
    this.specs = const [],
    this.footerText,
    this.originalPrice,
    this.discountBadge,
    this.applianceBreakdown = const [],
    this.ctaLabel = 'Rent Now',
  });

  final String badge;
  final String title;
  final String description;
  final List<String> checklist;
  final Widget art;
  final String price;
  final CheckoutProduct checkoutProduct;
  final List<ProductSpec> specs;
  final String? footerText;

  /// Pre-discount price (e.g. "₹2,597") shown struck through next to
  /// [price] when a combo has a discount to advertise. Null for products
  /// with no discount.
  final String? originalPrice;

  /// Short discount pill text, e.g. "10% OFF". Shown alongside
  /// [originalPrice]; null hides the pill.
  final String? discountBadge;

  /// Per-appliance spec breakdown for combos — see [ApplianceBreakdown].
  final List<ApplianceBreakdown> applianceBreakdown;

  /// Sticky bottom bar CTA text on [ProductDetailsScreen]. Defaults to
  /// "Rent Now"; combos pass "Rent This Combo".
  final String ctaLabel;
}
