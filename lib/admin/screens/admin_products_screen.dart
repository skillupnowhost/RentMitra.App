import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/admin_design_system.dart';
import '../../widgets/admin/admin_sidebar.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  String _selectedStatus = 'All';
  String _searchQuery = '';

  int _currentPage = 1;
  static const int _rowsPerPage = 10;

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
          _currentPage = 1;
          _applyFilters();
        });
      }
    });

    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.getAdminProducts();

      final Map<int, Map<String, dynamic>> uniqueProducts = {};

      for (final product in results) {
        final productId = int.tryParse(product['product_id']?.toString() ?? '');

        if (productId != null) {
          uniqueProducts[productId] = product;
        }
      }

      final cleanedProducts = uniqueProducts.values.toList();

      cleanedProducts.sort((a, b) {
        final aId = int.tryParse(a['product_id']?.toString() ?? '0') ?? 0;

        final bId = int.tryParse(b['product_id']?.toString() ?? '0') ?? 0;

        return aId.compareTo(bId);
      });

      if (!mounted) return;

      setState(() {
        _products = cleanedProducts;
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

    final filtered = _products.where((product) {
      final productId = product['product_id']?.toString().toLowerCase() ?? '';

      final productName =
          product['product_name']?.toString().toLowerCase() ?? '';

      final category = product['category']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          productId.contains(query) ||
          productName.contains(query) ||
          category.contains(query);

      final active = _isActive(product);

      final matchesStatus = switch (_selectedStatus) {
        'Active' => active,
        'Inactive' => !active,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();

    _filteredProducts = filtered;

    final totalPages = _totalPages;
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    if (_currentPage < 1) {
      _currentPage = 1;
    }
  }

  void _changeStatus(String status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _currentPage = 1;
      _applyFilters();
    });
  }

  int get _totalPages {
    if (_filteredProducts.isEmpty) return 1;
    return (_filteredProducts.length / _rowsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedProducts {
    if (_filteredProducts.isEmpty) return [];

    final startIndex = (_currentPage - 1) * _rowsPerPage;

    if (startIndex >= _filteredProducts.length) return [];

    final endIndex = (startIndex + _rowsPerPage > _filteredProducts.length)
        ? _filteredProducts.length
        : startIndex + _rowsPerPage;

    return _filteredProducts.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;

    setState(() {
      _currentPage = page;
    });
  }

  // ============================================================
  // PRODUCT API - CREATE / UPDATE
  // ============================================================

  Future<Map<String, dynamic>> _createProduct({
    required String productName,
    required String category,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/admin/products');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'product_name': productName.trim(),
            'category': category.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _handleProductMutationResponse(response);
  }

  Future<Map<String, dynamic>> _updateProduct({
    required int productId,
    required String productName,
    required String category,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/admin/products/$productId');

    final response = await http
        .put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'product_name': productName.trim(),
            'category': category.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _handleProductMutationResponse(response);
  }

  // ============================================================
  // PRODUCT ACTIVATE / INACTIVATE
  // ============================================================

  Future<Map<String, dynamic>> _setProductActiveStatus({
    required int productId,
    required bool activate,
  }) async {
    final Uri url;
    late http.Response response;

    if (activate) {
      // Existing backend endpoint:
      // PATCH /products/:id/reactivate
      url = Uri.parse(
        '${ApiService.baseUrl}/products/$productId/reactivate',
      );

      response = await http
          .patch(
            url,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } else {
      // Existing backend endpoint:
      // DELETE /products/:id
      // This performs a soft delete by setting is_active = FALSE.
      url = Uri.parse(
        '${ApiService.baseUrl}/products/$productId',
      );

      response = await http
          .delete(
            url,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    }

    return _handleProductMutationResponse(response);
  }

  Future<void> _changeProductActiveStatus(
    Map<String, dynamic> product,
  ) async {
    final productId = int.tryParse(
      product['product_id']?.toString() ?? '',
    );

    if (productId == null) {
      _showMessage('Invalid product ID.');
      return;
    }

    final currentlyActive = _isActive(product);
    final activate = !currentlyActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                activate
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_outlined,
                color: activate ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  activate ? 'Activate Product' : 'Inactivate Product',
                ),
              ),
            ],
          ),
          content: Text(
            activate
                ? 'Are you sure you want to activate ${_productName(product)}?'
                : 'Are you sure you want to inactivate ${_productName(product)}?\n\nThe product will no longer be available as an active product.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    activate ? Colors.green.shade700 : Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(activate ? 'Activate' : 'Inactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      _showLoadingMessage(
        activate ? 'Activating product...' : 'Inactivating product...',
      );

      await _setProductActiveStatus(
        productId: productId,
        activate: activate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? 'Product activated successfully.'
                : 'Product inactivated successfully.',
          ),
          backgroundColor: activate ? Colors.green.shade700 : Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadProducts();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showMessage(_cleanErrorMessage(error));
    }
  }

  void _showLoadingMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(minutes: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<Map<String, dynamic>> _handleProductMutationResponse(
    http.Response response,
  ) async {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();

        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception(
        'Product request failed. Status code: ${response.statusCode}.',
      );
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception('Invalid product response from backend.');
  }

  // ============================================================
  // CREATE / EDIT PRODUCT DIALOG
  // ============================================================

  Future<void> _showProductForm({Map<String, dynamic>? product}) async {
    final isEdit = product != null;

    final nameController = TextEditingController(
      text: isEdit ? _productName(product) : '',
    );
    final categoryController = TextEditingController(
      text: isEdit && _category(product) != '-' ? _category(product) : '',
    );

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: !saving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.ctaPurple,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Product' : 'Create Product',
                        style: AdminDesign.text(
                          figmaSize: 25,
                          weight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 440,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Product Name',
                            hintText: 'Enter product name',
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F9FC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';

                            if (name.isEmpty) {
                              return 'Product name is required';
                            }

                            if (name.length < 2) {
                              return 'Enter a valid product name';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: categoryController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            hintText: 'Example: AC',
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F9FC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final category = value?.trim() ?? '';

                            if (category.isEmpty) {
                              return 'Category is required';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              final name = nameController.text.trim();
                              final category =
                                  categoryController.text.trim();

                              if (isEdit) {
                                final productId = int.tryParse(
                                  product!['product_id']?.toString() ?? '',
                                );

                                if (productId == null) {
                                  throw Exception('Invalid product ID.');
                                }

                                await _updateProduct(
                                  productId: productId,
                                  productName: name,
                                  category: category,
                                );
                              } else {
                                await _createProduct(
                                  productName: name,
                                  category: category,
                                );
                              }

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            } catch (error) {
                              setDialogState(() {
                                saving = false;
                              });

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _cleanErrorMessage(error),
                                      ),
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
                        : Icon(
                            isEdit
                                ? Icons.save_outlined
                                : Icons.add_rounded,
                          ),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : isEdit
                              ? 'Save Changes'
                              : 'Create Product',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                isEdit
                    ? 'Product updated successfully.'
                    : 'Product created successfully.',
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );

        await _loadProducts();
      }
    } finally {
      nameController.dispose();
      categoryController.dispose();
    }
  }

  // ============================================================
  // PRODUCT HELPERS
  // ============================================================

  String _productId(Map<String, dynamic> product) {
    return product['product_id']?.toString() ?? '-';
  }

  String _productName(Map<String, dynamic> product) {
    final value = product['product_name']?.toString().trim() ?? '';

    return value.isEmpty ? 'Unnamed Product' : value;
  }

  String _category(Map<String, dynamic> product) {
    final value = product['category']?.toString().trim() ?? '';

    return value.isEmpty ? '-' : value;
  }

  bool _isActive(Map<String, dynamic> product) {
    final value = product['is_active'];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    if (value is num) {
      return value != 0;
    }

    return false;
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

  int get _totalProducts => _products.length;

  int get _activeProducts {
    return _products.where(_isActive).length;
  }

  int get _inactiveProducts {
    return _products.where((product) => !_isActive(product)).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),

      // IMPORTANT:
      // Mobile admin navigation drawer.
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
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 250, child: AdminSidebar(compact: false)),
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
  // TABLET LAYOUT
  // ============================================================

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 82, child: AdminSidebar(compact: true)),
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
  // MOBILE LAYOUT
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
            onRefresh: _loadProducts,
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
                _buildPageHeader(),
                const SizedBox(height: 20),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildSearchAndFilterSection(),
                const SizedBox(height: 18),
                _buildProductsSection(),
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
              builder: (drawerContext) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(drawerContext).openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.navy,
                );
              },
            ),

          if (showMenuButton) const SizedBox(width: 4),

          if (!showMenuButton)
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.ctaPurple,
              size: 26,
            ),

          const SizedBox(width: 12),

          Text(
            'Products',
            style: AdminDesign.text(
              figmaSize: 30,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: _loadProducts,
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

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products',
              style: AdminDesign.text(
                figmaSize: 42,
                weight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage products available for rental',
              style: AdminDesign.text(
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
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Create Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPurple,
              foregroundColor: Colors.white,
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
  // STATISTICS
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
                  title: 'Total Products',
                  value: _totalProducts.toString(),
                  icon: Icons.inventory_2_outlined,
                  iconBackground: const Color(0xFFEDEAFF),
                  iconColor: AppColors.ctaPurple,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Products',
                  value: _activeProducts.toString(),
                  icon: Icons.check_circle_outline,
                  iconBackground: const Color(0xFFE7F7ED),
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Inactive Products',
                  value: _inactiveProducts.toString(),
                  icon: Icons.pause_circle_outline,
                  iconBackground: const Color(0xFFFFF1DE),
                  iconColor: Colors.orange,
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
            childAspectRatio: 2.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Total Products',
                value: _totalProducts.toString(),
                icon: Icons.inventory_2_outlined,
                iconBackground: const Color(0xFFEDEAFF),
                iconColor: AppColors.ctaPurple,
              ),
              _buildStatCard(
                title: 'Active Products',
                value: _activeProducts.toString(),
                icon: Icons.check_circle_outline,
                iconBackground: const Color(0xFFE7F7ED),
                iconColor: Colors.green,
              ),
              _buildStatCard(
                title: 'Inactive Products',
                value: _inactiveProducts.toString(),
                icon: Icons.pause_circle_outline,
                iconBackground: const Color(0xFFFFF1DE),
                iconColor: Colors.orange,
              ),
            ],
          );
        }

        // PHONE
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Products',
                    value: _totalProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                    iconBackground: const Color(0xFFEDEAFF),
                    iconColor: AppColors.ctaPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Products',
                    value: _activeProducts.toString(),
                    icon: Icons.check_circle_outline,
                    iconBackground: const Color(0xFFE7F7ED),
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Inactive Products',
              value: _inactiveProducts.toString(),
              icon: Icons.pause_circle_outline,
              iconBackground: const Color(0xFFFFF1DE),
              iconColor: Colors.orange,
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
                  style: AdminDesign.text(
                    figmaSize: 18,
                    weight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AdminDesign.text(
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
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: _buildStatusDropdown(),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: 58,
                child: _buildSearchField(),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 300,
              height: 58,
              child: _buildStatusDropdown(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search product, ID or category...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedStatus,
            isExpanded: true,
            isDense: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 25,
              color: Color(0xFF666666),
            ),
            style: AdminDesign.text(
              figmaSize: 18,
              weight: FontWeight.w600,
              color: AppColors.navy,
            ),
            items: _statusFilters.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
                  style: AdminDesign.text(
                    figmaSize: 18,
                    weight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _changeStatus(value);
              }
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCTS SECTION
  // ============================================================

  Widget _buildProductsSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _buildDesktopProductsTable();
            }

            return _buildMobileProductList();
          },
        ),
        const SizedBox(height: 14),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    final total = _filteredProducts.length;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final start = ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = (_currentPage * _rowsPerPage > total)
        ? total
        : _currentPage * _rowsPerPage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        final pageButtons = <Widget>[];

        for (int page = 1; page <= _totalPages; page++) {
          pageButtons.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => _goToPage(page),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: page == _currentPage
                        ? AppColors.ctaPurple
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: page == _currentPage
                          ? AppColors.ctaPurple
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '$page',
                    style: AdminDesign.text(
                      figmaSize: 16,
                      weight: FontWeight.w700,
                      color: page == _currentPage
                          ? Colors.white
                          : AppColors.navy,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _currentPage > 1
                  ? () => _goToPage(_currentPage - 1)
                  : null,
              tooltip: 'Previous page',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            ...pageButtons,
            IconButton(
              onPressed: _currentPage < _totalPages
                  ? () => _goToPage(_currentPage + 1)
                  : null,
              tooltip: 'Next page',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        );

        if (compact) {
          return Column(
            children: [
              Text(
                'Showing $start–$end of $total',
                style: AdminDesign.text(
                  figmaSize: 15,
                  weight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: controls,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $start–$end of $total products',
              style: AdminDesign.text(
                figmaSize: 15,
                weight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            controls,
          ],
        );
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
            'Unable to load products',
            style: AdminDesign.text(
              figmaSize: 27,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: AdminDesign.text(
              figmaSize: 19.5,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadProducts,
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
    final hasFilter = _searchQuery.isNotEmpty || _selectedStatus != 'All';

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
              Icons.inventory_2_outlined,
              color: AppColors.ctaPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No matching products' : 'No products found',
            style: AdminDesign.text(
              figmaSize: 27,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasFilter
                ? 'Try changing your search or filter.'
                : 'Products will appear here once added.',
            textAlign: TextAlign.center,
            style: AdminDesign.text(
              figmaSize: 19.5,
              weight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          if (hasFilter) ...[
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

  Widget _buildDesktopProductsTable() {
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
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFD)),
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Created')),
                DataColumn(label: Text('')),
              ],
              rows: _paginatedProducts.map((product) {
                final active = _isActive(product);

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 300,
                        child: Row(
                          children: [
                            _productIcon(size: 42),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _productName(product),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AdminDesign.text(
                                      figmaSize: 22.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '#${_productId(product)}',
                                    style: AdminDesign.text(
                                      figmaSize: 18,
                                      weight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _category(product),
                        style: AdminDesign.text(
                          figmaSize: 18,
                          weight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(active)),
                    DataCell(
                      Text(
                        _formatDate(product['created_at']),
                        style: AdminDesign.text(
                          figmaSize: 22.5,
                          weight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        onPressed: () => _showProductDetails(product),
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                        ),
                        color: Colors.grey.shade600,
                        tooltip: 'View product',
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
  // MOBILE / TABLET PRODUCT LIST
  // ============================================================

  Widget _buildMobileProductList() {
    return Column(
      children: _paginatedProducts.map((product) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProductCard(product),
        );
      }).toList(),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final active = _isActive(product);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showProductDetails(product),
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
                  _productIcon(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _productName(product),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AdminDesign.text(
                            figmaSize: 23,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Product #${_productId(product)}',
                          style: AdminDesign.text(
                            figmaSize: 16,
                            weight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(active),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn('Category', _category(product)),
                  ),
                  Container(width: 1, height: 34, color: Colors.grey.shade200),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildInfoColumn(
                        'Created',
                        _formatDate(product['created_at']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      active ? 'Product is active' : 'Product is inactive',
                      style: AdminDesign.text(
                        figmaSize: 16,
                        weight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showProductDetails(product),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: AdminDesign.text(
                              figmaSize: 15,
                              weight: FontWeight.w700,
                              color: AppColors.ctaPurple,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.ctaPurple,
                            size: 12,
                          ),
                        ],
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
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AdminDesign.text(
            figmaSize: 15,
            weight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AdminDesign.text(
            figmaSize: 17,
            weight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _productIcon({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.ctaPurple,
        size: size * 0.52,
      ),
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F7ED) : const Color(0xFFFCEDEA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AdminDesign.text(
          figmaSize: 15,
          weight: FontWeight.w700,
          color: active ? Colors.green : Colors.redAccent,
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT DETAILS
  // ============================================================

  void _showProductDetails(Map<String, dynamic> product) {
    final active = _isActive(product);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.90,
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
                            'Product #${_productId(product)}',
                            style: AdminDesign.text(
                              figmaSize: 31,
                              weight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _showProductForm(product: product);
                          },
                          tooltip: 'Edit product',
                          icon: const Icon(Icons.edit_outlined),
                          color: AppColors.ctaPurple,
                        ),
                        IconButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _changeProductActiveStatus(product);
                          },
                          tooltip: active
                              ? 'Inactivate product'
                              : 'Activate product',
                          icon: Icon(
                            active
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            size: 30,
                          ),
                          color: active
                              ? Colors.green.shade700
                              : Colors.grey.shade500,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Close',
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _productIcon(size: 54),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _productName(product),
                                      style: AdminDesign.text(
                                        figmaSize: 24,
                                        weight: FontWeight.w800,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _category(product),
                                      style: AdminDesign.text(
                                        figmaSize: 17,
                                        weight: FontWeight.w400,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(active),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildDetailsSection(
                          title: 'Product Information',
                          icon: Icons.inventory_2_outlined,
                          children: [
                            _buildDetailRow('Product ID', _productId(product)),
                            _buildDetailRow(
                              'Product Name',
                              _productName(product),
                            ),
                            _buildDetailRow('Category', _category(product)),
                            _buildDetailRow(
                              'Status',
                              active ? 'Active' : 'Inactive',
                            ),
                            _buildDetailRow(
                              'Created',
                              _formatDate(product['created_at']),
                            ),
                            _buildDetailRow(
                              'Updated',
                              _formatDate(product['updated_at']),
                            ),
                          ],
                        ),                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _changeProductActiveStatus(product);
                            },
                            icon: Icon(
                              active
                                  ? Icons.block_outlined
                                  : Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              active
                                  ? 'Inactivate Product'
                                  : 'Activate Product',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: active
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
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
              Icon(icon, size: 20, color: AppColors.ctaPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: AdminDesign.text(
                  figmaSize: 22,
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
              style: AdminDesign.text(
                figmaSize: 18,
                weight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AdminDesign.text(
                figmaSize: 19,
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
