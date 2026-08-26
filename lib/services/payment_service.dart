/// Result of a payment attempt. [transactionId] is only set on success.
class PaymentResult {
  const PaymentResult.success(this.transactionId) : success = true;
  const PaymentResult.failure()
      : success = false,
        transactionId = null;

  final bool success;
  final String? transactionId;
}

/// Stand-in for a real payment gateway (Razorpay) call. [PaymentScreen]'s
/// "Pay Now" awaits this and reacts to the result exactly as it would to a
/// real gateway response — swapping this method's body for a real
/// razorpay_flutter checkout call (backed by a server order-create/verify
/// step) is the entire scope of wiring up real payments later; no call
/// site outside this file needs to change.
class PaymentService {
  static Future<PaymentResult> simulate({
    required String method,
    required int amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final transactionId = 'SIM${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult.success(transactionId);
  }
}
