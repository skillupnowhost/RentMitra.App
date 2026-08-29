import 'dart:convert';

import 'package:http/http.dart' as http;

/// Change this URL only if your backend is running somewhere else.
///
/// Windows / Chrome:
/// http://localhost:3000
///
/// Android emulator:
/// http://10.0.2.2:3000
class CheckoutService {
  // static const String baseUrl = 'http://localhost:3000';
  static const String baseUrl = 'http://10.177.34.45:3000';

  /// Creates a checkout/order in the RentMitra backend.
  static Future<CheckoutResponse> createCheckout({
    required int variantId,
    required int quantity,
    required String fullName,
    required String mobile,
    required String email,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    required String landmark,
    required String city,
    required String pincode,
  }) async {
    final uri = Uri.parse('$baseUrl/checkout');

    final body = {
      'variant_id': variantId,
      'quantity': quantity,
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      Map<String, dynamic> responseData = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            responseData = decoded;
          }
        } catch (_) {
          responseData = {};
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return CheckoutResponse.fromJson(responseData);
      }

      final message =
          responseData['message']?.toString() ??
          'Checkout failed with status code ${response.statusCode}.';

      throw CheckoutException(message);
    } catch (e) {
      if (e is CheckoutException) {
        rethrow;
      }

      throw CheckoutException(
        'Unable to connect to the checkout server. '
        'Please make sure the backend server is running.',
      );
    }
  }
}

/// Response returned by POST /checkout.
class CheckoutResponse {
  final String message;
  final CheckoutData checkout;

  CheckoutResponse({
    required this.message,
    required this.checkout,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    final checkoutJson = json['checkout'];

    if (checkoutJson is! Map) {
      throw CheckoutException(
        'Invalid checkout response received from the server.',
      );
    }

    return CheckoutResponse(
      message: json['message']?.toString() ?? 'Checkout created successfully',
      checkout: CheckoutData.fromJson(
        Map<String, dynamic>.from(checkoutJson),
      ),
    );
  }
}

/// Checkout data returned from the backend.
class CheckoutData {
  final String fullName;
  final String mobile;
  final String email;

  final int addressId;
  final int orderId;
  final int orderItemId;
  final int variantId;

  final String variantName;
  final int quantity;

  final double monthlyRent;
  final double orderAmount;

  final String paymentStatus;
  final String orderStatus;

  CheckoutData({
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.addressId,
    required this.orderId,
    required this.orderItemId,
    required this.variantId,
    required this.variantName,
    required this.quantity,
    required this.monthlyRent,
    required this.orderAmount,
    required this.paymentStatus,
    required this.orderStatus,
  });

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      fullName: json['full_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      addressId: _toInt(json['address_id']),
      orderId: _toInt(json['order_id']),
      orderItemId: _toInt(json['order_item_id']),
      variantId: _toInt(json['variant_id']),
      variantName: json['variant_name']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      monthlyRent: _toDouble(json['monthly_rent']),
      orderAmount: _toDouble(json['order_amount']),
      paymentStatus: json['payment_status']?.toString() ?? '',
      orderStatus: json['order_status']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Exception specifically for checkout API errors.
class CheckoutException implements Exception {
  final String message;

  CheckoutException(this.message);

  @override
  String toString() => message;
}