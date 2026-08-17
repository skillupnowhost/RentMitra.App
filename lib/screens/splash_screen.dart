import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/cinematic_route.dart';
import '../widgets/floating_orbs.dart';
import '../widgets/logo_mark.dart';
import 'splash_slider_screen.dart';

/// Cinematic brand splash: an animated gradient + drifting orb field behind
/// a staged logo reveal — glow ring, mark, then wordmark and tagline
/// lifting in in sequence — held briefly, then a fade/scale hand-off into
/// the swipeable per-appliance splash slider.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
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
    _reveal.addStatusListener((status) {
      if (status == AnimationStatus.completed) _glow.repeat(reverse: true);
    });
    _navTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(cinematicRoute(const SplashSliderScreen()));
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _reveal.dispose();
    _glow.dispose();
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final logoStage = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    final wordStage = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0.35, 0.78, curve: Curves.easeOutCubic),
    );
    final taglineStage = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
    );

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (context, child) {
                            final pulse = 0.18 + _glow.value * 0.22;
                            final scale = 1.0 + _glow.value * 0.08;
                            return Opacity(
                              opacity: pulse,
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.purple.withValues(alpha: 0.55),
                                  AppColors.purple.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: logoStage,
                          builder: (context, child) {
                            return Opacity(
                              opacity: logoStage.value,
                              child: Transform.scale(
                                scale: 0.72 + logoStage.value * 0.28,
                                child: child,
                              ),
                            );
                          },
                          child: const LogoMark(width: 92),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTextStyles.fig(20)),
                  AnimatedBuilder(
                    animation: wordStage,
                    builder: (context, child) {
                      return Opacity(
                        opacity: wordStage.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - wordStage.value) * 16),
                          child: child,
                        ),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Rent',
                              style: AppTextStyles.display(
                                figmaSize: 56,
                                weight: FontWeight.w800,
                                color: AppColors.navyDeep,
                              ),
                            ),
                            TextSpan(
                              text: 'Mitra',
                              style: AppTextStyles.display(
                                figmaSize: 54,
                                weight: FontWeight.w800,
                                color: AppColors.purple,
                                shadows: [
                                  Shadow(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTextStyles.fig(14)),
                  AnimatedBuilder(
                    animation: taglineStage,
                    builder: (context, child) {
                      return Opacity(
                        opacity: taglineStage.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - taglineStage.value) * 12),
                          child: child,
                        ),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _dash(),
                          SizedBox(width: AppTextStyles.fig(10)),
                          Text(
                            'RENT MADE EASY',
                            style: AppTextStyles.of(
                              figmaSize: 21,
                              weight: FontWeight.w600,
                              color: AppColors.textGrayMed,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(width: AppTextStyles.fig(10)),
                          _dash(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dash() {
    return Container(
      width: 26,
      height: 1.2,
      color: AppColors.purple.withValues(alpha: 0.55),
    );
  }
}
