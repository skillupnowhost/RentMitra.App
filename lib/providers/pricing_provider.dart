import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_variant.dart';
import '../services/api_service.dart';

/// Live rent amounts for every product variant, fetched from the backend's
/// `GET /product-variants` (see `rentmitra-backend/server.js`) — the single
/// source of truth for whatever an admin has set each variant's monthly
/// rent to via `PUT /admin/product-variants/:id`. Every screen that used to
/// hardcode a price reads it from here instead, so an admin's edit shows up
/// across the app without a release.
///
/// The last successful fetch is also cached on-device (see
/// [_cachedVariantsPrefsKey]), so a cold start with no connectivity still
/// shows real, previously-fetched prices instead of a blank "₹—" — never a
/// hardcoded number. The moment the network call succeeds, the cache and
/// the UI both refresh to whatever the backend/admin currently has set.
class PricingProvider extends ChangeNotifier {
  static const _cachedVariantsPrefsKey = 'rentmitra.cached_product_variants';

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

    // Show the last cached prices immediately — e.g. a cold start with no
    // connectivity — so screens never sit blank while the live call below
    // is still in flight (or times out). Skipped once something is already
    // in memory (a previous successful load this session beats disk cache).
    if (_variantsById.isEmpty && await _loadFromCache()) {
      notifyListeners();
    }

    try {
      final rows = await ApiService.fetchProductVariants();
      final variants = rows.map(ProductVariant.fromJson);

      _variantsById = {
        for (final variant in variants) variant.variantId: variant,
      };

      _hasLoaded = true;
      unawaited(_saveToCache(rows));
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');

      // Offline/unreachable backend: whatever cache (or prior in-memory
      // load) is already sitting in [_variantsById] stays on screen rather
      // than being cleared out from under the user.
      if (_variantsById.isNotEmpty) {
        _hasLoaded = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  /// Restores [_variantsById] from the on-device cache written by the last
  /// successful [load]. Returns whether it found anything usable.
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedVariantsPrefsKey);

      if (cached == null) {
        return false;
      }

      final rows = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
      final variants = rows.map(ProductVariant.fromJson);

      _variantsById = {
        for (final variant in variants) variant.variantId: variant,
      };

      return _variantsById.isNotEmpty;
    } catch (_) {
      // Corrupt or unreadable cache — the live fetch below is still tried
      // as normal, so this just means no offline fallback this time.
      return false;
    }
  }

  /// Persists the raw rows from a successful [load] so [_loadFromCache] has
  /// real, backend-sourced prices to fall back to next time there's no
  /// connectivity.
  Future<void> _saveToCache(List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedVariantsPrefsKey, jsonEncode(rows));
    } catch (_) {
      // Best-effort — a failed cache write shouldn't break live pricing.
    }
  }
}
