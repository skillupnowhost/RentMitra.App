import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CreateManualOrderDialog extends StatefulWidget {
  const CreateManualOrderDialog({
    super.key,
  });

  @override
  State<CreateManualOrderDialog> createState() =>
      _CreateManualOrderDialogState();
}

class _CreateManualOrderDialogState
    extends State<CreateManualOrderDialog> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  final _houseController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController(
    text: 'Chennai',
  );
  final _pincodeController = TextEditingController();

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _variants = [];

  bool _isLoadingData = true;
  bool _isCreating = false;

  String? _loadError;

  // ============================================================
  // CUSTOMER
  // ============================================================

  bool _isNewCustomer = true;

  int? _selectedCustomerId;

  Map<String, dynamic>? _selectedCustomer;

  // ============================================================
  // PRODUCT
  // ============================================================

  Map<String, dynamic>? _selectedProduct;

  Map<String, dynamic>? _selectedVariant;

  int _quantity = 1;

  // ============================================================
  // PAYMENT
  // ============================================================

  String _paymentMethod = 'Cash';
  String _paymentStatus = 'Verified';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();

    _houseController.dispose();
    _apartmentController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD CUSTOMERS + PRODUCTS
  // ============================================================

  Future<void> _loadFormData() async {
    try {
      final results = await Future.wait([
        ApiService.getAdminCustomers(),
        ApiService.getAdminProducts(),
        ApiService.fetchProductVariants(),
      ]);

      if (!mounted) return;

      setState(() {
        _customers =
            results[0] as List<Map<String, dynamic>>;

        _products =
            results[1] as List<Map<String, dynamic>>;

        _variants =
            results[2] as List<Map<String, dynamic>>;

        _isLoadingData = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
        _loadError = _cleanError(error);
      });
    }
  }

  // ============================================================
  // CUSTOMER SELECTION
  // ============================================================

  void _selectCustomer(
    Map<String, dynamic> customer,
  ) {
    final id = int.tryParse(
      customer['customer_id']?.toString() ?? '',
    );

    setState(() {
      _selectedCustomer = customer;
      _selectedCustomerId = id;

      _nameController.text =
          customer['full_name']?.toString() ?? '';

      _mobileController.text =
          customer['mobile']?.toString() ?? '';

      _emailController.text =
          customer['email']?.toString() ?? '';

      _isNewCustomer = false;
    });
  }

  void _switchToNewCustomer() {
    setState(() {
      _selectedCustomer = null;
      _selectedCustomerId = null;

      _isNewCustomer = true;

      _nameController.clear();
      _mobileController.clear();
      _emailController.clear();
    });
  }

  // ============================================================
  // PRODUCT SELECTION
  // ============================================================

  void _selectProduct(
    Map<String, dynamic>? product,
  ) {
    setState(() {
      _selectedProduct = product;
      _selectedVariant = null;
    });
  }

  List<Map<String, dynamic>> _variantsForProduct(
    Map<String, dynamic>? product,
  ) {
    if (product == null) {
      return [];
    }

    final productId =
        product['product_id']?.toString();

    return _variants.where((variant) {
      return variant['product_id']?.toString() ==
          productId;
    }).toList();
  }

  void _selectVariant(
    Map<String, dynamic>? variant,
  ) {
    setState(() {
      _selectedVariant = variant;
    });
  }

  // ============================================================
  // PRICING
  // ============================================================

  double get _monthlyRent {
    if (_selectedVariant == null) {
      return 0;
    }

    return double.tryParse(
          _selectedVariant!['monthly_rent']
                  ?.toString() ??
              '',
        ) ??
        0;
  }

  double get _baseRent {
    return (_monthlyRent * _quantity).roundToDouble();
  }

  double get _cgst {
    return (_baseRent * 0.09).roundToDouble();
  }

  double get _sgst {
    return (_baseRent * 0.09).roundToDouble();
  }

  double get _totalAmount {
    return (_baseRent + _cgst + _sgst).roundToDouble();
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVariant == null) {
      _showError(
        'Please select a product variant.',
      );
      return;
    }

    if (!_isNewCustomer &&
        _selectedCustomerId == null) {
      _showError(
        'Please select a customer.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final response =
          await ApiService.createManualOrder(
        customerId: _selectedCustomerId,

        fullName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),

        houseFlatNumber:
            _houseController.text.trim(),

        apartmentName:
            _apartmentController.text.trim(),

        streetArea:
            _streetController.text.trim(),

        landmark:
            _landmarkController.text.trim().isEmpty
                ? null
                : _landmarkController.text.trim(),

        city:
            _cityController.text.trim(),

        pincode:
            _pincodeController.text.trim(),

        variantId: int.parse(
          _selectedVariant!['variant_id']
              .toString(),
        ),

        quantity: _quantity,

        monthlyRent: _monthlyRent,

        orderAmount: _totalAmount,

        paymentMethod: _paymentMethod,

        paymentStatus: _paymentStatus,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        response,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      _showError(
        _cleanError(error),
      );
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _requiredValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _mobileValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    if (!RegExp(
      r'^[0-9]{10}$',
    ).hasMatch(value.trim())) {
      return 'Enter valid 10 digit mobile';
    }

    return null;
  }

  String? _emailValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(value.trim())) {
      return 'Enter valid email';
    }

    return null;
  }

  String? _pincodeValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(value.trim())) {
      return 'Enter valid pincode';
    }

    return null;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(Object error) {
    final value = error.toString();

    if (value.startsWith('Exception: ')) {
      return value.substring(
        'Exception: '.length,
      );
    }

    return value;
  }

  void _showError(String message) {
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

  String _productName(
    Map<String, dynamic> product,
  ) {
    return product['product_name']?.toString() ??
        product['name']?.toString() ??
        'Product';
  }

  String _variantName(
    Map<String, dynamic> variant,
  ) {
    return variant['variant_name']
            ?.toString() ??
        'Variant';
  }

  String _money(double value) {
    return '₹${value.round()}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final isMobile = screenWidth < 700;
    final keyboardOpen = media.viewInsets.bottom > 0;

    final horizontalInset = isMobile ? 10.0 : 30.0;
    final verticalInset = isMobile ? 10.0 : 24.0;

    final availableHeight =
        screenHeight - media.viewInsets.bottom - (verticalInset * 2);

    final dialogMaxHeight = isMobile
        ? availableHeight.clamp(360.0, 760.0)
        : availableHeight.clamp(520.0, 850.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 600 : 900,
          maxHeight: dialogMaxHeight,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(isMobile: isMobile),
            Expanded(
              child: _buildBody(isMobile: isMobile),
            ),
            if (!keyboardOpen || !isMobile) _buildBottomBar(
              isMobile: isMobile,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 14 : 18,
        isMobile ? 10 : 18,
        isMobile ? 14 : 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 42 : 44,
            height: isMobile ? 42 : 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.ctaPurple,
              size: isMobile ? 22 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Manual Order',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: isMobile ? 21 : 26,
                    weight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Create an office / walk-in customer rental order',
                  maxLines: isMobile ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: isMobile ? 13 : 17,
                    weight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            onPressed: _isCreating
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody({required bool isMobile}) {
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.ctaPurple,
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadFormData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 24,
          isMobile ? 12 : 24,
          isMobile ? 12 : 24,
          isMobile ? 14 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            _buildAddressSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            _buildProductSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            _buildPriceSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            _buildPaymentSection(isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOMER SECTION
  // ============================================================

  Widget _buildCustomerSection({required bool isMobile}) {
    return _section(
      title: 'Customer Details',
      icon: Icons.person_outline_rounded,
      isMobile: isMobile,
      children: [
        if (isMobile)
          Row(
            children: [
              Expanded(
                child: _customerTypeChip(
                  label: 'Existing Customer',
                  selected: !_isNewCustomer,
                  onTap: () {
                    setState(() {
                      _isNewCustomer = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _customerTypeChip(
                  label: 'New Customer',
                  selected: _isNewCustomer,
                  onTap: _switchToNewCustomer,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  value: false,
                  groupValue: _isNewCustomer,
                  onChanged: (_) {
                    setState(() {
                      _isNewCustomer = false;
                    });
                  },
                  title: const Text('Existing Customer'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  value: true,
                  groupValue: _isNewCustomer,
                  onChanged: (_) => _switchToNewCustomer(),
                  title: const Text('New Customer'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        if (!_isNewCustomer) ...[
          SizedBox(height: isMobile ? 10 : 12),
          _buildCustomerDropdown(),
        ],
        SizedBox(height: isMobile ? 10 : 12),
        if (isMobile)
          Column(
            children: [
              _field(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: _requiredValidator,
                enabled: _isNewCustomer,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _mobileController,
                label: 'Mobile Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _mobileValidator,
                enabled: _isNewCustomer,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: _requiredValidator,
                  enabled: _isNewCustomer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _field(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _mobileValidator,
                  enabled: _isNewCustomer,
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        _field(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
          enabled: _isNewCustomer,
        ),
      ],
    );
  }

  Widget _customerTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFFEDE7FF)
          : const Color(0xFFF6F6F8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.ctaPurple
                  : Colors.grey.shade300,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected
                    ? AppColors.ctaPurple
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.ctaPurple
                        : AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCustomerId,
      isExpanded: true,
      decoration:
          _decoration(
        'Select Existing Customer',
        Icons.person_search_outlined,
      ),
      items: _customers.map(
        (customer) {
          final id = int.tryParse(
            customer['customer_id']
                    ?.toString() ??
                '',
          );

          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              '${customer['full_name'] ?? '-'}  •  ${customer['mobile'] ?? '-'}',
              overflow:
                  TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: (id) {
        if (id == null) return;

        final customer =
            _customers.firstWhere(
          (item) =>
              item['customer_id']
                  ?.toString() ==
              id.toString(),
        );

        _selectCustomer(
          customer,
        );
      },
      validator: (_) {
        if (!_isNewCustomer &&
            _selectedCustomerId ==
                null) {
          return 'Select customer';
        }

        return null;
      },
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Widget _buildAddressSection({required bool isMobile}) {
    return _section(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      isMobile: isMobile,
      children: [
        if (isMobile)
          Column(
            children: [
              _field(
                controller: _houseController,
                label: 'House / Flat Number',
                icon: Icons.home_outlined,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _apartmentController,
                label: 'Apartment Name',
                icon: Icons.apartment_outlined,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _streetController,
                label: 'Street / Area',
                icon: Icons.location_city_outlined,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _landmarkController,
                label: 'Landmark',
                icon: Icons.place_outlined,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_rounded,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _pincodeController,
                label: 'Pincode',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                validator: _pincodeValidator,
              ),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _houseController,
                      label: 'House / Flat Number',
                      icon: Icons.home_outlined,
                      validator: _requiredValidator,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _field(
                      controller: _apartmentController,
                      label: 'Apartment Name',
                      icon: Icons.apartment_outlined,
                      validator: _requiredValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _streetController,
                      label: 'Street / Area',
                      icon: Icons.location_city_outlined,
                      validator: _requiredValidator,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _field(
                      controller: _landmarkController,
                      label: 'Landmark',
                      icon: Icons.place_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city_rounded,
                      validator: _requiredValidator,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _field(
                      controller: _pincodeController,
                      label: 'Pincode',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      validator: _pincodeValidator,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // PRODUCT
  // ============================================================

  Widget _buildProductSection({required bool isMobile}) {
    final variants = _variantsForProduct(_selectedProduct);

    final productDropdown = DropdownButtonFormField<String>(
      value: _selectedProduct == null
          ? null
          : _selectedProduct!['product_id']?.toString(),
      isExpanded: true,
      decoration: _decoration(
        'Product',
        Icons.inventory_2_outlined,
        isMobile: isMobile,
      ),
      items: _products.map((product) {
        return DropdownMenuItem<String>(
          value: product['product_id']?.toString(),
          child: Text(
            _productName(product),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        final product = _products.firstWhere(
          (item) => item['product_id']?.toString() == value,
        );
        _selectProduct(product);
      },
      validator: (_) =>
          _selectedProduct == null ? 'Select product' : null,
    );

    final variantDropdown = DropdownButtonFormField<String>(
      value: _selectedVariant == null
          ? null
          : _selectedVariant!['variant_id']?.toString(),
      isExpanded: true,
      decoration: _decoration(
        'Variant',
        Icons.tune_rounded,
        isMobile: isMobile,
      ),
      items: variants.map((variant) {
        return DropdownMenuItem<String>(
          value: variant['variant_id']?.toString(),
          child: Text(
            _variantName(variant),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        final variant = variants.firstWhere(
          (item) => item['variant_id']?.toString() == value,
        );
        _selectVariant(variant);
      },
      validator: (_) =>
          _selectedVariant == null ? 'Select variant' : null,
    );

    return _section(
      title: 'Product',
      icon: Icons.inventory_2_outlined,
      isMobile: isMobile,
      children: [
        if (isMobile)
          Column(
            children: [
              productDropdown,
              const SizedBox(height: 10),
              variantDropdown,
            ],
          )
        else
          Row(
            children: [
              Expanded(child: productDropdown),
              const SizedBox(width: 14),
              Expanded(child: variantDropdown),
            ],
          ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 14,
            vertical: isMobile ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F4FF),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color(0xFFE6E0FF),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              _quantityButton(
                icon: Icons.remove_rounded,
                enabled: _quantity > 1,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              SizedBox(
                width: isMobile ? 12 : 16,
              ),
              Text(
                '$_quantity',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(
                width: isMobile ? 12 : 16,
              ),
              _quantityButton(
                icon: Icons.add_rounded,
                enabled: true,
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
        if (_selectedVariant != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_money(_monthlyRent)} / month',
              style: AppTextStyles.of(
                figmaSize: isMobile ? 15 : 20,
                weight: FontWeight.w700,
                color: AppColors.ctaPurple,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ctaPurple,
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRICE
  // ============================================================

  Widget _buildPriceSection({required bool isMobile}) {
    return _section(
      title: 'Price Summary',
      icon: Icons.receipt_long_outlined,
      isMobile: isMobile,
      children: [
        _priceRow('Monthly Rent', _baseRent, isMobile: isMobile),
        _priceRow('CGST (9%)', _cgst, isMobile: isMobile),
        _priceRow('SGST (9%)', _sgst, isMobile: isMobile),
        const Divider(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total Monthly Amount',
                style: AppTextStyles.of(
                  figmaSize: isMobile ? 15 : 20,
                  weight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _money(_totalAmount),
              style: AppTextStyles.of(
                figmaSize: isMobile ? 19 : 24,
                weight: FontWeight.w800,
                color: AppColors.ctaPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(
    String label,
    double amount, {
    required bool isMobile,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.of(
                figmaSize: isMobile ? 14 : 17,
                weight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            _money(amount),
            style: AppTextStyles.of(
              figmaSize: isMobile ? 14 : 18,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentSection({required bool isMobile}) {
    final method = DropdownButtonFormField<String>(
      value: _paymentMethod,
      isExpanded: true,
      decoration: _decoration(
        'Payment Method',
        Icons.payment_outlined,
        isMobile: isMobile,
      ),
      items: const [
        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
        DropdownMenuItem(value: 'Card', child: Text('Card')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _paymentMethod = value);
      },
    );

    final status = DropdownButtonFormField<String>(
      value: _paymentStatus,
      isExpanded: true,
      decoration: _decoration(
        'Payment Status',
        Icons.verified_outlined,
        isMobile: isMobile,
      ),
      items: const [
        DropdownMenuItem(value: 'Verified', child: Text('Verified')),
        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _paymentStatus = value);
      },
    );

    return _section(
      title: 'Payment',
      icon: Icons.payments_outlined,
      isMobile: isMobile,
      children: [
        if (isMobile)
          Column(
            children: [
              method,
              const SizedBox(height: 10),
              status,
            ],
          )
        else
          Row(
            children: [
              Expanded(child: method),
              const SizedBox(width: 14),
              Expanded(child: status),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 18,
        isMobile ? 10 : 14,
        isMobile ? 12 : 18,
        isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: AppColors.ctaPurple,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _selectedVariant == null
                            ? 'Select a product to calculate total'
                            : 'Total: ${_money(_totalAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.of(
                          figmaSize: 15,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isCreating
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createOrder,
                        icon: _isCreating
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                                size: 19,
                              ),
                        label: Text(
                          _isCreating ? 'Creating...' : 'Create Order',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ctaPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedVariant == null
                        ? 'Select a product to calculate total'
                        : 'Total: ${_money(_totalAmount)}',
                    style: AppTextStyles.of(
                      figmaSize: 19,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _isCreating
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createOrder,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isCreating ? 'Creating...' : 'Create Order',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // COMMON SECTION
  // ============================================================

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 13 : 16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.ctaPurple,
                size: isMobile ? 19 : 21,
              ),
              SizedBox(width: isMobile ? 7 : 9),
              Text(
                title,
                style: AppTextStyles.of(
                  figmaSize: isMobile ? 17 : 21,
                  weight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _decoration(
        label,
        icon,
        isMobile: isMobile,
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    bool isMobile = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: isMobile ? 13 : 14,
      ),
      prefixIcon: Icon(
        icon,
        size: isMobile ? 19 : 20,
      ),
      isDense: isMobile,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 11 : 12,
        vertical: isMobile ? 12 : 16,
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 11),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 11),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 11),
        borderSide: const BorderSide(
          color: AppColors.ctaPurple,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 11),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

}
