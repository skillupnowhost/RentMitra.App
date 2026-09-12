import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSession extends ChangeNotifier {
  CustomerSession._();

  static final CustomerSession instance = CustomerSession._();

  static const String _customerIdKey = 'customer_id';
  static const String _fullNameKey = 'customer_full_name';

  int? _customerId;
  String? _fullName;

  int? get customerId => _customerId;

  String? get fullName => _fullName;

  String get firstLetter {
    final name = _fullName?.trim() ?? '';

    if (name.isEmpty) {
      return '';
    }

    return name[0].toUpperCase();
  }

  bool get isLoggedIn => _customerId != null;

  /// Restore the customer session saved on the device.
  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();

    final savedCustomerId =
        preferences.getInt(_customerIdKey);

    final savedFullName =
        preferences.getString(_fullNameKey);

    if (savedCustomerId != null && savedCustomerId > 0) {
      _customerId = savedCustomerId;
      _fullName = savedFullName?.trim();

      notifyListeners();
    }
  }

  /// Save customer information after login/payment.
  Future<void> setCustomer({
    required int customerId,
    required String fullName,
  }) async {
    _customerId = customerId;
    _fullName = fullName.trim();

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setInt(
      _customerIdKey,
      customerId,
    );

    await preferences.setString(
      _fullNameKey,
      _fullName!,
    );

    notifyListeners();
  }

  /// Update the customer's name in memory and storage.
  Future<void> updateName(String fullName) async {
    _fullName = fullName.trim();

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _fullNameKey,
      _fullName!,
    );

    notifyListeners();
  }

  /// Clear the customer session and log out.
  Future<void> clear() async {
    _customerId = null;
    _fullName = null;

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_customerIdKey);
    await preferences.remove(_fullNameKey);

    notifyListeners();
  }
}