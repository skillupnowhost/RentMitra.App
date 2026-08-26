import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/floating_orbs.dart';

/// Cinematic brand splash: an animated gradient + drifting orb field behind
/// a fade/scale reveal of the full RentMitra.app logo lockup — held
/// briefly, then a fade/scale hand-off into the swipeable per-appliance
/// splash slider.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _bg = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _reveal.forward();
    _navTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      context.go('/splash-slider');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _reveal.dispose();
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoStage = CurvedAnimation(
      parent: _reveal,
      curve: Curves.easeOutCubic,
    );
    final logoWidth = (size.width * 0.8).clamp(0.0, 340.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.splashBackground.first,
      body: Stack(
        children: [
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
          Positioned(
            top: 0,
            left: 0,
            width: size.width * 0.6,
            child: Image.asset(
              'assets/images/blob_top_left.png',
              fit: BoxFit.contain,
            ),
          ),
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
          const FloatingOrbsBackground(intensity: 0.85),
          Center(
            child: AnimatedBuilder(
              animation: logoStage,
              builder: (context, child) {
                return Opacity(
                  opacity: logoStage.value,
                  child: Transform.scale(
                    scale: 0.85 + logoStage.value * 0.15,
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
