/// One row from the backend's `product_variants` table (see
/// `rentmitra-backend/server.js` `GET /product-variants`) — the live,
/// admin-editable monthly rent for a single variant (e.g. "1 Ton AC",
/// "Smart Living Combo"). Fetched by [PricingProvider] and keyed by
/// [variantId], which already matches the ids `CheckoutProduct.variantId`
/// hands the checkout API.
class ProductVariant {
  const ProductVariant({
    required this.variantId,
    required this.productId,
    required this.variantName,
    required this.monthlyRent,
    required this.isActive,
  });

  final int variantId;
  final int productId;
  final String variantName;
  final num monthlyRent;
  final bool isActive;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: _toInt(json['variant_id']),
      productId: _toInt(json['product_id']),
      variantName: json['variant_name']?.toString() ?? '',
      monthlyRent: _toNum(json['monthly_rent']),
      isActive: json['is_active'] == true,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}
