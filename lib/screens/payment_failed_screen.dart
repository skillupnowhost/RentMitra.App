
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/rent_pricing.dart';
import 'checkout_screen.dart';

class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({
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
    this.errorMessage,
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

  final Map<String, dynamic> checkoutData;

  final String? errorMessage;

  // Sourced from the backend's checkout response — the rent actually
  // locked into the order that failed to pay, not re-derived here.
  RentBreakdown get _breakdown {
    final rent = num.tryParse(
      checkoutData['monthly_rent']?.toString() ?? '',
    );

    return RentBreakdown.fromRent(rent ?? 0, isCombo: product.isCombo);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 520.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTextStyles.fig(20),
                AppTextStyles.fig(24),
                AppTextStyles.fig(20),
                AppTextStyles.fig(20),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: AppTextStyles.fig(30),
                          ),

                          // ------------------------------------------------
                          // FAILURE ICON
                          // ------------------------------------------------

                          Container(
                            width: AppTextStyles.fig(110),
                            height: AppTextStyles.fig(110),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: AppTextStyles.fig(82),
                                height: AppTextStyles.fig(82),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: EdgeInsets.all(
                                    AppTextStyles.fig(8),
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.shade600,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: AppTextStyles.fig(46),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: AppTextStyles.fig(24),
                          ),

                          Text(
                            'Payment Failed',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.of(
                              figmaSize: 27,
                              weight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),

                          SizedBox(
                            height: AppTextStyles.fig(8),
                          ),

                          Text(
                            'Your payment could not be completed.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.of(
                              figmaSize: 14,
                              weight: FontWeight.w400,
                              color: AppColors.textGray,
                              height: 1.4,
                            ),
                          ),

                          SizedBox(
                            height: AppTextStyles.fig(24),
                          ),

                          // ------------------------------------------------
                          // ERROR MESSAGE
                          // ------------------------------------------------

                          if (errorMessage != null &&
                              errorMessage!.trim().isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                AppTextStyles.fig(14),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(11),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                      errorMessage!,
                                      style: AppTextStyles.of(
                                        figmaSize: 12,
                                        weight: FontWeight.w500,
                                        color:
                                            Colors.red.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(
                            height: AppTextStyles.fig(20),
                          ),

                          // ------------------------------------------------
                          // ORDER SUMMARY
                          // ------------------------------------------------

                          _card(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Summary',
                                  style: AppTextStyles.of(
                                    figmaSize: 17,
                                    weight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),

                                SizedBox(
                                  height:
                                      AppTextStyles.fig(14),
                                ),

                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(
                                    AppTextStyles.fig(12),
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.bgCardPurple,
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width:
                                            AppTextStyles.fig(
                                          68,
                                        ),
                                        height:
                                            AppTextStyles.fig(
                                          68,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                AppColors.divider,
                                          ),
                                        ),
                                        child: Icon(
                                          _productIcon(product),
                                          color:
                                              AppColors.purple,
                                          size:
                                              AppTextStyles.fig(
                                            34,
                                          ),
                                        ),
                                      ),

                                      SizedBox(
                                        width:
                                            AppTextStyles.fig(
                                          12,
                                        ),
                                      ),

                                      Expanded(
                                        child: Text(
                                          product.name,
                                          maxLines: 3,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style:
                                              AppTextStyles.of(
                                            figmaSize: 15,
                                            weight:
                                                FontWeight.w700,
                                            color:
                                                AppColors.navy,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(
                                  height:
                                      AppTextStyles.fig(14),
                                ),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Monthly Amount',
                                        style:
                                            AppTextStyles.of(
                                          figmaSize: 13,
                                          weight:
                                              FontWeight.w500,
                                          color:
                                              AppColors.navy,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _money(_breakdown.total),
                                      style:
                                          AppTextStyles.of(
                                        figmaSize: 18,
                                        weight:
                                            FontWeight.w800,
                                        color:
                                            AppColors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: AppTextStyles.fig(16),
                          ),

                          // ------------------------------------------------
                          // INFORMATION
                          // ------------------------------------------------

                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              AppTextStyles.fig(14),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCardPurple,
                              borderRadius:
                                  BorderRadius.circular(11),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.purple,
                                  size: 22,
                                ),

                                SizedBox(
                                  width:
                                      AppTextStyles.fig(10),
                                ),

                                Expanded(
                                  child: Text(
                                    'No amount has been confirmed as a '
                                    'successful payment through this attempt. '
                                    'You can return to checkout and try again.',
                                    style:
                                        AppTextStyles.of(
                                      figmaSize: 12,
                                      weight:
                                          FontWeight.w400,
                                      color:
                                          AppColors.navy,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --------------------------------------------------------
                  // BOTTOM BUTTONS
                  // --------------------------------------------------------

                  SizedBox(
                    height: AppTextStyles.fig(14),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: AppTextStyles.fig(54),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 23,
                          ),

                          SizedBox(
                            width:
                                AppTextStyles.fig(10),
                          ),

                          Text(
                            'Try Payment Again',
                            style:
                                AppTextStyles.of(
                              figmaSize: 15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: AppTextStyles.fig(10),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: AppTextStyles.fig(50),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.purple,
                        side: const BorderSide(
                          color: AppColors.purple,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Go to Home',
                        style:
                            AppTextStyles.of(
                          figmaSize: 15,
                          weight:
                              FontWeight.w600,
                          color:
                              AppColors.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
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
      child: child,
    );
  }

  IconData _productIcon(
    CheckoutProduct product,
  ) {
    final name = product.name.toLowerCase();

    if (name.contains('ac') ||
        name.contains('air conditioner')) {
      return Icons.ac_unit_outlined;
    }

    if (name.contains('refrigerator') ||
        name.contains('fridge')) {
      return Icons.kitchen_outlined;
    }

    if (name.contains('washing')) {
      return Icons.local_laundry_service_outlined;
    }

    if (product.isCombo) {
      return Icons.home_work_outlined;
    }

    return Icons.home_repair_service_outlined;
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

