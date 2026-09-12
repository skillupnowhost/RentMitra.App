import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/customer_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({
    super.key,
  });

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _rentals = [];

  int? get _customerId {
    return CustomerSession.instance.customerId;
  }

  @override
  void initState() {
    super.initState();

    CustomerSession.instance.addListener(
      _onCustomerSessionChanged,
    );

    _loadRentals();
  }

  @override
  void dispose() {
    CustomerSession.instance.removeListener(
      _onCustomerSessionChanged,
    );

    super.dispose();
  }

  void _onCustomerSessionChanged() {
    if (!mounted) {
      return;
    }

    _loadRentals();
  }

  // ============================================================
  // LOAD RENTALS
  // ============================================================

  Future<void> _loadRentals() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final customerId = _customerId;

    if (customerId == null || customerId <= 0) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _customer = null;
        _rentals = [];
        _errorMessage = null;
      });

      return;
    }

    try {
      final response =
          await ApiService.getCustomerRentals(
        customerId: customerId,
      );

      Map<String, dynamic>? customer;

      final customerData = response['customer'];

      if (customerData is Map) {
        customer =
            Map<String, dynamic>.from(
          customerData,
        );
      }

      final List<Map<String, dynamic>> rentals = [];

      final rentalsData = response['rentals'];

      if (rentalsData is List) {
        for (final item in rentalsData) {
          if (item is Map) {
            rentals.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _customer = customer;
        _rentals = rentals;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            _cleanErrorMessage(error.toString());
      });
    }
  }

  String _cleanErrorMessage(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring(
        'Exception: '.length,
      );
    }

    return error;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'My Rentals',
          style: AppTextStyles.of(
            figmaSize: 24,
            weight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadRentals,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_customerId == null ||
        _customerId! <= 0) {
      return _buildNoCustomerState();
    }

    if (_rentals.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRentals,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24,
        ),
        children: [
          _buildCustomerCard(),

          const SizedBox(height: 18),

          _buildRentalCount(),

          const SizedBox(height: 12),

          ..._rentals.map(
            (rental) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 16),
              child: _buildRentalCard(rental),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER CARD
  // ============================================================

  Widget _buildCustomerCard() {
    final customer = _customer;

    final name =
        customer?['full_name']?.toString().trim() ??
            '';

    final mobile =
        customer?['mobile']?.toString().trim() ??
            '';

    final email =
        customer?['email']?.toString().trim() ??
            '';

    final firstLetter =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  AppColors.purple.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: AppTextStyles.of(
                  figmaSize: 22,
                  weight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty
                      ? 'Customer'
                      : name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 17,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),

                if (mobile.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+91 $mobile',
                    style: AppTextStyles.of(
                      figmaSize: 13,
                      weight: FontWeight.w400,
                      color:
                          AppColors.textGray,
                    ),
                  ),
                ],

                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: AppTextStyles.of(
                      figmaSize: 13,
                      weight: FontWeight.w400,
                      color:
                          AppColors.textGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTAL COUNT
  // ============================================================

  Widget _buildRentalCount() {
    final count = _rentals.length;

    return Text(
      count == 1
          ? '1 Rental'
          : '$count Rentals',
      style: AppTextStyles.of(
        figmaSize: 18,
        weight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  // ============================================================
  // RENTAL CARD
  // ============================================================

  Widget _buildRentalCard(
    Map<String, dynamic> rental,
  ) {
    final productName =
        rental['product_name']?.toString() ??
            'Rental Product';

    final variantName =
        rental['variant_name']?.toString() ??
            '';

    final category =
        rental['category']?.toString() ?? '';

    final orderId =
        rental['order_id']?.toString() ?? '-';

    final quantity =
        rental['quantity']?.toString() ?? '1';

    final monthlyRent =
        _formatMoney(rental['monthly_rent']);

    final paymentStatus =
        rental['payment_status']?.toString() ??
            'Pending';

    final rentalStatus =
        rental['rental_status']?.toString() ??
            '-';

    final orderStatus =
        rental['order_status']?.toString() ??
            'New Order';

    final startDate =
        _formatDate(rental['start_date']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // PRODUCT HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildProductIcon(
                  category: category,
                  productName: productName,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: AppTextStyles.of(
                          figmaSize: 17,
                          weight:
                              FontWeight.w700,
                          color:
                              AppColors.navy,
                        ),
                      ),

                      if (variantName
                          .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          variantName,
                          style:
                              AppTextStyles.of(
                            figmaSize: 13,
                            weight:
                                FontWeight.w400,
                            color: AppColors
                                .textGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _buildStatusChip(
                  orderStatus,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // RENTAL DETAILS
            // --------------------------------------------------

            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Order ID',
                    value: '#$orderId',
                  ),

                  const SizedBox(height: 10),

                  _buildDetailRow(
                    label: 'Quantity',
                    value: quantity,
                  ),

                  const SizedBox(height: 10),

                  _buildDetailRow(
                    label: 'Monthly Rent',
                    value: '₹$monthlyRent',
                    valueBold: true,
                  ),

                  const SizedBox(height: 10),

                  _buildDetailRow(
                    label: 'Payment',
                    value: paymentStatus,
                    valueWidget:
                        _buildPaymentStatus(
                      paymentStatus,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildDetailRow(
                    label: 'Rental',
                    value: rentalStatus,
                  ),

                  if (startDate != '-') ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      label: 'Start Date',
                      value: startDate,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TIMELINE TITLE
            // --------------------------------------------------

            Text(
              'Rental Progress',
              style: AppTextStyles.of(
                figmaSize: 16,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // TIMELINE
            // --------------------------------------------------

            _buildTimeline(orderStatus),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT ICON
  // ============================================================

  Widget _buildProductIcon({
    required String category,
    required String productName,
  }) {
    final text =
        '$category $productName'.toLowerCase();

    IconData icon;

    if (text.contains('ac') ||
        text.contains('air conditioner')) {
      icon = Icons.ac_unit_rounded;
    } else if (text.contains('refrigerator') ||
        text.contains('fridge')) {
      icon = Icons.kitchen_outlined;
    } else if (text.contains('washing') ||
        text.contains('washer')) {
      icon =
          Icons.local_laundry_service_outlined;
    } else if (text.contains('combo')) {
      icon =
          Icons.dashboard_customize_outlined;
    } else {
      icon =
          Icons.home_repair_service_outlined;
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color:
            AppColors.purple.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: AppColors.purple,
        size: 30,
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String status,
  ) {
    final isActive =
        status == 'Active Rental';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(
                alpha: 0.10,
              )
            : AppColors.purple.withValues(
                alpha: 0.10,
              ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive
              ? Colors.green.shade700
              : AppColors.purple,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Widget _buildPaymentStatus(
    String status,
  ) {
    final verified =
        status.toLowerCase() == 'verified';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified
              ? Icons.check_circle_rounded
              : Icons.pending_outlined,
          size: 15,
          color: verified
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ),
        const SizedBox(width: 5),
        Text(
          status,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: verified
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow({
    required String label,
    required String value,
    Widget? valueWidget,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.of(
              figmaSize: 13,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ),
        if (valueWidget != null)
          valueWidget
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.of(
                figmaSize: 13,
                weight: valueBold
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Widget _buildTimeline(
    String currentStatus,
  ) {
    const steps = [
      _TimelineStepData(
        title: 'Order Placed',
        backendStatus: 'New Order',
        icon:
            Icons.shopping_bag_outlined,
      ),
      _TimelineStepData(
        title: 'Payment Verified',
        backendStatus: 'Payment Verified',
        icon: Icons.verified_outlined,
      ),
      _TimelineStepData(
        title: 'Delivery Assigned',
        backendStatus: 'Delivery Assigned',
        icon:
            Icons.local_shipping_outlined,
      ),
      _TimelineStepData(
        title: 'Installation Scheduled',
        backendStatus:
            'Installation Scheduled',
        icon: Icons.build_outlined,
      ),
      _TimelineStepData(
        title: 'Delivered',
        backendStatus: 'Delivered',
        icon: Icons.home_outlined,
      ),
      _TimelineStepData(
        title: 'Active Rental',
        backendStatus: 'Active Rental',
        icon: Icons.autorenew_rounded,
      ),
    ];

    final currentIndex =
        _statusIndex(currentStatus);

    return Column(
      children: List.generate(
        steps.length,
        (index) {
          final step = steps[index];

          final completed =
              index <= currentIndex;

          final isCurrent =
              index == currentIndex;

          final isLast =
              index == steps.length - 1;

          return _buildTimelineItem(
            step: step,
            completed: completed,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({
    required _TimelineStepData step,
    required bool completed,
    required bool isCurrent,
    required bool isLast,
  }) {
    final Color circleColor =
        completed
            ? AppColors.purple
            : Colors.grey.shade300;

    final textColor =
        completed
            ? AppColors.navy
            : Colors.grey.shade500;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 250,
                ),
                width:
                    isCurrent ? 32 : 28,
                height:
                    isCurrent ? 32 : 28,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors
                                .purple
                                .withValues(
                              alpha: 0.22,
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : step.icon,
                  size:
                      isCurrent ? 18 : 16,
                  color: completed
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 34,
                  color: completed
                      ? AppColors.purple
                          .withValues(
                          alpha: 0.35,
                        )
                      : Colors.grey.shade300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 4,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: isCurrent
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Current status',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          AppColors.purple,
                    ),
                  ),
                ],
                if (!isLast)
                  const SizedBox(
                    height: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS INDEX
  // ============================================================

  int _statusIndex(
    String status,
  ) {
    switch (status) {
      case 'New Order':
        return 0;

      case 'Payment Verified':
        return 1;

      case 'Delivery Assigned':
        return 2;

      case 'Installation Scheduled':
        return 3;

      case 'Delivered':
        return 4;

      case 'Active Rental':
        return 5;

      default:
        return 0;
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadRentals,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.home_work_outlined,
            size: 70,
            color:
                AppColors.purple.withValues(
              alpha: 0.45,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Rentals Yet',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 22,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your rental orders will appear here '
            'after a successful payment.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO CUSTOMER STATE
  // ============================================================

  Widget _buildNoCustomerState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 70,
              color:
                  AppColors.purple.withValues(
                alpha: 0.45,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Customer Account',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 22,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your rentals will appear here after '
              'your first successful payment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 14,
                weight: FontWeight.w400,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to Load Rentals',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 20,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 13,
                weight: FontWeight.w400,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRentals,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT MONEY
  // ============================================================

  String _formatMoney(dynamic value) {
    if (value == null) {
      return '0';
    }

    final number =
        double.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final date =
        DateTime.tryParse(value.toString());

    if (date == null) {
      return '-';
    }

    final localDate = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${localDate.day.toString().padLeft(2, '0')} '
        '${months[localDate.month - 1]} '
        '${localDate.year}';
  }

  // ============================================================
  // DISPLAY STATUS
  // ============================================================

  String _displayStatus(String status) {
    switch (status) {
      case 'New Order':
        return 'Order Placed';

      case 'Payment Verified':
        return 'Payment Verified';

      case 'Delivery Assigned':
        return 'Delivery Assigned';

      case 'Installation Scheduled':
        return 'Installation';

      case 'Delivered':
        return 'Delivered';

      case 'Active Rental':
        return 'Active Rental';

      default:
        return status;
    }
  }
}

// ================================================================
// TIMELINE DATA
// ================================================================

class _TimelineStepData {
  final String title;
  final String backendStatus;
  final IconData icon;

  const _TimelineStepData({
    required this.title,
    required this.backendStatus,
    required this.icon,
  });
}