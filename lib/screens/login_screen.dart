import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../services/customer_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.embedded = false,
  });

  /// When true, the login UI is shown inside Profile instead of
  /// navigating to a separate /login page.
  final bool embedded;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginMode { customer, admin }

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController =
      TextEditingController();

  final TextEditingController _adminEmailController =
      TextEditingController();

  final TextEditingController _adminPasswordController =
      TextEditingController();

  final FocusNode _mobileFocusNode =
      FocusNode();

  bool _isLoading = false;
  bool _obscureAdminPassword = true;
  String? _errorMessage;
  _LoginMode _loginMode = _LoginMode.customer;

  // Android / iOS Firebase verification ID.
  String? _verificationId;

  // Web Firebase confirmation result.
  ConfirmationResult? _confirmationResult;

  @override
  void dispose() {
    _mobileController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN / SEND OTP
  // ============================================================

  Future<void> _login() async {
    if (_loginMode == _LoginMode.admin) {
      await _adminLogin();
      return;
    }

    await _customerLogin();
  }

  // ============================================================
  // CUSTOMER LOGIN / SEND OTP
  // ============================================================

  Future<void> _customerLogin() async {
    FocusScope.of(context).unfocus();

    final mobile = _mobileController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (mobile.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your mobile number.';
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
      final phoneNumber = '+91$mobile';

      if (kIsWeb) {
        await _sendOtpWeb(phoneNumber);
      } else {
        await _sendOtpMobile(phoneNumber);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _firebaseErrorMessage(error);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _cleanErrorMessage(error.toString());
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // ADMIN LOGIN
  // ============================================================

  Future<void> _adminLogin() async {
    FocusScope.of(context).unfocus();

    final email = _adminEmailController.text.trim();
    final password = _adminPasswordController.text;

    setState(() {
      _errorMessage = null;
    });

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your admin email address.';
      });
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your admin password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Unable to authenticate admin account.');
      }

      final idToken = await firebaseUser.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Unable to obtain Firebase authentication token.',
        );
      }

      final response = await ApiService.firebaseAdminLogin(
        idToken: idToken,
      );

      if (response['success'] != true) {
        await FirebaseAuth.instance.signOut();

        throw Exception(
          response['message']?.toString() ?? 'Admin login failed.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      context.go('/admin');
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _adminFirebaseErrorMessage(error);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _cleanErrorMessage(error.toString());
        _isLoading = false;
      });

      // Make sure an unauthorized Firebase admin attempt does not
      // leave the Firebase account signed in.
      await FirebaseAuth.instance.signOut();
    }
  }

  String _adminFirebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid admin email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return error.message ?? 'Admin login failed.';
    }
  }

  // ============================================================
  // WEB - SEND OTP
  // ============================================================

  Future<void> _sendOtpWeb(
    String phoneNumber,
  ) async {
    final auth = FirebaseAuth.instance;

    debugPrint(
      '======================================',
    );
    debugPrint(
      'Starting Firebase Web phone authentication...',
    );
    debugPrint(
      'Phone: $phoneNumber',
    );
    debugPrint(
      '======================================',
    );

    // Firebase automatically handles the Web reCAPTCHA
    // when signInWithPhoneNumber() is called.
    _confirmationResult =
        await auth.signInWithPhoneNumber(
      phoneNumber,
    );

    debugPrint(
      'Firebase OTP request completed.',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    await _showOtpDialog();
  }

  // ============================================================
  // ANDROID / IOS - SEND OTP
  // ============================================================

  Future<void> _sendOtpMobile(
    String phoneNumber,
  ) async {
    final auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      // ----------------------------------------------------------
      // Automatic verification
      // ----------------------------------------------------------

      verificationCompleted:
          (PhoneAuthCredential credential) async {
        try {
          final userCredential =
              await auth.signInWithCredential(
            credential,
          );

          await _completeBackendLogin(
            userCredential.user,
          );
        } catch (error) {
          if (!mounted) {
            return;
          }

          setState(() {
            _errorMessage =
                _cleanErrorMessage(
              error.toString(),
            );
            _isLoading = false;
          });
        }
      },

      // ----------------------------------------------------------
      // Verification failed
      // ----------------------------------------------------------

      verificationFailed:
          (FirebaseAuthException error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage =
              _firebaseErrorMessage(error);
          _isLoading = false;
        });
      },

      // ----------------------------------------------------------
      // OTP sent
      // ----------------------------------------------------------

      codeSent: (
        String verificationId,
        int? resendToken,
      ) async {
        _verificationId =
            verificationId;

        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        await _showOtpDialog();
      },

      // ----------------------------------------------------------
      // Auto retrieval timeout
      // ----------------------------------------------------------

      codeAutoRetrievalTimeout:
          (String verificationId) {
        _verificationId =
            verificationId;
      },
    );
  }

  // ============================================================
  // OTP DIALOG
  // ============================================================

  Future<void> _showOtpDialog() async {
    final TextEditingController otpController =
        TextEditingController();

    String? otpError;

    final String? otp =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Verify Mobile Number',
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the 6-digit OTP sent to your mobile number.',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    controller:
                        otpController,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    decoration:
                        InputDecoration(
                      labelText: 'OTP',
                      hintText:
                          'Enter OTP',
                      counterText: '',
                      errorText:
                          otpError,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    final code =
                        otpController
                            .text
                            .trim();

                    if (!RegExp(
                      r'^\d{6}$',
                    ).hasMatch(code)) {
                      setDialogState(() {
                        otpError =
                            'Please enter a valid 6-digit OTP.';
                      });
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(code);
                  },
                  child:
                      const Text(
                    'Verify',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    otpController.dispose();

    // User cancelled OTP dialog.
    if (otp == null ||
        otp.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential;

      // ========================================================
      // WEB OTP VERIFICATION
      // ========================================================

      if (kIsWeb) {
        final confirmation =
            _confirmationResult;

        if (confirmation == null) {
          throw Exception(
            'OTP verification session expired. Please request a new OTP.',
          );
        }

        userCredential =
            await confirmation.confirm(
          otp,
        );
      }

      // ========================================================
      // ANDROID / IOS OTP VERIFICATION
      // ========================================================

      else {
        final verificationId =
            _verificationId;

        if (verificationId == null ||
            verificationId.isEmpty) {
          throw Exception(
            'OTP verification session expired. Please request a new OTP.',
          );
        }

        final credential =
            PhoneAuthProvider.credential(
          verificationId:
              verificationId,
          smsCode: otp,
        );

        userCredential =
            await FirebaseAuth.instance
                .signInWithCredential(
          credential,
        );
      }

      debugPrint(
        '======================================',
      );
      debugPrint(
        'Firebase phone authentication successful.',
      );
      debugPrint(
        'Firebase UID: ${userCredential.user?.uid}',
      );
      debugPrint(
        '======================================',
      );

      // Send Firebase user to backend.
      await _completeBackendLogin(
        userCredential.user,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            _firebaseErrorMessage(error);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            _cleanErrorMessage(
          error.toString(),
        );
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FIREBASE → BACKEND LOGIN
  // ============================================================

  Future<void> _completeBackendLogin(
    User? firebaseUser,
  ) async {
    if (firebaseUser == null) {
      throw Exception(
        'Firebase user information was not received.',
      );
    }

    debugPrint(
      'Firebase user UID: ${firebaseUser.uid}',
    );

    debugPrint(
      'Getting Firebase ID token...',
    );

    // Get Firebase ID token.
    final idToken =
        await firebaseUser.getIdToken();

    if (idToken == null ||
        idToken.isEmpty) {
      throw Exception(
        'Unable to obtain Firebase authentication token.',
      );
    }

    debugPrint(
      'Firebase ID token received successfully.',
    );

    debugPrint(
      'Calling RentMitra backend...',
    );

    // ----------------------------------------------------------
    // CALL BACKEND
    // ----------------------------------------------------------

    Map<String, dynamic> response;

    try {
      response =
          await ApiService.firebaseCustomerLogin(
        idToken: idToken,
      );
    } catch (error) {
      final backendError =
          _cleanErrorMessage(
        error.toString(),
      );

      debugPrint(
        'Firebase backend login failed: $backendError',
      );

      // ========================================================
      // NEW CUSTOMER
      // ========================================================
      //
      // Backend team API returns 404 with:
      //
      // "Customer account not found. Please complete a rental
      // booking first."
      //
      // Firebase authentication itself succeeded, but the
      // customer does not yet have a RentMitra customer account.
      //
      // We must sign the Firebase user out here because we do
      // not want an unregistered customer to remain authenticated
      // in Firebase.
      // ========================================================

      if (_isNewCustomerError(backendError)) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        await _showNewCustomerDialog();

        if (!mounted) {
          return;
        }

        // Send the user back to Home / Products.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // Any other backend error should continue to the
      // normal error handling.
      throw Exception(backendError);
    }

    // ==========================================================
    // DEBUG BACKEND RESPONSE
    // ==========================================================

    debugPrint(
      '======================================',
    );
    debugPrint(
      'FIREBASE BACKEND RESPONSE: $response',
    );
    debugPrint(
      '======================================',
    );

    // ==========================================================
    // READ CUSTOMER
    // ==========================================================

    final customerData =
        response['customer'];

    if (customerData is! Map) {
      throw Exception(
        'Invalid response received from the backend.',
      );
    }

    final customer =
        Map<String, dynamic>.from(
      customerData,
    );

    final customerId =
        int.tryParse(
      customer['customer_id']
              ?.toString() ??
          '',
    );

    final fullName =
        customer['full_name']
                ?.toString()
                .trim() ??
            '';

    if (customerId == null ||
        customerId <= 0) {
      throw Exception(
        'Invalid customer ID received from server.',
      );
    }

    if (fullName.isEmpty) {
      throw Exception(
        'Customer name was not returned by server.',
      );
    }

    // ==========================================================
    // SAVE CUSTOMER SESSION
    // ==========================================================

    await CustomerSession.instance.setCustomer(
      customerId: customerId,
      fullName: fullName,
    );

    debugPrint(
      'Customer session saved successfully.',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    // ==========================================================
    // GO TO NEXT SCREEN
    // ==========================================================

    if (widget.embedded) {
      // Login was opened directly inside Profile.
      context.go('/profile');
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  // ============================================================
  // CHECK NEW CUSTOMER ERROR
  // ============================================================

  bool _isNewCustomerError(String message) {
    final normalized =
        message.toLowerCase();

    return normalized.contains(
          'customer account not found',
        ) ||
        normalized.contains(
          'please complete a rental booking first',
        );
  }

  // ============================================================
  // NEW CUSTOMER DIALOG
  // ============================================================

  Future<void> _showNewCustomerDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Profile Not Available',
          ),
          content: const Text(
            'Make your first order to view your profile.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Go to Home',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Please enter a valid mobile number.';

      case 'too-many-requests':
        return 'Too many OTP attempts. Please try again later.';

      case 'invalid-verification-code':
        return 'The OTP is incorrect. Please try again.';

      case 'session-expired':
        return 'The OTP has expired. Please request a new OTP.';

      case 'quota-exceeded':
        return 'OTP limit reached. Please try again later.';

      case 'captcha-check-failed':
        return 'Security verification failed. Please try again.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Phone authentication is not enabled in Firebase.';

      case 'billing-not-enabled':
        return 'Firebase Phone Authentication requires billing for real SMS.';

      default:
        return error.message ??
            'Firebase authentication failed.';
    }
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(
    String error,
  ) {
    if (error.startsWith(
      'Exception: ',
    )) {
      return error.substring(
        'Exception: '.length,
      );
    }

    return error;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 20 : 32,
            vertical: isCompact ? 24 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Login to view your profile, rentals and account details.',
                      style: AppTextStyles.of(
                        figmaSize: 15,
                        weight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _buildLoginCard(),
                  const SizedBox(height: 18),
                  _buildSecurityNote(),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: content,
      ),
    );
  }

  // ============================================================
  // LOGIN MODE SELECTOR
  // ============================================================

  Widget _buildModeSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: 'Customer',
              icon: Icons.person_outline_rounded,
              mode: _LoginMode.customer,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton(
              label: 'Admin',
              icon: Icons.admin_panel_settings_outlined,
              mode: _LoginMode.admin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required _LoginMode mode,
  }) {
    final selected = _loginMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                FocusScope.of(context).unfocus();

                setState(() {
                  _loginMode = mode;
                  _errorMessage = null;
                });
              },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.purple
                    : AppColors.textGray,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTextStyles.of(
                  figmaSize: 13,
                  weight: FontWeight.w700,
                  color: selected
                      ? AppColors.navy
                      : AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _loginMode == _LoginMode.admin
          ? _buildAdminLoginCard()
          : _buildCustomerLoginCard(),
    );
  }

  Widget _buildCustomerLoginCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mobile number'),
        const SizedBox(height: 8),
        TextField(
          controller: _mobileController,
          focusNode: _mobileFocusNode,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          enabled: !_isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isLoading) {
              _login();
            }
          },
          decoration: _fieldDecoration(
            hint: 'Enter 10-digit mobile number',
            prefix: _buildPhonePrefix(),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
        const SizedBox(height: 18),
        _buildLoginButton(
          label: 'Continue',
          onPressed: _login,
        ),
        const SizedBox(height: 11),
        Center(
          child: Text(
            'We will send a verification code to your mobile.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 11,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminLoginCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Email address'),
        const SizedBox(height: 8),
        TextField(
          controller: _adminEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          onSubmitted: (_) {
            if (!_isLoading) {
              FocusScope.of(context).nextFocus();
            }
          },
          decoration: _fieldDecoration(
            hint: 'Enter admin email',
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _adminPasswordController,
          obscureText: _obscureAdminPassword,
          enabled: !_isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isLoading) {
              _login();
            }
          },
          decoration: _fieldDecoration(
            hint: 'Enter password',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              tooltip: _obscureAdminPassword
                  ? 'Show password'
                  : 'Hide password',
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _obscureAdminPassword =
                            !_obscureAdminPassword;
                      });
                    },
              icon: Icon(
                _obscureAdminPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 19,
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
        const SizedBox(height: 18),
        _buildLoginButton(
          label: 'Sign in',
          onPressed: _login,
        ),
      ],
    );
  }

  // ============================================================
  // FIELD HELPERS
  // ============================================================

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.of(
        figmaSize: 12,
        weight: FontWeight.w600,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildPhonePrefix() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 13,
        right: 8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+91',
            style: AppTextStyles.of(
              figmaSize: 13,
              weight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFFD9D9DF),
          ),
          const SizedBox(width: 7),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: AppTextStyles.of(
        figmaSize: 13,
        weight: FontWeight.w400,
        color: AppColors.textGray,
      ),
      prefixIcon: prefix ??
          (prefixIcon == null
              ? null
              : Icon(
                  prefixIcon,
                  size: 19,
                  color: AppColors.textGray,
                )),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE1E1E7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE1E1E7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: AppColors.purple,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE57373),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFF5D3D3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: Color(0xFFD64545),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.of(
                figmaSize: 11,
                weight: FontWeight.w500,
                color: const Color(0xFFC43D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN BUTTON
  // ============================================================

  Widget _buildLoginButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.purple.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: AppTextStyles.of(
                  figmaSize: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // SECURITY NOTE
  // ============================================================

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 15,
          color: AppColors.textGray,
        ),
        const SizedBox(width: 6),
        Text(
          'Secure login powered by Firebase',
          style: AppTextStyles.of(
            figmaSize: 10,
            weight: FontWeight.w400,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
