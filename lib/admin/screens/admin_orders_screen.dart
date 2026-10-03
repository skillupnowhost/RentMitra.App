import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_sidebar.dart';
import 'create_manual_order_dialog.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];

  int _totalOrders = 0;
  int _verifiedPayments = 0;
  int _activeRentals = 0;
  int _scheduledInstallationCount = 0;

  String _selectedStatus = 'All';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = const [
    'All',
    'New Order',
    'Payment Verified',
    'Delivery Assigned',
    'Installation Scheduled',
    'Installation Completed',
    'Delivered',
    'Active Rental',
    'Completed',
    'Cancelled',
  ];

  // Delivery partner assignment
  List<Map<String, dynamic>> _deliveryPartners = [];
  bool _isLoadingDeliveryPartners = false;
  String? _deliveryPartnersError;
  final ValueNotifier<int> _deliveryPartnersRefresh = ValueNotifier<int>(0);
  bool _isAssigningDelivery = false;
  final Map<int, Map<String, dynamic>> _assignedDeliveryPartners = {};

  // Installation workflow
  List<Map<String, dynamic>> _installationPartners = [];
  bool _isLoadingInstallationPartners = false;
  String? _installationPartnersError;
  bool _isSchedulingInstallation = false;
  bool _isMarkingDelivered = false;
  bool _isCompletingInstallation = false;
  bool _isActivatingRental = false;
  final Map<int, Map<String, dynamic>> _scheduledInstallationByOrder = {};
  int? _selectedInstallationPartnerId;
  DateTime? _selectedInstallationDate;
  TimeOfDay? _selectedInstallationTime;
  final ValueNotifier<int> _workflowRefresh = ValueNotifier<int>(0);
  Timer? _ordersRefreshTimer;

  // Pagination
  int _currentPage = 1;
  static const int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final value = _searchController.text.trim();

      if (_searchQuery != value) {
        setState(() {
          _searchQuery = value;
          _currentPage = 1;
          _applyFilters();
        });
      }
    });

    _loadOrders();
    _loadScheduledInstallations();
    _loadDeliveryAssignments();

    _startAutomaticOrderRefresh();
  }

  @override
  void dispose() {
    _ordersRefreshTimer?.cancel();

    _searchController.dispose();
    _deliveryPartnersRefresh.dispose();
    _workflowRefresh.dispose();

    super.dispose();
  }

  // ============================================================
  // AUTOMATIC ORDER REFRESH
  // ============================================================

  void _startAutomaticOrderRefresh() {
    _ordersRefreshTimer?.cancel();

    _ordersRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted || _isLoading) {
          return;
        }

        _refreshOrdersInBackground();
      },
    );
  }

  Future<void> _refreshOrdersInBackground() async {
    if (!mounted || _isLoading) return;

    try {
      final results = await Future.wait([
        ApiService.getAdminOrders(),
        ApiService.getAdminDashboard(),
        ApiService.getAdminInstallations(),
        ApiService.getDeliveryAssignments(),
      ]);

      final ordersResponse =
          results[0] as Map<String, dynamic>;
      final dashboardResponse =
          results[1] as Map<String, dynamic>;
      final installationsResponse =
          results[2] as List<Map<String, dynamic>>;
      final deliveryAssignmentsResponse =
          results[3] as List<Map<String, dynamic>>;

      final dynamic rawOrders = ordersResponse['orders'];

      if (rawOrders is! List) {
        return;
      }

      final incomingOrders = <int, Map<String, dynamic>>{};

      for (final rawOrder in rawOrders) {
        if (rawOrder is! Map) continue;

        final incoming = Map<String, dynamic>.from(rawOrder);

        final orderId = int.tryParse(
          incoming['order_id']?.toString() ?? '',
        );

        if (orderId == null) continue;

        incomingOrders[orderId] = incoming;
      }

      // Update existing maps in place. This is important because an
      // open Order Details dialog may still hold the same Map reference.
      final existingById = <int, Map<String, dynamic>>{};

      for (final existing in _orders) {
        final id = int.tryParse(
          existing['order_id']?.toString() ?? '',
        );

        if (id != null) {
          existingById[id] = existing;
        }
      }

      final updatedOrders = <Map<String, dynamic>>[];

      for (final entry in incomingOrders.entries) {
        final existing = existingById[entry.key];

        if (existing != null) {
          existing
            ..clear()
            ..addAll(entry.value);

          updatedOrders.add(existing);
        } else {
          updatedOrders.add(entry.value);
        }
      }

      updatedOrders.sort((a, b) {
        final aId =
            int.tryParse(a['order_id']?.toString() ?? '0') ?? 0;
        final bId =
            int.tryParse(b['order_id']?.toString() ?? '0') ?? 0;

        return bId.compareTo(aId);
      });

      // Refresh delivery assignment cache.
      if (deliveryAssignmentsResponse is List) {
        final mappedDelivery =
            <int, Map<String, dynamic>>{};

        for (final rawAssignment
            in deliveryAssignmentsResponse) {
          if (rawAssignment is! Map) continue;

          final assignment =
              Map<String, dynamic>.from(rawAssignment);

          final orderId = int.tryParse(
            assignment['order_id']?.toString() ?? '',
          );

          if (orderId == null) continue;

          mappedDelivery[orderId] = assignment;
        }

        _assignedDeliveryPartners
          ..clear()
          ..addAll(mappedDelivery);
      }

      // Refresh installation cache.
      if (installationsResponse is List) {
        final mappedInstallations =
            <int, Map<String, dynamic>>{};

        for (final rawInstallation
            in installationsResponse) {
          if (rawInstallation is! Map) continue;

          final installation =
              _normalizeInstallationPartner(
            Map<String, dynamic>.from(rawInstallation),
          );

          final orderId = int.tryParse(
            installation['order_id']?.toString() ?? '',
          );

          if (orderId == null) continue;

          mappedInstallations[orderId] =
              installation;
        }

        _scheduledInstallationByOrder
          ..clear()
          ..addAll(mappedInstallations);
      }

      int verifiedPayments = 0;
      int activeRentals = 0;
      int scheduledInstallations = 0;

      for (final order in updatedOrders) {
        final paymentStatus =
            order['payment_status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        final orderStatus =
            order['order_status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (paymentStatus == 'verified') {
          verifiedPayments++;
        }

        if (orderStatus == 'active rental' ||
            orderStatus.contains('active rental')) {
          activeRentals++;
        }

        if (orderStatus == 'installation scheduled' ||
            orderStatus == 'installation completed') {
          scheduledInstallations++;
        }
      }

      final dashboardTotal =
          int.tryParse(
                dashboardResponse['total_orders']?.toString() ?? '',
              ) ??
              updatedOrders.length;

      if (!mounted) return;

      setState(() {
        _orders = updatedOrders;

        _totalOrders = dashboardTotal;
        _verifiedPayments = verifiedPayments;
        _activeRentals = activeRentals;
        _scheduledInstallationCount =
            scheduledInstallations;

        _applyFilters();
      });

      // Keep the current page valid after new orders/status changes.
      final totalPages =
          (_filteredOrders.length / _rowsPerPage).ceil();

      if (totalPages > 0 && _currentPage > totalPages) {
        setState(() {
          _currentPage = totalPages;
        });
      }

      _deliveryPartnersRefresh.value++;
      _workflowRefresh.value++;
    } catch (error) {
      debugPrint(
        'Automatic order refresh failed: $error',
      );
    }
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAdminOrders(),
        ApiService.getAdminDashboard(),
      ]);

      final ordersResponse =
          results[0] as Map<String, dynamic>;
      final dashboardResponse =
          results[1] as Map<String, dynamic>;

      final dynamic rawOrders = ordersResponse['orders'];

      if (rawOrders is! List) {
        throw Exception('Invalid orders response from server.');
      }

      final List<Map<String, dynamic>> parsedOrders = rawOrders
          .whereType<Map>()
          .map((order) => Map<String, dynamic>.from(order))
          .toList();

      // ----------------------------------------------------------
      // IMPORTANT:
      // Keep the UI unique by order_id. If the API ever returns a
      // duplicate row, only the latest occurrence is rendered.
      // ----------------------------------------------------------

      final Map<int, Map<String, dynamic>> uniqueOrderMap = {};

      for (final order in parsedOrders) {
        final int? orderId = int.tryParse(order['order_id']?.toString() ?? '');

        if (orderId == null) {
          continue;
        }

        uniqueOrderMap[orderId] = order;
      }

      final List<Map<String, dynamic>> cleanedOrders = uniqueOrderMap.values
          .toList();

      // Newest order first.
      cleanedOrders.sort((a, b) {
        final int orderA = int.tryParse(a['order_id']?.toString() ?? '0') ?? 0;

        final int orderB = int.tryParse(b['order_id']?.toString() ?? '0') ?? 0;

        return orderB.compareTo(orderA);
      });

      final int dashboardTotal =
          int.tryParse(dashboardResponse['total_orders']?.toString() ?? '') ??
          cleanedOrders.length;

      int verifiedPayments = 0;
      int activeRentals = 0;
      int scheduledInstallations = 0;

      for (final order in cleanedOrders) {
        final String paymentStatus =
            order['payment_status']?.toString().trim().toLowerCase() ?? '';

        final String orderStatus =
            order['order_status']?.toString().trim().toLowerCase() ?? '';

        if (paymentStatus == 'verified') {
          verifiedPayments++;
        }

        if (orderStatus.contains('active rental') ||
            orderStatus == 'rental active' ||
            orderStatus == 'active') {
          activeRentals++;
        }

        if (orderStatus.contains('installation scheduled')) {
          scheduledInstallations++;
        }
      }

      if (!mounted) return;

      setState(() {
        _orders = cleanedOrders;
        _totalOrders = dashboardTotal;
        _verifiedPayments = verifiedPayments;
        _activeRentals = activeRentals;
        _scheduledInstallationCount = scheduledInstallations;

        _applyFilters();

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(error);
      });
    }
  }


  Map<String, dynamic> _normalizeInstallationPartner(
    Map<String, dynamic> rawInstallation,
  ) {
    final installation = Map<String, dynamic>.from(rawInstallation);
    final partnerId = installation['installation_partner_id']?.toString();
    final partnerName = installation['partner_name']?.toString().trim();
    final contactPerson = installation['installation_contact_person']?.toString().trim();
    final partnerMobile = installation['installation_partner_mobile']?.toString().trim();
    final partnerEmail = installation['installation_partner_email']?.toString().trim();

    if (partnerName != null && partnerName.isNotEmpty) {
      installation['installation_partner_name'] = partnerName;
    }
    if (partnerMobile != null && partnerMobile.isNotEmpty) {
      installation['installation_partner_mobile'] = partnerMobile;
    }
    if ((partnerName != null && partnerName.isNotEmpty) ||
        (partnerMobile != null && partnerMobile.isNotEmpty)) {
      installation['installation_partner'] = {
        'installation_partner_id': partnerId,
        'partner_name': partnerName ?? '',
        'contact_person': contactPerson ?? '',
        'mobile': partnerMobile ?? '',
        'email': partnerEmail ?? '',
        'partner_status': installation['partner_status'] ?? 'Active',
      };
    }
    return installation;
  }

  Future<void> _loadScheduledInstallations() async {
    try {
      final installations = await ApiService.getAdminInstallations();
      if (!mounted) return;

      final mapped = <int, Map<String, dynamic>>{};
      for (final installation in installations) {
        final orderId = int.tryParse(
          installation['order_id']?.toString() ?? '',
        );
        if (orderId != null) {
          mapped[orderId] = _normalizeInstallationPartner(installation);
        }
      }

      setState(() {
        _scheduledInstallationByOrder
          ..clear()
          ..addAll(mapped);
      });
      _workflowRefresh.value++;
    } catch (_) {
      // The workflow can still be shown from the order status.
    }
  }

  Future<void> _loadDeliveryAssignments() async {
    try {
      final assignments = await ApiService.getDeliveryAssignments();
      if (!mounted) return;

      final mapped = <int, Map<String, dynamic>>{};
      for (final assignment in assignments) {
        final orderId = int.tryParse(
          assignment['order_id']?.toString() ?? '',
        );
        if (orderId == null) continue;

        mapped[orderId] = Map<String, dynamic>.from(assignment);
      }

      setState(() {
        _assignedDeliveryPartners.clear();
        _assignedDeliveryPartners.addAll(mapped);
      });
      _deliveryPartnersRefresh.value++;
    } catch (_) {
      // Order screen can still load even if assignment lookup fails.
    }
  }

  Future<void> _loadDeliveryPartners() async {
    if (_isLoadingDeliveryPartners) return;

    setState(() {
      _isLoadingDeliveryPartners = true;
      _deliveryPartnersError = null;
    });
    _deliveryPartnersRefresh.value++;

    try {
      final partners = await ApiService.getAdminDeliveryPartners();

      if (!mounted) return;

      setState(() {
        _deliveryPartners = partners
            .where((partner) {
              final status = partner['partner_status']?.toString().trim().toLowerCase();
              return status == null || status.isEmpty || status == 'active';
            })
            .toList();
        _isLoadingDeliveryPartners = false;
      });
      _deliveryPartnersRefresh.value++;
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingDeliveryPartners = false;
        _deliveryPartnersError = _cleanErrorMessage(error);
      });
      _deliveryPartnersRefresh.value++;
    }
  }

  Future<void> _loadInstallationPartners() async {
    if (_isLoadingInstallationPartners) return;
    setState(() { _isLoadingInstallationPartners = true; _installationPartnersError = null; });
    _workflowRefresh.value++;
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
      _workflowRefresh.value++;
    } catch (error) {
      if (!mounted) return;
      setState(() { _isLoadingInstallationPartners = false; _installationPartnersError = _cleanErrorMessage(error); });
      _workflowRefresh.value++;
    }
  }

  Future<void> _loadInstallationForOrder(int orderId) async {
    try {
      final installations = await ApiService.getAdminInstallations();
      if (!mounted) return;

      for (final rawInstallation in installations) {
        if (rawInstallation['order_id']?.toString() != orderId.toString()) {
          continue;
        }

        final installation = _normalizeInstallationPartner(rawInstallation);
        setState(() {
          _scheduledInstallationByOrder[orderId] = installation;
        });
        _workflowRefresh.value++;
        break;
      }
    } catch (error) {
      debugPrint('Failed to load installation for order $orderId: $error');
    }
  }

  Future<void> _pickInstallationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedInstallationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedInstallationDate = picked);
    _workflowRefresh.value++;
  }

  Future<void> _pickInstallationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedInstallationTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedInstallationTime = picked);
    _workflowRefresh.value++;
  }

  String _installationDateForApi(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _installationTimeForApi(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String _displayInstallationDate(DateTime? date) => date == null ? 'Select date' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _displayInstallationTime(TimeOfDay? time) => time == null ? 'Select time' : time.format(context);

  Future<void> _scheduleInstallation({required Map<String, dynamic> order}) async {
    final orderId = int.tryParse(order['order_id']?.toString() ?? '');
    if (orderId == null) {
      _showMessage('Invalid order ID.');
      return;
    }
    if (_selectedInstallationPartnerId == null) {
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
    setState(() => _isSchedulingInstallation = true);
    try {
      final result = await ApiService.scheduleInstallation(
        orderId: orderId,
        scheduledDate: _installationDateForApi(_selectedInstallationDate!),
        scheduledAt: _installationTimeForApi(_selectedInstallationTime!),
        installationPartnerId: _selectedInstallationPartnerId!,
      );
      if (!mounted) return;
      final partner = _installationPartners.firstWhere(
        (item) => item['installation_partner_id']?.toString() == _selectedInstallationPartnerId.toString(),
        orElse: () => <String, dynamic>{},
      );
      final installation = result['installation'] is Map
          ? Map<String, dynamic>.from(result['installation'])
          : <String, dynamic>{};

      if (partner.isNotEmpty) {
        installation['installation_partner'] = Map<String, dynamic>.from(partner);
        installation['installation_partner_id'] = partner['installation_partner_id'];
        installation['partner_name'] = partner['partner_name'];
        installation['installation_contact_person'] = partner['contact_person'];
        installation['installation_partner_mobile'] = partner['mobile'];
        installation['installation_partner_email'] = partner['email'];
        installation['partner_status'] = partner['partner_status'];
      }

      installation['scheduled_date'] = _installationDateForApi(_selectedInstallationDate!);
      installation['scheduled_at'] = _installationTimeForApi(_selectedInstallationTime!);
      setState(() {
        _isSchedulingInstallation = false;
        _scheduledInstallationByOrder[orderId] = installation;
        order['order_status'] = 'Installation Scheduled';
        final index = _orders.indexWhere((item) => item['order_id']?.toString() == orderId.toString());
        if (index >= 0) _orders[index]['order_status'] = 'Installation Scheduled';
      });
      _workflowRefresh.value++;
      _deliveryPartnersRefresh.value++;
      _applyFilters();
      _showMessage('Installation scheduled successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSchedulingInstallation = false);
      _showMessage(_cleanErrorMessage(error));
    }
  }

  Future<void> _markOrderAsDelivered({required Map<String, dynamic> order}) async {
    final orderId = int.tryParse(
      order['order_id']?.toString() ?? '',
    );

    if (orderId == null) {
      _showMessage('Invalid order ID.');
      return;
    }

    setState(() {
      _isMarkingDelivered = true;
    });

    try {
      await ApiService.markOrderAsDelivered(
        orderId: orderId,
      );

      if (!mounted) return;

      setState(() {
        _isMarkingDelivered = false;
        order['order_status'] = 'Delivered';

        final index = _orders.indexWhere(
          (item) =>
              item['order_id']?.toString() == orderId.toString(),
        );

        if (index >= 0) {
          _orders[index]['order_status'] = 'Delivered';
        }

        // Reset installation selection because the order has just
        // entered the installation-assignment stage.
        _selectedInstallationPartnerId = null;
        _selectedInstallationDate = null;
        _selectedInstallationTime = null;
      });

      // Load installation partners immediately after delivery is
      // completed. This prevents the partner dropdown from appearing
      // only after the order dialog is closed and opened again.
      await _loadInstallationPartners();

      if (!mounted) return;

      _workflowRefresh.value++;
      _deliveryPartnersRefresh.value++;
      _applyFilters();

      _showMessage('Order marked as delivered.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isMarkingDelivered = false;
      });

      _showMessage(_cleanErrorMessage(error));
    }
  }

  Future<void> _markInstallationCompleted({
    required Map<String, dynamic> order,
  }) async {
    final orderId = int.tryParse(order['order_id']?.toString() ?? '');
    if (orderId == null) {
      _showMessage('Invalid order ID.');
      return;
    }

    setState(() => _isCompletingInstallation = true);

    try {
      final result = await ApiService.markInstallationAsCompleted(orderId: orderId);
      if (!mounted) return;

      final existingInstallation = _scheduledInstallationByOrder[orderId];
      final mergedInstallation = <String, dynamic>{
        if (existingInstallation != null) ...existingInstallation,
      };

      final resultInstallation = result['installation'];
      if (resultInstallation is Map) {
        mergedInstallation.addAll(Map<String, dynamic>.from(resultInstallation));
      }

      final existingPartner = existingInstallation?['installation_partner'];
      if (existingPartner is Map) {
        mergedInstallation['installation_partner'] = Map<String, dynamic>.from(existingPartner);
      }

      final partnerId = mergedInstallation['installation_partner_id']?.toString();
      final partnerName = mergedInstallation['partner_name']?.toString().trim();
      final contactPerson = mergedInstallation['installation_contact_person']?.toString().trim();
      final partnerMobile = mergedInstallation['installation_partner_mobile']?.toString().trim();
      final partnerEmail = mergedInstallation['installation_partner_email']?.toString().trim();

      if (partnerName != null && partnerName.isNotEmpty) {
        mergedInstallation['installation_partner_name'] = partnerName;
      }
      if (partnerMobile != null && partnerMobile.isNotEmpty) {
        mergedInstallation['installation_partner_mobile'] = partnerMobile;
      }
      if ((partnerName != null && partnerName.isNotEmpty) ||
          (partnerMobile != null && partnerMobile.isNotEmpty)) {
        mergedInstallation['installation_partner'] = {
          'installation_partner_id': partnerId,
          'partner_name': partnerName ?? '',
          'contact_person': contactPerson ?? '',
          'mobile': partnerMobile ?? '',
          'email': partnerEmail ?? '',
          'partner_status': mergedInstallation['partner_status'] ?? 'Active',
        };
      }
      mergedInstallation['installation_status'] = 'Completed';

      setState(() {
        _isCompletingInstallation = false;
        _scheduledInstallationByOrder[orderId] = mergedInstallation;
        order['order_status'] = 'Installation Completed';
        final index = _orders.indexWhere((item) => item['order_id']?.toString() == orderId.toString());
        if (index >= 0) {
          _orders[index]['order_status'] = 'Installation Completed';
        }
      });

      await _loadInstallationForOrder(orderId);
      if (!mounted) return;

      _workflowRefresh.value++;
      _applyFilters();
      _showMessage('Installation completed successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCompletingInstallation = false);
      _showMessage(_cleanErrorMessage(error));
    }
  }

  Future<void> _activateRental({
    required Map<String, dynamic> order,
  }) async {
    final orderId = int.tryParse(order['order_id']?.toString() ?? '');
    if (orderId == null) {
      _showMessage('Invalid order ID.');
      return;
    }

    setState(() => _isActivatingRental = true);
    try {
      await ApiService.activateRental(orderId: orderId);
      if (!mounted) return;

      setState(() {
        _isActivatingRental = false;
        order['order_status'] = 'Active Rental';
        final index = _orders.indexWhere((item) => item['order_id']?.toString() == orderId.toString());
        if (index >= 0) {
          _orders[index]['order_status'] = 'Active Rental';
        }
      });

      await _loadInstallationForOrder(orderId);
      if (!mounted) return;

      _workflowRefresh.value++;
      _deliveryPartnersRefresh.value++;
      _applyFilters();
      _showMessage('Rental activated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isActivatingRental = false);
      _showMessage(_cleanErrorMessage(error));
    }
  }

  Future<void> _assignDeliveryPartner({
    required Map<String, dynamic> order,
    required Map<String, dynamic> partner,
  }) async {
    final orderId = int.tryParse(order['order_id']?.toString() ?? '');
    final partnerId = int.tryParse(
      partner['delivery_partner_id']?.toString() ?? '',
    );

    if (orderId == null || partnerId == null) {
      _showMessage('Invalid order or delivery partner.');
      return;
    }

    setState(() {
      _isAssigningDelivery = true;
    });

    try {
      await ApiService.assignDelivery(
        orderId: orderId,
        deliveryPartnerId: partnerId,
      );

      if (!mounted) return;

      setState(() {
        _assignedDeliveryPartners[orderId] = partner;
        _isAssigningDelivery = false;

        final index = _orders.indexWhere(
          (item) => item['order_id']?.toString() == orderId.toString(),
        );

        if (index >= 0) {
          // The backend automatically changes the order status to
          // `Delivery Assigned` when the delivery is successfully assigned.
          // Keep the same order map updated so the open details dialog can
          // immediately display the new status.
          _orders[index]['order_status'] = 'Delivery Assigned';
        }

        // `showDialog` has its own route/build context, so the parent's
        // setState does not rebuild widgets already inside the dialog.
        // Notify the dialog explicitly so the status and assignment card
        // refresh immediately without closing the dialog.
        _deliveryPartnersRefresh.value++;
        _workflowRefresh.value++;

        _applyFilters();
      });

      _showMessage('Delivery partner assigned successfully.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isAssigningDelivery = false;
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

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  List<Map<String, dynamic>> get _paginatedOrders {
    if (_filteredOrders.isEmpty) {
      return const [];
    }

    final start =
        (_currentPage - 1) * _rowsPerPage;

    if (start >= _filteredOrders.length) {
      return const [];
    }

    final end = (start + _rowsPerPage)
        .clamp(0, _filteredOrders.length);

    return _filteredOrders.sublist(start, end);
  }

  int get _totalPages {
    if (_filteredOrders.isEmpty) {
      return 1;
    }

    return (_filteredOrders.length / _rowsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildPagination() {
    if (_filteredOrders.length <= _rowsPerPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _totalPages;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          if (compact) {
            return Row(
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: _currentPage > 1
                      ? () => _goToPage(_currentPage - 1)
                      : null,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Page $_currentPage of $totalPages',
                      style: AppTextStyles.of(
                        figmaSize: 17,
                        weight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: _currentPage < totalPages
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Text(
                'Showing ${((_currentPage - 1) * _rowsPerPage) + 1}'
                '–${((_currentPage - 1) * _rowsPerPage + _paginatedOrders.length)}'
                ' of ${_filteredOrders.length}',
                style: AppTextStyles.of(
                  figmaSize: 17,
                  weight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Previous page',
                onPressed: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                ),
              ),
              const SizedBox(width: 4),
              ..._buildPageButtons(totalPages),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Next page',
                onPressed: _currentPage < totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPageButtons(int totalPages) {
    final pages = <int>{};

    pages.add(1);
    pages.add(totalPages);
    pages.add(_currentPage);

    if (_currentPage > 1) {
      pages.add(_currentPage - 1);
    }

    if (_currentPage < totalPages) {
      pages.add(_currentPage + 1);
    }

    final sortedPages = pages.toList()..sort();
    final widgets = <Widget>[];

    for (var i = 0; i < sortedPages.length; i++) {
      if (i > 0 && sortedPages[i] - sortedPages[i - 1] > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Text(
              '…',
              style: AppTextStyles.of(
                figmaSize: 17,
                weight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      }

      final page = sortedPages[i];
      final selected = page == _currentPage;

      widgets.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _goToPage(page),
          child: Container(
            width: 36,
            height: 36,
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
                figmaSize: 16,
                weight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : AppColors.navy,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  // ============================================================
  // FILTERS
  // ============================================================

  // ============================================================
  // SEARCH + STATUS HELPERS
  // ============================================================

  void _clearSearch() {
    _searchController.clear();
  }

  void _changeStatus(String status) {
    if (!_statusFilters.contains(status)) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase().trim();

    final filtered = _orders.where((order) {
      final orderId = order['order_id']?.toString() ?? '';

      final customerName = order['full_name']?.toString().toLowerCase() ?? '';

      final mobile = order['mobile']?.toString().toLowerCase() ?? '';

      final email = order['email']?.toString().toLowerCase() ?? '';

      final orderStatus = order['order_status']?.toString().trim() ?? '';

      final paymentStatus = order['payment_status']?.toString().trim() ?? '';

      final matchesSearch =
          query.isEmpty ||
          orderId.toLowerCase().contains(query) ||
          customerName.contains(query) ||
          mobile.contains(query) ||
          email.contains(query);

      final bool matchesStatus = _selectedStatus == 'All'
          ? true
          : _selectedStatus == 'Payment Verified'
          ? paymentStatus.toLowerCase() == 'verified'
          : orderStatus.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    // Final defensive deduplication.
    final Map<int, Map<String, dynamic>> uniqueFiltered = {};

    for (final order in filtered) {
      final id = int.tryParse(order['order_id']?.toString() ?? '');

      if (id != null) {
        uniqueFiltered[id] = order;
      }
    }

    final result = uniqueFiltered.values.toList();

    result.sort((a, b) {
      final aId = int.tryParse(a['order_id']?.toString() ?? '0') ?? 0;

      final bId = int.tryParse(b['order_id']?.toString() ?? '0') ?? 0;

      return bId.compareTo(aId);
    });

    _filteredOrders = result;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _displayOrderId(Map<String, dynamic> order) {
    final id = order['order_id']?.toString() ?? '-';
    return '#RM$id';
  }

  String _customerName(Map<String, dynamic> order) {
    final name = order['full_name']?.toString().trim() ?? '';

    if (name.isEmpty) {
      return 'Customer';
    }

    return name;
  }

  String _mobile(Map<String, dynamic> order) {
    return order['mobile']?.toString().trim() ?? '-';
  }

  String _email(Map<String, dynamic> order) {
    return order['email']?.toString().trim() ?? '-';
  }

  String _amount(Map<String, dynamic> order) {
    final value = double.tryParse(order['order_amount']?.toString() ?? '');

    if (value == null) {
      return '₹0.00';
    }

    return '₹${value.toStringAsFixed(2)}';
  }

  String _status(Map<String, dynamic> order) {
    final status = order['order_status']?.toString().trim();

    if (status == null || status.isEmpty) {
      return 'New Order';
    }

    return status;
  }

  String _paymentStatus(Map<String, dynamic> order) {
    final status = order['payment_status']?.toString().trim();

    if (status == null || status.isEmpty) {
      return 'Pending';
    }

    return status;
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final raw = value.toString();

    if (raw.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(raw).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
          ? date.hour - 12
          : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$day/$month/$year, '
          '${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains('cancel')) {
      return Colors.red;
    }

    if (value.contains('complete')) {
      return Colors.green;
    }

    if (value.contains('active')) {
      return Colors.green;
    }

    if (value.contains('install')) {
      return Colors.orange;
    }

    if (value.contains('payment verified')) {
      return Colors.indigo;
    }

    if (value.contains('verified')) {
      return Colors.indigo;
    }

    return AppColors.ctaPurple;
  }

  Color _paymentColor(String status) {
    final value = status.toLowerCase();

    if (value == 'verified' || value == 'successful') {
      return Colors.green;
    }

    if (value == 'failed' || value == 'cancelled') {
      return Colors.red;
    }

    return Colors.orange;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.white,
        child: AdminSidebar(
          compact: false,
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width >= 1100) {
              return _buildDesktopLayout(context);
            }

            if (width >= 700) {
              return _buildTabletLayout(context);
            }

            return _buildMobileLayout(context);
          },
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 250,
          child: AdminSidebar(compact: false),
        ),
        Expanded(
          child: _buildMainContent(
            context,
            showMenuButton: false,
            horizontalPadding: 32,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 82,
          child: AdminSidebar(compact: true),
        ),
        Expanded(
          child: _buildMainContent(
            context,
            showMenuButton: false,
            horizontalPadding: 24,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout(BuildContext context) {
    return _buildMainContent(
      context,
      showMenuButton: true,
      horizontalPadding: 16,
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent(
    BuildContext context, {
    required bool showMenuButton,
    required double horizontalPadding,
  }) {
    return Column(
      children: [
        _buildTopBar(context, showMenuButton: showMenuButton),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                32,
              ),
              children: [
                _buildPageHeader(context),
                const SizedBox(height: 20),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildSearchAndFilterSection(),
                const SizedBox(height: 18),
                _buildOrdersSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context, {required bool showMenuButton}) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.navy,
                );
              },
            ),
          if (showMenuButton) const SizedBox(width: 4),
          if (!showMenuButton)
            const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.ctaPurple,
              size: 26,
            ),
          const SizedBox(width: 12),
          Text(
            'Orders',
            style: AppTextStyles.of(
              figmaSize: 30,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadOrders,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.ctaPurple,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: AppTextStyles.of(
                      figmaSize: 42,
                      weight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage customer orders and rental status',
                    style: AppTextStyles.of(
                      figmaSize: 21,
                      weight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openCreateManualOrder,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 21,
                  ),
                  label: const Text(
                    'Create Order',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: AppTextStyles.of(
                      figmaSize: 42,
                      weight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage customer orders and rental status',
                    style: AppTextStyles.of(
                      figmaSize: 21,
                      weight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            ElevatedButton.icon(
              onPressed: _openCreateManualOrder,
              icon: const Icon(
                Icons.add_rounded,
                size: 21,
              ),
              label: const Text(
                'Create Order',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CREATE MANUAL ORDER
  // ============================================================

  Future<void> _openCreateManualOrder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const CreateManualOrderDialog();
      },
    );

    if (!mounted || result == null) {
      return;
    }

    // The dialog closes automatically after the backend successfully
    // creates the order and returns the complete API response.
    // Refresh the Orders screen so the new order appears immediately.
    await _loadOrders();
    await _loadScheduledInstallations();
    await _loadDeliveryAssignments();

    if (!mounted) {
      return;
    }

    final emailStatus =
        result['email_status']?.toString().trim().toLowerCase();

    final receiptStatus =
        result['receipt_status']?.toString().trim().toLowerCase();

    if (emailStatus == 'sent') {
      _showMessage(
        'Order created successfully. Confirmation email sent to customer.',
      );
    } else if (emailStatus == 'failed') {
      _showMessage(
        'Order created successfully, but confirmation email could not be sent.',
      );
    } else if (emailStatus == 'not_available') {
      _showMessage(
        'Order created successfully, but customer email is not available.',
      );
    } else if (receiptStatus == 'failed') {
      _showMessage(
        'Order created successfully, but receipt could not be generated.',
      );
    } else {
      _showMessage(
        'Manual order created successfully.',
      );
    }
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 900) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Orders',
                  value: _totalOrders.toString(),
                  icon: Icons.shopping_bag_outlined,
                  iconBackground: const Color(0xFFEDEAFF),
                  iconColor: AppColors.ctaPurple,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Payment Verified',
                  value: _verifiedPayments.toString(),
                  icon: Icons.verified_rounded,
                  iconBackground: const Color(0xFFE7F7ED),
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Rentals',
                  value: _activeRentals.toString(),
                  icon: Icons.home_work_outlined,
                  iconBackground: const Color(0xFFFFF1DE),
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Installations',
                  value: _scheduledInstallationCount.toString(),
                  icon: Icons.build_circle_outlined,
                  iconBackground: const Color(0xFFE9F2FF),
                  iconColor: Colors.blue,
                ),
              ),
            ],
          );
        }

        if (width >= 500) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Total Orders',
                value: _totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
                iconBackground: const Color(0xFFEDEAFF),
                iconColor: AppColors.ctaPurple,
              ),
              _buildStatCard(
                title: 'Payment Verified',
                value: _verifiedPayments.toString(),
                icon: Icons.verified_rounded,
                iconBackground: const Color(0xFFE7F7ED),
                iconColor: Colors.green,
              ),
              _buildStatCard(
                title: 'Active Rentals',
                value: _activeRentals.toString(),
                icon: Icons.home_work_outlined,
                iconBackground: const Color(0xFFFFF1DE),
                iconColor: Colors.orange,
              ),
              _buildStatCard(
                title: 'Installations',
                value: _scheduledInstallationCount.toString(),
                icon: Icons.build_circle_outlined,
                iconBackground: const Color(0xFFE9F2FF),
                iconColor: Colors.blue,
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Orders',
                    value: _totalOrders.toString(),
                    icon: Icons.shopping_bag_outlined,
                    iconBackground: const Color(0xFFEDEAFF),
                    iconColor: AppColors.ctaPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Payment Verified',
                    value: _verifiedPayments.toString(),
                    icon: Icons.verified_rounded,
                    iconBackground: const Color(0xFFE7F7ED),
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Rentals',
                    value: _activeRentals.toString(),
                    icon: Icons.home_work_outlined,
                    iconBackground: const Color(0xFFFFF1DE),
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Installations',
                    value: _scheduledInstallationCount.toString(),
                    icon: Icons.build_circle_outlined,
                    iconBackground: const Color(0xFFE9F2FF),
                    iconColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 18,
                    weight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.of(
                    figmaSize: 33,
                    weight: FontWeight.w800,
                    color: AppColors.navy,
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
  // SEARCH + FILTER
  // ============================================================

  Widget _buildSearchAndFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              _buildStatusDropdown(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildSearchField()),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: _buildStatusDropdown()),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search order, customer or mobile...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.ctaPurple, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _statusFilters.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 21,
                  weight: FontWeight.w400,
                  color: AppColors.navy,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            _changeStatus(value);
          },
        ),
      ),
    );
  }

  // ============================================================
  // ORDERS SECTION
  // ============================================================

  Widget _buildOrdersSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ordersView = constraints.maxWidth >= 900
            ? _buildDesktopOrdersTable()
            : _buildMobileOrderList();

        return Column(
          children: [
            ordersView,
            _buildPagination(),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 70),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.ctaPurple),
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
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          Text(
            'Unable to load orders',
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
            onPressed: _loadOrders,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.ctaPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'All'
                ? 'No matching orders'
                : 'No orders found',
            style: AppTextStyles.of(
              figmaSize: 27,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'All'
                ? 'Try changing your search or filter.'
                : 'Orders will appear here once customers place them.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 22.5,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedStatus != 'All') ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                _clearSearch();

                setState(() {
                  _selectedStatus = 'All';
                  _applyFilters();
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopOrdersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1080),
            child: DataTable(
              headingRowHeight: 52,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 82,
              horizontalMargin: 20,
              columnSpacing: 22,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFD)),
              columns: const [
                DataColumn(label: Text('Order')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('')),
              ],
              rows: _paginatedOrders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(
                          _displayOrderId(order),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w700,
                            color: AppColors.ctaPurple,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          _customerName(order),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: Text(
                          _amount(order),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildPaymentBadge(_paymentStatus(order)),
                    ),
                    DataCell(
                      _buildStatusBadge(_status(order)),
                    ),
                    DataCell(
                      SizedBox(
                        width: 175,
                        child: Text(
                          _formatDate(order['created_at']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        onPressed: () => _showOrderDetails(order),
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                        ),
                        color: Colors.grey.shade600,
                        tooltip: 'View order',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE / TABLET LIST
  // ============================================================

  Widget _buildMobileOrderList() {
    return Column(
      children: _paginatedOrders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCard(order),
        );
      }).toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderStatus = _status(order);
    final paymentStatus = _paymentStatus(order);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetails(order),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayOrderId(order),
                          style: AppTextStyles.of(
                            figmaSize: 24,
                            weight: FontWeight.w800,
                            color: AppColors.ctaPurple,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatDate(order['created_at']),
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w400,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _amount(order),
                    style: AppTextStyles.of(
                      figmaSize: 25.5,
                      weight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.ctaPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName(order),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _mobile(order),
                          style: AppTextStyles.of(
                            figmaSize: 22.5,
                            weight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentBadge(paymentStatus),
                  _buildStatusBadge(orderStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BADGES
  // ============================================================

  Widget _buildPaymentBadge(String status) {
    final color = _paymentColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.toLowerCase() == 'verified'
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // ORDER DETAILS
  // ============================================================

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    final currentOrderStatus = _status(order).trim().toLowerCase();

    // Delivery is the first actionable step after payment verification.
    // Wait for the API call to finish BEFORE opening the dialog so the
    // delivery-partner dropdown does not stay on the loading state.
    if (currentOrderStatus == 'payment verified') {
      await _loadDeliveryPartners();
    }

    // Installation starts only after delivery is completed.
    if (currentOrderStatus == 'delivered') {
      _selectedInstallationPartnerId = null;
      _selectedInstallationDate = null;
      _selectedInstallationTime = null;
      await _loadInstallationPartners();
    }

    // Existing installation details are loaded once the installation has
    // been scheduled/completed or the rental has been activated.
    if (currentOrderStatus == 'installation scheduled' ||
        currentOrderStatus == 'installation completed' ||
        currentOrderStatus == 'active rental') {
      final orderId = int.tryParse(order['order_id']?.toString() ?? '');
      if (orderId != null) {
        await _loadInstallationForOrder(orderId);
      }
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: size.width < 820 ? size.width - 32 : 800,
            height: size.height * 0.84,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order ${_displayOrderId(order)}',
                            style: AppTextStyles.of(
                              figmaSize: 31.5,
                              weight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      children: [
                        _buildDetailsAmountCard(order),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'Order Information',
                          icon: Icons.receipt_long_outlined,
                          children: [
                            _buildDetailRow('Order ID', _displayOrderId(order)),
                            _buildDetailRow(
                              'Created',
                              _formatDate(order['created_at']),
                            ),
                            _buildDetailRow(
                              'Updated',
                              _formatDate(order['updated_at']),
                            ),
                            _buildDetailRow('Order Status', _status(order)),
                            _buildDetailRow(
                              'Payment Status',
                              _paymentStatus(order),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ValueListenableBuilder<int>(
                          valueListenable: _workflowRefresh,
                          builder: (context, _, __) =>
                              _buildInstallationWorkflowCard(order),
                        ),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'Customer Details',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildDetailRow('Name', _customerName(order)),
                            _buildDetailRow('Mobile', _mobile(order)),
                            _buildDetailRow('Email', _email(order)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'Delivery Address',
                          icon: Icons.location_on_outlined,
                          children: [
                            _buildDetailRow(
                              'House / Flat',
                              _value(order['house_flat_number']),
                            ),
                            _buildDetailRow(
                              'Apartment',
                              _value(order['apartment_name']),
                            ),
                            _buildDetailRow(
                              'Street / Area',
                              _value(order['street_area']),
                            ),
                            _buildDetailRow(
                              'Landmark',
                              _value(order['landmark']),
                            ),
                            _buildDetailRow('City', _value(order['city'])),
                            _buildDetailRow(
                              'Pincode',
                              _value(order['pincode']),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildDeliveryAssignmentCard(Map<String, dynamic> order) {
    final orderId = int.tryParse(
      order['order_id']?.toString() ?? '',
    );
    final currentStatus = _status(order);
    final assignedPartner = orderId == null
        ? null
        : _assignedDeliveryPartners[orderId];

    final isDeliveryAssigned =
        currentStatus.toLowerCase() == 'delivery assigned';
    final isDelivered = currentStatus.toLowerCase() == 'delivered' ||
        currentStatus.toLowerCase() == 'installation scheduled' ||
        currentStatus.toLowerCase() == 'installation completed' ||
        currentStatus.toLowerCase() == 'active rental';

    if (isDeliveryAssigned || isDelivered) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  size: 20,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDelivered
                        ? 'Delivery Completed'
                        : 'Delivery Scheduled',
                    style: AppTextStyles.of(
                      figmaSize: 22.5,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 21,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
              'Partner',
              _value(
                assignedPartner?['partner_name'] ??
                    assignedPartner?['contact_person'],
              ),
            ),
            _buildDetailRow(
              'Mobile',
              _value(assignedPartner?['mobile']),
            ),
            _buildDetailRow('Status', isDelivered ? 'Delivered' : currentStatus),
            if (isDeliveryAssigned) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isMarkingDelivered
                      ? null
                      : () => _markOrderAsDelivered(order: order),
                  icon: _isMarkingDelivered
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isMarkingDelivered
                        ? 'Completing Delivery...'
                        : 'Mark Delivery Completed',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppColors.ctaPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Schedule Delivery',
                  style: AppTextStyles.of(
                    figmaSize: 22.5,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select the delivery partner for this paid order.',
            style: AppTextStyles.of(
              figmaSize: 18,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoadingDeliveryPartners)
            Container(
              height: 52,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading delivery partners...',
                    style: AppTextStyles.of(
                      figmaSize: 18,
                      weight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else if (_deliveryPartnersError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load delivery partners: $_deliveryPartnersError',
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton.icon(
                  onPressed: _loadDeliveryPartners,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (_deliveryPartners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'No active delivery partners available.',
                style: AppTextStyles.of(
                  figmaSize: 18,
                  weight: FontWeight.w500,
                  color: Colors.orange.shade800,
                ),
              ),
            )
          else
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Delivery Partner',
                labelStyle: AppTextStyles.of(
                  figmaSize: 17,
                  weight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
              isExpanded: true,
              hint: const Text('Select delivery partner'),
              items: _deliveryPartners
                  .map((partner) {
                    final id = int.tryParse(
                      partner['delivery_partner_id']?.toString() ?? '',
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
                          figmaSize: 18,
                          weight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    );
                  })
                  .whereType<DropdownMenuItem<int>>()
                  .toList(),
              onChanged: _isAssigningDelivery
                  ? null
                  : (partnerId) {
                      if (partnerId == null) return;

                      final partner = _deliveryPartners.firstWhere(
                        (item) =>
                            item['delivery_partner_id']?.toString() ==
                            partnerId.toString(),
                      );

                      _confirmAndAssignDelivery(
                        order: order,
                        partner: partner,
                      );
                    },
            ),
          if (_isAssigningDelivery) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Scheduling delivery...',
                  style: AppTextStyles.of(
                    figmaSize: 18,
                    weight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmAndAssignDelivery({
    required Map<String, dynamic> order,
    required Map<String, dynamic> partner,
  }) async {
    final partnerName = _value(
      partner['partner_name'] ?? partner['contact_person'],
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Schedule Delivery'),
          content: Text(
            'Schedule delivery for ${_displayOrderId(order)} with $partnerName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Schedule'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _assignDeliveryPartner(
      order: order,
      partner: partner,
    );
  }


  Widget _buildInstallationWorkflowCard(Map<String, dynamic> order) {
    final status = _status(order).trim().toLowerCase();
    final orderId = int.tryParse(order['order_id']?.toString() ?? '');

    if (status == 'new order') {
      return _buildWorkflowBanner(
        icon: Icons.schedule_rounded,
        title: 'Waiting for payment',
        message: 'This order becomes actionable after payment is verified.',
      );
    }

    if (status == 'payment verified') {
      return _buildDeliveryAssignmentCard(order);
    }

    if (status == 'delivery assigned') {
      return _buildDeliveryAssignmentCard(order);
    }

    if (status == 'delivered') {
      return _buildScheduleInstallationCard(order);
    }

    if (status == 'installation scheduled' ||
        status == 'installation completed' ||
        status == 'active rental') {
      return _buildScheduledInstallationCard(order, orderId);
    }

    return _buildWorkflowBanner(
      icon: Icons.info_outline_rounded,
      title: _status(order),
      message: 'No workflow action is available for this status.',
    );
  }

  Widget _buildWorkflowBanner({
    required IconData icon,
    required String title,
    required String message,
    bool success = false,
  }) {
    final iconColor = success ? Colors.green.shade700 : AppColors.ctaPurple;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withValues(alpha: 0.06)
            : AppColors.ctaPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: success
              ? Colors.green.withValues(alpha: 0.14)
              : AppColors.ctaPurple.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.of(
                    figmaSize: 18,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.of(
                    figmaSize: 15,
                    weight: FontWeight.w400,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInstallationCard(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 20,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Assign Installation Partner',
                  style: AppTextStyles.of(
                    figmaSize: 22.5,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Delivery is completed. Select the installation partner, date and time.',
            style: AppTextStyles.of(
              figmaSize: 18,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoadingInstallationPartners)
            const SizedBox(
              height: 52,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_installationPartnersError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load installation partners: $_installationPartnersError',
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton.icon(
                  onPressed: _loadInstallationPartners,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (_installationPartners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'No active installation partners available.',
                style: AppTextStyles.of(
                  figmaSize: 18,
                  weight: FontWeight.w500,
                  color: Colors.orange.shade800,
                ),
              ),
            )
          else ...[
            DropdownButtonFormField<int>(
              initialValue: _installationPartners.any(
                (item) =>
                    item['installation_partner_id']?.toString() ==
                    _selectedInstallationPartnerId?.toString(),
              )
                  ? _selectedInstallationPartnerId
                  : null,
              decoration: InputDecoration(
                labelText: 'Installation Partner',
                labelStyle: AppTextStyles.of(
                  figmaSize: 17,
                  weight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              isExpanded: true,
              hint: const Text('Select installation partner'),
              items: _installationPartners
                  .map((partner) {
                    final id = int.tryParse(
                      partner['installation_partner_id']?.toString() ?? '',
                    );
                    if (id == null) return null;
                    final name = _value(
                      partner['partner_name'] ?? partner['contact_person'],
                    );
                    final mobile = _value(partner['mobile']);
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        mobile == '-' ? name : '$name • $mobile',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.of(
                          figmaSize: 18,
                          weight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    );
                  })
                  .whereType<DropdownMenuItem<int>>()
                  .toList(),
              onChanged: _isSchedulingInstallation
                  ? null
                  : (value) {
                      setState(
                        () => _selectedInstallationPartnerId = value,
                      );
                      _workflowRefresh.value++;
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSchedulingInstallation
                        ? null
                        : _pickInstallationDate,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _displayInstallationDate(
                        _selectedInstallationDate,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSchedulingInstallation
                        ? null
                        : _pickInstallationTime,
                    icon: const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _displayInstallationTime(
                        _selectedInstallationTime,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSchedulingInstallation
                    ? null
                    : () => _scheduleInstallation(order: order),
                icon: _isSchedulingInstallation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.event_available_rounded),
                label: Text(
                  _isSchedulingInstallation
                      ? 'Scheduling Installation...'
                      : 'Schedule Installation',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduledInstallationCard(
    Map<String, dynamic> order,
    int? orderId,
  ) {
    final installation = orderId == null
        ? null
        : _scheduledInstallationByOrder[orderId];
    final partner = installation?['installation_partner'];
    final partnerName = partner is Map
        ? _value(
            partner['partner_name'] ?? partner['contact_person'],
          )
        : _value(
            installation?['installation_partner_name'] ??
                installation?['partner_name'],
          );
    final partnerMobile = partner is Map
        ? _value(partner['mobile'])
        : _value(
            installation?['installation_partner_mobile'] ??
                installation?['mobile'],
          );
    final scheduledDate =
        installation?['scheduled_date'] ?? order['scheduled_date'];
    final scheduledAt =
        installation?['scheduled_at'] ?? order['scheduled_at'];
    final status = _status(order);
    final normalizedStatus = status.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_circle_rounded,
                size: 20,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  normalizedStatus == 'installation completed'
                      ? 'Installation Completed'
                      : normalizedStatus == 'active rental'
                      ? 'Installation Completed'
                      : 'Installation Details',
                  style: AppTextStyles.of(
                    figmaSize: 22.5,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 21,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Status', status),
          _buildDetailRow('Partner', partnerName),
          _buildDetailRow('Mobile', partnerMobile),
          _buildDetailRow(
            'Date',
            scheduledDate?.toString().split('T').first ?? '-',
          ),
          _buildDetailRow(
            'Time',
            scheduledAt?.toString() ?? '-',
          ),
          if (normalizedStatus == 'installation scheduled') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCompletingInstallation
                    ? null
                    : () => _markInstallationCompleted(
                          order: order,
                        ),
                icon: _isCompletingInstallation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: Text(
                  _isCompletingInstallation
                      ? 'Completing Installation...'
                      : 'Mark Installation Completed',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (normalizedStatus == 'installation completed') ...[
            const SizedBox(height: 12),
            _buildWorkflowBanner(
              icon: Icons.task_alt_rounded,
              title: 'Installation completed',
              message: 'The installation is complete. The rental can now be activated.',
              success: true,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isActivatingRental
                    ? null
                    : () => _activateRental(order: order),
                icon: _isActivatingRental
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.home_work_rounded),
                label: Text(
                  _isActivatingRental
                      ? 'Activating Rental...'
                      : 'Activate Rental',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (normalizedStatus == 'active rental') ...[
            const SizedBox(height: 12),
            _buildWorkflowBanner(
              icon: Icons.check_circle_rounded,
              title: 'Rental is active',
              message: 'The order workflow is complete.',
              success: true,
            ),
          ],
        ],
      ),
    );
  }

  String _value(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? '-' : text;
  }

  Widget _buildDetailsAmountCard(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.ctaPurple,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Amount',
                  style: AppTextStyles.of(
                    figmaSize: 22.5,
                    weight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _amount(order),
                  style: AppTextStyles.of(
                    figmaSize: 33,
                    weight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          _buildPaymentBadge(_paymentStatus(order)),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.ctaPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.of(
                  figmaSize: 22.5,
                  weight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.of(
                figmaSize: 22.5,
                weight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.of(
                figmaSize: 22.5,
                weight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  // Sidebar navigation is provided by AdminSidebar so every admin
  // screen uses the same width, spacing, selected state and routes.
}
