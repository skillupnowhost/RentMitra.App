import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/admin_design_system.dart';
import '../../widgets/admin/admin_sidebar.dart';

class AdminVariantsScreen extends StatefulWidget {
  const AdminVariantsScreen({super.key});

  @override
  State<AdminVariantsScreen> createState() => _AdminVariantsScreenState();
}

class _AdminVariantsScreenState extends State<AdminVariantsScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isCrudLoading = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _filteredVariants = [];

  List<Map<String, dynamic>> _products = [];

  String _selectedStatus = 'All';
  String _searchQuery = '';

  final TextEditingController _searchController =
      TextEditingController();

  static const List<String> _statusFilters = [
    'All',
    'Active',
    'Inactive',
  ];

  // ============================================================
  // INIT
  // ============================================================

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

    _loadVariants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD VARIANTS
  // ============================================================

  Future<void> _loadVariants() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.getAdminVariants();

      debugPrint('==============================================');
      debugPrint('VARIANTS SCREEN');
      debugPrint('Variants received: ${results.length}');
      debugPrint('==============================================');

      final List<Map<String, dynamic>> cleaned = [];

      for (final item in results) {
        cleaned.add(
          Map<String, dynamic>.from(item),
        );
      }

      // Sort:
      // Active first
      // Then highest variant ID first
      cleaned.sort((a, b) {
        final aActive = _isActive(a);
        final bActive = _isActive(b);

        if (aActive != bActive) {
          return aActive ? -1 : 1;
        }

        final aId =
            int.tryParse(
              a['variant_id']?.toString() ?? '0',
            ) ??
            0;

        final bId =
            int.tryParse(
              b['variant_id']?.toString() ?? '0',
            ) ??
            0;

        return bId.compareTo(aId);
      });

      if (!mounted) return;

      setState(() {
        _variants = cleaned;
        _applyFilters();
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('VARIANTS LOAD ERROR: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(error);
      });
    }
  }

  // ============================================================
  // LOAD PRODUCTS
  // Used only when opening Create Variant dialog
  // ============================================================

  Future<void> _loadProductsForForm() async {
    try {
      final products = await ApiService.getAdminProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
      });
    } catch (error) {
      debugPrint('PRODUCT LOAD FOR VARIANT FORM ERROR: $error');
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _applyFilters() {
    final query = _searchQuery.toLowerCase().trim();

    final filtered = _variants.where((variant) {
      final variantId =
          variant['variant_id']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final productId =
          variant['product_id']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final variantName =
          variant['variant_name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final matchesSearch =
          query.isEmpty ||
          variantId.contains(query) ||
          productId.contains(query) ||
          variantName.contains(query);

      final active = _isActive(variant);

      final matchesStatus = switch (_selectedStatus) {
        'Active' => active,
        'Inactive' => !active,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final aActive = _isActive(a);
      final bActive = _isActive(b);

      if (aActive != bActive) {
        return aActive ? -1 : 1;
      }

      final aId =
          int.tryParse(
            a['variant_id']?.toString() ?? '0',
          ) ??
          0;

      final bId =
          int.tryParse(
            b['variant_id']?.toString() ?? '0',
          ) ??
          0;

      return bId.compareTo(aId);
    });

    _filteredVariants = filtered;
  }

  void _changeStatus(String value) {
    setState(() {
      _selectedStatus = value;
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

  // ============================================================
  // DATA HELPERS
  // ============================================================

  bool _isActive(Map<String, dynamic> variant) {
    final value = variant['is_active'];

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  String _variantId(Map<String, dynamic> variant) {
    return variant['variant_id']?.toString() ?? '-';
  }

  String _productId(Map<String, dynamic> variant) {
    return variant['product_id']?.toString() ?? '-';
  }

  String _variantName(Map<String, dynamic> variant) {
    final value =
        variant['variant_name']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty ? 'Unnamed Variant' : value;
  }

  double _monthlyRent(Map<String, dynamic> variant) {
    final value = variant['monthly_rent'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatRent(Map<String, dynamic> variant) {
    final rent = _monthlyRent(variant);

    if (rent == rent.roundToDouble()) {
      return '₹${rent.toInt()}';
    }

    return '₹${rent.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(text).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return text;
    }
  }

  String _productName(int productId) {
    for (final product in _products) {
      final id =
          int.tryParse(
            product['product_id']?.toString() ?? '',
          );

      if (id == productId) {
        return product['product_name']?.toString() ??
            product['name']?.toString() ??
            'Product #$productId';
      }
    }

    return 'Product #$productId';
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get _totalVariants => _variants.length;

  int get _activeVariants =>
      _variants.where(_isActive).length;

  int get _inactiveVariants =>
      _variants.where((item) => !_isActive(item)).length;

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

            // ------------------------------
            // DESKTOP
            // ------------------------------
            if (width >= 1100) {
              return Row(
                children: [
                  const SizedBox(
                    width: 250,
                    child: AdminSidebar(
                      compact: false,
                    ),
                  ),
                  Expanded(
                    child: _mainContent(
                      context,
                      isMobile: false,
                      horizontalPadding: 32,
                    ),
                  ),
                ],
              );
            }

            // ------------------------------
            // TABLET
            // ------------------------------
            if (width >= 700) {
              return Row(
                children: [
                  const SizedBox(
                    width: 82,
                    child: AdminSidebar(
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _mainContent(
                      context,
                      isMobile: false,
                      horizontalPadding: 24,
                    ),
                  ),
                ],
              );
            }

            // ------------------------------
            // MOBILE
            // ------------------------------
            return _mainContent(
              context,
              isMobile: true,
              horizontalPadding: 16,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _mainContent(
    BuildContext context, {
    required bool isMobile,
    required double horizontalPadding,
  }) {
    return Column(
      children: [
        _topBar(
          context,
          isMobile: isMobile,
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVariants,
            color: AppColors.ctaPurple,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),

              children: [
                _pageHeader(isMobile),

                const SizedBox(height: 20),

                _stats(isMobile),

                const SizedBox(height: 22),

                _searchAndFilter(isMobile),

                const SizedBox(height: 18),

                _variantsContent(isMobile),
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

  Widget _topBar(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (drawerContext) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(
                      drawerContext,
                    ).openDrawer();
                  },
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 28,
                  ),
                );
              },
            ),

          if (isMobile)
            const SizedBox(width: 4),

          const Icon(
            Icons.category_outlined,
            color: AppColors.ctaPurple,
            size: 25,
          ),

          const SizedBox(width: 10),

          Text(
            'Variants',
            style: AdminDesign.text(
              figmaSize: 28,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: _loadVariants,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
              size: 23,
            ),
          ),

          const SizedBox(width: 4),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius:
                  BorderRadius.circular(12),
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

  Widget _pageHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Variants',
            style: AdminDesign.text(
              figmaSize: 38,
              weight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Manage product variants and monthly rental prices',
            style: AdminDesign.text(
              figmaSize: 18,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCrudLoading
                  ? null
                  : () => _showVariantForm(),
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Create Variant',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.ctaPurple,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Variants',
                style: AdminDesign.text(
                  figmaSize: 42,
                  weight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage product variants and monthly rental prices',
                style: AdminDesign.text(
                  figmaSize: 21,
                  weight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        ElevatedButton.icon(
          onPressed: _isCrudLoading
              ? null
              : () => _showVariantForm(),
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'Create Variant',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                AppColors.ctaPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _stats(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Variants',
                  value:
                      _totalVariants.toString(),
                  icon:
                      Icons.category_outlined,
                  iconBackground:
                      const Color(0xFFEDEAFF),
                  iconColor:
                      AppColors.ctaPurple,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _statCard(
                  title: 'Active Variants',
                  value:
                      _activeVariants.toString(),
                  icon:
                      Icons.check_circle_outline,
                  iconBackground:
                      const Color(0xFFE7F7ED),
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _statCard(
            title: 'Inactive Variants',
            value:
                _inactiveVariants.toString(),
            icon:
                Icons.pause_circle_outline,
            iconBackground:
                const Color(0xFFFFF1DE),
            iconColor: Colors.orange,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Total Variants',
            value:
                _totalVariants.toString(),
            icon:
                Icons.category_outlined,
            iconBackground:
                const Color(0xFFEDEAFF),
            iconColor:
                AppColors.ctaPurple,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            title: 'Active Variants',
            value:
                _activeVariants.toString(),
            icon:
                Icons.check_circle_outline,
            iconBackground:
                const Color(0xFFE7F7ED),
            iconColor: Colors.green,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            title: 'Inactive Variants',
            value:
                _inactiveVariants.toString(),
            icon:
                Icons.pause_circle_outline,
            iconBackground:
                const Color(0xFFFFF1DE),
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 118,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: AdminDesign.text(
                    figmaSize: 16,
                    weight: FontWeight.w500,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: AdminDesign.text(
                    figmaSize: 30,
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
  // SEARCH + STATUS DROPDOWN
  // ============================================================

  Widget _searchAndFilter(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _searchField(),

          const SizedBox(height: 10),

          _statusDropdown(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _searchField(),
        ),

        const SizedBox(width: 14),

        SizedBox(
          width: 280,
          child: _statusDropdown(),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _searchField() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          Icon(
            Icons.search_rounded,
            color: Colors.grey.shade600,
            size: 27,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller:
                  _searchController,
              textAlignVertical:
                  TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w500,
                color: AppColors.navy,
              ),
              decoration:
                  const InputDecoration(
                hintText:
                    'Search variant, ID or product...',
                hintStyle: TextStyle(
                  fontSize: 17,
                  color:
                      Color(0xFF9E9E9E),
                ),
                border:
                    InputBorder.none,
                contentPadding:
                    EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(
                Icons.close_rounded,
              ),
              color:
                  Colors.grey.shade600,
            ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget _statusDropdown() {
    return Container(
      height: 58,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 26,
          ),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          items: _statusFilters.map(
            (status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            },
          ).toList(),
          onChanged: (value) {
            if (value != null) {
              _changeStatus(value);
            }
          },
        ),
      ),
    );
  }

  // ============================================================
  // VARIANTS CONTENT
  // ============================================================

  Widget _variantsContent(bool isMobile) {
    if (_isLoading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 70,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color:
                AppColors.ctaPurple,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _errorState();
    }

    if (_filteredVariants.isEmpty) {
      return _emptyState();
    }

    if (isMobile) {
      return Column(
        children: _filteredVariants
            .map(
              (variant) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child:
                    _variantCard(variant),
              ),
            )
            .toList(),
      );
    }

    return _desktopTable();
  }

  // ============================================================
  // MOBILE VARIANT CARD
  // ============================================================

  Widget _variantCard(
    Map<String, dynamic> variant,
  ) {
    final active = _isActive(variant);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _variantIcon(48),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _variantName(variant),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: AdminDesign.text(
                        figmaSize: 20,
                        weight:
                            FontWeight.w700,
                        color:
                            AppColors.navy,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Variant #${_variantId(variant)}',
                      style:
                          AdminDesign.text(
                        figmaSize: 15,
                        weight:
                            FontWeight.w400,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _statusBadge(active),
            ],
          ),

          const SizedBox(height: 14),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _infoBlock(
                  title: 'Product',
                  value:
                      'Product #${_productId(variant)}',
                ),
              ),

              Container(
                width: 1,
                height: 45,
                color: Colors.grey.shade200,
              ),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    left: 16,
                  ),
                  child: _infoBlock(
                    title: 'Monthly Rent',
                    value:
                        '${_formatRent(variant)}/month',
                    valueColor:
                        AppColors.ctaPurple,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Text(
                  active
                      ? 'Variant is active'
                      : 'Variant is inactive',
                  style:
                      AdminDesign.text(
                    figmaSize: 15,
                    weight:
                        FontWeight.w400,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showVariantForm(
                      variant: variant,
                    );
                  }

                  if (value == 'status') {
                    _confirmStatusChange(
                      variant,
                    );
                  }

                  if (value == 'view') {
                    _showVariantDetails(
                      variant,
                    );
                  }
                },
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey,
                ),
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 19,
                          ),
                          SizedBox(width: 10),
                          Text('Edit Variant'),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            active
                                ? Icons
                                    .toggle_off_rounded
                                : Icons
                                    .toggle_on_rounded,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            active
                                ? 'Deactivate'
                                : 'Activate',
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .visibility_outlined,
                            size: 19,
                          ),
                          SizedBox(width: 10),
                          Text('View Details'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _desktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 58,
          dataRowMinHeight: 78,
          dataRowMaxHeight: 92,
          horizontalMargin: 22,
          columnSpacing: 30,
          headingRowColor:
              WidgetStateProperty.all(
            const Color(0xFFFAFAFD),
          ),
          columns: [
            DataColumn(
              label: _tableHeader(
                'Variant',
              ),
            ),
            DataColumn(
              label: _tableHeader(
                'Product',
              ),
            ),
            DataColumn(
              label: _tableHeader(
                'Monthly Rent',
              ),
            ),
            DataColumn(
              label: _tableHeader(
                'Status',
              ),
            ),
            DataColumn(
              label: _tableHeader(
                'Created',
              ),
            ),
            const DataColumn(
              label: SizedBox.shrink(),
            ),
          ],
          rows: _filteredVariants.map(
            (variant) {
              final active =
                  _isActive(variant);

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        _variantIcon(44),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 220,
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _variantName(
                                  variant,
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    AdminDesign
                                        .text(
                                  figmaSize: 18,
                                  weight:
                                      FontWeight
                                          .w700,
                                  color:
                                      AppColors
                                          .navy,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Variant #${_variantId(variant)}',
                                style:
                                    AdminDesign
                                        .text(
                                  figmaSize: 14,
                                  weight:
                                      FontWeight
                                          .w400,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  DataCell(
                    Text(
                      'Product #${_productId(variant)}',
                      style:
                          AdminDesign.text(
                        figmaSize: 16,
                        weight:
                            FontWeight.w500,
                        color:
                            AppColors.navy,
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      '${_formatRent(variant)}/month',
                      style:
                          AdminDesign.text(
                        figmaSize: 16,
                        weight:
                            FontWeight.w700,
                        color:
                            AppColors.ctaPurple,
                      ),
                    ),
                  ),

                  DataCell(
                    _statusBadge(active),
                  ),

                  DataCell(
                    Text(
                      _formatDate(
                        variant['created_at'],
                      ),
                      style:
                          AdminDesign.text(
                        figmaSize: 15,
                        weight:
                            FontWeight.w500,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ),

                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showVariantForm(
                            variant: variant,
                          );
                        }

                        if (value == 'status') {
                          _confirmStatusChange(
                            variant,
                          );
                        }

                        if (value == 'view') {
                          _showVariantDetails(
                            variant,
                          );
                        }
                      },
                      itemBuilder:
                          (context) {
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit Variant',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'status',
                            child: Text(
                              active
                                  ? 'Deactivate'
                                  : 'Activate',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'view',
                            child: Text(
                              'View Details',
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text,
      style: AdminDesign.text(
        figmaSize: 17,
        weight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  // ============================================================
  // ICON
  // ============================================================

  Widget _variantIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAFF),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Icon(
        Icons.category_outlined,
        color: AppColors.ctaPurple,
        size: size * 0.50,
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(bool active) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE7F7ED)
            : const Color(0xFFFFEEEE),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: active
              ? Colors.green.shade700
              : Colors.red.shade700,
        ),
      ),
    );
  }

  // ============================================================
  // INFO BLOCK
  // ============================================================

  Widget _infoBlock({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AdminDesign.text(
            figmaSize: 14,
            weight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AdminDesign.text(
            figmaSize: 16,
            weight: FontWeight.w700,
            color:
                valueColor ?? AppColors.navy,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 46,
          ),

          const SizedBox(height: 12),

          Text(
            'Unable to load variants',
            style: AdminDesign.text(
              figmaSize: 21,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: AdminDesign.text(
              figmaSize: 15,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _loadVariants,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Try Again',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.ctaPurple,
              foregroundColor:
                  Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    final isFiltered =
        _searchQuery.isNotEmpty ||
        _selectedStatus != 'All';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isFiltered
                ? Icons.search_off_rounded
                : Icons.category_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 14),

          Text(
            isFiltered
                ? 'No variants found'
                : 'No variants available',
            style: AdminDesign.text(
              figmaSize: 21,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            isFiltered
                ? 'Try changing the search or status filter.'
                : 'Create your first product variant.',
            textAlign: TextAlign.center,
            style: AdminDesign.text(
              figmaSize: 15,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREATE / EDIT VARIANT
  // ============================================================

  Future<void> _showVariantForm({
    Map<String, dynamic>? variant,
  }) async {
    final isEdit = variant != null;

    await _loadProductsForForm();

    if (!mounted) return;

    final nameController =
        TextEditingController(
      text: isEdit
          ? _variantName(variant)
          : '',
    );

    final rentController =
        TextEditingController(
      text: isEdit
          ? _monthlyRent(variant)
              .toString()
          : '',
    );

    int? selectedProductId = isEdit
        ? int.tryParse(
            _productId(variant),
          )
        : null;

    String? formError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit
                    ? 'Edit Variant'
                    : 'Create Variant',
              ),

              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      DropdownButtonFormField<
                          int>(
                        value:
                            selectedProductId,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Product',
                          border:
                              OutlineInputBorder(),
                        ),
                        items: _products
                            .map(
                              (product) {
                                final id =
                                    int.tryParse(
                                  product[
                                              'product_id']
                                          ?.toString() ??
                                      '',
                                );

                                if (id ==
                                    null) {
                                  return null;
                                }

                                final name =
                                    product[
                                                'product_name']
                                            ?.toString() ??
                                        product[
                                                'name']
                                            ?.toString() ??
                                        'Product #$id';

                                return DropdownMenuItem<
                                    int>(
                                  value: id,
                                  child: Text(
                                    '$name (#$id)',
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),
                                );
                              },
                            )
                            .whereType<
                                DropdownMenuItem<
                                    int>>()
                            .toList(),
                        onChanged: isEdit
                            ? null
                            : (value) {
                                setDialogState(
                                  () {
                                    selectedProductId =
                                        value;
                                  },
                                );
                              },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      TextField(
                        controller:
                            nameController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Variant Name',
                          hintText:
                              'Example: 1.5 Ton',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      TextField(
                        controller:
                            rentController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Monthly Rent',
                          prefixText: '₹ ',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      if (formError != null) ...[
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          formError!,
                          style: TextStyle(
                            color:
                                Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: _isCrudLoading
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: _isCrudLoading
                      ? null
                      : () async {
                          final name =
                              nameController
                                  .text
                                  .trim();

                          final rent =
                              double.tryParse(
                            rentController
                                .text
                                .trim(),
                          );

                          if (!isEdit &&
                              selectedProductId ==
                                  null) {
                            setDialogState(() {
                              formError =
                                  'Please select a product.';
                            });
                            return;
                          }

                          if (name.isEmpty) {
                            setDialogState(() {
                              formError =
                                  'Please enter variant name.';
                            });
                            return;
                          }

                          if (rent == null ||
                              rent <= 0) {
                            setDialogState(() {
                              formError =
                                  'Please enter a valid monthly rent.';
                            });
                            return;
                          }

                          setDialogState(() {
                            formError = null;
                          });

                          setState(() {
                            _isCrudLoading =
                                true;
                          });

                          try {
                            if (isEdit) {
                              final id =
                                  int.parse(
                                _variantId(
                                  variant,
                                ),
                              );

                              await ApiService
                                  .updateProductVariant(
                                variantId: id,
                                variantName:
                                    name,
                                monthlyRent:
                                    rent,
                              );
                            } else {
                              await ApiService
                                  .createProductVariant(
                                productId:
                                    selectedProductId!,
                                variantName:
                                    name,
                                monthlyRent:
                                    rent,
                              );
                            }

                            if (!mounted) return;

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            _showMessage(
                              isEdit
                                  ? 'Variant updated successfully.'
                                  : 'Variant created successfully.',
                            );

                            await _loadVariants();
                          } catch (error) {
                            setDialogState(() {
                              formError =
                                  _cleanErrorMessage(
                                error,
                              );
                            });
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isCrudLoading =
                                    false;
                              });
                            }
                          }
                        },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.ctaPurple,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit
                        ? 'Save Changes'
                        : 'Create Variant',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    rentController.dispose();
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<void> _confirmStatusChange(
    Map<String, dynamic> variant,
  ) async {
    final active = _isActive(variant);

    final action =
        active ? 'Deactivate' : 'Activate';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '$action Variant?',
          ),
          content: Text(
            active
                ? 'Are you sure you want to deactivate ${_variantName(variant)}?'
                : 'Are you sure you want to activate ${_variantName(variant)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: active
                    ? Colors.redAccent
                    : Colors.green,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(() {
      _isCrudLoading = true;
    });

    try {
      final id = int.parse(
        _variantId(variant),
      );

      if (active) {
        await ApiService
            .deactivateProductVariant(
          variantId: id,
        );
      } else {
        await ApiService
            .reactivateProductVariant(
          variantId: id,
        );
      }

      if (!mounted) return;

      _showMessage(
        active
            ? 'Variant deactivated successfully.'
            : 'Variant activated successfully.',
      );

      await _loadVariants();
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanErrorMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCrudLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showVariantDetails(
    Map<String, dynamic> variant,
  ) {
    final active = _isActive(variant);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints:
                const BoxConstraints(
              maxHeight: 600,
            ),
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Variant Details',
                          style:
                              AdminDesign.text(
                            figmaSize: 27,
                            weight:
                                FontWeight.w800,
                            color:
                                AppColors.navy,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.of(
                            sheetContext,
                          ).pop();
                        },
                        icon:
                            const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF4F2FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Row(
                      children: [
                        _variantIcon(52),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _variantName(
                                  variant,
                                ),
                                style:
                                    AdminDesign
                                        .text(
                                  figmaSize: 22,
                                  weight:
                                      FontWeight
                                          .w800,
                                  color:
                                      AppColors
                                          .navy,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Variant #${_variantId(variant)}',
                                style:
                                    AdminDesign
                                        .text(
                                  figmaSize: 15,
                                  weight:
                                      FontWeight
                                          .w400,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _statusBadge(active),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _detailRow(
                    'Product ID',
                    _productId(variant),
                  ),

                  _detailRow(
                    'Variant ID',
                    _variantId(variant),
                  ),

                  _detailRow(
                    'Variant Name',
                    _variantName(variant),
                  ),

                  _detailRow(
                    'Monthly Rent',
                    '${_formatRent(variant)} / month',
                  ),

                  _detailRow(
                    'Created',
                    _formatDate(
                      variant['created_at'],
                    ),
                  ),

                  _detailRow(
                    'Updated',
                    _formatDate(
                      variant['updated_at'],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              _isCrudLoading
                                  ? null
                                  : () {
                                      Navigator.of(
                                        sheetContext,
                                      ).pop();

                                      _showVariantForm(
                                        variant:
                                            variant,
                                      );
                                    },
                          icon:
                              const Icon(
                            Icons
                                .edit_outlined,
                          ),
                          label:
                              const Text(
                            'Edit',
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                AppColors
                                    .ctaPurple,
                            side:
                                const BorderSide(
                              color:
                                  AppColors
                                      .ctaPurple,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _isCrudLoading
                                  ? null
                                  : () {
                                      Navigator.of(
                                        sheetContext,
                                      ).pop();

                                      _confirmStatusChange(
                                        variant,
                                      );
                                    },
                          icon: Icon(
                            active
                                ? Icons
                                    .pause_circle_outline
                                : Icons
                                    .play_circle_outline,
                          ),
                          label: Text(
                            active
                                ? 'Deactivate'
                                : 'Activate',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                active
                                    ? Colors
                                        .redAccent
                                    : Colors
                                        .green,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w500,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}