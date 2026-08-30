import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/help_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/location_selector.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.product = CheckoutProduct.acOnePointFiveTon,
  });

  final CheckoutProduct product;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ============================================================
  // SCROLL CONTROLLER
  // ============================================================

  final _scrollController = ScrollController();

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final _fullNameController = TextEditingController();

  final _houseController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();

  final _cityController = TextEditingController(text: 'Chennai');

  final _pincodeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  // ============================================================
  // FOCUS NODES
  // ============================================================

  final _fullNameFocus = FocusNode();

  final _houseFocus = FocusNode();
  final _buildingFocus = FocusNode();
  final _streetFocus = FocusNode();
  final _landmarkFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _pincodeFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _emailFocus = FocusNode();

  // ============================================================
  // STATE
  // ============================================================

  bool _emailUpdates = true;

  bool _isCreatingCheckout = false;

  String? _topErrorMessage;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    final selectedCity = LocationController.instance.city.value.trim();

    if (selectedCity.isNotEmpty) {
      _cityController.text = selectedCity;
    }

    LocationController.instance.city.addListener(_onCityChanged);

    _addFocusListener(_fullNameFocus);
    _addFocusListener(_houseFocus);
    _addFocusListener(_buildingFocus);
    _addFocusListener(_streetFocus);
    _addFocusListener(_landmarkFocus);
    _addFocusListener(_cityFocus);
    _addFocusListener(_pincodeFocus);
    _addFocusListener(_mobileFocus);
    _addFocusListener(_emailFocus);
  }

  // ============================================================
  // FOCUS LISTENER
  // ============================================================

  void _addFocusListener(FocusNode focusNode) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollFocusedFieldIntoView(focusNode);
        });
      }
    });
  }

  // ============================================================
  // SCROLL FOCUSED FIELD INTO VIEW
  // ============================================================

  void _scrollFocusedFieldIntoView(FocusNode focusNode) {
    if (!mounted) {
      return;
    }

    if (!focusNode.hasFocus) {
      return;
    }

    final context = focusNode.context;

    if (context == null) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.18,
    );
  }

  // ============================================================
  // CITY CHANGE
  // ============================================================

  void _onCityChanged() {
    final selectedCity = LocationController.instance.city.value.trim();

    if (selectedCity.isEmpty) {
      return;
    }

    if (_cityController.text != selectedCity) {
      _cityController.text = selectedCity;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    LocationController.instance.city.removeListener(_onCityChanged);

    _scrollController.dispose();

    _fullNameController.dispose();

    _houseController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();

    _cityController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    _emailController.dispose();

    _fullNameFocus.dispose();

    _houseFocus.dispose();
    _buildingFocus.dispose();
    _streetFocus.dispose();
    _landmarkFocus.dispose();
    _cityFocus.dispose();
    _pincodeFocus.dispose();
    _mobileFocus.dispose();
    _emailFocus.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final contentWidth = width > 520 ? 520.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          AppTextStyles.fig(16),
                          AppTextStyles.fig(8),
                          AppTextStyles.fig(16),
                          AppTextStyles.fig(150),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_topErrorMessage != null) ...[
                              _buildTopErrorMessage(),

                              SizedBox(height: AppTextStyles.fig(12)),
                            ],

                            _buildProductCard(),

                            SizedBox(height: AppTextStyles.fig(14)),

                            _buildGstInfo(),

                            SizedBox(height: AppTextStyles.fig(26)),

                            _buildFullNameField(),

                            SizedBox(height: AppTextStyles.fig(16)),

                            _buildDeliveryHeader(),

                            SizedBox(height: AppTextStyles.fig(16)),

                            _buildAddressField(
                              icon: Icons.home_outlined,
                              title: 'House / Flat Number',
                              hint: 'Enter house / flat number',
                              controller: _houseController,
                              focusNode: _houseFocus,
                              requiredField: true,
                              nextFocus: _buildingFocus,
                            ),

                            _buildAddressField(
                              icon: Icons.apartment_outlined,
                              title: 'Apartment / Building Name',
                              hint: 'Enter apartment / building / society name',
                              controller: _buildingController,
                              focusNode: _buildingFocus,
                              requiredField: true,
                              nextFocus: _streetFocus,
                            ),

                            _buildAddressField(
                              icon: Icons.alt_route_outlined,
                              title: 'Street / Area',
                              hint: 'Enter street / area / locality',
                              controller: _streetController,
                              focusNode: _streetFocus,
                              requiredField: true,
                              nextFocus: _landmarkFocus,
                            ),

                            _buildAddressField(
                              icon: Icons.location_on_outlined,
                              title: 'Landmark',
                              hint: 'Enter nearby landmark',
                              controller: _landmarkController,
                              focusNode: _landmarkFocus,
                              requiredField: false,
                              nextFocus: _cityFocus,
                            ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildAddressField(
                                    icon: Icons.location_city_outlined,
                                    title: 'City',
                                    hint: 'Enter city',
                                    controller: _cityController,
                                    focusNode: _cityFocus,
                                    requiredField: true,
                                    compact: true,
                                    nextFocus: _pincodeFocus,
                                  ),
                                ),

                                SizedBox(width: AppTextStyles.fig(10)),

                                Expanded(
                                  child: _buildAddressField(
                                    icon: Icons.pin_drop_outlined,
                                    title: 'Pincode',
                                    hint: 'Enter pincode',
                                    controller: _pincodeController,
                                    focusNode: _pincodeFocus,
                                    requiredField: true,
                                    compact: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    nextFocus: _mobileFocus,
                                  ),
                                ),
                              ],
                            ),

                            _buildMobileField(),

                            _buildAddressField(
                              icon: Icons.mail_outline,
                              title: 'Email Address',
                              hint: 'Enter your email address',
                              controller: _emailController,
                              focusNode: _emailFocus,
                              requiredField: true,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            _buildEmailNotice(),

                            SizedBox(height: AppTextStyles.fig(20)),

                            HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                          ],
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBottomPaymentBar(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP ERROR
  // ============================================================

  Widget _buildTopErrorMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(14),
        vertical: AppTextStyles.fig(12),
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),

          SizedBox(width: AppTextStyles.fig(10)),

          Expanded(
            child: Text(
              _topErrorMessage!,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w600,
                color: Colors.red.shade700,
                height: 1.35,
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              setState(() {
                _topErrorMessage = null;
              });
            },
            child: Icon(Icons.close, color: Colors.red.shade700, size: 18),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(16),
        AppTextStyles.fig(8),
        AppTextStyles.fig(16),
        AppTextStyles.fig(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.navy,
              size: 28,
            ),
          ),

          Expanded(
            child: Text(
              'Checkout',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 20,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),

          ValueListenableBuilder<String>(
            valueListenable: LocationController.instance.city,
            builder: (context, city, _) {
              return ValueListenableBuilder<LocationStatus>(
                valueListenable: LocationController.instance.status,
                builder: (context, status, _) {
                  return LocationSelector(
                    city: city.isEmpty ? 'Chennai' : city,
                    status: status,
                    onTap: () {
                      LocationPickerSheet.show(context);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard() {
    final product = widget.product;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTextStyles.fig(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Product',
            style: AppTextStyles.of(
              figmaSize: 16,
              weight: FontWeight.w700,
              color: AppColors.purple,
            ),
          ),

          SizedBox(height: AppTextStyles.fig(10)),

          Text(
            product.name,
            style: AppTextStyles.of(
              figmaSize: 22,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),

          if (product.description != null) ...[
            SizedBox(height: AppTextStyles.fig(4)),

            Text(
              product.description!,
              style: AppTextStyles.of(
                figmaSize: 13,
                weight: FontWeight.w400,
                color: AppColors.navy,
                height: 1.35,
              ),
            ),
          ],

          SizedBox(height: AppTextStyles.fig(14)),

          Container(height: 1, color: AppColors.divider),

          SizedBox(height: AppTextStyles.fig(14)),

          if (product.isCombo) ...[
            _priceRow('Monthly Rent (Before Discount)', product.monthlyRent),

            SizedBox(height: AppTextStyles.fig(10)),

            _priceRow(
              'Combo Discount (10%)',
              -product.discount,
              valueColor: Colors.green,
              titleColor: Colors.green,
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: AppTextStyles.fig(12)),
              child: _dashedDivider(),
            ),

            _priceRow('Monthly Rent (After Discount)', product.afterDiscount),

            SizedBox(height: AppTextStyles.fig(10)),

            _priceRow('CGST (9%)', product.cgst),

            SizedBox(height: AppTextStyles.fig(10)),

            _priceRow('SGST (9%)', product.sgst),
          ] else ...[
            _priceRow('Monthly Rent', product.monthlyRent),

            SizedBox(height: AppTextStyles.fig(10)),

            _priceRow('CGST (9%)', product.cgst),

            SizedBox(height: AppTextStyles.fig(10)),

            _priceRow('SGST (9%)', product.sgst),
          ],

          Padding(
            padding: EdgeInsets.symmetric(vertical: AppTextStyles.fig(14)),
            child: _dashedDivider(),
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Monthly Amount',
                  style: AppTextStyles.of(
                    figmaSize: 16,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),

              Text(
                _money(product.total),
                style: AppTextStyles.of(
                  figmaSize: 27,
                  weight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _priceRow(
    String title,
    int amount, {
    Color? valueColor,
    Color? titleColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: titleColor ?? AppColors.navy,
            ),
          ),
        ),

        Text(
          _money(amount),
          style: AppTextStyles.of(
            figmaSize: 14,
            weight: FontWeight.w600,
            color: valueColor ?? AppColors.navy,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHED DIVIDER
  // ============================================================

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 7).floor();

        return Row(
          children: List.generate(
            count,
            (index) => Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: AppColors.divider,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // GST INFO
  // ============================================================

  Widget _buildGstInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(14),
        vertical: AppTextStyles.fig(12),
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: AppTextStyles.fig(28),
            height: AppTextStyles.fig(28),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.purple, width: 2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.purple,
              size: 18,
            ),
          ),

          SizedBox(width: AppTextStyles.fig(12)),

          Expanded(
            child: Text(
              'GST 18% is split into CGST 9% and SGST 9% as per applicable regulations.',
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w400,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL NAME
  // ============================================================

  Widget _buildFullNameField() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppTextStyles.fig(10)),
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(12),
        vertical: AppTextStyles.fig(9),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppTextStyles.fig(40),
            child: Padding(
              padding: EdgeInsets.only(top: AppTextStyles.fig(5)),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textGrayMed,
                size: 22,
              ),
            ),
          ),

          SizedBox(width: AppTextStyles.fig(8)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Full Name',
                    style: AppTextStyles.of(
                      figmaSize: 12,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppTextStyles.fig(2)),

                TextFormField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    _moveToNextField(_houseFocus);
                  },
                  style: AppTextStyles.of(
                    figmaSize: 15,
                    weight: FontWeight.w400,
                    color: AppColors.navy,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: AppTextStyles.of(
                      figmaSize: 15,
                      weight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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
  // DELIVERY HEADER
  // ============================================================

  Widget _buildDeliveryHeader() {
    return Row(
      children: [
        Container(
          width: AppTextStyles.fig(52),
          height: AppTextStyles.fig(52),
          decoration: const BoxDecoration(
            color: AppColors.bgCardPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.home_outlined,
            color: AppColors.purple,
            size: 30,
          ),
        ),

        SizedBox(width: AppTextStyles.fig(14)),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: AppTextStyles.of(
                  figmaSize: 19,
                  weight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),

              SizedBox(height: AppTextStyles.fig(2)),

              Text(
                'Please enter correct address for smooth delivery',
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
    );
  }

  // ============================================================
  // ADDRESS FIELD
  // ============================================================

  Widget _buildAddressField({
    required IconData icon,
    required String title,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool requiredField,
    FocusNode? nextFocus,
    bool compact = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTextStyles.fig(10)),
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(12),
        vertical: AppTextStyles.fig(compact ? 8 : 9),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppTextStyles.fig(40),
            child: Padding(
              padding: EdgeInsets.only(top: AppTextStyles.fig(5)),
              child: Icon(icon, color: AppColors.textGrayMed, size: 22),
            ),
          ),

          SizedBox(width: AppTextStyles.fig(8)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: title,
                    style: AppTextStyles.of(
                      figmaSize: 12,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    children: requiredField
                        ? const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ]
                        : [],
                  ),
                ),

                SizedBox(height: AppTextStyles.fig(2)),

                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    if (nextFocus != null) {
                      _moveToNextField(nextFocus);
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  style: AppTextStyles.of(
                    figmaSize: 15,
                    weight: FontWeight.w400,
                    color: AppColors.navy,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.of(
                      figmaSize: 15,
                      weight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
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
  // MOVE TO NEXT FIELD
  // ============================================================

  void _moveToNextField(FocusNode nextFocus) {
    FocusScope.of(context).requestFocus(nextFocus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollFocusedFieldIntoView(nextFocus);
    });
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileField() {
    return Container(
      margin: EdgeInsets.only(bottom: AppTextStyles.fig(10)),
      padding: EdgeInsets.symmetric(
        horizontal: AppTextStyles.fig(12),
        vertical: AppTextStyles.fig(9),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppTextStyles.fig(40),
            child: Padding(
              padding: EdgeInsets.only(top: AppTextStyles.fig(5)),
              child: const Icon(
                Icons.phone_android_outlined,
                color: AppColors.textGrayMed,
                size: 22,
              ),
            ),
          ),

          SizedBox(width: AppTextStyles.fig(8)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Mobile Number',
                    style: AppTextStyles.of(
                      figmaSize: 12,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppTextStyles.fig(4)),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==================================================
                    // SMALL INDIAN FLAG
                    // ==================================================

                    Container(
                      width: 20,
                      height: 13,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF9933),
                            Colors.white,
                            Color(0xFF138808),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: AppTextStyles.fig(8)),

                    Text(
                      '+91',
                      style: AppTextStyles.of(
                        figmaSize: 13,
                        weight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),

                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.navy,
                    ),

                    SizedBox(width: AppTextStyles.fig(8)),

                    Expanded(
                      child: TextFormField(
                        controller: _mobileController,
                        focusNode: _mobileFocus,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _moveToNextField(_emailFocus);
                        },
                        style: AppTextStyles.of(
                          figmaSize: 15,
                          weight: FontWeight.w400,
                          color: AppColors.navy,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 10 digit mobile number',
                          hintStyle: AppTextStyles.of(
                            figmaSize: 15,
                            weight: FontWeight.w400,
                            color: AppColors.textGray,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMAIL NOTICE
  // ============================================================

  Widget _buildEmailNotice() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTextStyles.fig(6),
        bottom: AppTextStyles.fig(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _emailUpdates = !_emailUpdates;
              });
            },
            child: Icon(
              _emailUpdates
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              color: AppColors.purple,
              size: 23,
            ),
          ),

          SizedBox(width: AppTextStyles.fig(8)),

          Expanded(
            child: Text(
              'Rental invoices and order updates will be sent to this email address.',
              style: AppTextStyles.of(
                figmaSize: 11,
                weight: FontWeight.w400,
                color: AppColors.textGray,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM PAYMENT BAR
  // ============================================================

  Widget _buildBottomPaymentBar() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppTextStyles.fig(18),
          AppTextStyles.fig(12),
          AppTextStyles.fig(18),
          AppTextStyles.fig(16),
        ),
        decoration: const BoxDecoration(
          color: AppColors.bgCardPurple,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppTextStyles.fig(125),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Monthly Amount',
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w500,
                      color: AppColors.navy,
                    ),
                  ),

                  SizedBox(height: AppTextStyles.fig(2)),

                  Text(
                    _money(widget.product.total),
                    style: AppTextStyles.of(
                      figmaSize: 24,
                      weight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 1,
              height: AppTextStyles.fig(48),
              color: AppColors.divider,
            ),

            SizedBox(width: AppTextStyles.fig(16)),

            Expanded(
              child: SizedBox(
                height: AppTextStyles.fig(54),
                child: ElevatedButton(
                  onPressed: _isCreatingCheckout ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    disabledBackgroundColor: AppColors.purple.withValues(
                      alpha: 0.6,
                    ),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isCreatingCheckout
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Proceed to Payment',
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.of(
                                  figmaSize: 15,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(width: AppTextStyles.fig(10)),

                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 27,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROCEED TO PAYMENT
  // ============================================================

  Future<void> _proceedToPayment() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _topErrorMessage = null;
    });

    // ============================================================
    // GET VALUES
    // ============================================================

    final fullName = _fullNameController.text.trim();

    final house = _houseController.text.trim();

    final building = _buildingController.text.trim();

    final street = _streetController.text.trim();

    final landmark = _landmarkController.text.trim();

    final city = _cityController.text.trim();

    final pincode = _pincodeController.text.trim();

    final mobile = _mobileController.text.trim();

    final email = _emailController.text.trim();

    // ============================================================
    // REQUIRED FIELDS
    // ============================================================

    if (fullName.isEmpty ||
        house.isEmpty ||
        building.isEmpty ||
        street.isEmpty ||
        city.isEmpty ||
        pincode.isEmpty ||
        mobile.isEmpty ||
        email.isEmpty) {
      setState(() {
        _topErrorMessage =
            'Please fill all the required fields before proceeding to payment.';
      });

      _scrollToTop();

      return;
    }

    // ============================================================
    // FULL NAME
    // ============================================================

    if (fullName.length < 2) {
      setState(() {
        _topErrorMessage = 'Please enter a valid full name.';
      });

      _scrollToTop();

      return;
    }

    // ============================================================
    // PINCODE
    // ============================================================

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      setState(() {
        _topErrorMessage = 'Please enter a valid 6 digit pincode.';
      });

      _scrollToTop();

      return;
    }

    // ============================================================
    // MOBILE
    // ============================================================

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      setState(() {
        _topErrorMessage = 'Please enter a valid 10 digit mobile number.';
      });

      _scrollToTop();

      return;
    }

    // ============================================================
    // EMAIL
    // ============================================================

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      setState(() {
        _topErrorMessage = 'Please enter a valid email address.';
      });

      _scrollToTop();

      return;
    }

    // ============================================================
    // VARIANT VALIDATION
    // ============================================================

    final variantId = widget.product.variantId;

    if (variantId <= 0) {
      setState(() {
        _topErrorMessage =
            'This product is not yet connected to a backend product variant.';
      });

      _scrollToTop();

      return;
    }

    // ============================================================
    // CREATE CHECKOUT IN BACKEND
    // ============================================================

    setState(() {
      _isCreatingCheckout = true;
    });

    try {
      final checkoutResponse = await ApiService.createCheckout(
        variantId: variantId,
        quantity: 1,
        fullName: fullName,
        mobile: mobile,
        email: email,
        houseFlatNumber: house,
        apartmentName: building,
        streetArea: street,
        landmark: landmark.isEmpty ? null : landmark,
        city: city,
        pincode: pincode,
      );

      if (!mounted) {
        return;
      }

      final checkout = checkoutResponse['checkout'];

      if (checkout is! Map) {
        throw Exception('Backend did not return valid checkout data.');
      }

      final checkoutData = Map<String, dynamic>.from(checkout);

      if (!mounted) {
        return;
      }

      context.push(
        '/payment',
        extra: PaymentScreenArgs(
          product: widget.product,

          fullName: fullName,
          mobile: mobile,
          email: email,

          houseFlatNumber: house,
          apartmentName: building,
          streetArea: street,
          landmark: landmark,
          city: city,
          pincode: pincode,

          checkoutData: checkoutData,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _topErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });

      _scrollToTop();
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingCheckout = false;
        });
      }
    }
  }

  // ============================================================
  // SCROLL TO TOP
  // ============================================================

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(int value) {
    final sign = value < 0 ? '-' : '';

    final number = value.abs().toString();

    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return '$sign₹$formatted';
  }
}

// ================================================================
// CHECKOUT PRODUCT
// ================================================================

enum CheckoutProduct {
  smartLivingCombo,
  familyEssentialsCombo,
  premiumFamilyCombo,
  ultimatePremiumCombo,

  washingMachineTopLoad,
  washingMachineFrontLoad,

  acOneTon,
  acOnePointFiveTon,

  refrigeratorSingleDoor,
  refrigeratorDoubleDoor,
}

// ================================================================
// PRODUCT DATA
// ================================================================

extension CheckoutProductData on CheckoutProduct {
  String get name {
    switch (this) {
      case CheckoutProduct.smartLivingCombo:
        return 'Smart Living Combo';

      case CheckoutProduct.familyEssentialsCombo:
        return 'Family Essentials Combo';

      case CheckoutProduct.premiumFamilyCombo:
        return 'Premium Family Combo';

      case CheckoutProduct.ultimatePremiumCombo:
        return 'Ultimate Premium Combo';

      case CheckoutProduct.washingMachineTopLoad:
        return 'Top Load Washing Machine';

      case CheckoutProduct.washingMachineFrontLoad:
        return 'Front Load Washing Machine';

      case CheckoutProduct.acOneTon:
        return '1 Ton Smart Inverter Split AC';

      case CheckoutProduct.acOnePointFiveTon:
        return '1.5 Ton Smart Inverter Split AC';

      case CheckoutProduct.refrigeratorSingleDoor:
        return 'Single Door Refrigerator';

      case CheckoutProduct.refrigeratorDoubleDoor:
        return 'Double Door Refrigerator';
    }
  }

  String? get description {
    switch (this) {
      case CheckoutProduct.smartLivingCombo:
        return '(1 Ton AC + Double Door Refrigerator + Front Load Washing Machine)';

      case CheckoutProduct.familyEssentialsCombo:
        return '(1 Ton AC + Double Door Refrigerator + Top Load Washing Machine)';

      case CheckoutProduct.premiumFamilyCombo:
        return '(1.5 Ton AC + Double Door Refrigerator + Top Load Washing Machine)';

      case CheckoutProduct.ultimatePremiumCombo:
        return '(1.5 Ton AC + Double Door Refrigerator + Front Load Washing Machine)';

      case CheckoutProduct.washingMachineTopLoad:
        return 'Powerful cleaning with multiple wash programs.';

      case CheckoutProduct.washingMachineFrontLoad:
        return 'Energy efficient washing with gentle fabric care.';

      case CheckoutProduct.acOneTon:
        return 'Powerful cooling with low power consumption.';

      case CheckoutProduct.acOnePointFiveTon:
        return 'Powerful cooling for larger rooms with low power consumption.';

      case CheckoutProduct.refrigeratorSingleDoor:
        return 'Efficient cooling with spacious storage.';

      case CheckoutProduct.refrigeratorDoubleDoor:
        return 'Powerful cooling with large storage capacity.';
    }
  }

  // ============================================================
  // IS COMBO
  // ============================================================

  bool get isCombo {
    switch (this) {
      case CheckoutProduct.smartLivingCombo:
      case CheckoutProduct.familyEssentialsCombo:
      case CheckoutProduct.premiumFamilyCombo:
      case CheckoutProduct.ultimatePremiumCombo:
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // MONTHLY RENT
  // ============================================================

  int get monthlyRent {
    switch (this) {
      case CheckoutProduct.smartLivingCombo:
        return 2597;

      case CheckoutProduct.familyEssentialsCombo:
        return 2349;

      case CheckoutProduct.premiumFamilyCombo:
        return 2647;

      case CheckoutProduct.ultimatePremiumCombo:
        return 2897;

      case CheckoutProduct.washingMachineTopLoad:
        return 599;

      case CheckoutProduct.washingMachineFrontLoad:
        return 899;

      case CheckoutProduct.acOneTon:
        return 999;

      case CheckoutProduct.acOnePointFiveTon:
        return 1299;

      case CheckoutProduct.refrigeratorSingleDoor:
        return 499;

      case CheckoutProduct.refrigeratorDoubleDoor:
        return 749;
    }
  }

  // ============================================================
  // DISCOUNT
  // ============================================================

  int get discount {
    switch (this) {
      case CheckoutProduct.smartLivingCombo:
        return 260;

      case CheckoutProduct.familyEssentialsCombo:
        return 237;

      case CheckoutProduct.premiumFamilyCombo:
        return 265;

      case CheckoutProduct.ultimatePremiumCombo:
        return 290;

      default:
        return 0;
    }
  }

  // ============================================================
  // AFTER DISCOUNT
  // ============================================================

  int get afterDiscount {
    return monthlyRent - discount;
  }

  // ============================================================
  // TOTAL GST
  // ============================================================

  int get gst {
    switch (this) {
      case CheckoutProduct.smartLivingCombo:
        return 421;

      case CheckoutProduct.familyEssentialsCombo:
        return 380;

      case CheckoutProduct.premiumFamilyCombo:
        return 429;

      case CheckoutProduct.ultimatePremiumCombo:
        return 469;

      case CheckoutProduct.washingMachineTopLoad:
        return 108;

      case CheckoutProduct.washingMachineFrontLoad:
        return 162;

      case CheckoutProduct.acOneTon:
        return 180;

      case CheckoutProduct.acOnePointFiveTon:
        return 234;

      case CheckoutProduct.refrigeratorSingleDoor:
        return 90;

      case CheckoutProduct.refrigeratorDoubleDoor:
        return 135;
    }
  }

  // ============================================================
  // CGST
  // ============================================================

  int get cgst {
    return gst ~/ 2;
  }

  // ============================================================
  // SGST
  // ============================================================

  int get sgst {
    return gst - cgst;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  int get total {
    return afterDiscount + gst;
  }

  // ============================================================
  // DATABASE VARIANT ID
  //
  // IMPORTANT:
  // These IDs MUST match the PostgreSQL product_variants table
  // (product_id 4, "Combo Plan", for the combo rows).
  //
  // 1  = 1.5 Ton AC
  // 2  = 1 Ton AC
  // 3  = Single Door Refrigerator
  // 4  = Double Door Refrigerator
  // 5  = Top Load Washing Machine
  // 6  = Front Load Washing Machine
  // 7  = Essential Combo (retired — no longer offered, kept for order history)
  // 8  = Premium Combo (retired — no longer offered, kept for order history)
  // 9  = Smart Living Combo
  // 10 = Family Essentials Combo
  // 11 = Premium Family Combo
  // 12 = Ultimate Premium Combo
  // ============================================================

  int get variantId {
    switch (this) {
      // ========================================================
      // AC
      // ========================================================

      case CheckoutProduct.acOnePointFiveTon:
        return 1;

      case CheckoutProduct.acOneTon:
        return 2;

      // ========================================================
      // REFRIGERATOR
      // ========================================================

      case CheckoutProduct.refrigeratorSingleDoor:
        return 3;

      case CheckoutProduct.refrigeratorDoubleDoor:
        return 4;

      // ========================================================
      // WASHING MACHINE
      // ========================================================

      case CheckoutProduct.washingMachineTopLoad:
        return 5;

      case CheckoutProduct.washingMachineFrontLoad:
        return 6;

      // ========================================================
      // COMBO
      // ========================================================

      case CheckoutProduct.smartLivingCombo:
        return 9;

      case CheckoutProduct.familyEssentialsCombo:
        return 10;

      case CheckoutProduct.premiumFamilyCombo:
        return 11;

      case CheckoutProduct.ultimatePremiumCombo:
        return 12;
    }
  }
}
