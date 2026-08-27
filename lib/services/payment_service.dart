import 'dart:convert';

import 'package:http/http.dart' as http;

class PaymentService {
  // static const String baseUrl = 'http://localhost:3000';
 static const String baseUrl = 'http://10.177.34.45:3000';

  static Future<Map<String, dynamic>> createCheckout({
    required int variantId,
    required int quantity,
    required String fullName,
    required String mobile,
    required String email,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
  }) async {
    final url = Uri.parse('$baseUrl/checkout');

    final body = {
      'variant_id': variantId,
      'quantity': quantity,
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark ?? '',
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ??
            'Checkout creation failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the backend: $e',
      };
    }
  }
}