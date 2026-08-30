/// Fixed business rates applied on top of whatever rent the backend
/// returns — these are tax/promo rules, not per-product prices, so they
/// stay here rather than hardcoded per screen.
const double kComboDiscountRate = 0.10;
const double kGstRate = 0.18;

/// The rent math shared by every screen that shows a monthly price: the
/// admin-set [afterDiscount] rent (read straight from the backend's
/// `product_variants.monthly_rent`) plus the combo "was" price and GST
/// split derived from it.
class RentBreakdown {
  const RentBreakdown({required this.afterDiscount, required this.beforeDiscount});

  /// [rent] is the actual monthly rent from the backend — already the
  /// post-discount figure for combo variants. [isCombo] only controls
  /// whether a struck-through "before discount" price is derived for
  /// display; it never changes the amount actually charged.
  factory RentBreakdown.fromRent(num rent, {bool isCombo = false}) {
    final after = rent.round();
    final before = isCombo ? (rent / (1 - kComboDiscountRate)).round() : after;
    return RentBreakdown(afterDiscount: after, beforeDiscount: before);
  }

  final int afterDiscount;
  final int beforeDiscount;

  int get discount => beforeDiscount - afterDiscount;
  int get gst => (afterDiscount * kGstRate).round();
  int get cgst => gst ~/ 2;
  int get sgst => gst - cgst;
  int get total => afterDiscount + gst;
}

/// Shared "₹1,234" formatter used anywhere a live rent value is displayed.
String formatRupees(num value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final number = rounded.abs().toString();
  final formatted = number.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$sign₹$formatted';
}
