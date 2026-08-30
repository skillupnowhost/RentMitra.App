import 'package:flutter/foundation.dart';

import '../models/product_variant.dart';
import '../services/api_service.dart';

/// Live rent amounts for every product variant, fetched from the backend's
/// `GET /product-variants` (see `rentmitra-backend/server.js`) — the single
/// source of truth for whatever an admin has set each variant's monthly
/// rent to via `PUT /admin/product-variants/:id`. Every screen that used to
/// hardcode a price reads it from here instead, so an admin's edit shows up
/// across the app without a release.
class PricingProvider extends ChangeNotifier {
  Map<int, ProductVariant> _variantsById = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  /// The live monthly rent for [variantId], or null if pricing hasn't
  /// loaded yet (or that variant is inactive/unknown).
  num? rentFor(int variantId) => _variantsById[variantId]?.monthlyRent;

  /// Lowest rent among [variantIds] — used for "Starting at ₹X" copy on
  /// category cards. Null while unloaded or if none of the ids are known.
  num? lowestRentAmong(Iterable<int> variantIds) {
    num? lowest;

    for (final id in variantIds) {
      final rent = rentFor(id);

      if (rent == null) {
        continue;
      }

      if (lowest == null || rent < lowest) {
        lowest = rent;
      }
    }

    return lowest;
  }

  /// Lowest rent among every active variant under [productId] — unlike
  /// [lowestRentAmong], this isn't limited to a caller-supplied list of
  /// variant ids, so it also picks up older/legacy variants of that product
  /// that are still active in the backend but no longer shown as a
  /// selectable card anywhere (e.g. a retired combo tier kept around for
  /// existing orders). Null while unloaded or if [productId] has no active
  /// variants.
  num? lowestRentForProduct(int productId) {
    num? lowest;

    for (final variant in _variantsById.values) {
      if (variant.productId != productId) {
        continue;
      }

      if (lowest == null || variant.monthlyRent < lowest) {
        lowest = variant.monthlyRent;
      }
    }

    return lowest;
  }

  Future<void> load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rows = await ApiService.fetchProductVariants();
      final variants = rows.map(ProductVariant.fromJson);

      _variantsById = {
        for (final variant in variants) variant.variantId: variant,
      };

      _hasLoaded = true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();
}
