import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/logo_mark.dart';
import 'splash_slider_screen.dart';

/// Pure brand splash: logo + tagline, fade/scale in, brief hold, then hand
/// off to the swipeable per-appliance splash slider (which itself hands off
/// to the onboarding carousel). Kept intentionally minimal per spec — the
/// richer composition (appliance art, feature icons, pagination dots) lives
/// on the slider/onboarding screens so it isn't shown twice in a row.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashSliderScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.splashBackground.first,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.splashBackground,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: BrandWordmark(
                      figmaWordmarkSize: 78,
                      figmaLogoWidth: 197,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
