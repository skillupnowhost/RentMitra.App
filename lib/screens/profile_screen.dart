import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/customer_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String? _errorMessage;

  Map<String, dynamic>? _customer;
  Map<String, dynamic>? _address;

  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  late final TextEditingController _houseController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _streetController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();

    _houseController = TextEditingController();
    _apartmentController = TextEditingController();
    _streetController = TextEditingController();
    _landmarkController = TextEditingController();
    _cityController = TextEditingController();
    _pincodeController = TextEditingController();

    _loadProfile();
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
  // CUSTOMER ID
  // ============================================================

  int? get _customerId {
    return CustomerSession.instance.customerId;
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
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
        _address = null;
        _errorMessage = null;
      });

      return;
    }

    try {
      // ----------------------------------------------------------
      // GET CUSTOMER + ADDRESS FROM ONE API
      // ----------------------------------------------------------

      final response = await ApiService.getCustomerProfile(
        customerId: customerId,
      );

      // ----------------------------------------------------------
      // CUSTOMER
      // ----------------------------------------------------------

      Map<String, dynamic>? customer;

      if (response['customer'] is Map) {
        customer = Map<String, dynamic>.from(response['customer'] as Map);
      }

      // ----------------------------------------------------------
      // ADDRESS
      // ----------------------------------------------------------

      Map<String, dynamic>? address;

      if (response['address'] is Map) {
        address = Map<String, dynamic>.from(response['address'] as Map);
      }

      // ----------------------------------------------------------
      // VALIDATE CUSTOMER RESPONSE
      // ----------------------------------------------------------

      if (customer == null) {
        throw Exception('Customer information was not returned by server.');
      }

      final name = customer['full_name']?.toString().trim() ?? '';

      final mobile = customer['mobile']?.toString().trim() ?? '';

      final email = customer['email']?.toString().trim() ?? '';

      // ----------------------------------------------------------
      // SET ADDRESS CONTROLLERS
      // ----------------------------------------------------------

      _setAddressControllers(address);

      if (!mounted) {
        return;
      }

      setState(() {
        _customer = customer;
        _address = address;

        _nameController.text = name;
        _mobileController.text = mobile;
        _emailController.text = email;

        _isLoading = false;
      });

      // ----------------------------------------------------------
      // KEEP SESSION NAME SYNCHRONIZED
      // ----------------------------------------------------------

      if (name.isNotEmpty) {
        await CustomerSession.instance.updateName(name);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(error.toString());
      });
    }
  }
  // ============================================================
  // SET ADDRESS CONTROLLERS
  // ============================================================

  void _setAddressControllers(Map<String, dynamic>? address) {
    _houseController.text = address?['house_flat_number']?.toString() ?? '';

    _apartmentController.text = address?['apartment_name']?.toString() ?? '';

    _streetController.text = address?['street_area']?.toString() ?? '';

    _landmarkController.text = address?['landmark']?.toString() ?? '';

    _cityController.text = address?['city']?.toString() ?? '';

    _pincodeController.text = address?['pincode']?.toString() ?? '';
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanErrorMessage(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring('Exception: '.length);
    }

    return error;
  }

  // ============================================================
  // SAVE PROFILE + ADDRESS
  // ============================================================

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final customerId = _customerId;

    if (customerId == null || customerId <= 0) {
      _showMessage('Customer account is not available.');
      return;
    }

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    final house = _houseController.text.trim();
    final apartment = _apartmentController.text.trim();
    final street = _streetController.text.trim();
    final landmark = _landmarkController.text.trim();
    final city = _cityController.text.trim();
    final pincode = _pincodeController.text.trim();

    // ----------------------------------------------------------
    // CUSTOMER VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      _showMessage('Mobile number must contain exactly 10 digits.');
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailRegex.hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    // ----------------------------------------------------------
    // ADDRESS VALIDATION
    // ----------------------------------------------------------

    if (house.isEmpty) {
      _showMessage('Please enter your house or flat number.');
      return;
    }

    if (apartment.isEmpty) {
      _showMessage('Please enter your apartment name.');
      return;
    }

    if (street.isEmpty) {
      _showMessage('Please enter your street or area.');
      return;
    }

    if (city.isEmpty) {
      _showMessage('Please enter your city.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _showMessage('Pincode must contain exactly 6 digits.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // UPDATE CUSTOMER
      // --------------------------------------------------------

      final customerResponse = await ApiService.updateCustomer(
        customerId: customerId,
        fullName: name,
        mobile: mobile,
        email: email,
      );

      Map<String, dynamic>? updatedCustomer;

      if (customerResponse['customer'] is Map) {
        updatedCustomer = Map<String, dynamic>.from(
          customerResponse['customer'] as Map,
        );
      }

      // --------------------------------------------------------
      // UPDATE OR CREATE ADDRESS
      // --------------------------------------------------------

      final addressId = _parseInt(_address?['address_id']);

      Map<String, dynamic> addressResponse;

      if (addressId != null && addressId > 0) {
        addressResponse = await ApiService.updateAddress(
          addressId: addressId,
          houseFlatNumber: house,
          apartmentName: apartment,
          streetArea: street,
          landmark: landmark,
          city: city,
          pincode: pincode,
        );
      } else {
        addressResponse = await ApiService.createAddress(
          customerId: customerId,
          houseFlatNumber: house,
          apartmentName: apartment,
          streetArea: street,
          landmark: landmark,
          city: city,
          pincode: pincode,
        );
      }

      Map<String, dynamic>? updatedAddress;

      if (addressResponse['address'] is Map) {
        updatedAddress = Map<String, dynamic>.from(
          addressResponse['address'] as Map,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        if (updatedCustomer != null) {
          _customer = updatedCustomer;
        }

        if (updatedAddress != null) {
          _address = updatedAddress;
        }

        _isSaving = false;
        _isEditing = false;
      });

      // --------------------------------------------------------
      // UPDATE SESSION NAME
      // --------------------------------------------------------

      CustomerSession.instance.updateName(name);

      _showMessage('Profile updated successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(_cleanErrorMessage(error.toString()));
    }
  }

  // ============================================================
  // CANCEL EDIT
  // ============================================================

  void _cancelEditing() {
    final customer = _customer;

    _nameController.text = customer?['full_name']?.toString() ?? '';

    _mobileController.text = customer?['mobile']?.toString() ?? '';

    _emailController.text = customer?['email']?.toString() ?? '';

    _setAddressControllers(_address);

    setState(() {
      _isEditing = false;
    });

    FocusScope.of(context).unfocus();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // PARSE INTEGER
  // ============================================================

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(20),
        AppTextStyles.fig(18),
        AppTextStyles.fig(12),
        AppTextStyles.fig(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Profile',
              style: AppTextStyles.of(
                figmaSize: 24,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          if (!_isLoading && _errorMessage == null && _customer != null)
            TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        _cancelEditing();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
              icon: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(_isEditing ? 'Cancel' : 'Edit'),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_customer == null) {
      return _buildNoCustomerState();
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          _buildProfileHeader(),

          const SizedBox(height: 20),

          _buildPersonalInformationCard(),

          const SizedBox(height: 20),

          _buildAddressCard(),

          const SizedBox(height: 20),

          if (_isEditing) _buildSaveButton(),

          if (!_isEditing) _buildAccountInfo(),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    final name = _customer?['full_name']?.toString().trim() ?? '';

    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: AppTextStyles.of(
                  figmaSize: 34,
                  weight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            name.isEmpty ? 'Customer' : name,
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 20,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'RentMitra Customer',
            style: AppTextStyles.of(
              figmaSize: 13,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalInformationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTextStyles.of(
              figmaSize: 17,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 18),

          _buildField(
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
            keyboardType: TextInputType.name,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
            maxLength: 10,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Email Address',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: _isEditing,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: AppTextStyles.of(
              figmaSize: 17,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 18),

          _buildField(
            label: 'House / Flat Number',
            icon: Icons.home_outlined,
            controller: _houseController,
            keyboardType: TextInputType.streetAddress,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Apartment Name',
            icon: Icons.apartment_outlined,
            controller: _apartmentController,
            keyboardType: TextInputType.streetAddress,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Street / Area',
            icon: Icons.location_on_outlined,
            controller: _streetController,
            keyboardType: TextInputType.streetAddress,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Landmark',
            icon: Icons.place_outlined,
            controller: _landmarkController,
            keyboardType: TextInputType.streetAddress,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'City',
            icon: Icons.location_city_outlined,
            controller: _cityController,
            keyboardType: TextInputType.streetAddress,
            enabled: _isEditing,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Pincode',
            icon: Icons.markunread_mailbox_outlined,
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            enabled: _isEditing,
            maxLength: 6,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required bool enabled,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: AppTextStyles.of(
        figmaSize: 14,
        weight: FontWeight.w500,
        color: AppColors.navy,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.purple : AppColors.textGray,
        ),
        counterText: '',
        filled: true,
        fillColor: enabled ? AppColors.background : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.purple, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
      ),
    );
  }

  // ============================================================
  // ACCOUNT INFO
  // ============================================================

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.purple, size: 24),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Active',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Your RentMitra customer account is active.',
                  style: AppTextStyles.of(
                    figmaSize: 12,
                    weight: FontWeight.w400,
                    color: AppColors.textGray,
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
  // NO CUSTOMER STATE
  // ============================================================

  Widget _buildNoCustomerState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 60,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 18),

            Text(
              'No Customer Profile',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 20,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Your customer profile will appear here after your first successful payment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 13,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 18),

            Text(
              'Unable to Load Profile',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 20,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 13,
                weight: FontWeight.w400,
                color: AppColors.textGray,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
