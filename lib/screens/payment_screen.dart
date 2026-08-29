import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'checkout_screen.dart';
import 'rental_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.product,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.houseFlatNumber,
    required this.apartmentName,
    required this.streetArea,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.checkoutData,
  });

  final CheckoutProduct product;

  final String fullName;
  final String mobile;
  final String email;

  final String houseFlatNumber;
  final String apartmentName;
  final String streetArea;
  final String landmark;
  final String city;
  final String pincode;

  // Backend checkout response.
  final Map<String, dynamic> checkoutData;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ============================================================
  // RAZORPAY
  // ============================================================

  late final Razorpay _razorpay;

  // ============================================================
  // PAYMENT STATE
  // ============================================================

  String _selectedPaymentMethod = 'UPI';

  String? _topErrorMessage;

  bool _isCreatingPaymentOrder = false;
  bool _isRecordingPayment = false;

  // Prevent Pay Now from being clicked repeatedly.
  bool get _isPaymentProcessing =>
      _isCreatingPaymentOrder || _isRecordingPayment;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _razorpay.clear();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 520.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppTextStyles.fig(16),
                          AppTextStyles.fig(8),
                          AppTextStyles.fig(16),
                          AppTextStyles.fig(190),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_topErrorMessage != null) ...[
                              _buildTopErrorMessage(),

                              SizedBox(
                                height: AppTextStyles.fig(12),
                              ),
                            ],

                            _buildOrderSummary(),

                            SizedBox(
                              height: AppTextStyles.fig(22),
                            ),

                            _buildPaymentHeader(),

                            SizedBox(
                              height: AppTextStyles.fig(14),
                            ),

                            _buildPaymentMethod(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'UPI',
                              subtitle:
                                  'Pay using Google Pay, PhonePe, Paytm etc.',
                              value: 'UPI',
                            ),

                            _buildPaymentMethod(
                              icon: Icons.credit_card_outlined,
                              title: 'Credit / Debit Card',
                              subtitle:
                                  'Visa, Mastercard, RuPay and more',
                              value: 'Credit / Debit Card',
                            ),

                            _buildPaymentMethod(
                              icon: Icons.account_balance_outlined,
                              title: 'Net Banking',
                              subtitle:
                                  'Pay directly through your bank',
                              value: 'Net Banking',
                            ),

                            SizedBox(
                              height: AppTextStyles.fig(20),
                            ),

                            _buildPriceDetails(),

                            SizedBox(
                              height: AppTextStyles.fig(20),
                            ),

                            _buildCustomerDetails(),

                            SizedBox(
                              height: AppTextStyles.fig(20),
                            ),

                            _buildSecurePaymentInfo(),
                          ],
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBottomPaymentBar(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP ERROR MESSAGE
  // ============================================================

  Widget _buildTopErrorMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(14),
        vertical: AppTextStyles.fig(12),
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 22,
          ),

          SizedBox(
            width: AppTextStyles.fig(10),
          ),

          Expanded(
            child: Text(
              _topErrorMessage!,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w600,
                color: Colors.red.shade700,
                height: 1.35,
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              setState(() {
                _topErrorMessage = null;
              });
            },
            child: Icon(
              Icons.close,
              color: Colors.red.shade700,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(16),
        AppTextStyles.fig(8),
        AppTextStyles.fig(16),
        AppTextStyles.fig(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isPaymentProcessing) {
                return;
              }

              Navigator.of(context).maybePop();
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.navy,
              size: 28,
            ),
          ),

          Expanded(
            child: Text(
              'Payment',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 20,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),

          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================

  Widget _buildOrderSummary() {
    final product = widget.product;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        AppTextStyles.fig(18),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTextStyles.of(
              figmaSize: 16,
              weight: FontWeight.w700,
              color: AppColors.purple,
            ),
          ),

          SizedBox(
            height: AppTextStyles.fig(10),
          ),

          Text(
            product.name,
            style: AppTextStyles.of(
              figmaSize: 20,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          if (product.description != null) ...[
            SizedBox(
              height: AppTextStyles.fig(5),
            ),

            Text(
              product.description!,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w400,
                color: AppColors.textGray,
                height: 1.35,
              ),
            ),
          ],

          SizedBox(
            height: AppTextStyles.fig(14),
          ),

          Container(
            height: 1,
            color: AppColors.divider,
          ),

          SizedBox(
            height: AppTextStyles.fig(14),
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Monthly Amount',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),

              Text(
                _money(product.total),
                style: AppTextStyles.of(
                  figmaSize: 20,
                  weight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT HEADER
  // ============================================================

  Widget _buildPaymentHeader() {
    return Row(
      children: [
        Container(
          width: AppTextStyles.fig(46),
          height: AppTextStyles.fig(46),
          decoration: const BoxDecoration(
            color: AppColors.bgCardPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.payment_outlined,
            color: AppColors.purple,
            size: 27,
          ),
        ),

        SizedBox(
          width: AppTextStyles.fig(12),
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Payment Method',
                style: AppTextStyles.of(
                  figmaSize: 18,
                  weight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),

              SizedBox(
                height: AppTextStyles.fig(2),
              ),

              Text(
                'Select your preferred payment method',
                style: AppTextStyles.of(
                  figmaSize: 12,
                  weight: FontWeight.w400,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  Widget _buildPaymentMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: _isPaymentProcessing
          ? null
          : () {
              setState(() {
                _selectedPaymentMethod = value;
                _topErrorMessage = null;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        width: double.infinity,
        margin: EdgeInsets.only(
          bottom: AppTextStyles.fig(10),
        ),
        padding: EdgeInsets.all(
          AppTextStyles.fig(14),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.bgCardPurple
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppTextStyles.fig(44),
              height: AppTextStyles.fig(44),
              decoration: BoxDecoration(
                color: AppColors.bgCardPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.purple,
                size: 25,
              ),
            ),

            SizedBox(
              width: AppTextStyles.fig(12),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.of(
                      figmaSize: 15,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),

                  SizedBox(
                    height: AppTextStyles.fig(3),
                  ),

                  Text(
                    subtitle,
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: AppTextStyles.fig(8),
            ),

            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.purple
                  : AppColors.textGrayMed,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRICE DETAILS
  // ============================================================

  Widget _buildPriceDetails() {
    final product = widget.product;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        AppTextStyles.fig(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Details',
            style: AppTextStyles.of(
              figmaSize: 16,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          SizedBox(
            height: AppTextStyles.fig(14),
          ),

          if (product.isCombo) ...[
            _priceRow(
              'Monthly Rent',
              product.monthlyRent,
            ),

            SizedBox(
              height: AppTextStyles.fig(9),
            ),

            _priceRow(
              'Combo Discount',
              -product.discount,
              valueColor: Colors.green,
              titleColor: Colors.green,
            ),

            SizedBox(
              height: AppTextStyles.fig(9),
            ),

            _priceRow(
              'Monthly Rent After Discount',
              product.afterDiscount,
            ),

            SizedBox(
              height: AppTextStyles.fig(9),
            ),

            _priceRow(
              'GST (18%)',
              product.gst,
            ),
          ] else ...[
            _priceRow(
              'Monthly Rent',
              product.monthlyRent,
            ),

            SizedBox(
              height: AppTextStyles.fig(9),
            ),

            _priceRow(
              'GST (18%)',
              product.gst,
            ),
          ],

          Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTextStyles.fig(14),
            ),
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),

          _priceRow(
            'Total',
            product.total,
            bold: true,
            valueSize: 20,
            valueColor: AppColors.purple,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _priceRow(
    String title,
    int amount, {
    Color? valueColor,
    Color? titleColor,
    bool bold = false,
    double valueSize = 14,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.of(
              figmaSize: bold ? 15 : 13,
              weight: bold
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: titleColor ?? AppColors.navy,
            ),
          ),
        ),

        Text(
          _money(amount),
          style: AppTextStyles.of(
            figmaSize: valueSize,
            weight: bold
                ? FontWeight.w700
                : FontWeight.w600,
            color: valueColor ?? AppColors.navy,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CUSTOMER DETAILS
  // ============================================================

  Widget _buildCustomerDetails() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        AppTextStyles.fig(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Details',
            style: AppTextStyles.of(
              figmaSize: 16,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          SizedBox(
            height: AppTextStyles.fig(14),
          ),

          _detailRow(
            Icons.person_outline,
            'Name',
            widget.fullName,
          ),

          _detailRow(
            Icons.phone_outlined,
            'Mobile',
            '+91 ${widget.mobile}',
          ),

          _detailRow(
            Icons.email_outlined,
            'Email',
            widget.email,
          ),

          _detailRow(
            Icons.location_on_outlined,
            'Delivery Address',
            _buildAddressText(),
            multiline: true,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value, {
    bool multiline = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppTextStyles.fig(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.purple,
            size: 21,
          ),

          SizedBox(
            width: AppTextStyles.fig(10),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.of(
                    figmaSize: 11,
                    weight: FontWeight.w500,
                    color: AppColors.textGray,
                  ),
                ),

                SizedBox(
                  height: AppTextStyles.fig(2),
                ),

                Text(
                  value,
                  maxLines: multiline ? null : 2,
                  overflow: multiline
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 13,
                    weight: FontWeight.w600,
                    color: AppColors.navy,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildAddressText() {
    final parts = <String>[
      widget.houseFlatNumber,
      widget.apartmentName,
      widget.streetArea,
      if (widget.landmark.trim().isNotEmpty)
        widget.landmark,
      widget.city,
      widget.pincode,
    ].where(
      (value) => value.trim().isNotEmpty,
    ).toList();

    return parts.join(', ');
  }

  // ============================================================
  // SECURE PAYMENT INFO
  // ============================================================

  Widget _buildSecurePaymentInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(14),
        vertical: AppTextStyles.fig(12),
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppColors.purple,
            size: 22,
          ),

          SizedBox(
            width: AppTextStyles.fig(10),
          ),

          Expanded(
            child: Text(
              'Your payment information is secure and protected. '
              'You will be redirected to Razorpay secure payment gateway.',
              style: AppTextStyles.of(
                figmaSize: 11,
                weight: FontWeight.w400,
                color: AppColors.navy,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM PAYMENT BAR
  // ============================================================

  Widget _buildBottomPaymentBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(18),
        AppTextStyles.fig(12),
        AppTextStyles.fig(18),
        AppTextStyles.fig(16),
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCardPurple,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppTextStyles.fig(125),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount',
                  style: AppTextStyles.of(
                    figmaSize: 11,
                    weight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),

                SizedBox(
                  height: AppTextStyles.fig(2),
                ),

                Text(
                  _money(widget.product.total),
                  style: AppTextStyles.of(
                    figmaSize: 22,
                    weight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: AppTextStyles.fig(48),
            color: AppColors.divider,
          ),

          SizedBox(
            width: AppTextStyles.fig(16),
          ),

          Expanded(
            child: SizedBox(
              height: AppTextStyles.fig(54),
              child: ElevatedButton(
                onPressed:
                    _isPaymentProcessing ? null : _payNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  disabledBackgroundColor:
                      AppColors.purple.withValues(
                    alpha: 0.6,
                  ),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isPaymentProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Pay Now',
                              overflow:
                                  TextOverflow.ellipsis,
                              style: AppTextStyles.of(
                                figmaSize: 15,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: AppTextStyles.fig(10),
                          ),

                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 25,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAY NOW
  // ============================================================

  Future<void> _payNow() async {
    FocusScope.of(context).unfocus();

    if (_selectedPaymentMethod.trim().isEmpty) {
      _showError(
        'Please select a payment method before proceeding.',
      );

      return;
    }

    // ----------------------------------------------------------
    // GET BACKEND ORDER ID
    // ----------------------------------------------------------

    final orderId = _getOrderIdFromCheckout();

    if (orderId == null || orderId <= 0) {
      _showError(
        'Unable to find the backend order ID. '
        'Please go back to checkout and try again.',
      );

      return;
    }

    setState(() {
      _topErrorMessage = null;
      _isCreatingPaymentOrder = true;
    });

    try {
      // --------------------------------------------------------
      // CREATE RAZORPAY ORDER
      // --------------------------------------------------------

      final paymentOrderResponse =
          await ApiService.createPaymentOrder(
        orderId: orderId,
      );

      if (!mounted) {
        return;
      }

      final razorpayOrderId =
          paymentOrderResponse['razorpay_order_id']
              ?.toString();

      final amount =
          _parseInt(paymentOrderResponse['amount']);

      final currency =
          paymentOrderResponse['currency']
              ?.toString()
              .trim();

      if (razorpayOrderId == null ||
          razorpayOrderId.isEmpty) {
        throw Exception(
          'Backend did not return a valid Razorpay order ID.',
        );
      }

      if (amount == null || amount <= 0) {
        throw Exception(
          'Backend did not return a valid payment amount.',
        );
      }

      if (currency == null || currency.isEmpty) {
        throw Exception(
          'Backend did not return a valid payment currency.',
        );
      }

      // --------------------------------------------------------
      // OPEN RAZORPAY
      // --------------------------------------------------------

      setState(() {
        _isCreatingPaymentOrder = false;
      });

      _openRazorpay(
        razorpayOrderId: razorpayOrderId,
        amount: amount,
        currency: currency,
        orderId: orderId,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingPaymentOrder = false;
      });

      _showError(
        _cleanError(error),
      );
    }
  }

  // ============================================================
  // OPEN RAZORPAY
  // ============================================================

  void _openRazorpay({
    required String razorpayOrderId,
    required int amount,
    required String currency,
    required int orderId,
  }) {
    final options = {
      // IMPORTANT:
      // This must be your Razorpay TEST KEY ID.
      //
      // Never put the Razorpay secret key in Flutter.
      'key': 'rzp_test_TRuOi385MuOzF7',

      'amount': amount,

      'currency': currency,

      'name': 'RentMitra',

      'description': widget.product.name,

      'order_id': razorpayOrderId,

      'prefill': {
        'name': widget.fullName,
        'email': widget.email,
        'contact': widget.mobile,
      },

      'notes': {
        'order_id': orderId.toString(),
        'payment_method': _selectedPaymentMethod,
      },

      'theme': {
        'color': '#6C3FBF',
      },
    };

    try {
      _razorpay.open(options);
    } catch (error) {
      _showError(
        'Unable to open Razorpay payment gateway.',
      );
    }
  }

  // ============================================================
  // RAZORPAY SUCCESS
  // ============================================================

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    final razorpayPaymentId =
        response.paymentId?.trim();

    final razorpayOrderId =
        response.orderId?.trim();

    final signature =
        response.signature?.trim();

    // ----------------------------------------------------------
    // VALIDATE RAZORPAY RESPONSE
    // ----------------------------------------------------------

    if (razorpayPaymentId == null ||
        razorpayPaymentId.isEmpty) {
      _showError(
        'Razorpay payment succeeded, but payment ID '
        'was not received.',
      );

      return;
    }

    if (razorpayOrderId == null ||
        razorpayOrderId.isEmpty) {
      _showError(
        'Razorpay payment succeeded, but Razorpay order ID '
        'was not received.',
      );

      return;
    }

    if (signature == null ||
        signature.isEmpty) {
      _showError(
        'Razorpay payment succeeded, but payment signature '
        'was not received.',
      );

      return;
    }

    // ----------------------------------------------------------
    // GET RENTMITRA ORDER ID
    // ----------------------------------------------------------

    final orderId = _getOrderIdFromCheckout();

    if (orderId == null || orderId <= 0) {
      _showError(
        'Payment was successful, but the RentMitra order ID '
        'could not be found.',
      );

      return;
    }

    // ----------------------------------------------------------
    // START RECORDING / VERIFYING PAYMENT
    // ----------------------------------------------------------

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecordingPayment = true;
      _topErrorMessage = null;
    });

    try {
      // --------------------------------------------------------
      // VERIFY PAYMENT ON BACKEND
      //
      // Backend verifies:
      //
      // razorpay_order_id
      // razorpay_payment_id
      // razorpay_signature
      //
      // using RAZORPAY_KEY_SECRET.
      // --------------------------------------------------------

      final verificationResponse =
          await ApiService.verifyPayment(
        orderId: orderId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: signature,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // CHECK BACKEND VERIFICATION STATUS
      // --------------------------------------------------------

      final verificationStatus =
          verificationResponse['verification_status']
              ?.toString()
              .trim();

      if (verificationStatus != 'Verified') {
        setState(() {
          _isRecordingPayment = false;
        });

        _showError(
          'Payment was received, but backend verification '
          'was not completed.',
        );

        return;
      }

      // --------------------------------------------------------
      // PAYMENT COMPLETELY VERIFIED
      // --------------------------------------------------------

      setState(() {
        _isRecordingPayment = false;
        _topErrorMessage = null;
      });

      // --------------------------------------------------------
      // GO TO RENTAL CONFIRMATION
      // --------------------------------------------------------

      _showPaymentSuccess(
        orderId: orderId,
        razorpayPaymentId: razorpayPaymentId,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRecordingPayment = false;
      });

      _showError(
        'Payment was received by Razorpay, but verification failed. '
        '${_cleanError(error)}',
      );
    }
  }

  // ============================================================
  // RAZORPAY PAYMENT ERROR
  // ============================================================

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    if (!mounted) {
      return;
    }

    final errorCode =
        response.code?.toString();

    final errorMessage =
        response.message?.toString().trim();

    String message;

    if (errorMessage != null &&
        errorMessage.isNotEmpty) {
      message = 'Payment failed: $errorMessage';
    } else {
      message =
          'Payment could not be completed. Please try again.';
    }

    if (errorCode != null &&
        errorCode.isNotEmpty) {
      message = '$message (Code: $errorCode)';
    }

    _showError(message);
  }

  // ============================================================
  // RAZORPAY EXTERNAL WALLET
  // ============================================================

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    if (!mounted) {
      return;
    }

    final walletName =
        response.walletName?.trim();

    _showError(
      walletName != null && walletName.isNotEmpty
          ? 'External wallet selected: $walletName'
          : 'External wallet selected.',
    );
  }

  // ============================================================
  // PAYMENT SUCCESS → RENTAL CONFIRMATION
  // ============================================================

  void _showPaymentSuccess({
    required int orderId,
    required String razorpayPaymentId,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RentalConfirmationScreen(
          product: widget.product,
          fullName: widget.fullName,
          mobile: widget.mobile,
          email: widget.email,
          houseFlatNumber:
              widget.houseFlatNumber,
          apartmentName:
              widget.apartmentName,
          streetArea:
              widget.streetArea,
          landmark:
              widget.landmark,
          city:
              widget.city,
          pincode:
              widget.pincode,
          orderId:
              orderId,
          razorpayPaymentId:
              razorpayPaymentId,
        ),
      ),
    );
  }

  // ============================================================
  // GET ORDER ID
  // ============================================================

  int? _getOrderIdFromCheckout() {
    final possibleKeys = [
      'order_id',
      'orderId',
      'id',
    ];

    for (final key in possibleKeys) {
      final value = widget.checkoutData[key];

      final parsed = _parseInt(value);

      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _topErrorMessage = message;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(
            AppTextStyles.fig(16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  // ============================================================
  // MONEY FORMAT
  // ============================================================

  String _money(int value) {
    final sign = value < 0 ? '-' : '';

    final number = value.abs().toString();

    final formatted = number.replaceAllMapped(
      RegExp(
        r'(\d)(?=(\d{3})+(?!\d))',
      ),
      (match) => '${match[1]},',
    );

    return '$sign₹$formatted';
  }
}