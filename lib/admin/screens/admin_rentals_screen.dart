import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../theme/app_text_styles.dart';
import 'admin_orders_style_shell.dart';

class AdminRentalsScreen extends StatefulWidget {
  const AdminRentalsScreen({super.key});

  @override
  State<AdminRentalsScreen> createState() => _AdminRentalsScreenState();
}

class _AdminRentalsScreenState extends State<AdminRentalsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _rentals = [];
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const int _rowsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRentals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rentals = await ApiService.getAdminRentals();

      final unique = <String, Map<String, dynamic>>{};
      for (final rental in rentals) {
        final id = _stringValue(rental['rental_id']);
        if (id.isNotEmpty) unique[id] = rental;
      }

      final list = unique.values.toList()
        ..sort((a, b) => _intValue(b['rental_id'])
            .compareTo(_intValue(a['rental_id'])));

      if (!mounted) return;
      setState(() {
        _rentals = list;
        _currentPage = 1;
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

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _intValue(dynamic value) {
    return int.tryParse(_stringValue(value)) ?? 0;
  }

  static double _doubleValue(dynamic value) {
    return double.tryParse(_stringValue(value)) ?? 0;
  }

  String _status(Map<String, dynamic> rental) {
    final value = _stringValue(rental['rental_status']);
    return value.isEmpty ? 'Unknown' : value;
  }

  List<Map<String, dynamic>> get _filteredRentals {
    final query = _searchQuery.trim().toLowerCase();

    return _rentals.where((rental) {
      final status = _status(rental);
      final statusMatch = _selectedStatus == 'All' ||
          status.toLowerCase() == _selectedStatus.toLowerCase();

      if (!statusMatch) return false;
      if (query.isEmpty) return true;

      final searchable = [
        rental['rental_id'],
        rental['order_id'],
        rental['order_item_id'],
        rental['customer_id'],
        rental['monthly_rent'],
        rental['start_date'],
        rental['rental_status'],
      ].map(_stringValue).join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  int get _totalPages {
    final count = _filteredRentals.length;
    if (count == 0) return 1;
    return (count / _rowsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedRentals {
    final filtered = _filteredRentals;

    if (filtered.isEmpty) return [];

    final safePage = _currentPage.clamp(1, _totalPages);
    final start = (safePage - 1) * _rowsPerPage;

    if (start >= filtered.length) return [];

    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _pageStart {
    if (_filteredRentals.isEmpty) return 0;
    return ((_currentPage - 1) * _rowsPerPage) + 1;
  }

  int get _pageEnd {
    if (_filteredRentals.isEmpty) return 0;
    final end = _currentPage * _rowsPerPage;
    return end > _filteredRentals.length ? _filteredRentals.length : end;
  }

  void _resetPagination() {
    if (_currentPage != 1) {
      setState(() => _currentPage = 1);
    }
  }

  int get _totalRentals => _rentals.length;

  int get _activeRentals => _rentals
      .where((r) => _status(r).toLowerCase() == 'active')
      .length;

  int get _completedRentals => _rentals
      .where((r) => _status(r).toLowerCase() == 'completed')
      .length;

  List<String> get _statuses {
    final values = <String>{};
    for (final rental in _rentals) {
      values.add(_status(rental));
    }

    final ordered = <String>[];
    for (final preferred in ['Active', 'Completed', 'Pending', 'Cancelled']) {
      final match = values.firstWhere(
        (v) => v.toLowerCase() == preferred.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) ordered.add(match);
    }

    final remaining = values
        .where((v) => !ordered.any(
              (o) => o.toLowerCase() == v.toLowerCase(),
            ))
        .toList()
      ..sort();

    return ['All', ...ordered, ...remaining];
  }

  TextStyle _text({
    required double size,
    required FontWeight weight,
    Color color = AppColors.navy,
  }) {
    return AppTextStyles.of(
      figmaSize: size,
      weight: weight,
      color: color,
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.checkGreen;
      case 'completed':
        return const Color(0xFF2563EB);
      case 'pending':
        return const Color(0xFFD97706);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return AppColors.textGray;
    }
  }

  String _date(dynamic value) {
    final raw = _stringValue(value);
    if (raw.isEmpty) return '—';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _dateTime(dynamic value) {
    final raw = _stringValue(value);
    if (raw.isEmpty) return '—';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _rent(dynamic value) {
    final amount = _doubleValue(value);
    return '₹${amount.toStringAsFixed(0)} / month';
  }

  List<AdminOrdersStyleStat> _ordersStyleRentalStats() => [
        AdminOrdersStyleStat(title: 'Total Rentals', value: '$_totalRentals', icon: Icons.home_work_outlined, iconBackground: const Color(0xFFEDEAFF), iconColor: AppColors.ctaPurple),
        AdminOrdersStyleStat(title: 'Active Rentals', value: '$_activeRentals', icon: Icons.check_circle_outline_rounded, iconBackground: const Color(0xFFE7F7ED), iconColor: Colors.green),
        AdminOrdersStyleStat(title: 'Completed', value: '$_completedRentals', icon: Icons.task_alt_rounded, iconBackground: const Color(0xFFE9F2FF), iconColor: Colors.blue),
        AdminOrdersStyleStat(title: 'Other', value: '${_totalRentals - _activeRentals - _completedRentals}', icon: Icons.pending_actions_outlined, iconBackground: const Color(0xFFFFF1DE), iconColor: Colors.orange),
      ];

  Widget _ordersStyleRentalFilters() => AdminOrdersStyleFilterRow(
        controller: _searchController,
        hintText: 'Search rental, order or customer ID...',
        selectedValue: _selectedStatus,
        values: _statuses,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedStatus = value;
              _currentPage = 1;
            });
          }
        },
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 1;
          });
        },
        onClear: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
            _currentPage = 1;
          });
        },
      );

  Widget _ordersStyleRentalContent() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_filteredRentals.isEmpty) return _buildEmpty();
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 900 ? _buildDesktopTable() : _buildMobileList());
  }

  @override
  Widget build(BuildContext context) {
    return AdminOrdersStyleShell(
      title: 'Rentals',
      subtitle: 'Track active rentals and rental history',
      refresh: _loadRentals,
      stats: _ordersStyleRentalStats(),
      filters: _ordersStyleRentalFilters(),
      content: _ordersStyleRentalContent(),
    );
  }


  Widget _buildTopBar(BuildContext context, {required bool mobile}) {
    return Container(
      height: mobile ? 64 : 72,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          if (mobile)
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Menu',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.navy,
                onPressed: () {
                  Scaffold.of(drawerContext).openDrawer();
                },
              ),
            ),
          if (mobile) const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rentals',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text(
                size: mobile ? 18 : 24,
                weight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadRentals,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.navy,
          ),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: _text(
                size: 15,
                weight: FontWeight.w800,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool mobile,
    required bool tablet,
  }) {
    return RefreshIndicator(
      onRefresh: _loadRentals,
      color: AppColors.ctaPurple,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 28,
          mobile ? 22 : 30,
          mobile ? 16 : 28,
          36,
        ),
        children: [
          Text(
            'Rental Management',
            style: _text(
              size: mobile ? 28 : 40,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Track active rentals and rental history',
            style: _text(
              size: mobile ? 13 : 17,
              weight: FontWeight.w500,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 22),
          _buildStats(mobile: mobile),
          const SizedBox(height: 20),
          _buildControls(mobile: mobile),
          const SizedBox(height: 18),
          if (_isLoading)
            _buildLoading()
          else if (_errorMessage != null)
            _buildError()
          else if (_filteredRentals.isEmpty)
            _buildEmpty()
          else if (mobile || tablet)
            _buildMobileList()
          else
            _buildDesktopTable(),

          if (_filteredRentals.isNotEmpty && _totalPages > 1) ...[
            const SizedBox(height: 14),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  Widget _buildStats({required bool mobile}) {
    final cards = [
      _StatData(
        label: 'Total Rentals',
        value: _totalRentals.toString(),
        icon: Icons.home_work_outlined,
        background: AppColors.bgCardPurple,
        accent: AppColors.purple,
      ),
      _StatData(
        label: 'Active Rentals',
        value: _activeRentals.toString(),
        icon: Icons.check_circle_outline_rounded,
        background: AppColors.bgCardNeutral,
        accent: AppColors.checkGreen,
      ),
      _StatData(
        label: 'Completed',
        value: _completedRentals.toString(),
        icon: Icons.task_alt_rounded,
        background: AppColors.bgCardLavender,
        accent: const Color(0xFF2563EB),
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatCard(cards[2]),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard(cards[0])),
        const SizedBox(width: 14),
        Expanded(child: _buildStatCard(cards[1])),
        const SizedBox(width: 14),
        Expanded(child: _buildStatCard(cards[2])),
      ],
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.accent.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    size: 22.5,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: _text(
                    size: 27,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls({required bool mobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) => setState(() {
            _searchQuery = value;
            _currentPage = 1;
          }),
          style: _text(size: 14, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search rental, order or customer ID...',
            hintStyle: _text(
              size: 22.5,
              weight: FontWeight.w500,
              color: AppColors.textGraySoft,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textGrayMed,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.purple,
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final status = _statuses[index];
              final selected = _selectedStatus.toLowerCase() ==
                  status.toLowerCase();

              return ChoiceChip(
                label: Text(
                  status,
                  style: _text(
                    size: 16,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : AppColors.textGray,
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = status;
                    _currentPage = 1;
                  });
                },
                selectedColor: AppColors.ctaPurple,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected
                      ? AppColors.ctaPurple
                      : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: DataTable(
                headingRowHeight: 54,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 84,
                horizontalMargin: 16,
                columnSpacing: 12,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFFAFAFD)),
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 82,
                      child: Text(
                        'RENTAL',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 82,
                      child: Text(
                        'ORDER',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 92,
                      child: Text(
                        'CUSTOMER',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 135,
                      child: Text(
                        'MONTHLY RENT',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 125,
                      child: Text(
                        'START DATE',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 82,
                      child: Text(
                        'STATUS',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 82,
                      child: Text(
                        'ACTION',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: _paginatedRentals.map((rental) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 82,
                          child: Text(
                            '#R${_stringValue(rental['rental_id'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              size: 17,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 82,
                          child: Text(
                            '#O${_stringValue(rental['order_id'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              size: 17,
                              weight: FontWeight.w600,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 92,
                          child: Text(
                            '#C${_stringValue(rental['customer_id'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              size: 17,
                              weight: FontWeight.w600,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 135,
                          child: Text(
                            _rent(rental['monthly_rent']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              size: 17,
                              weight: FontWeight.w800,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 125,
                          child: Text(
                            _date(rental['start_date']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              size: 17,
                              weight: FontWeight.w600,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 82,
                          child: _buildStatusChip(_status(rental)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 82,
                          child: OutlinedButton(
                            onPressed: () => _showRentalDetails(rental),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(78, 40),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              foregroundColor: AppColors.purple,
                              side: const BorderSide(
                                color: AppColors.purple,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: Text(
                              'View',
                              style: _text(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AppColors.purple,
                              ),
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
        },
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _paginatedRentals
          .map(
            (rental) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRentalCard(rental),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPagination() {
    final totalPages = _totalPages;
    final page = _currentPage.clamp(1, totalPages).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final pageButtons = <Widget>[];

          int startPage;
          int endPage;

          if (totalPages <= 5) {
            startPage = 1;
            endPage = totalPages;
          } else if (page <= 3) {
            startPage = 1;
            endPage = 5;
          } else if (page >= totalPages - 2) {
            startPage = totalPages - 4;
            endPage = totalPages;
          } else {
            startPage = page - 2;
            endPage = page + 2;
          }

          for (int pageNumber = startPage;
              pageNumber <= endPage;
              pageNumber++) {
            final selected = pageNumber == page;

            pageButtons.add(
              InkWell(
                onTap: selected
                    ? null
                    : () => setState(() => _currentPage = pageNumber),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ctaPurple
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppColors.ctaPurple
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: _text(
                      size: 14,
                      weight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppColors.navy,
                    ),
                  ),
                ),
              ),
            );
          }

          final navigation = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: page > 1
                    ? () => setState(() => _currentPage = page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.navy,
              ),
              ...pageButtons.expand(
                (button) => [
                  const SizedBox(width: 4),
                  button,
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Next page',
                onPressed: page < totalPages
                    ? () => setState(() => _currentPage = page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.navy,
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                Text(
                  'Showing $_pageStart–$_pageEnd of ${_filteredRentals.length}',
                  style: _text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: navigation,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $_pageStart–$_pageEnd of ${_filteredRentals.length}',
                style: _text(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
              navigation,
            ],
          );
        },
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final status = _status(rental);
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
                      '#R${_stringValue(rental['rental_id'])}',
                      style: _text(
                        size: 17,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Order #${_stringValue(rental['order_id'])}',
                      style: _text(
                        size: 16,
                        weight: FontWeight.w600,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _detailValue(
                    'Customer',
                    '#C${_stringValue(rental['customer_id'])}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _detailValue(
                    'Order Item',
                    '#${_stringValue(rental['order_item_id'])}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _detailValue(
                  'Monthly Rent',
                  _rent(rental['monthly_rent']),
                  valueColor: AppColors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailValue(
                  'Start Date',
                  _date(rental['start_date']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Updated ${_dateTime(rental['updated_at'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    size: 11,
                    weight: FontWeight.w500,
                    color: AppColors.textGraySoft,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _showRentalDetails(rental),
                style: OutlinedButton.styleFrom(
                  foregroundColor: statusColor,
                  side: BorderSide(color: statusColor),
                  minimumSize: const Size(94, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: _text(
                    size: 15,
                    weight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailValue(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _text(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.textGraySoft,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _text(
            size: 22.5,
            weight: FontWeight.w800,
            color: valueColor ?? AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: _text(
          size: 14,
          weight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.ctaPurple,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load rentals',
            style: _text(
              size: 17,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: _text(
              size: 16,
              weight: FontWeight.w500,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _loadRentals,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home_work_outlined,
            size: 46,
            color: AppColors.textGraySoft,
          ),
          const SizedBox(height: 13),
          Text(
            'No rentals found',
            style: _text(
              size: 18,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try changing your search or rental filter.'
                : 'There are no rentals to display.',
            textAlign: TextAlign.center,
            style: _text(
              size: 16,
              weight: FontWeight.w500,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  void _showRentalDetails(Map<String, dynamic> rental) {
    final status = _status(rental);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: size.height * .84,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Rental Details',
                            style: _text(
                              size: 24,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _buildStatusChip(status),
                        const SizedBox(width: 12),
                        Material(
                          color: AppColors.background,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: const SizedBox(
                              width: 46,
                              height: 46,
                              child: Icon(
                                Icons.close_rounded,
                                size: 27,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sheetSection(
                      'Rental Information',
                      [
                        _sheetRow(
                          'Rental ID',
                          '#R${_stringValue(rental['rental_id'])}',
                        ),
                        _sheetRow(
                          'Order ID',
                          '#O${_stringValue(rental['order_id'])}',
                        ),
                        _sheetRow(
                          'Order Item ID',
                          '#${_stringValue(rental['order_item_id'])}',
                        ),
                        _sheetRow(
                          'Customer ID',
                          '#C${_stringValue(rental['customer_id'])}',
                        ),
                        _sheetRow(
                          'Monthly Rent',
                          _rent(rental['monthly_rent']),
                          valueColor: AppColors.purple,
                        ),
                        _sheetRow(
                          'Start Date',
                          _dateTime(rental['start_date']),
                        ),
                        _sheetRow(
                          'Status',
                          status,
                          valueColor: _statusColor(status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sheetSection(
                      'Record Information',
                      [
                        _sheetRow(
                          'Created At',
                          _dateTime(rental['created_at']),
                        ),
                        _sheetRow(
                          'Updated At',
                          _dateTime(rental['updated_at']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetSection(
    String title,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _text(
              size: 21,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _sheetRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: _text(
                size: 15,
                weight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _text(
                size: 18,
                weight: FontWeight.w700,
                color: valueColor ?? AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color accent;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.accent,
  });
}
