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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 850,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.ctaPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Manual Order',
                  style: AppTextStyles.of(
                    figmaSize: 26,
                    weight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Create an office / walk-in customer rental order',
                  style: AppTextStyles.of(
                    figmaSize: 17,
                    weight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isCreating
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
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
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
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
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildCustomerSection(),

                  const SizedBox(height: 18),

                  _buildAddressSection(),

                  const SizedBox(height: 18),

                  _buildProductSection(),

                  const SizedBox(height: 18),

                  _buildPriceSection(),

                  const SizedBox(height: 18),

                  _buildPaymentSection(),
                ],
              ),
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER SECTION
  // ============================================================

  Widget _buildCustomerSection() {
    return _section(
      title: 'Customer Details',
      icon: Icons.person_outline_rounded,
      children: [
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
                title: const Text(
                  'Existing Customer',
                ),
                contentPadding:
                    EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                value: true,
                groupValue: _isNewCustomer,
                onChanged: (_) {
                  _switchToNewCustomer();
                },
                title: const Text(
                  'New Customer',
                ),
                contentPadding:
                    EdgeInsets.zero,
              ),
            ),
          ],
        ),

        if (!_isNewCustomer)
          _buildCustomerDropdown(),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _field(
                controller:
                    _nameController,
                label: 'Full Name',
                icon:
                    Icons.person_outline,
                validator:
                    _requiredValidator,
                enabled:
                    _isNewCustomer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _field(
                controller:
                    _mobileController,
                label: 'Mobile Number',
                icon:
                    Icons.phone_outlined,
                keyboardType:
                    TextInputType.phone,
                validator:
                    _mobileValidator,
                enabled:
                    _isNewCustomer,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _field(
          controller:
              _emailController,
          label: 'Email Address',
          icon:
              Icons.email_outlined,
          keyboardType:
              TextInputType.emailAddress,
          validator:
              _emailValidator,
          enabled:
              _isNewCustomer,
        ),
      ],
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

  Widget _buildAddressSection() {
    return _section(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                controller:
                    _houseController,
                label:
                    'House / Flat Number',
                icon:
                    Icons.home_outlined,
                validator:
                    _requiredValidator,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _field(
                controller:
                    _apartmentController,
                label:
                    'Apartment Name',
                icon:
                    Icons.apartment_outlined,
                validator:
                    _requiredValidator,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _field(
                controller:
                    _streetController,
                label:
                    'Street / Area',
                icon:
                    Icons.location_city_outlined,
                validator:
                    _requiredValidator,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _field(
                controller:
                    _landmarkController,
                label: 'Landmark',
                icon:
                    Icons.place_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _field(
                controller:
                    _cityController,
                label: 'City',
                icon:
                    Icons.location_city_rounded,
                validator:
                    _requiredValidator,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _field(
                controller:
                    _pincodeController,
                label: 'Pincode',
                icon:
                    Icons.pin_drop_outlined,
                keyboardType:
                    TextInputType.number,
                validator:
                    _pincodeValidator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT
  // ============================================================

  Widget _buildProductSection() {
    final variants =
        _variantsForProduct(
      _selectedProduct,
    );

    return _section(
      title: 'Product',
      icon:
          Icons.inventory_2_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  DropdownButtonFormField<String>(
                value: _selectedProduct ==
                        null
                    ? null
                    : _selectedProduct![
                            'product_id']
                        ?.toString(),
                isExpanded: true,
                decoration:
                    _decoration(
                  'Product',
                  Icons.inventory_2_outlined,
                ),
                items:
                    _products.map(
                  (product) {
                    return DropdownMenuItem<
                        String>(
                      value: product[
                              'product_id']
                          ?.toString(),
                      child: Text(
                        _productName(
                          product,
                        ),
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    (value) {
                  if (value == null) {
                    return;
                  }

                  final product =
                      _products.firstWhere(
                    (item) =>
                        item['product_id']
                            ?.toString() ==
                        value,
                  );

                  _selectProduct(
                    product,
                  );
                },
                validator: (_) {
                  if (_selectedProduct ==
                      null) {
                    return 'Select product';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child:
                  DropdownButtonFormField<String>(
                value:
                    _selectedVariant == null
                        ? null
                        : _selectedVariant![
                                'variant_id']
                            ?.toString(),
                isExpanded: true,
                decoration:
                    _decoration(
                  'Variant',
                  Icons.tune_rounded,
                ),
                items:
                    variants.map(
                  (variant) {
                    return DropdownMenuItem<
                        String>(
                      value: variant[
                              'variant_id']
                          ?.toString(),
                      child: Text(
                        _variantName(
                          variant,
                        ),
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    (value) {
                  if (value == null) {
                    return;
                  }

                  final variant =
                      variants.firstWhere(
                    (item) =>
                        item['variant_id']
                            ?.toString() ==
                        value,
                  );

                  _selectVariant(
                    variant,
                  );
                },
                validator: (_) {
                  if (_selectedVariant ==
                      null) {
                    return 'Select variant';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Text(
              'Quantity',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),

            Container(
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF3F2FA,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                    icon: const Icon(
                      Icons.remove_rounded,
                    ),
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (_selectedVariant != null)
              Text(
                '${_money(_monthlyRent)} / month',
                style:
                    AppTextStyles.of(
                  figmaSize: 20,
                  weight:
                      FontWeight.w700,
                  color:
                      AppColors.ctaPurple,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PRICE
  // ============================================================

  Widget _buildPriceSection() {
    return _section(
      title: 'Price Summary',
      icon:
          Icons.receipt_long_outlined,
      children: [
        _priceRow(
          'Monthly Rent',
          _baseRent,
        ),
        _priceRow(
          'CGST (9%)',
          _cgst,
        ),
        _priceRow(
          'SGST (9%)',
          _sgst,
        ),

        const Divider(
          height: 24,
        ),

        Row(
          children: [
            Text(
              'Total Monthly Amount',
              style:
                  AppTextStyles.of(
                figmaSize: 20,
                weight:
                    FontWeight.w800,
                color:
                    AppColors.navy,
              ),
            ),
            const Spacer(),
            Text(
              _money(_totalAmount),
              style:
                  AppTextStyles.of(
                figmaSize: 24,
                weight:
                    FontWeight.w800,
                color:
                    AppColors.ctaPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(
    String label,
    double amount,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Text(
            label,
            style:
                AppTextStyles.of(
              figmaSize: 17,
              weight:
                  FontWeight.w500,
              color:
                  Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            _money(amount),
            style:
                AppTextStyles.of(
              figmaSize: 18,
              weight:
                  FontWeight.w700,
              color:
                  AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentSection() {
    return _section(
      title: 'Payment',
      icon:
          Icons.payments_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  DropdownButtonFormField<String>(
                value:
                    _paymentMethod,
                decoration:
                    _decoration(
                  'Payment Method',
                  Icons.payment_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Cash',
                    child:
                        Text('Cash'),
                  ),
                  DropdownMenuItem(
                    value: 'UPI',
                    child:
                        Text('UPI'),
                  ),
                  DropdownMenuItem(
                    value: 'Card',
                    child:
                        Text('Card'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child:
                        Text('Other'),
                  ),
                ],
                onChanged:
                    (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _paymentMethod =
                        value;
                  });
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child:
                  DropdownButtonFormField<String>(
                value:
                    _paymentStatus,
                decoration:
                    _decoration(
                  'Payment Status',
                  Icons.verified_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Verified',
                    child:
                        Text('Verified'),
                  ),
                  DropdownMenuItem(
                    value: 'Pending',
                    child:
                        Text('Pending'),
                  ),
                ],
                onChanged:
                    (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _paymentStatus =
                        value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),
        borderRadius:
            const BorderRadius.only(
          bottomLeft:
              Radius.circular(20),
          bottomRight:
              Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedVariant ==
                      null
                  ? 'Select a product to calculate total'
                  : 'Total: ${_money(_totalAmount)}',
              style:
                  AppTextStyles.of(
                figmaSize: 19,
                weight:
                    FontWeight.w700,
                color:
                    AppColors.navy,
              ),
            ),
          ),

          OutlinedButton(
            onPressed: _isCreating
                ? null
                : () => Navigator.of(
                      context,
                    ).pop(),
            child:
                const Text('Cancel'),
          ),

          const SizedBox(width: 12),

          ElevatedButton.icon(
            onPressed:
                _isCreating
                    ? null
                    : _createOrder,
            icon:
                _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .check_circle_outline,
                      ),
            label: Text(
              _isCreating
                  ? 'Creating...'
                  : 'Create Order',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.ctaPurple,
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 22,
                vertical: 14,
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
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    AppColors.ctaPurple,
                size: 21,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style:
                    AppTextStyles.of(
                  figmaSize: 21,
                  weight:
                      FontWeight.w800,
                  color:
                      AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration:
          _decoration(label, icon),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 20,
      ),
      filled: true,
      fillColor:
          const Color(0xFFFAFAFC),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide: BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide: BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide:
            const BorderSide(
          color:
              AppColors.ctaPurple,
          width: 1.5,
        ),
      ),
    );
  }
}