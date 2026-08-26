import 'package:flutter/widgets.dart';

import '../screens/checkout_screen.dart' show CheckoutProduct;
import '../widgets/product_option_card.dart' show ProductSpec;

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
}
