import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/customer_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController =
      TextEditingController();

  final FocusNode _mobileFocusNode =
      FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final mobile = _mobileController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (mobile.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter your mobile number.';
      });
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      setState(() {
        _errorMessage =
            'Mobile number must contain exactly 10 digits.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.loginCustomer(
        mobile: mobile,
      );

      final customerData = response['customer'];

      if (customerData is! Map) {
        throw Exception(
          'Invalid customer information received.',
        );
      }

      final customer =
          Map<String, dynamic>.from(customerData);

      final customerId = int.tryParse(
        customer['customer_id']?.toString() ?? '',
      );

      final fullName =
          customer['full_name']?.toString().trim() ?? '';

      if (customerId == null || customerId <= 0) {
        throw Exception(
          'Invalid customer ID received from server.',
        );
      }

      if (fullName.isEmpty) {
        throw Exception(
          'Customer name was not returned by server.',
        );
      }

      // Save customer session permanently.
      await CustomerSession.instance.setCustomer(
        customerId: customerId,
        fullName: fullName,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _cleanErrorMessage(
          error.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _cleanErrorMessage(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring(
        'Exception: '.length,
      );
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 42),
                  _buildLoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: 34,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: AppTextStyles.of(
            figmaSize: 30,
            weight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to access your profile and rentals.',
          style: AppTextStyles.of(
            figmaSize: 15,
            weight: FontWeight.w400,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Number',
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mobileController,
            focusNode: _mobileFocusNode,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            enabled: !_isLoading,
            textInputAction:
                TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) {
                _login();
              }
            },
            decoration: InputDecoration(
              counterText: '',
              hintText:
                  'Enter 10-digit mobile number',
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.only(
                  left: 14,
                  right: 8,
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      '+91',
                      style: AppTextStyles.of(
                        figmaSize: 14,
                        weight:
                            FontWeight.w600,
                        color:
                            AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.purple,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.06,
                ),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _isLoading ? null : _login,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.purple,
                foregroundColor:
                    Colors.white,
                disabledBackgroundColor:
                    AppColors.purple.withValues(
                  alpha: 0.5,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      'Login',
                      style:
                          AppTextStyles.of(
                        figmaSize: 15,
                        weight:
                            FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Use the mobile number registered with your RentMitra account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 12,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}