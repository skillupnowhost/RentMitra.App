import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_sidebar.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  bool _isLoading = true;
  bool _isCrudLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];

  int _totalCustomers = 0;
  int _activeCustomers = 0;
  int _inactiveCustomers = 0;

  String _selectedStatus = 'All';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = const ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final value = _searchController.text.trim();

      if (_searchQuery != value) {
        setState(() {
          _searchQuery = value;
          _applyFilters();
        });
      }
    });

    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CUSTOMERS
  // ============================================================

  Future<void> _loadCustomers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = await ApiService.getAdminCustomers();

      final Map<int, Map<String, dynamic>> uniqueCustomerMap = {};

      for (final customer in customers) {
        final customerId = int.tryParse(
          customer['customer_id']?.toString() ?? '',
        );

        if (customerId == null) {
          continue;
        }

        uniqueCustomerMap[customerId] = customer;
      }

      final cleanedCustomers = uniqueCustomerMap.values.toList();

      cleanedCustomers.sort((a, b) {
        final aId = int.tryParse(a['customer_id']?.toString() ?? '0') ?? 0;

        final bId = int.tryParse(b['customer_id']?.toString() ?? '0') ?? 0;

        return bId.compareTo(aId);
      });

      int activeCount = 0;
      int inactiveCount = 0;

      for (final customer in cleanedCustomers) {
        if (_isCustomerActive(customer)) {
          activeCount++;
        } else {
          inactiveCount++;
        }
      }

      if (!mounted) return;

      setState(() {
        _customers = cleanedCustomers;
        _filteredCustomers = cleanedCustomers;
        _totalCustomers = cleanedCustomers.length;
        _activeCustomers = activeCount;
        _inactiveCustomers = inactiveCount;

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

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // FILTERS
  // ============================================================

  void _applyFilters() {
    final query = _searchQuery.toLowerCase().trim();

    final filtered = _customers.where((customer) {
      final customerId =
          customer['customer_id']?.toString().toLowerCase() ?? '';

      final name = customer['full_name']?.toString().toLowerCase() ?? '';

      final mobile = customer['mobile']?.toString().toLowerCase() ?? '';

      final email = customer['email']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          customerId.contains(query) ||
          name.contains(query) ||
          mobile.contains(query) ||
          email.contains(query);

      final active = _isCustomerActive(customer);

      final matchesStatus = switch (_selectedStatus) {
        'Active' => active,
        'Inactive' => !active,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final aId = int.tryParse(a['customer_id']?.toString() ?? '0') ?? 0;

      final bId = int.tryParse(b['customer_id']?.toString() ?? '0') ?? 0;

      return bId.compareTo(aId);
    });

    _filteredCustomers = filtered;
  }

  void _changeStatus(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _applyFilters();
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedStatus = 'All';
      _applyFilters();
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isCustomerActive(Map<String, dynamic> customer) {
    final value = customer['is_active'];

    if (value is bool) {
      return value;
    }

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'active' || text == 'yes';
  }

  String _customerId(Map<String, dynamic> customer) {
    final id = customer['customer_id']?.toString() ?? '-';

    return '#C$id';
  }

  String _customerName(Map<String, dynamic> customer) {
    final name = customer['full_name']?.toString().trim() ?? '';

    return name.isEmpty ? 'Customer' : name;
  }

  String _mobile(Map<String, dynamic> customer) {
    final mobile = customer['mobile']?.toString().trim() ?? '';

    return mobile.isEmpty ? '-' : mobile;
  }

  String _email(Map<String, dynamic> customer) {
    final email = customer['email']?.toString().trim() ?? '';

    return email.isEmpty ? '-' : email;
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

      return '$day/$month/$year';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(bool active) {
    return active ? Colors.green : Colors.red;
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
          onNavigate: () {
            Navigator.of(context).pop();
          },
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
            onRefresh: _loadCustomers,
            color: AppColors.ctaPurple,
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
                _buildCustomersSection(),
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
              Icons.people_outline_rounded,
              color: AppColors.ctaPurple,
              size: 26,
            ),
          const SizedBox(width: 12),
          Text(
            'Customers',
            style: AppTextStyles.of(
              figmaSize: 30,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadCustomers,
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
        final isMobile = constraints.maxWidth < 650;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customers',
              style: AppTextStyles.of(
                figmaSize: 42,
                weight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage customer accounts and contact information',
              style: AppTextStyles.of(
                figmaSize: 21,
                weight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );

        final addButton = SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isCrudLoading ? null : () => _showCustomerForm(),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
            label: const Text('Add Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPurple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleSection,
              const SizedBox(height: 14),
              addButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 18),
            addButton,
          ],
        );
      },
    );
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
                  title: 'Total Customers',
                  value: _totalCustomers.toString(),
                  icon: Icons.people_outline_rounded,
                  iconBackground: const Color(0xFFEDEAFF),
                  iconColor: AppColors.ctaPurple,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Customers',
                  value: _activeCustomers.toString(),
                  icon: Icons.verified_user_outlined,
                  iconBackground: const Color(0xFFE7F7ED),
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Inactive Customers',
                  value: _inactiveCustomers.toString(),
                  icon: Icons.person_off_outlined,
                  iconBackground: const Color(0xFFFFEEEE),
                  iconColor: Colors.red,
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
                title: 'Total Customers',
                value: _totalCustomers.toString(),
                icon: Icons.people_outline_rounded,
                iconBackground: const Color(0xFFEDEAFF),
                iconColor: AppColors.ctaPurple,
              ),
              _buildStatCard(
                title: 'Active Customers',
                value: _activeCustomers.toString(),
                icon: Icons.verified_user_outlined,
                iconBackground: const Color(0xFFE7F7ED),
                iconColor: Colors.green,
              ),
              _buildStatCard(
                title: 'Inactive Customers',
                value: _inactiveCustomers.toString(),
                icon: Icons.person_off_outlined,
                iconBackground: const Color(0xFFFFEEEE),
                iconColor: Colors.red,
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
                    title: 'Total Customers',
                    value: _totalCustomers.toString(),
                    icon: Icons.people_outline_rounded,
                    iconBackground: const Color(0xFFEDEAFF),
                    iconColor: AppColors.ctaPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Customers',
                    value: _activeCustomers.toString(),
                    icon: Icons.verified_user_outlined,
                    iconBackground: const Color(0xFFE7F7ED),
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Inactive Customers',
              value: _inactiveCustomers.toString(),
              icon: Icons.person_off_outlined,
              iconBackground: const Color(0xFFFFEEEE),
              iconColor: Colors.red,
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
        hintText: 'Search customer, mobile or email...',
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(13)),
          borderSide: BorderSide(color: AppColors.ctaPurple, width: 1.4),
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
  // CUSTOMERS SECTION
  // ============================================================

  Widget _buildCustomersSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredCustomers.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktopCustomersTable();
        }

        return _buildMobileCustomerList();
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 70),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.ctaPurple),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

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
            'Unable to load customers',
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
              figmaSize: 19.5,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadCustomers,
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

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedStatus != 'All';

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
              Icons.people_outline_rounded,
              color: AppColors.ctaPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No matching customers' : 'No customers found',
            style: AppTextStyles.of(
              figmaSize: 27,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasFilters
                ? 'Try changing your search or filter.'
                : 'Customers will appear here once they register.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 19.5,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _clearFilters,
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

  Widget _buildDesktopCustomersTable() {
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
            constraints: const BoxConstraints(minWidth: 900),
            child: DataTable(
              headingRowHeight: 52,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 82,
              horizontalMargin: 20,
              columnSpacing: 28,
              headingRowColor: WidgetStatePropertyAll(Color(0xFFFAFAFD)),
              columns: const [
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Mobile')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Joined')),
                DataColumn(label: Text('')),
              ],
              rows: _filteredCustomers.map((customer) {
                final active = _isCustomerActive(customer);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        _customerId(customer),
                        style: AppTextStyles.of(
                          figmaSize: 21,
                          weight: FontWeight.w700,
                          color: AppColors.ctaPurple,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          _customerName(customer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 19.5,
                            weight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _mobile(customer),
                        style: AppTextStyles.of(
                          figmaSize: 19.5,
                          weight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          _email(customer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 18,
                            weight: FontWeight.w400,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(active)),
                    DataCell(
                      Text(
                        _formatDate(customer['created_at']),
                        style: AppTextStyles.of(
                          figmaSize: 18,
                          weight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        onPressed: () => _showCustomerDetails(customer),
                        icon: const Icon(Icons.more_vert_rounded, size: 21),
                        color: Colors.grey.shade600,
                        tooltip: 'Customer actions',
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

  Widget _buildMobileCustomerList() {
    return Column(
      children: _filteredCustomers.map((customer) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCustomerCard(customer),
        );
      }).toList(),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final active = _isCustomerActive(customer);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showCustomerDetails(customer);
        },
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEAFF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.ctaPurple,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName(customer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.of(
                            figmaSize: 23,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _customerId(customer),
                          style: AppTextStyles.of(
                            figmaSize: 17,
                            weight: FontWeight.w500,
                            color: AppColors.ctaPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(active),
                ],
              ),
              const SizedBox(height: 15),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 14),
              _buildContactRow(
                icon: Icons.phone_outlined,
                value: _mobile(customer),
              ),
              const SizedBox(height: 9),
              _buildContactRow(
                icon: Icons.email_outlined,
                value: _email(customer),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Joined ${_formatDate(customer['created_at'])}',
                    style: AppTextStyles.of(
                      figmaSize: 16.5,
                      weight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: 18,
              weight: FontWeight.w400,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(bool active) {
    final color = _statusColor(active);

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
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
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

  // ============================================================
  // CUSTOMER CRUD
  // ============================================================

  Future<void> _showCustomerForm({Map<String, dynamic>? customer}) async {
    final isEdit = customer != null;
    final nameController = TextEditingController(
      text: customer?['full_name']?.toString() ?? '',
    );
    final mobileController = TextEditingController(
      text: customer?['mobile']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: customer?['email']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
                content: SizedBox(
                  width: 460,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _customerFormField(
                            controller: nameController,
                            label: 'Full Name',
                            hint: 'Enter full name',
                            icon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.trim().length < 2) {
                                return 'Enter a valid full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _customerFormField(
                            controller: mobileController,
                            label: 'Mobile Number',
                            hint: '10 digit mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 10,
                            validator: (value) {
                              final mobile = value?.trim() ?? '';
                              if (mobile.isEmpty) {
                                return 'Mobile number is required';
                              }
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
                                return 'Enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _customerFormField(
                            controller: emailController,
                            label: 'Email Address',
                            hint: 'Enter email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email address is required';
                              }
                              if (!RegExp(
                                r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                              ).hasMatch(email)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setDialogState(() => saving = true);

                            try {
                              final name = nameController.text.trim();
                              final mobile = mobileController.text.trim();
                              final email = emailController.text.trim().toLowerCase();

                              if (isEdit) {
                                final id = int.tryParse(
                                  customer!['customer_id']?.toString() ?? '',
                                );
                                if (id == null) {
                                  throw Exception('Invalid customer ID.');
                                }

                                await ApiService.updateCustomer(
                                  customerId: id,
                                  fullName: name,
                                  mobile: mobile,
                                  email: email,
                                );
                              } else {
                                await ApiService.createAdminCustomer(
                                  fullName: name,
                                  mobile: mobile,
                                  email: email,
                                );
                              }

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            } catch (error) {
                              setDialogState(() => saving = false);
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text(_cleanErrorMessage(error)),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isEdit ? Icons.save_outlined : Icons.add_rounded),
                    label: Text(saving ? 'Saving...' : isEdit ? 'Save Changes' : 'Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Customer updated successfully.' : 'Customer created successfully.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadCustomers();
      }
    } finally {
      nameController.dispose();
      mobileController.dispose();
      emailController.dispose();
    }
  }

  Widget _customerFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF9F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.ctaPurple, width: 1.4),
        ),
      ),
    );
  }

  Future<void> _deactivateCustomer(Map<String, dynamic> customer) async {
    final id = int.tryParse(customer['customer_id']?.toString() ?? '');
    if (id == null) return;

    final confirmed = await _confirmCustomerAction(
      title: 'Deactivate Customer?',
      message: 'This will deactivate ${_customerName(customer)}. The customer will no longer be active.',
      actionLabel: 'Deactivate',
      actionColor: Colors.red,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isCrudLoading = true);
    try {
      await ApiService.deactivateCustomer(customerId: id);
      await _loadCustomers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_customerName(customer)} deactivated successfully.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanErrorMessage(error)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCrudLoading = false);
    }
  }

  Future<void> _reactivateCustomer(Map<String, dynamic> customer) async {
    final id = int.tryParse(customer['customer_id']?.toString() ?? '');
    if (id == null) return;

    final confirmed = await _confirmCustomerAction(
      title: 'Reactivate Customer?',
      message: 'This will make ${_customerName(customer)} active again.',
      actionLabel: 'Reactivate',
      actionColor: Colors.green,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isCrudLoading = true);
    try {
      await ApiService.reactivateCustomer(customerId: id);
      await _loadCustomers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_customerName(customer)} reactivated successfully.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanErrorMessage(error)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCrudLoading = false);
    }
  }

  Future<bool> _confirmCustomerAction({
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ============================================================
  // CUSTOMER DETAILS
  // ============================================================

  void _showCustomerDetails(Map<String, dynamic> customer) {
    final active = _isCustomerActive(customer);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFFD5D5DD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEAFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.ctaPurple,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customerName(customer),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.of(
                                  figmaSize: 27,
                                  weight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _customerId(customer),
                                style: AppTextStyles.of(
                                  figmaSize: 17,
                                  weight: FontWeight.w500,
                                  color: AppColors.ctaPurple,
                                ),
                              ),
                            ],
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCrudLoading
                                ? null
                                : () async {
                                    Navigator.of(context).pop();
                                    await _showCustomerForm(customer: customer);
                                  },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ctaPurple,
                              side: const BorderSide(color: AppColors.ctaPurple),
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCrudLoading
                                ? null
                                : () async {
                                    Navigator.of(context).pop();
                                    if (active) {
                                      await _deactivateCustomer(customer);
                                    } else {
                                      await _reactivateCustomer(customer);
                                    }
                                  },
                            icon: Icon(
                              active
                                  ? Icons.person_off_outlined
                                  : Icons.person_add_alt_1_outlined,
                              size: 18,
                            ),
                            label: Text(active ? 'Deactivate' : 'Reactivate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: active ? Colors.red : Colors.green,
                              side: BorderSide(
                                color: active ? Colors.red : Colors.green,
                              ),
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      children: [
                        _buildCustomerSummaryCard(customer, active),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'Customer Information',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildDetailRow(
                              'Customer ID',
                              _customerId(customer),
                            ),
                            _buildDetailRow(
                              'Full Name',
                              _customerName(customer),
                            ),
                            _buildDetailRow('Mobile', _mobile(customer)),
                            _buildDetailRow('Email', _email(customer)),
                            _buildDetailRow(
                              'Status',
                              active ? 'Active' : 'Inactive',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'Account Information',
                          icon: Icons.manage_accounts_outlined,
                          children: [
                            _buildDetailRow(
                              'Created',
                              _formatDate(customer['created_at']),
                            ),
                            _buildDetailRow(
                              'Last Updated',
                              _formatDate(customer['updated_at']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerSummaryCard(Map<String, dynamic> customer, bool active) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.ctaPurple,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: AppTextStyles.of(
                    figmaSize: 18,
                    weight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active ? 'Active Customer' : 'Inactive Customer',
                  style: AppTextStyles.of(
                    figmaSize: 24,
                    weight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(active),
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
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.of(
                    figmaSize: 22.5,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
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
                figmaSize: 18,
                weight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.of(
                figmaSize: 19.5,
                weight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }


}