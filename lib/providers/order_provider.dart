import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// The order history shared across the app: [PaymentScreen] adds to it once
/// payment succeeds, [MyRentalsScreen] reads it. The only cross-screen
/// shared state this refactor introduces — the Product → Details → Checkout
/// hand-off is a single-hop linear pass carried via GoRouter `extra`
/// instead, since that state is never read by more than the next screen.
class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  Order? get lastOrder => _orders.isEmpty ? null : _orders.first;

  void placeOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }
}
