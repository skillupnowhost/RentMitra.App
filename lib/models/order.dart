/// A placed order, created once payment succeeds and shown on
/// [OrderSuccessScreen] / listed in [MyRentalsScreen] via [OrderProvider].
class Order {
  const Order({
    required this.id,
    required this.productName,
    required this.amount,
    required this.paymentMethod,
    required this.placedAt,
  });

  final String id;
  final String productName;
  final int amount;
  final String paymentMethod;
  final DateTime placedAt;
}
