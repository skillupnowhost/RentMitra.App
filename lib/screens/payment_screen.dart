import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'checkout_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.product,
  });

  final CheckoutProduct product;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'UPI';

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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(8),
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(120),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(),

                        SizedBox(
                          height: AppTextStyles.fig(20),
                        ),

                        _buildPaymentHeader(),

                        SizedBox(
                          height: AppTextStyles.fig(12),
                        ),

                        _buildPaymentMethod(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'UPI',
                          subtitle: 'Pay using Google Pay, PhonePe, Paytm etc.',
                          value: 'UPI',
                        ),

                        _buildPaymentMethod(
                          icon: Icons.credit_card_outlined,
                          title: 'Credit / Debit Card',
                          subtitle: 'Visa, Mastercard, RuPay and more',
                          value: 'Credit / Debit Card',
                        ),

                        _buildPaymentMethod(
                          icon: Icons.account_balance_outlined,
                          title: 'Net Banking',
                          subtitle: 'Pay directly through your bank',
                          value: 'Net Banking',
                        ),

                        SizedBox(
                          height: AppTextStyles.fig(20),
                        ),

                        _buildPriceDetails(),
                      ],
                    ),
                  ),
                ),

                _buildBottomPaymentBar(),
              ],
            ),
          ),
        ),
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
            onTap: () => Navigator.of(context).maybePop(),
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

          // Keeps the title centered.
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
            color: Colors.black.withOpacity(0.04),
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
            height: AppTextStyles.fig(12),
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

        Column(
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
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(
          bottom: AppTextStyles.fig(10),
        ),
        padding: EdgeInsets.all(
          AppTextStyles.fig(14),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
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

  Widget _priceRow(
    String title,
    int amount, {
    Color? valueColor,
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
              color: AppColors.navy,
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
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Column(
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

          SizedBox(
            width: AppTextStyles.fig(16),
          ),

          Expanded(
            child: SizedBox(
              height: AppTextStyles.fig(54),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payment integration will be connected later.',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Pay Now',
                  style: AppTextStyles.of(
                    figmaSize: 15,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(int value) {
    final sign = value < 0 ? '-' : '';
    final number = value.abs().toString();

    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return '$sign₹$formatted';
  }
}