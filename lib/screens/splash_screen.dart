import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/floating_orbs.dart';

/// Launch sequence:
/// 1. Brief white frame
/// 2. Cinematic RentMitra brand splash
/// 3. Animated logo reveal
/// 4. Navigate to the Home screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // TIMING
  // ============================================================

  static const _whitePhase = Duration(milliseconds: 200);
  static const _brandHold = Duration(milliseconds: 2600);

  // ============================================================
  // ANIMATIONS
  // ============================================================

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final AnimationController _bg = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  // ============================================================
  // STATE
  // ============================================================

  bool _showWhite = true;

  Timer? _whiteTimer;
  Timer? _navTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // WHITE LAUNCH PHASE
    // ------------------------------------------------------------

    _whiteTimer = Timer(_whitePhase, () {
      if (!mounted) return;

      setState(() {
        _showWhite = false;
      });

      _reveal.forward();
    });

    // ------------------------------------------------------------
    // NAVIGATION TO HOME
    // ------------------------------------------------------------
    //
    // Previously:
    // context.go('/splash-slider');
    //
    // There is currently no /splash-slider route registered
    // in GoRouter, which caused the "Page Not Found" screen.
    //
    // The current customer flow is:
    //
    // Splash → Home → Product Selection
    //
    // Therefore we navigate directly to /home.
    // ------------------------------------------------------------

    _navTimer = Timer(_whitePhase + _brandHold, () {
      if (!mounted) return;

      context.go('/home');
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _whiteTimer?.cancel();
    _navTimer?.cancel();

    _reveal.dispose();
    _bg.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // WHITE INITIAL FRAME
    // ------------------------------------------------------------

    if (_showWhite) {
      return const Scaffold(
        backgroundColor: Colors.white,
      );
    }

    // ------------------------------------------------------------
    // SCREEN SIZE
    // ------------------------------------------------------------

    final size = MediaQuery.of(context).size;

    // ------------------------------------------------------------
    // LOGO ANIMATION
    // ------------------------------------------------------------

    final logoStage = CurvedAnimation(
      parent: _reveal,
      curve: Curves.easeOutCubic,
    );

    final logoWidth = (size.width * 0.8)
        .clamp(0.0, 340.0)
        .toDouble();

    // ------------------------------------------------------------
    // SPLASH SCREEN
    // ------------------------------------------------------------

    return Scaffold(
      backgroundColor: AppColors.splashBackground.first,
      body: Stack(
        children: [
          // ======================================================
          // ANIMATED GRADIENT BACKGROUND
          // ======================================================

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bg,
              builder: (context, _) {
                final shift = _bg.value * 0.16;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.splashBackground,
                      begin: Alignment.topCenter,
                      end: Alignment(shift, 1.0),
                    ),
                  ),
                );
              },
            ),
          ),

          // ======================================================
          // TOP LEFT BLOB
          // ======================================================

          Positioned(
            top: 0,
            left: 0,
            width: size.width * 0.6,
            child: Image.asset(
              'assets/images/blob_top_left.png',
              fit: BoxFit.contain,
            ),
          ),

          // ======================================================
          // BOTTOM RIGHT BLOB
          // ======================================================

          Positioned(
            bottom: 0,
            right: 0,
            width: size.width * 0.6,
            child: Transform.rotate(
              angle: 3.14159,
              child: Image.asset(
                'assets/images/blob_top_left.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ======================================================
          // FLOATING ORBS
          // ======================================================

          const FloatingOrbsBackground(
            intensity: 0.85,
          ),

          // ======================================================
          // RENTMITRA LOGO
          // ======================================================

          Center(
            child: AnimatedBuilder(
              animation: logoStage,
              builder: (context, child) {
                return Opacity(
                  opacity: logoStage.value,
                  child: Transform.scale(
                    scale: 0.85 + (logoStage.value * 0.15),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo_full.png',
                width: logoWidth,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}