import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_sidebar.dart';
import 'admin_orders_style_shell.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _payments = <Map<String, dynamic>>[];
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final TextEditingController _searchController = TextEditingController();

  TextStyle _style({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.navy,
    double? letterSpacing,
    double? height,
  }) {
    return AppTextStyles.of(
      figmaSize: size,
      weight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getAdminPayments();
      final Map<String, Map<String, dynamic>> unique =
          <String, Map<String, dynamic>>{};

      for (final payment in result) {
        final rawId = payment['payment_id'];
        if (rawId == null) continue;

        final id = rawId.toString().trim();
        if (id.isEmpty) continue;

        unique[id] = Map<String, dynamic>.from(payment);
      }

      final payments = unique.values.toList();
      payments.sort((a, b) {
        final aId = int.tryParse('${a['payment_id'] ?? 0}') ?? 0;
        final bId = int.tryParse('${b['payment_id'] ?? 0}') ?? 0;
        return bId.compareTo(aId);
      });

      if (!mounted) return;
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    final query = _searchQuery.trim().toLowerCase();

    return _payments.where((payment) {
      final status = _status(payment);
      final statusMatches =
          _selectedStatus == 'All' || status == _selectedStatus.toLowerCase();

      if (!statusMatches) return false;
      if (query.isEmpty) return true;

      final values = <String>[
        '${payment['payment_id'] ?? ''}',
        '${payment['order_id'] ?? ''}',
        '${payment['razorpay_order_id'] ?? ''}',
        '${payment['razorpay_payment_id'] ?? ''}',
        '${payment['payment_status'] ?? ''}',
        '${payment['verification_status'] ?? ''}',
      ];

      return values.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  int get _totalPayments => _payments.length;

  int get _verifiedPayments => _payments.where((payment) {
        return _status(payment) == 'verified';
      }).length;

  int get _pendingPayments => _payments.where((payment) {
        return _status(payment) == 'pending';
      }).length;

  String _status(Map<String, dynamic> payment) {
    final verification =
        '${payment['verification_status'] ?? ''}'.trim().toLowerCase();
    final paymentStatus =
        '${payment['payment_status'] ?? ''}'.trim().toLowerCase();

    if (verification == 'verified' || paymentStatus == 'verified') {
      return 'verified';
    }
    if (verification == 'failed' || paymentStatus == 'failed') {
      return 'failed';
    }
    return 'pending';
  }

  String _displayStatus(Map<String, dynamic> payment) {
    final status = _status(payment);
    return status[0].toUpperCase() + status.substring(1);
  }

  String _value(dynamic value) {
    if (value == null) return '—';
    final text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '₹0.00';

    final amount = double.tryParse(value.toString()) ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return _value(value);

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    var hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour %= 12;
    if (hour == 0) hour = 12;

    return '$day/$month/$year ${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment Details',
                          style: _style(
                            size: 26,
                            weight: FontWeight.w800,
                            color: AppColors.navyDeep,
                          ),
                        ),
                      ),
                      _StatusChip(status: _displayStatus(payment)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailTile(
                    icon: Icons.payments_outlined,
                    title: 'Payment ID',
                    value: '#${_value(payment['payment_id'])}',
                  ),
                  _DetailTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order ID',
                    value: '#${_value(payment['order_id'])}',
                  ),
                  _DetailTile(
                    icon: Icons.currency_rupee,
                    title: 'Amount',
                    value: _formatAmount(payment['amount']),
                  ),
                  _DetailTile(
                    icon: Icons.verified_outlined,
                    title: 'Verification Status',
                    value: _value(payment['verification_status']),
                  ),
                  _DetailTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Razorpay Order ID',
                    value: _value(payment['razorpay_order_id']),
                  ),
                  _DetailTile(
                    icon: Icons.credit_card_outlined,
                    title: 'Razorpay Payment ID',
                    value: _value(payment['razorpay_payment_id']),
                  ),
                  _DetailTile(
                    icon: Icons.schedule_outlined,
                    title: 'Payment Date',
                    value: _formatDate(payment['payment_timestamp']),
                  ),
                  _DetailTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Created At',
                    value: _formatDate(payment['created_at']),
                  ),
                  _DetailTile(
                    icon: Icons.update_outlined,
                    title: 'Updated At',
                    value: _formatDate(payment['updated_at']),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: _style(
                          size: 17,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _logoIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.ctaPurple,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.home_work_outlined,
        color: Colors.white,
        size: 21,
      ),
    );
  }

  Widget _buildSidebar() {
    return const SizedBox(width: 250, child: AdminSidebar(compact: false));
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      child: AdminSidebar(
        compact: false,
        onNavigate: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildTopBar({required bool mobile}) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          if (mobile)
            Builder(
              builder: (context) => IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 42,
                ),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(
                  Icons.menu,
                  size: 27,
                  color: AppColors.navyDeep,
                ),
              ),
            ),
          if (mobile) const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Payments',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _style(
                size: 30,
                weight: FontWeight.w800,
                color: AppColors.navyDeep,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadPayments,
            icon: const Icon(
              Icons.refresh_outlined,
              size: 22,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bgCardPurple,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.ctaPurple,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader({required bool mobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Management',
          style: _style(
            size: 42,
            weight: FontWeight.w800,
            color: AppColors.navyDeep,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage payment transactions and verification details',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _style(
            size: 21,
            color: AppColors.textGray,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildKpis({required bool mobile}) {
    final cards = [
      _KpiCard(
        title: 'Total Payments',
        value: '$_totalPayments',
        icon: Icons.payments_outlined,
        iconColor: AppColors.ctaPurple,
        background: AppColors.bgCardPurple,
      ),
      _KpiCard(
        title: 'Verified Payments',
        value: '$_verifiedPayments',
        icon: Icons.verified_outlined,
        iconColor: AppColors.categoryGreen,
        background: AppColors.bgCardNeutral,
      ),
      _KpiCard(
        title: 'Pending Payments',
        value: '$_pendingPayments',
        icon: Icons.pending_outlined,
        iconColor: AppColors.brandOrange,
        background: AppColors.bgCardPeach,
      ),
    ];

    if (mobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 560;

          if (twoColumns) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 14),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 14),
                cards[2],
              ],
            );
          }

          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
            ],
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildFilters({required bool mobile}) {
    const statuses = ['All', 'Verified', 'Pending', 'Failed'];

    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            textInputAction: TextInputAction.search,
            style: _style(
              size: 15,
              weight: FontWeight.w500,
              color: AppColors.navy,
            ),
            decoration: InputDecoration(
              hintText: 'Search payments...',
              hintStyle: _style(
                size: 15,
                color: AppColors.textGraySoft,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 28,
                color: AppColors.textGray,
              ),
              filled: true,
              fillColor: AppColors.bgCardLavender,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.ctaPurple,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 500;
              return Row(
                children: statuses.map((status) {
                  final selected = _selectedStatus == status;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: status == statuses.last ? 0 : 8,
                      ),
                      child: _FilterButton(
                        label: status,
                        selected: selected,
                        compact: compact,
                        onTap: () {
                          setState(() => _selectedStatus = status);
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    if (_filteredPayments.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: _filteredPayments.map((payment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PaymentCard(
            payment: payment,
            status: _displayStatus(payment),
            amount: _formatAmount(payment['amount']),
            date: _formatDate(payment['payment_timestamp']),
            onDetails: () => _showPaymentDetails(payment),
            style: _style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable() {
    if (_filteredPayments.isEmpty) {
      return const _EmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          horizontalMargin: 20,
          headingRowHeight: 52,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 82,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFD)),
          columns: [
            _column('Payment'),
            _column('Order'),
            _column('Amount'),
            _column('Status'),
            _column('Verification'),
            _column('Payment Date'),
            const DataColumn(label: SizedBox(width: 92)),
          ],
          rows: _filteredPayments.map((payment) {
            final status = _displayStatus(payment);
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '#${_value(payment['payment_id'])}',
                    style: _style(
                      size: 21,
                      weight: FontWeight.w800,
                      color: AppColors.navyDeep,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '#${_value(payment['order_id'])}',
                    style: _style(size: 20, weight: FontWeight.w700),
                  ),
                ),
                DataCell(
                  Text(
                    _formatAmount(payment['amount']),
                    style: _style(
                      size: 21,
                      weight: FontWeight.w800,
                      color: AppColors.navyDeep,
                    ),
                  ),
                ),
                DataCell(_StatusChip(status: status)),
                DataCell(
                  Text(
                    _value(payment['verification_status']),
                    style: _style(
                      size: 19,
                      weight: FontWeight.w800,
                      color: _statusColor(_status(payment)),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(payment['payment_timestamp']),
                    style: _style(
                      size: 17,
                      weight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
                DataCell(
                  TextButton(
                    onPressed: () => _showPaymentDetails(payment),
                    child: Text(
                      'View Details',
                      style: _style(
                        size: 18,
                        weight: FontWeight.w800,
                        color: AppColors.ctaPurple,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DataColumn _column(String title) {
    return DataColumn(
      label: Text(
        title,
        style: _style(
          size: 18,
          weight: FontWeight.w800,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.categoryGreen;
      case 'failed':
        return Colors.red.shade600;
      default:
        return AppColors.brandOrange;
    }
  }

  Widget _buildBody({required bool mobile}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ctaPurple),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 44,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load payments',
                    textAlign: TextAlign.center,
                    style: _style(
                      size: 18,
                      weight: FontWeight.w800,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: _style(
                      size: 17,
                      weight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _loadPayments,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      'Retry',
                      style: _style(
                        size: 22.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.ctaPurple,
      onRefresh: _loadPayments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 28,
          mobile ? 18 : 26,
          mobile ? 16 : 28,
          30,
        ),
        children: [
          _buildPageHeader(mobile: mobile),
          SizedBox(height: mobile ? 18 : 24),
          _buildKpis(mobile: mobile),
          SizedBox(height: mobile ? 18 : 24),
          _buildFilters(mobile: mobile),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_filteredPayments.length} payment${_filteredPayments.length == 1 ? '' : 's'}',
                  style: _style(
                    size: mobile ? 17 : 18,
                    weight: FontWeight.w800,
                    color: AppColors.navyDeep,
                  ),
                ),
              ),
              if (_selectedStatus != 'All')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedStatus,
                    style: _style(
                      size: 11,
                      weight: FontWeight.w800,
                      color: AppColors.ctaPurple,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (mobile)
            _buildMobileList()
          else
            _buildDesktopTable(),
        ],
      ),
    );
  }

  List<AdminOrdersStyleStat> _ordersStylePaymentStats() => [
        AdminOrdersStyleStat(title: 'Total Payments', value: '$_totalPayments', icon: Icons.payments_outlined, iconBackground: const Color(0xFFEDEAFF), iconColor: AppColors.ctaPurple),
        AdminOrdersStyleStat(title: 'Verified Payments', value: '$_verifiedPayments', icon: Icons.verified_rounded, iconBackground: const Color(0xFFE7F7ED), iconColor: Colors.green),
        AdminOrdersStyleStat(title: 'Pending Payments', value: '$_pendingPayments', icon: Icons.pending_outlined, iconBackground: const Color(0xFFFFF1DE), iconColor: Colors.orange),
        AdminOrdersStyleStat(title: 'Failed Payments', value: '${_payments.where((p) => _status(p) == 'failed').length}', icon: Icons.error_outline_rounded, iconBackground: const Color(0xFFFFE8E8), iconColor: Colors.red),
      ];

  Widget _ordersStylePaymentFilters() => AdminOrdersStyleFilterRow(
        controller: _searchController,
        hintText: 'Search payment, order or Razorpay ID...',
        selectedValue: _selectedStatus,
        values: const ['All', 'Verified', 'Pending', 'Failed'],
        onChanged: (value) { if (value != null) setState(() => _selectedStatus = value); },
        onSearchChanged: (value) => setState(() => _searchQuery = value),
        onClear: () { _searchController.clear(); setState(() => _searchQuery = ''); },
      );

  Widget _ordersStylePaymentContent() {
    if (_isLoading) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: AppColors.ctaPurple)));
    if (_errorMessage != null) return _buildErrorState();
    if (_filteredPayments.isEmpty) return const _EmptyState();
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 900 ? _buildDesktopTable() : _buildMobileList());
  }

  @override
  Widget build(BuildContext context) {
    return AdminOrdersStyleShell(
      title: 'Payments',
      subtitle: 'Manage payment transactions and verification details',
      refresh: _loadPayments,
      stats: _ordersStylePaymentStats(),
      filters: _ordersStylePaymentFilters(),
      content: _ordersStylePaymentContent(),
    );
  }



  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          Text(
            'Unable to load payments',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 27,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 20.5,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 900;
    final compact = width < 560;

    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 108 : mobile ? 122 : 142,
      ),
      padding: EdgeInsets.all(compact ? 14 : mobile ? 16 : 20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 52 : 62,
            height: compact ? 52 : 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: compact ? 26 : 30,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: (compact ? 13 : 15) * 1.20,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: AppTextStyles.of(
                    figmaSize: (compact ? 28 : 34) * 1.20,
                    weight: FontWeight.w800,
                    color: AppColors.navyDeep,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 48 : 54,
      child: Material(
        color: selected ? AppColors.ctaPurple : AppColors.bgCardLavender,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.of(
                figmaSize: (compact ? 13 : 14) * 1.20,
                weight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.navyDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final Color foreground;
    final Color background;

    if (normalized == 'verified') {
      foreground = AppColors.categoryGreen;
      background = AppColors.bgCardNeutral;
    } else if (normalized == 'failed') {
      foreground = Colors.red.shade600;
      background = Colors.red.shade50;
    } else {
      foreground = AppColors.brandOrange;
      background = AppColors.bgCardPeach;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: AppTextStyles.of(
          figmaSize: 12 * 1.20,
          weight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.status,
    required this.amount,
    required this.date,
    required this.onDetails,
    required this.style,
  });

  final Map<String, dynamic> payment;
  final String status;
  final String amount;
  final String date;
  final VoidCallback onDetails;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double? letterSpacing,
    double? height,
  }) style;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final statusColor = normalized == 'verified'
        ? AppColors.categoryGreen
        : normalized == 'failed'
            ? Colors.red.shade600
            : AppColors.brandOrange;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: normalized == 'verified'
                      ? AppColors.bgCardNeutral
                      : normalized == 'failed'
                          ? Colors.red.shade50
                          : AppColors.bgCardPeach,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment #${payment['payment_id'] ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(
                        size: 18,
                        weight: FontWeight.w800,
                        color: AppColors.navyDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${payment['order_id'] ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(
                        size: 14,
                        weight: FontWeight.w500,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.bgCardLavender,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: style(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(
                          size: 21,
                          weight: FontWeight.w800,
                          color: AppColors.navyDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification',
                          style: style(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${payment['verification_status'] ?? 'Pending'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style(
                            size: 15,
                            weight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 21,
                color: AppColors.textGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: style(
                        size: 13,
                        weight: FontWeight.w800,
                        color: AppColors.ctaPurple,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.ctaPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.bgCardLavender,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.ctaPurple),
            const SizedBox(width: 11),
            Expanded(
              flex: 4,
              child: Text(
                title,
                style: AppTextStyles.of(
                  figmaSize: 15,
                  weight: FontWeight.w700,
                  color: AppColors.textGray,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 17,
                  weight: FontWeight.w800,
                  color: AppColors.navyDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 46,
            color: AppColors.textGraySoft,
          ),
          const SizedBox(height: 12),
          Text(
            'No payments found',
            style: AppTextStyles.of(
              figmaSize: 18 * 1.20,
              weight: FontWeight.w800,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try changing the search or payment filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 13 * 1.20,
              weight: FontWeight.w500,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}
