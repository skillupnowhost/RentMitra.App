import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================
  static const String baseUrl = 'http://10.177.34.45:3000';
  // static const String baseUrl = 'http://10.123.221.45:3000';
  // static const String baseUrl = 'http://localhost:3000';

  // ============================================================
  // CREATE CHECKOUT
  // ============================================================

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
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to connect to the backend server.');
    }
  }

  // ============================================================
  // GET PRODUCT VARIANTS
  // ============================================================
  //
  // Backend endpoint:
  // GET /product-variants
  //
  // Used by PricingProvider to get the latest monthly rent
  // values from the backend/database.
  //
  // This keeps product pricing dynamic instead of hardcoded
  // inside the Flutter application.
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchProductVariants() async {
    final url = Uri.parse('$baseUrl/product-variants');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        // Backend response:
        //
        // [
        //   {
        //     "variant_id": 1,
        //     "variant_name": "1.5 Ton",
        //     "monthly_rent": 1299
        //   }
        // ]

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        // Also support:
        //
        // {
        //   "data": [
        //      {...},
        //      {...}
        //   ]
        // }

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is List) {
            return data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }

          // Also support:
          //
          // {
          //   "product_variants": [...]
          // }

          final productVariants = decoded['product_variants'];

          if (productVariants is List) {
            return productVariants
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }

          // Also support:
          //
          // {
          //   "variants": [...]
          // }

          final variants = decoded['variants'];

          if (variants is List) {
            return variants
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        }

        throw Exception('Invalid product variants response from backend.');
      }

      // ----------------------------------------------------------
      // ERROR RESPONSE
      // ----------------------------------------------------------

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString().trim();

          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
      } catch (error) {
        if (error is Exception) {
          rethrow;
        }
      }

      throw Exception(
        'Failed to load product variants. '
        'Status code: ${response.statusCode}.',
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load product variants.');
    }
  }

  // ============================================================
  // GET CUSTOMER RENTALS
  // ============================================================

  static Future<Map<String, dynamic>> getCustomerRentals({
    required int customerId,
  }) async {
    final url = Uri.parse('$baseUrl/rentals/customer/$customerId');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load customer rentals.');
    }
  }

  // ============================================================
  // CREATE RAZORPAY ORDER
  // ============================================================

  static Future<Map<String, dynamic>> createPaymentOrder({
    required int orderId,
  }) async {
    final url = Uri.parse('$baseUrl/payments/create-order');

    final body = {'order_id': orderId};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response);

      // ----------------------------------------------------------
      // GET NESTED RAZORPAY OBJECT
      // ----------------------------------------------------------

      final razorpayData = responseData['razorpay'];

      if (razorpayData is! Map) {
        throw Exception('Backend did not return Razorpay order details.');
      }

      final razorpayOrderId = razorpayData['razorpay_order_id']
          ?.toString()
          .trim();

      final amount = _parseInt(razorpayData['amount']);

      final currency = razorpayData['currency']?.toString().trim();

      // ----------------------------------------------------------
      // VALIDATE RAZORPAY DATA
      // ----------------------------------------------------------

      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        throw Exception('Backend did not return a valid Razorpay order ID.');
      }

      if (amount == null || amount <= 0) {
        throw Exception('Backend did not return a valid payment amount.');
      }

      if (currency == null || currency.isEmpty) {
        throw Exception('Backend did not return a valid payment currency.');
      }

      // ----------------------------------------------------------
      // RETURN NORMALIZED RESPONSE
      // ----------------------------------------------------------

      return {
        ...responseData,
        'razorpay_order_id': razorpayOrderId,
        'amount': amount,
        'currency': currency,
      };
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to create Razorpay payment order.');
    }
  }

  // ============================================================
  // VERIFY RAZORPAY PAYMENT
  // ============================================================

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse('$baseUrl/payments/verify');

    final body = {
      'order_id': orderId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to verify Razorpay payment.');
    }
  }

  // ============================================================
  // GET CUSTOMER PROFILE + ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>> getCustomerProfile({
    required int customerId,
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId/profile');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load customer profile.');
    }
  }

  // ============================================================
  // UPDATE CUSTOMER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateCustomer({
    required int customerId,
    required String fullName,
    required String mobile,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId');

    final body = {'full_name': fullName, 'mobile': mobile, 'email': email};

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to update customer profile.');
    }
  }

  // ============================================================
  // GET CUSTOMER ADDRESSES
  // ============================================================

  static Future<List<dynamic>> getCustomerAddresses({
    required int customerId,
  }) async {
    final url = Uri.parse('$baseUrl/addresses/customer/$customerId');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded;
        }

        // Support { "data": [...] }
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is List) {
            return data;
          }
        }

        throw Exception('Invalid address response from server.');
      }

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString();

          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
      } catch (error) {
        if (error is Exception) {
          rethrow;
        }
      }

      throw Exception(
        'Failed to load customer addresses. '
        'Status code: ${response.statusCode}',
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load customer address.');
    }
  }

  // ============================================================
  // CREATE CUSTOMER ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>> createAddress({
    required int customerId,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
  }) async {
    final url = Uri.parse('$baseUrl/addresses');

    final body = {
      'customer_id': customerId,
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark ?? '',
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to create customer address.');
    }
  }

  // ============================================================
  // UPDATE CUSTOMER ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
  }) async {
    final url = Uri.parse('$baseUrl/addresses/$addressId');

    final body = {
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark ?? '',
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to update customer address.');
    }
  }

  // ============================================================
  // CUSTOMER LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> loginCustomer({
    required String mobile,
  }) async {
    final url = Uri.parse('$baseUrl/customers/login');

    final body = {'mobile': mobile.trim()};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to login. Please try again.');
    }
  }

  // ============================================================
  // FIREBASE CUSTOMER LOGIN
  // POST /auth/firebase-login
  // ============================================================
  //
  // Firebase authenticates the customer's phone number first.
  // The resulting Firebase ID token is sent to the backend.
  // The backend verifies the token and finds the customer
  // in PostgreSQL.
  //
  // ============================================================

  static Future<Map<String, dynamic>> firebaseCustomerLogin({
    required String idToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/firebase-login');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to complete Firebase customer login.');
    }
  }

  static Future<Map<String, dynamic>> firebaseAdminLogin({
    required String idToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/admin-login');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to complete admin login.');
    }
  }

  // ============================================================
  // HANDLE HTTP RESPONSE
  // ============================================================

  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> responseData;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      } else {
        throw Exception('Invalid response format received from backend.');
      }
    } catch (_) {
      throw Exception('Invalid response received from the backend.');
    }

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    final message = responseData['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      throw Exception(message);
    }

    throw Exception(
      'Request failed with status code '
      '${response.statusCode}.',
    );
  }

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // ============================================================
  // ADMIN DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final url = Uri.parse('$baseUrl/admin/dashboard');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load admin dashboard.');
    }
  }

  static Future<Map<String, dynamic>> getAdminOrders() async {
    final url = Uri.parse('$baseUrl/admin/orders');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load admin orders.');
    }
  }

  // ============================================================
  // ADMIN - GET ALL CUSTOMERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAdminCustomers() async {
    final url = Uri.parse('$baseUrl/admin/customers');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      // DEBUG LOGS
      print('==============================================');
      print('ADMIN CUSTOMERS API');
      print('URL: $url');
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
      print('==============================================');

      // ----------------------------------------------------------
      // HTTP ERROR
      // ----------------------------------------------------------

      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final errorBody = jsonDecode(response.body);

          if (errorBody is Map) {
            final message = errorBody['message']?.toString().trim();

            if (message != null && message.isNotEmpty) {
              throw Exception(message);
            }
          }
        } catch (error) {
          if (error is Exception) {
            rethrow;
          }
        }

        throw Exception(
          'Failed to load customers. '
          'Status code: ${response.statusCode}.',
        );
      }

      // ----------------------------------------------------------
      // DECODE RESPONSE
      // ----------------------------------------------------------

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Customer API returned invalid JSON.');
      }

      // ----------------------------------------------------------
      // RESPONSE FORMAT 1
      //
      // {
      //   "value": [
      //      {...},
      //      {...}
      //   ],
      //   "Count": 24
      // }
      // ----------------------------------------------------------

      if (decoded is Map) {
        final dynamic value = decoded['value'];

        if (value is List) {
          final customers = <Map<String, dynamic>>[];

          for (final item in value) {
            if (item is Map) {
              customers.add(Map<String, dynamic>.from(item));
            }
          }

          print('ADMIN CUSTOMERS PARSED: ${customers.length}');

          return customers;
        }

        // --------------------------------------------------------
        // RESPONSE FORMAT 2
        //
        // {
        //   "customers": [...]
        // }
        // --------------------------------------------------------

        final dynamic customersValue = decoded['customers'];

        if (customersValue is List) {
          return customersValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        // --------------------------------------------------------
        // RESPONSE FORMAT 3
        //
        // {
        //   "data": [...]
        // }
        // --------------------------------------------------------

        final dynamic dataValue = decoded['data'];

        if (dataValue is List) {
          return dataValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      // ----------------------------------------------------------
      // RESPONSE FORMAT 4
      //
      // [...]
      // ----------------------------------------------------------

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Invalid customers response from backend.');
    } catch (error) {
      print('ADMIN CUSTOMERS ERROR: $error');

      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load customers.');
    }
  }

  // ============================================================
  // ADMIN - GET ALL PRODUCTS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAdminProducts() async {
    final url = Uri.parse('$baseUrl/products');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('==============================================');
      print('ADMIN PRODUCTS API');
      print('URL: $url');
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
      print('==============================================');

      // ----------------------------------------------------------
      // HTTP ERROR
      // ----------------------------------------------------------

      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final errorBody = jsonDecode(response.body);

          if (errorBody is Map) {
            final message = errorBody['message']?.toString().trim();

            if (message != null && message.isNotEmpty) {
              throw Exception(message);
            }
          }
        } catch (error) {
          if (error is Exception) {
            rethrow;
          }
        }

        throw Exception(
          'Failed to load products. '
          'Status code: ${response.statusCode}.',
        );
      }

      // ----------------------------------------------------------
      // DECODE JSON
      // ----------------------------------------------------------

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Products API returned invalid JSON.');
      }

      // ----------------------------------------------------------
      // MAIN BACKEND FORMAT
      //
      // {
      //   "value": [...],
      //   "Count": 5
      // }
      // ----------------------------------------------------------

      if (decoded is Map) {
        final dynamic value = decoded['value'];

        if (value is List) {
          final products = <Map<String, dynamic>>[];

          for (final item in value) {
            if (item is Map) {
              products.add(Map<String, dynamic>.from(item));
            }
          }

          print('ADMIN PRODUCTS PARSED: ${products.length}');

          return products;
        }

        // --------------------------------------------------------
        // Alternative: { "products": [...] }
        // --------------------------------------------------------

        final dynamic productsValue = decoded['products'];

        if (productsValue is List) {
          return productsValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        // --------------------------------------------------------
        // Alternative: { "data": [...] }
        // --------------------------------------------------------

        final dynamic dataValue = decoded['data'];

        if (dataValue is List) {
          return dataValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      // ----------------------------------------------------------
      // Direct list response
      // ----------------------------------------------------------

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Invalid products response from backend.');
    } catch (error) {
      print('ADMIN PRODUCTS ERROR: $error');

      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load products.');
    }
  }

  // ============================================================
  // ADMIN - GET ALL PRODUCT VARIANTS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAdminVariants() async {
    final url = Uri.parse('$baseUrl/product-variants');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('==============================================');
      print('ADMIN VARIANTS API');
      print('URL: $url');
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
      print('==============================================');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final errorBody = jsonDecode(response.body);

          if (errorBody is Map) {
            final message = errorBody['message']?.toString().trim();

            if (message != null && message.isNotEmpty) {
              throw Exception(message);
            }
          }
        } catch (error) {
          if (error is Exception) {
            rethrow;
          }
        }

        throw Exception(
          'Failed to load product variants. '
          'Status code: ${response.statusCode}.',
        );
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Product variants API returned invalid JSON.');
      }

      // ----------------------------------------------------------
      // BACKEND RESPONSE:
      //
      // {
      //   "value": [
      //      {...},
      //      {...}
      //   ],
      //   "Count": 12
      // }
      // ----------------------------------------------------------

      if (decoded is Map) {
        final dynamic value = decoded['value'];

        if (value is List) {
          final variants = <Map<String, dynamic>>[];

          for (final item in value) {
            if (item is Map) {
              variants.add(Map<String, dynamic>.from(item));
            }
          }

          print('ADMIN VARIANTS PARSED: ${variants.length}');

          return variants;
        }

        // --------------------------------------------------------
        // SUPPORT ALTERNATIVE RESPONSE:
        // { "variants": [...] }
        // --------------------------------------------------------

        final dynamic variantsValue = decoded['variants'];

        if (variantsValue is List) {
          return variantsValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        // --------------------------------------------------------
        // SUPPORT ALTERNATIVE RESPONSE:
        // { "product_variants": [...] }
        // --------------------------------------------------------

        final dynamic productVariantsValue = decoded['product_variants'];

        if (productVariantsValue is List) {
          return productVariantsValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        // --------------------------------------------------------
        // SUPPORT ALTERNATIVE RESPONSE:
        // { "data": [...] }
        // --------------------------------------------------------

        final dynamic dataValue = decoded['data'];

        if (dataValue is List) {
          return dataValue
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      // ----------------------------------------------------------
      // SUPPORT DIRECT ARRAY RESPONSE
      // ----------------------------------------------------------

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Invalid product variants response from backend.');
    } catch (error) {
      print('ADMIN VARIANTS ERROR: $error');

      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load product variants.');
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminRentals() async {
    final uri = Uri.parse('$baseUrl/rentals');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('GET /rentals -> ${response.statusCode}');
    debugPrint('Rentals response: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load rentals: '
        '${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final rentals = decoded['rentals'];

      if (rentals is List) {
        return rentals
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      final value = decoded['value'];

      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    throw Exception('Unexpected rentals API response format.');
  }

  // ============================================================
  // ADMIN INSTALLATIONS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAdminInstallations() async {
    final uri = Uri.parse('$baseUrl/admin/installations');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('GET /admin/installations -> ${response.statusCode}');

    debugPrint('Installations response: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load installations: '
        '${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final installations = decoded['installations'];

      if (installations is List) {
        return installations
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    throw Exception('Unexpected installations API response format.');
  }

  static Future<List<Map<String, dynamic>>> getAdminAddresses() async {
    final uri = Uri.parse('$baseUrl/admin/addresses');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('GET /admin/addresses -> ${response.statusCode}');

    debugPrint('Addresses response: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load addresses: '
        '${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final addresses = decoded['addresses'];

      if (addresses is List) {
        return addresses
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    throw Exception('Unexpected addresses API response format.');
  }

  // ============================================================
  // ADMIN - UPDATE ORDER STATUS
  // PUT /admin/orders/:id/status
  // ============================================================

  static Future<Map<String, dynamic>> updateAdminOrderStatus({
    required int orderId,
    required String orderStatus,
  }) async {
    final url = Uri.parse('$baseUrl/admin/orders/$orderId/status');

    final body = {'order_status': orderStatus};

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to update order status.');
    }
  }

  static Future<Map<String, dynamic>> createAdminCustomer({
    required String fullName,
    required String mobile,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/customers');

    final body = {
      'full_name': fullName.trim(),
      'mobile': mobile.trim(),
      'email': email.trim().toLowerCase(),
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to create customer.');
    }
  }

  static Future<Map<String, dynamic>> deactivateCustomer({
    required int customerId,
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId');

    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to deactivate customer.');
    }
  }

  static Future<Map<String, dynamic>> reactivateCustomer({
    required int customerId,
  }) async {
    final url = Uri.parse('$baseUrl/customers/$customerId/reactivate');

    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to reactivate customer.');
    }
  }

  // ============================================================
  // ADMIN - DELIVERY PARTNERS
  // GET /admin/delivery-partners
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAdminDeliveryPartners() async {
    final url = Uri.parse('$baseUrl/admin/delivery-partners');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _handleResponse(response);
      final raw = decoded['delivery_partners'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Unexpected delivery partners API response format.');
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load delivery partners.');
    }
  }

  // ============================================================
  // GET DELIVERY ASSIGNMENTS
  // GET /deliveries/assignments
  // ============================================================

  static Future<List<Map<String, dynamic>>> getDeliveryAssignments() async {
    final url = Uri.parse('$baseUrl/deliveries/assignments');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _handleResponse(response);
      final raw = decoded['deliveries'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Unexpected delivery assignments API response format.');
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load delivery assignments.');
    }
  }

  // ============================================================
  // ASSIGN DELIVERY PARTNER
  // POST /deliveries/assign
  // ============================================================

  static Future<Map<String, dynamic>> assignDelivery({
    required int orderId,
    required int deliveryPartnerId,
  }) async {
    final url = Uri.parse('$baseUrl/deliveries/assign');

    final body = {
      'order_id': orderId,
      'delivery_partner_id': deliveryPartnerId,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to assign delivery partner.');
    }
  }

  // ============================================================
  // INSTALLATION PARTNERS
  // GET /admin/installation-partners
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getAdminInstallationPartners() async {
    final url = Uri.parse('$baseUrl/admin/installation-partners');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _handleResponse(response);
      final raw = decoded['installation_partners'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Unexpected installation partners API response format.');
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to load installation partners.');
    }
  }

  // ============================================================
  // SCHEDULE INSTALLATION
  // POST /installations/schedule
  // ============================================================

  static Future<Map<String, dynamic>> scheduleInstallation({
    required int orderId,
    required String scheduledDate,
    String? scheduledAt,
    required int installationPartnerId,
  }) async {
    final url = Uri.parse('$baseUrl/installations/schedule');

    final body = {
      'order_id': orderId,
      'scheduled_date': scheduledDate,
      'scheduled_at': scheduledAt,
      'installation_partner_id': installationPartnerId,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to schedule installation.');
    }
  }

  // ============================================================
  // MARK DELIVERY COMPLETED
  // PUT /deliveries/:order_id/delivered
  // ============================================================

  static Future<Map<String, dynamic>> markOrderAsDelivered({
    required int orderId,
  }) async {
    final url = Uri.parse('$baseUrl/deliveries/$orderId/delivered');

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to complete delivery.');
    }
  }

  // ============================================================
  // MARK INSTALLATION COMPLETED
  // PUT /installations/:order_id/completed
  // ============================================================

  static Future<Map<String, dynamic>> markInstallationAsCompleted({
    required int orderId,
  }) async {
    final url = Uri.parse('$baseUrl/installations/$orderId/completed');

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to complete installation.');
    }
  }

  // ============================================================
  // ACTIVATE RENTAL
  // PUT /rentals/order/:order_id/activate
  // ============================================================

  static Future<Map<String, dynamic>> activateRental({
    required int orderId,
  }) async {
    final url = Uri.parse('$baseUrl/rentals/order/$orderId/activate');

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to activate rental.');
    }
  }

  // ============================================================
  // ADMIN PAYMENTS
  // GET /admin/payments
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAdminPayments() async {
    final url = Uri.parse('$baseUrl/admin/payments');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _handleResponse(response);

      dynamic raw = decoded['payments'];
      raw ??= decoded['value'];
      raw ??= decoded['data'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Unexpected payments API response format.');
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to load payments.');
    }
  }

  // ============================================================
  // ADMIN PAYMENT DETAILS
  // GET /admin/payments/:id
  // ============================================================

  static Future<Map<String, dynamic>> getAdminPaymentDetails({
    required int paymentId,
  }) async {
    final url = Uri.parse('$baseUrl/admin/payments/$paymentId');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _handleResponse(response);
      final payment = decoded['payment'];

      if (payment is Map) {
        return Map<String, dynamic>.from(payment);
      }

      return decoded;
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to load payment details.');
    }
  }

  // ============================================================
  // ADMIN - CREATE PRODUCT VARIANT
  // POST /product-variants
  // ============================================================

  static Future<Map<String, dynamic>> createProductVariant({
    required int productId,
    required String variantName,
    required double monthlyRent,
  }) async {
    final url = Uri.parse('$baseUrl/product-variants');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'product_id': productId,
              'variant_name': variantName.trim(),
              'monthly_rent': monthlyRent,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to create product variant.');
    }
  }

  // ============================================================
  // ADMIN - UPDATE PRODUCT VARIANT
  // PUT /product-variants/:id
  // ============================================================

  static Future<Map<String, dynamic>> updateProductVariant({
    required int variantId,
    required String variantName,
    required double monthlyRent,
  }) async {
    final url = Uri.parse('$baseUrl/product-variants/$variantId');

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'variant_name': variantName.trim(),
              'monthly_rent': monthlyRent,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to update product variant.');
    }
  }

  // ============================================================
  // ADMIN - DEACTIVATE PRODUCT VARIANT
  // DELETE /product-variants/:id
  // ============================================================

  static Future<Map<String, dynamic>> deactivateProductVariant({
    required int variantId,
  }) async {
    final url = Uri.parse('$baseUrl/product-variants/$variantId');

    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to deactivate product variant.');
    }
  }

  // ============================================================
  // ADMIN - REACTIVATE PRODUCT VARIANT
  // PATCH /product-variants/:id/reactivate
  // ============================================================

  static Future<Map<String, dynamic>> reactivateProductVariant({
    required int variantId,
  }) async {
    final url = Uri.parse('$baseUrl/product-variants/$variantId/reactivate');

    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to reactivate product variant.');
    }
  }

  // ============================================================
  // ADMIN - CREATE MANUAL ORDER
  // POST /admin/manual-orders
  // ============================================================

  static Future<Map<String, dynamic>> createManualOrder({
    int? customerId,
    required String fullName,
    required String mobile,
    required String email,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
    required int variantId,
    required int quantity,
    required double monthlyRent,
    required double orderAmount,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    final url = Uri.parse('$baseUrl/admin/manual-orders');

    final body = <String, dynamic>{
      'customer_id': customerId,
      'full_name': fullName.trim(),
      'mobile': mobile.trim(),
      'email': email.trim(),
      'house_flat_number': houseFlatNumber.trim(),
      'apartment_name': apartmentName.trim(),
      'street_area': streetArea.trim(),
      'landmark': landmark?.trim(),
      'city': city.trim(),
      'pincode': pincode.trim(),
      'variant_id': variantId,
      'quantity': quantity,
      'monthly_rent': monthlyRent,
      'order_amount': orderAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to create manual order.');
    }
  }
}
