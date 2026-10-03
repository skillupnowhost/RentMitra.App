import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_orders_style_shell.dart';

class AdminInstallationsScreen extends StatefulWidget {
  const AdminInstallationsScreen({super.key});

  @override
  State<AdminInstallationsScreen> createState() =>
      _AdminInstallationsScreenState();
}

class _AdminInstallationsScreenState
    extends State<AdminInstallationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _installations = [];

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'All';
  DateTime? _selectedDate;

  // Orders that have Delivery Assigned but do not yet have an installation.
  List<Map<String, dynamic>> _pendingInstallationOrders = [];

  // Delivery assignments keyed by order_id.
  // This is loaded separately because /admin/orders does not expose the
  // delivery_partners relationship.
  final Map<String, Map<String, dynamic>> _deliveryAssignments = {};

  List<Map<String, dynamic>> _installationPartners = [];
  bool _isLoadingInstallationPartners = false;
  String? _installationPartnersError;

  int? _selectedInstallationPartnerId;
  DateTime? _selectedInstallationDate;
  TimeOfDay? _selectedInstallationTime;
  bool _isSchedulingInstallation = false;

  // ============================================================
  // PAGINATION
  // ============================================================

  static const int _rowsPerPage = 10;
  int _currentPage = 1;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_applyFilters);

    _loadInstallations();
    _loadInstallationPartners();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD INSTALLATIONS
  // ============================================================

  Future<void> _loadInstallations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Load installations first. The installation API contains the
      // installation/schedule fields, while customer and address data
      // comes from the admin orders API.
      final List<Map<String, dynamic>> installations =
          await ApiService.getAdminInstallations();

      // Load orders separately instead of using Future.wait().
      // This avoids Dart inferring Future.wait() as List<Object>.
      final dynamic ordersResponse =
          await ApiService.getAdminOrders();

      dynamic rawOrders;

      if (ordersResponse is Map) {
        rawOrders = ordersResponse['orders'];
      } else if (ordersResponse is List) {
        rawOrders = ordersResponse;
      }

      final List<Map<String, dynamic>> orders =
          rawOrders is List
              ? rawOrders
                  .whereType<Map>()
                  .map(
                    (item) => Map<String, dynamic>.from(item),
                  )
                  .toList()
              : <Map<String, dynamic>>[];

      // Delivery assignment is stored in deliveries, not in orders.
      // Load it once and merge it into the order/installation records.
      final List<Map<String, dynamic>> deliveryAssignments =
          await ApiService.getDeliveryAssignments();

      _deliveryAssignments.clear();

      for (final delivery in deliveryAssignments) {
        final orderId = delivery['order_id']?.toString().trim() ?? '';

        if (orderId.isEmpty) continue;

        _deliveryAssignments[orderId] = delivery;
      }

      // Add the assigned delivery partner fields to every order.
      // This is what the Pending Installation cards read.
      for (final order in orders) {
        final orderId = order['order_id']?.toString().trim() ?? '';
        final delivery = _deliveryAssignments[orderId];

        if (delivery == null) continue;

        order['delivery_id'] = delivery['delivery_id'];
        order['delivery_partner_id'] = delivery['delivery_partner_id'];
        order['delivery_status'] = delivery['delivery_status'];
        order['delivery_partner_name'] = delivery['partner_name'];
        order['delivery_partner_contact_person'] =
            delivery['contact_person'];
        order['delivery_partner_mobile'] = delivery['mobile'];
      }

      await _loadPendingInstallationOrders(orders, installations);

      // Build a quick lookup using order_id.
      final Map<String, Map<String, dynamic>> orderLookup = {};

      for (final order in orders) {
        final String orderId =
            order['order_id']?.toString().trim() ?? '';

        if (orderId.isEmpty) {
          continue;
        }

        orderLookup[orderId] = order;
      }

      // Merge customer and address information into each installation.
      final List<Map<String, dynamic>> mergedInstallations = [];

      for (final installation in installations) {
        final Map<String, dynamic> merged =
            Map<String, dynamic>.from(installation);

        final String orderId =
            installation['order_id']?.toString().trim() ?? '';

        if (orderId.isNotEmpty) {
          final Map<String, dynamic>? order =
              orderLookup[orderId];

          if (order != null) {
            merged['customer_id'] = order['customer_id'];
            merged['customer_name'] = order['full_name'];
            merged['customer_mobile'] = order['mobile'];
            merged['customer_email'] = order['email'];

            merged['address_id'] = order['address_id'];
            merged['house_flat_number'] =
                order['house_flat_number'];
            merged['apartment_name'] = order['apartment_name'];
            merged['street_area'] = order['street_area'];
            merged['landmark'] = order['landmark'];
            merged['city'] = order['city'];
            merged['pincode'] = order['pincode'];
          }
        }

        final delivery = _deliveryAssignments[orderId];

        if (delivery != null) {
          merged['delivery_id'] = delivery['delivery_id'];
          merged['delivery_partner_id'] =
              delivery['delivery_partner_id'];
          merged['delivery_status'] = delivery['delivery_status'];
          merged['delivery_partner_name'] = delivery['partner_name'];
          merged['delivery_partner_contact_person'] =
              delivery['contact_person'];
          merged['delivery_partner_mobile'] = delivery['mobile'];
        }

        mergedInstallations.add(merged);
      }

      if (!mounted) return;

      setState(() {
        _installations = mergedInstallations;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadInstallationPartners() async {
    if (_isLoadingInstallationPartners) return;

    if (mounted) {
      setState(() {
        _isLoadingInstallationPartners = true;
        _installationPartnersError = null;
      });
    }

    try {
      final partners = await ApiService.getAdminInstallationPartners();

      if (!mounted) return;

      setState(() {
        _installationPartners = partners.where((partner) {
          final status = partner['partner_status']?.toString().trim().toLowerCase();
          return status == null || status.isEmpty || status == 'active';
        }).toList();
        _isLoadingInstallationPartners = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingInstallationPartners = false;
        _installationPartnersError = _cleanErrorMessage(error);
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  Future<void> _loadPendingInstallationOrders(
    List<Map<String, dynamic>> orders,
    List<Map<String, dynamic>> installations,
  ) async {
    final installedOrderIds = installations
        .map((item) => item['order_id']?.toString().trim())
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => id!)
        .toSet();

    final pending = <Map<String, dynamic>>[];

    for (final order in orders) {
      final orderId = order['order_id']?.toString().trim() ?? '';
      final status = order['order_status']?.toString().trim().toLowerCase() ?? '';

      if (orderId.isEmpty) continue;
      if (status != 'delivery assigned') continue;
      if (installedOrderIds.contains(orderId)) continue;

      pending.add(Map<String, dynamic>.from(order));
    }

    if (!mounted) return;

    setState(() {
      _pendingInstallationOrders = pending;
    });
  }

  Future<void> _pickInstallationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedInstallationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.ctaPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDeep,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedInstallationDate = picked;
    });
  }

  Future<void> _pickInstallationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedInstallationTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.ctaPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDeep,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedInstallationTime = picked;
    });
  }

  String _displayInstallationDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _displayInstallationTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _apiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _apiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _scheduleInstallation(
    Map<String, dynamic> order,
  ) async {
    final orderId = int.tryParse(order['order_id']?.toString() ?? '');
    final partnerId = _selectedInstallationPartnerId;

    if (orderId == null) {
      _showMessage('Invalid order ID.');
      return;
    }

    if (partnerId == null) {
      _showMessage('Please select an installation partner.');
      return;
    }

    if (_selectedInstallationDate == null) {
      _showMessage('Please select an installation date.');
      return;
    }

    if (_selectedInstallationTime == null) {
      _showMessage('Please select an installation time.');
      return;
    }

    setState(() {
      _isSchedulingInstallation = true;
    });

    try {
      await ApiService.scheduleInstallation(
        orderId: orderId,
        scheduledDate: _apiDate(_selectedInstallationDate!),
        scheduledAt: _apiTime(_selectedInstallationTime!),
        installationPartnerId: partnerId,
      );

      if (!mounted) return;

      setState(() {
        _isSchedulingInstallation = false;
        _selectedInstallationPartnerId = null;
        _selectedInstallationDate = null;
        _selectedInstallationTime = null;
      });

      _showMessage('Installation scheduled successfully.');

      await _loadInstallations();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSchedulingInstallation = false;
      });

      _showMessage(_cleanErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // FILTERED INSTALLATIONS
  // ============================================================

  List<Map<String, dynamic>> get _filteredInstallations {
    final search =
        _searchController.text.trim().toLowerCase();

    return _installations.where((installation) {
      // --------------------------------------------------------
      // SEARCH
      // --------------------------------------------------------

      final installationId = _value(
        installation['installation_id'],
      ).toLowerCase();

      final orderId = _value(
        installation['order_id'],
      ).toLowerCase();

      final customerName = _value(
        installation['customer_name'],
      ).toLowerCase();

      final customerMobile = _value(
        installation['customer_mobile'],
      ).toLowerCase();

      final matchesSearch =
          search.isEmpty ||
          installationId.contains(search) ||
          orderId.contains(search) ||
          customerName.contains(search) ||
          customerMobile.contains(search);

      if (!matchesSearch) {
        return false;
      }

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      final status = _value(
        installation['installation_status'],
      ).toLowerCase();

      final matchesStatus =
          _selectedStatus == 'All' ||
          status == _selectedStatus.toLowerCase();

      if (!matchesStatus) {
        return false;
      }

      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      if (_selectedDate != null) {
        final scheduledDate =
            _parseDate(
          installation['scheduled_date'],
        );

        if (scheduledDate == null) {
          return false;
        }

        final matchesDate =
            scheduledDate.year ==
                _selectedDate!.year &&
            scheduledDate.month ==
                _selectedDate!.month &&
            scheduledDate.day ==
                _selectedDate!.day;

        if (!matchesDate) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _applyFilters() {
    if (!mounted) return;

    setState(() {
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get _paginatedInstallations {
    final items = _filteredInstallations;

    if (items.isEmpty) {
      return const [];
    }

    final start = (_currentPage - 1) * _rowsPerPage;

    if (start >= items.length) {
      return const [];
    }

    final end = (start + _rowsPerPage > items.length)
        ? items.length
        : start + _rowsPerPage;

    return items.sublist(start, end);
  }

  int get _totalPages {
    final count = _filteredInstallations.length;
    if (count == 0) return 1;
    return (count / _rowsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || !mounted) return;

    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildPagination() {
    final totalItems = _filteredInstallations.length;

    if (totalItems <= _rowsPerPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _totalPages;
    final start = ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = (_currentPage * _rowsPerPage > totalItems)
        ? totalItems
        : _currentPage * _rowsPerPage;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
              ),
              ...List.generate(totalPages, (index) {
                final page = index + 1;
                final selected = page == _currentPage;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => _goToPage(page),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.ctaPurple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$page',
                        style: AppTextStyles.of(
                          figmaSize: 15,
                          weight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                tooltip: 'Next page',
                onPressed: _currentPage < totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                Text(
                  'Showing $start–$end of $totalItems',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: controls,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  'Showing $start–$end of $totalItems installations',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              controls,
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedStatus = 'All';
      _selectedDate = null;
      _currentPage = 1;
    });
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedDate != null;
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.ctaPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDeep,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
      _currentPage = 1;
    });
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _value(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return '-';
    }

    return text;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final raw = value.toString().trim();

    if (raw.isEmpty ||
        raw.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(raw)?.toLocal();
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '-';
    }

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '$hour:$minute $period';
  }

  String _formatTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    final raw = value.toString().trim();

    if (raw.isEmpty ||
        raw.toLowerCase() == 'null') {
      return '-';
    }

    // Handles:
    // 10:30
    // 10:30:00
    // 10:30:00.000
    final parts = raw.split(':');

    if (parts.length < 2) {
      return raw;
    }

    final hour24 =
        int.tryParse(parts[0]);

    if (hour24 == null) {
      return raw;
    }

    final minute =
        parts[1].split('.').first.padLeft(2, '0');

    final hour12 = hour24 == 0
        ? 12
        : hour24 > 12
            ? hour24 - 12
            : hour24;

    final period =
        hour24 >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.ctaPurple;

      case 'completed':
      case 'installed':
        return AppColors.checkGreen;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      case 'in progress':
      case 'in_progress':
        return Colors.orange;

      default:
        return AppColors.textGray;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.ctaPurple.withValues(
          alpha: 0.10,
        );

      case 'completed':
      case 'installed':
        return AppColors.checkGreen.withValues(
          alpha: 0.10,
        );

      case 'cancelled':
      case 'canceled':
        return Colors.red.withValues(
          alpha: 0.08,
        );

      case 'in progress':
      case 'in_progress':
        return Colors.orange.withValues(
          alpha: 0.10,
        );

      default:
        return AppColors.textGray.withValues(
          alpha: 0.08,
        );
    }
  }

  Widget _buildStatusBadge(String status) {
    final displayStatus =
        status == '-' ? 'Unknown' : status;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(
          displayStatus,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        displayStatus,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.of(
          figmaSize: 14,
          weight: FontWeight.w700,
          color: _statusColor(
            displayStatus,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  List<String> _statusFilters() {
    final values = <String>{
      'Scheduled',
      'In Progress',
      'Completed',
      'Installed',
      'Cancelled',
    };

    for (final installation
        in _installations) {
      final status = _value(
        installation['installation_status'],
      );

      if (status != '-') {
        values.add(status);
      }
    }

    final result = values.toList()
      ..sort(
        (a, b) => a
            .toLowerCase()
            .compareTo(
              b.toLowerCase(),
            ),
      );

    return [
      'All',
      ...result,
    ];
  }

  // ============================================================
  // SUMMARY STATISTICS
  // ============================================================

  List<AdminOrdersStyleStat>
      _installationStats() {
    final total =
        _installations.length;

    final scheduled =
        _installations.where((item) {
      return _value(
            item['installation_status'],
          ).toLowerCase() ==
          'scheduled';
    }).length;

    final completed =
        _installations.where((item) {
      final status = _value(
        item['installation_status'],
      ).toLowerCase();

      return status == 'completed' ||
          status == 'installed';
    }).length;

    final other =
        total - scheduled - completed;

    return [
      AdminOrdersStyleStat(
        title: 'Total Installations',
        value: '$total',
        icon: Icons.build_circle_outlined,
        iconBackground:
            const Color(0xFFEDEAFF),
        iconColor:
            AppColors.ctaPurple,
      ),
      AdminOrdersStyleStat(
        title: 'Scheduled',
        value: '$scheduled',
        icon: Icons.event_available_outlined,
        iconBackground:
            const Color(0xFFE9F2FF),
        iconColor: Colors.blue,
      ),
      AdminOrdersStyleStat(
        title: 'Completed',
        value: '$completed',
        icon:
            Icons.check_circle_outline_rounded,
        iconBackground:
            const Color(0xFFE7F7ED),
        iconColor: Colors.green,
      ),
      AdminOrdersStyleStat(
        title: 'Other',
        value: '$other',
        icon:
            Icons.pending_actions_outlined,
        iconBackground:
            const Color(0xFFFFF1DE),
        iconColor: Colors.orange,
      ),
    ];
  }

  // ============================================================
  // FILTER UI
  // ============================================================

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        AdminOrdersStyleFilterRow(
          controller: _searchController,
          hintText:
              'Search installation, order or customer...',
          selectedValue:
              _selectedStatus,
          values: _statusFilters(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedStatus = value;
            });
          },
          onSearchChanged: (_) {
            _applyFilters();
          },
          onClear: _clearFilters,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
              ),
              label: Text(
                _selectedDate == null
                    ? 'Select date'
                    : _formatDate(
                        _selectedDate,
                      ),
                style: AppTextStyles.of(
                  figmaSize: 17,
                  weight:
                      FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    AppColors.navy,
                side: BorderSide(
                  color:
                      Colors.grey.shade200,
                ),
                minimumSize:
                    const Size(0, 46),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                tooltip: 'Clear date',
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.ctaPurple,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final hasScheduled = _filteredInstallations.isNotEmpty;

    // The Installation History table is the main content of this page.
    // Pending installation scheduling remains available in the existing
    // code/API, but the pending section is intentionally not displayed here.
    if (!hasScheduled) {
      return _buildNoResults();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDesktopTable(),
              _buildPagination(),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMobileList(),
            _buildPagination(),
          ],
        );
      },
    );
  }

  Widget _buildPendingInstallationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.orange.shade100),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.build_circle_outlined,
                    color: Colors.orange.shade700,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Installation',
                        style: AppTextStyles.of(
                          figmaSize: 22,
                          weight: FontWeight.w800,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Delivery assigned orders waiting for installation scheduling.',
                        style: AppTextStyles.of(
                          figmaSize: 15,
                          weight: FontWeight.w400,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_pendingInstallationOrders.length}',
                    style: AppTextStyles.of(
                      figmaSize: 16,
                      weight: FontWeight.w800,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: _pendingInstallationOrders
                  .map(_buildPendingInstallationCard)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInstallationCard(
    Map<String, dynamic> order,
  ) {
    final orderId = _value(order['order_id']);
    final customerName = _value(
      order['full_name'] ?? order['customer_name'],
    );
    final mobile = _value(
      order['mobile'] ?? order['customer_mobile'],
    );
    final city = _value(order['city']);
    final address = _buildOrderAddress(order);
    final deliveryPartner = _value(
      order['delivery_partner_name'] ??
          order['partner_name'] ??
          order['delivery_partner'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #$orderId',
                      style: AppTextStyles.of(
                        figmaSize: 19,
                        weight: FontWeight.w800,
                        color: AppColors.ctaPurple,
                      ),
                    ),
                  ),
                  _buildOrderStatusBadge('Delivery Assigned'),
                ],
              ),
              const SizedBox(height: 10),
              _pendingInfoRow(
                Icons.person_outline_rounded,
                'Customer',
                customerName,
              ),
              _pendingInfoRow(
                Icons.phone_outlined,
                'Mobile',
                mobile,
              ),
              _pendingInfoRow(
                Icons.location_on_outlined,
                'Address',
                address,
              ),
              _pendingInfoRow(
                Icons.local_shipping_outlined,
                'Delivery Partner',
                deliveryPartner,
              ),
              if (city != '-') ...[
                _pendingInfoRow(
                  Icons.location_city_outlined,
                  'City',
                  city,
                ),
              ],
            ],
          );

          final action = _buildScheduleForm(order);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 14),
                action,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: info),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: action),
            ],
          );
        },
      ),
    );
  }

  Widget _pendingInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.textGrayMed,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: AppTextStyles.of(
                figmaSize: 14,
                weight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.of(
                figmaSize: 15,
                weight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: AppTextStyles.of(
          figmaSize: 13,
          weight: FontWeight.w700,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  String _buildOrderAddress(Map<String, dynamic> order) {
    final parts = <String>[];

    for (final key in [
      'house_flat_number',
      'apartment_name',
      'street_area',
      'landmark',
      'city',
      'pincode',
    ]) {
      final value = _value(order[key]);
      if (value != '-') {
        parts.add(value);
      }
    }

    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  Widget _buildScheduleForm(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schedule Installation',
            style: AppTextStyles.of(
              figmaSize: 18,
              weight: FontWeight.w800,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingInstallationPartners)
            Container(
              height: 50,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.ctaPurple,
              ),
            )
          else if (_installationPartnersError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load installation partners.',
                  style: AppTextStyles.of(
                    figmaSize: 15,
                    weight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadInstallationPartners,
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (_installationPartners.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No active installation partners available.',
                style: AppTextStyles.of(
                  figmaSize: 15,
                  weight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            )
          else ...[
            DropdownButtonFormField<int>(
              value: _installationPartners.any(
                (partner) =>
                    partner['installation_partner_id']?.toString() ==
                    _selectedInstallationPartnerId?.toString(),
              )
                  ? _selectedInstallationPartnerId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Installation Partner',
                labelStyle: AppTextStyles.of(
                  figmaSize: 14,
                  weight: FontWeight.w500,
                  color: AppColors.textGray,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              hint: const Text('Select partner'),
              items: _installationPartners.map((partner) {
                final id = int.tryParse(
                  partner['installation_partner_id']?.toString() ?? '',
                );
                if (id == null) return null;

                final name = _value(
                  partner['partner_name'] ??
                      partner['contact_person'],
                );
                final mobile = _value(partner['mobile']);

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    mobile == '-' ? name : '$name • $mobile',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.of(
                      figmaSize: 15,
                      weight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                );
              }).whereType<DropdownMenuItem<int>>().toList(),
              onChanged: _isSchedulingInstallation
                  ? null
                  : (value) {
                      setState(() {
                        _selectedInstallationPartnerId = value;
                      });
                    },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSchedulingInstallation
                        ? null
                        : _pickInstallationDate,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 17,
                    ),
                    label: Text(
                      _displayInstallationDate(
                        _selectedInstallationDate,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSchedulingInstallation
                        ? null
                        : _pickInstallationTime,
                    icon: const Icon(
                      Icons.access_time_rounded,
                      size: 17,
                    ),
                    label: Text(
                      _displayInstallationTime(
                        _selectedInstallationTime,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _isSchedulingInstallation
                    ? null
                    : () => _scheduleInstallation(order),
                icon: _isSchedulingInstallation
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.event_available_rounded,
                        size: 18,
                      ),
                label: Text(
                  _isSchedulingInstallation
                      ? 'Scheduling...'
                      : 'Schedule Installation',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Container(
                color: const Color(0xFFF5F3FF),
                child: Column(
                  children: [
                    Container(
                      height: 78,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      color: const Color(0xFFF5F3FF),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: _TableHeader(
                              text: 'Installation',
                            ),
                          ),
                          Expanded(
                            flex: 10,
                            child: _TableHeader(
                              text: 'Order',
                            ),
                          ),
                          Expanded(
                            flex: 15,
                            child: _TableHeader(
                              text: 'Scheduled Date',
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: _TableHeader(
                              text: 'Time',
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: _TableHeader(
                              text: 'Status',
                            ),
                          ),
                          Expanded(
                            flex: 17,
                            child: _TableHeader(
                              text: 'Created',
                            ),
                          ),
                          const SizedBox(width: 42),
                        ],
                      ),
                    ),
                    ..._paginatedInstallations.map(
                      _buildDesktopRow,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopRow(
    Map<String, dynamic> installation,
  ) {
    final status = _value(
      installation['installation_status'],
    );

    return InkWell(
      onTap: () => _showInstallationDetails(installation),
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Text(
                '#${_value(installation['installation_id'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 19,
                  weight: FontWeight.w800,
                  color: AppColors.navyDeep,
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                '#${_value(installation['order_id'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 19,
                  weight: FontWeight.w700,
                  color: AppColors.ctaPurple,
                ),
              ),
            ),
            Expanded(
              flex: 15,
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.textGrayMed,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _formatDate(
                        installation['scheduled_date'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.of(
                        figmaSize: 18,
                        weight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 12,
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: AppColors.textGrayMed,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _formatTime(
                        installation['scheduled_at'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.of(
                        figmaSize: 18,
                        weight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(status),
              ),
            ),
            Expanded(
              flex: 17,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  _formatDateTime(
                    installation['created_at'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 17,
                    weight: FontWeight.w500,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGrayMed,
                  size: 29,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================

  Widget _buildMobileList() {
    return Column(
      children: List.generate(
        _filteredInstallations.length,
        (index) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: _buildMobileCard(
              _filteredInstallations[
                  index],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileCard(
    Map<String, dynamic> installation,
  ) {
    final installationId = _value(
      installation['installation_id'],
    );

    final orderId = _value(
      installation['order_id'],
    );

    final status = _value(
      installation['installation_status'],
    );

    final customerName = _value(
      installation['customer_name'],
    );

    return InkWell(
      onTap: () =>
          _showInstallationDetails(
        installation,
      ),
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color: AppColors
                        .ctaPurple
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .build_outlined,
                    color: AppColors
                        .ctaPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Installation #$installationId',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppTextStyles
                                .of(
                          figmaSize: 17,
                          weight:
                              FontWeight
                                  .w700,
                          color: AppColors
                              .navyDeep,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Order #$orderId',
                        style:
                            AppTextStyles
                                .of(
                          figmaSize: 16,
                          weight:
                              FontWeight
                                  .w500,
                          color: AppColors
                              .textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(
                  status,
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            if (customerName != '-')
              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  customerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles.of(
                    figmaSize: 17,
                    weight:
                        FontWeight.w600,
                    color:
                        AppColors.navy,
                  ),
                ),
              ),

            const SizedBox(
              height: 12,
            ),

            const Divider(
              height: 1,
              color:
                  AppColors.divider,
            ),

            const SizedBox(
              height: 13,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      _mobileInfoItem(
                    icon: Icons
                        .calendar_today_outlined,
                    label:
                        'Scheduled Date',
                    value:
                        _formatDate(
                      installation[
                          'scheduled_date'],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      _mobileInfoItem(
                    icon: Icons
                        .access_time_rounded,
                    label: 'Time',
                    value:
                        _formatTime(
                      installation[
                          'scheduled_at'],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            _mobileInfoItem(
              icon: Icons
                  .schedule_outlined,
              label: 'Created',
              value:
                  _formatDateTime(
                installation[
                    'created_at'],
              ),
              fullWidth: true,
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Text(
                  'View details',
                  style:
                      AppTextStyles.of(
                    figmaSize: 15,
                    weight:
                        FontWeight.w700,
                    color: AppColors
                        .ctaPurple,
                  ),
                ),
                const SizedBox(
                  width: 4,
                ),
                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors
                      .ctaPurple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width:
          fullWidth ? double.infinity : null,
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                AppColors.textGrayMed,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles.of(
                    figmaSize: 12,
                    weight:
                        FontWeight.w500,
                    color:
                        AppColors.textGray,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles.of(
                    figmaSize: 16,
                    weight:
                        FontWeight.w600,
                    color:
                        AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INSTALLATION DETAILS
  // ============================================================

  void _showInstallationDetails(
    Map<String, dynamic> installation,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: screenHeight * 0.86,
            ),
            child: _InstallationDetailsSheet(
              installation: installation,
              formatDate: _formatDate,
              formatDateTime: _formatDateTime,
              formatTime: _formatTime,
              statusColor: _statusColor,
              statusBackground: _statusBackground,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red
                  .withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .error_outline_rounded,
              color: Colors.red,
              size: 30,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Text(
            'Unable to load installations',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles.of(
              figmaSize: 21,
              weight:
                  FontWeight.w700,
              color:
                  AppColors.navyDeep,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            _errorMessage ??
                'Something went wrong.',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles.of(
              figmaSize: 17,
              weight:
                  FontWeight.w400,
              color:
                  AppColors.textGray,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          ElevatedButton.icon(
            onPressed:
                _loadInstallations,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label:
                const Text(
              'Try Again',
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  AppColors.ctaPurple,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO RESULTS
  // ============================================================

  Widget _buildNoResults() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 50,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors
                  .ctaPurple
                  .withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .search_off_rounded,
              color:
                  AppColors.ctaPurple,
              size: 30,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'No installations found',
            style:
                AppTextStyles.of(
              figmaSize: 20,
              weight:
                  FontWeight.w700,
              color:
                  AppColors.navyDeep,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            _hasActiveFilters
                ? 'Try changing or clearing your filters.'
                : 'Scheduled installations will appear here.',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles.of(
              figmaSize: 16,
              weight:
                  FontWeight.w400,
              color:
                  AppColors.textGray,
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(
              height: 18,
            ),
            OutlinedButton.icon(
              onPressed:
                  _clearFilters,
              icon: const Icon(
                Icons
                    .filter_alt_off_outlined,
                size: 17,
              ),
              label:
                  const Text(
                'Clear Filters',
              ),
              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    AppColors.ctaPurple,
                side:
                    const BorderSide(
                  color:
                      AppColors.ctaPurple,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AdminOrdersStyleShell(
      title: 'Installations',
      subtitle:
          'View installation schedules and service status',
      refresh:
          _loadInstallations,
      stats:
          _installationStats(),
      filters:
          _buildFilters(),
      content:
          _buildContent(),
    );
  }
}

// ============================================================
// TABLE HEADER
// ============================================================

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.of(
        figmaSize: 20,
        weight:
            FontWeight.w700,
        color:
            AppColors.textGray,
      ),
    );
  }
}

// ============================================================
// INSTALLATION DETAILS SHEET
// ============================================================

class _InstallationDetailsSheet
    extends StatelessWidget {
  final Map<String, dynamic>
      installation;

  final String Function(dynamic)
      formatDate;

  final String Function(dynamic)
      formatDateTime;

  final String Function(dynamic)
      formatTime;

  final Color Function(String)
      statusColor;

  final Color Function(String)
      statusBackground;

  const _InstallationDetailsSheet({
    required this.installation,
    required this.formatDate,
    required this.formatDateTime,
    required this.formatTime,
    required this.statusColor,
    required this.statusBackground,
  });

  String _value(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() ==
            'null') {
      return '-';
    }

    return text;
  }

  String _buildAddress() {
    final parts = <String>[];

    final house = _value(
      installation[
          'house_flat_number'],
    );

    final apartment = _value(
      installation[
          'apartment_name'],
    );

    final street = _value(
      installation[
          'street_area'],
    );

    final landmark = _value(
      installation[
          'landmark'],
    );

    final city = _value(
      installation['city'],
    );

    final pincode = _value(
      installation['pincode'],
    );

    if (house != '-') {
      parts.add(house);
    }

    if (apartment != '-') {
      parts.add(apartment);
    }

    if (street != '-') {
      parts.add(street);
    }

    if (landmark != '-') {
      parts.add(
        'Near $landmark',
      );
    }

    if (city != '-') {
      parts.add(city);
    }

    if (pincode != '-') {
      parts.add(pincode);
    }

    if (parts.isEmpty) {
      return 'Address not available';
    }

    return parts.join(', ');
  }

  String _customerName() {
    return _value(
      installation[
          'customer_name'],
    );
  }

  String _customerMobile() {
    return _value(
      installation[
          'customer_mobile'],
    );
  }

  String _customerEmail() {
    return _value(
      installation[
          'customer_email'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _value(
      installation[
          'installation_status'],
    );

    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // --------------------------------------------------
            // HANDLE
            // --------------------------------------------------

            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                16,
                12,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color: AppColors
                          .ctaPurple
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .build_outlined,
                      color: AppColors
                          .ctaPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Installation #${_value(installation['installation_id'])}',
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize: 24,
                            weight:
                                FontWeight
                                    .w800,
                            color: AppColors
                                .navyDeep,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          'Order #${_value(installation['order_id'])}',
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize: 17,
                            weight:
                                FontWeight
                                    .w600,
                            color: AppColors
                                .textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.background,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.close_rounded,
                          size: 28,
                          color: AppColors.navyDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color:
                  AppColors.divider,
            ),

            // --------------------------------------------------
            // CONTENT
            // --------------------------------------------------

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  20,
                  18,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    // STATUS
                    _sectionTitle(
                      'Installation Status',
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            statusBackground(
                          status,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          13,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .info_outline_rounded,
                            size: 21,
                            color:
                                statusColor(
                              status,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            status,
                            style:
                                AppTextStyles
                                    .of(
                              figmaSize: 18,
                              weight:
                                  FontWeight
                                      .w700,
                              color:
                                  statusColor(
                                status,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // SCHEDULE
                    _sectionTitle(
                      'Schedule',
                    ),

                    _DetailTile(
                      icon: Icons
                          .calendar_today_outlined,
                      title:
                          'Scheduled Date',
                      value:
                          formatDate(
                        installation[
                            'scheduled_date'],
                      ),
                    ),

                    _DetailTile(
                      icon: Icons
                          .access_time_rounded,
                      title:
                          'Scheduled Time',
                      value:
                          formatTime(
                        installation[
                            'scheduled_at'],
                      ),
                    ),

                    _DetailTile(
                      icon: Icons
                          .schedule_outlined,
                      title:
                          'Created At',
                      value:
                          formatDateTime(
                        installation[
                            'created_at'],
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // CUSTOMER
                    _sectionTitle(
                      'Customer Details',
                    ),

                    _DetailTile(
                      icon: Icons
                          .person_outline_rounded,
                      title:
                          'Customer Name',
                      value:
                          _customerName(),
                    ),

                    _DetailTile(
                      icon: Icons
                          .phone_outlined,
                      title:
                          'Mobile',
                      value:
                          _customerMobile(),
                    ),

                    _DetailTile(
                      icon: Icons
                          .email_outlined,
                      title:
                          'Email',
                      value:
                          _customerEmail(),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ADDRESS
                    _sectionTitle(
                      'Installation Address',
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .background,
                        borderRadius:
                            BorderRadius
                                .circular(
                          13,
                        ),
                        border: Border.all(
                          color: AppColors
                              .divider,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Icon(
                            Icons
                                .location_on_outlined,
                            size: 24,
                            color: AppColors
                                .ctaPurple,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              _buildAddress(),
                              style:
                                  AppTextStyles
                                      .of(
                                figmaSize: 17,
                                weight:
                                    FontWeight
                                        .w500,
                                color:
                                    AppColors
                                        .navy,
                                height:
                                    1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // CLOSE
                    SizedBox(
                      height: 48,
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () =>
                            Navigator.of(
                          context,
                        ).pop(),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .ctaPurple,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize: 17,
                            weight:
                                FontWeight
                                    .w700,
                            color: Colors
                                .white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style:
            AppTextStyles.of(
          figmaSize: 19,
          weight:
              FontWeight.w800,
          color:
              AppColors.navyDeep,
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL TILE
// ============================================================

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color: AppColors
                  .ctaPurple
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  AppColors.ctaPurple,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      AppTextStyles.of(
                    figmaSize: 14,
                    weight:
                        FontWeight.w600,
                    color:
                        AppColors.textGray,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  maxLines: 3,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles.of(
                    figmaSize: 16,
                    weight:
                        FontWeight.w600,
                    color:
                        AppColors.navy,
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