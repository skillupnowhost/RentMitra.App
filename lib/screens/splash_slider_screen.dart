import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/customer_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/cinematic_route.dart';
import '../widgets/animated_feature_badge.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/floating_art.dart';
import '../widgets/premium_cta_button.dart';
import '../widgets/reveal_text.dart';
import '../widgets/skip_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Splash carousel — the full-ecosystem hero first, then AC / Washing
/// Machine / Refrigerator deep-dives — each with its own headline, feature
/// badges, floating product art and tagline.
class SplashSliderScreen extends StatefulWidget {
  const SplashSliderScreen({super.key});

  @override
  State<SplashSliderScreen> createState() =>
      _SplashSliderScreenState();
}

class _SlideData {
  const _SlideData({
    required this.titleLine1,
    required this.titleLine2,
    required this.description,
    required this.features,
    required this.assetPath,
    required this.caption,
  });

  final String titleLine1;
  final String titleLine2;
  final String description;
  final List<AnimatedFeatureData> features;
  final String assetPath;
  final String caption;
}

const _slides = [
  _SlideData(
    titleLine1: 'Rent Smart.',
    titleLine2: 'Live Easy.',
    description:
        'AC, washing machines, refrigerators and more — one app for every premium appliance.',
    features: [
      AnimatedFeatureData(
        icon: Icons.local_shipping_outlined,
        label: 'Free\nDelivery',
      ),
      AnimatedFeatureData(
        icon: Icons.build_outlined,
        label: 'Free\nInstallation',
        labelWeight: FontWeight.w400,
      ),
      AnimatedFeatureData(
        icon: Icons.verified_user_outlined,
        label: 'Service &\nMaintenance',
        figmaLabelSize: 12,
      ),
    ],
    assetPath: 'assets/images/main_splash.png',
    caption: 'Smart Renting, Better Living',
  ),
  _SlideData(
    titleLine1: 'Rental AC',
    titleLine2: 'Cool Comfort, On Your Terms',
    description:
        'Rent premium air conditioners with hassle-free installation and maintenance.',
    features: [
      AnimatedFeatureData(
        icon: Icons.ac_unit,
        label: 'Fast\nCooling',
      ),
      AnimatedFeatureData(
        icon: Icons.build_outlined,
        label: 'Free\nInstallation',
        labelWeight: FontWeight.w400,
      ),
      AnimatedFeatureData(
        icon: Icons.verified_user_outlined,
        label: 'Service &\nMaintenance',
        figmaLabelSize: 12,
      ),
    ],
    assetPath: 'assets/images/ac_splash.png',
    caption: 'Stay Cool, Save More',
  ),
  _SlideData(
    titleLine1: 'Rental Washing Machine',
    titleLine2: 'Laundry Made Effortless',
    description:
        'Get fully automatic washing machines on rent with free delivery and setup.',
    features: [
      AnimatedFeatureData(
        icon: Icons.local_shipping_outlined,
        label: 'Free\nDelivery',
      ),
      AnimatedFeatureData(
        icon: Icons.settings_outlined,
        label: 'Easy\nInstallation',
        labelWeight: FontWeight.w400,
      ),
      AnimatedFeatureData(
        icon: Icons.shopping_basket_outlined,
        label: 'Premium\nMachines',
        figmaLabelSize: 12,
      ),
    ],
    assetPath:
        'assets/images/washing_machine_splash.png',
    caption: 'Fresh Clothes, Zero Hassle',
  ),
  _SlideData(
    titleLine1: 'Rental Refrigerator',
    titleLine2: 'Freshness That Lasts',
    description:
        'Rent energy-efficient refrigerators for every home and lifestyle.',
    features: [
      AnimatedFeatureData(
        icon: Icons.eco_outlined,
        label: 'Fresh Food\nStorage',
        figmaLabelSize: 12,
      ),
      AnimatedFeatureData(
        icon: Icons.bolt,
        label: 'Energy\nEfficient',
        labelWeight: FontWeight.w400,
      ),
      AnimatedFeatureData(
        icon: Icons.handyman_outlined,
        label: 'Free Service\nSupport',
        figmaLabelSize: 12,
      ),
    ],
    assetPath: 'assets/images/fridge_splash.png',
    caption: 'Keep It Fresh, Every Day',
  ),
];

class _SplashSliderScreenState
    extends State<SplashSliderScreen> {
  final _pageController = PageController();

  int _page = 0;
  bool _userInteracted = false;
  Timer? _autoTimer;

  static const _slideCount = 4;

  static const _autoplayInterval =
      Duration(milliseconds: 4200);

  @override
  void initState() {
    super.initState();
    _armAutoplay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _armAutoplay() {
    _autoTimer?.cancel();

    if (_userInteracted) {
      return;
    }

    _autoTimer = Timer(
      _autoplayInterval,
      () {
        if (!mounted || _userInteracted) {
          return;
        }

        final next =
            (_page + 1) % _slideCount;

        _pageController.animateToPage(
          next,
          duration:
              const Duration(milliseconds: 750),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  void _onUserInteraction() {
    if (_userInteracted) {
      return;
    }

    _userInteracted = true;
    _autoTimer?.cancel();
  }

  /// Opens the correct screen after the splash carousel.
  ///
  /// Existing customer:
  /// Splash → Home
  ///
  /// New customer:
  /// Splash → Login
  void _openAfterSplash() {
    if (!mounted) {
      return;
    }

    final Widget nextScreen =
        CustomerSession.instance.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen();

    Navigator.of(context).pushReplacement(
      cinematicRoute(nextScreen),
    );
  }

  void _skipToHome() {
    _openAfterSplash();
  }

  void _onPageChanged(int i) {
    setState(() {
      _page = i;
    });

    _armAutoplay();
  }

  void _next() {
    _onUserInteraction();

    if (_page == _slideCount - 1) {
      _openAfterSplash();
    } else {
      _pageController.nextPage(
        duration:
            const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  double _currentPageValue() {
    if (_pageController.hasClients &&
        _pageController.position.haveDimensions) {
      return _pageController.page ??
          _page.toDouble();
    }

    return _page.toDouble();
  }

  Widget _withPageTransform(
    int index,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final t = (index -
                _currentPageValue())
            .clamp(-1.0, 1.0);

        final absT = t.abs();
        final scale =
            1.0 - absT * 0.10;
        final opacity =
            (1.0 - absT).clamp(0.0, 1.0);
        final dy = t * 28;

        final blurSigma =
            absT > 0.03
                ? absT * 5
                : 0.0;

        Widget content = Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );

        if (blurSigma > 0) {
          content = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: content,
          );
        }

        return content;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size;

    final contentWidth =
        size.width > 520
            ? 480.0
            : size.width;

    final isLast =
        _page == _slideCount - 1;

    return Scaffold(
      backgroundColor:
          AppColors.splashBackground.first,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      AppColors.splashBackground,
                  begin:
                      Alignment.topCenter,
                  end:
                      Alignment.bottomCenter,
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

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(
                  maxWidth: contentWidth,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        AppTextStyles.fig(24),
                        AppTextStyles.fig(10),
                        AppTextStyles.fig(24),
                        0,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment:
                              Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo_full.png',
                              width:
                                  contentWidth *
                                      0.48,
                              fit:
                                  BoxFit.contain,
                            ),

                            if (!isLast)
                              Positioned(
                                top: 0,
                                right: 0,
                                child:
                                    SkipButton(
                                  onTap: () {
                                    _onUserInteraction();
                                    _skipToHome();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: Listener(
                        onPointerDown: (_) =>
                            _onUserInteraction(),
                        child: PageView(
                          controller:
                              _pageController,
                          onPageChanged:
                              _onPageChanged,
                          children: [
                            for (
                              var i = 0;
                              i < _slides.length;
                              i++
                            )
                              _withPageTransform(
                                i,
                                _ApplianceSlide(
                                  data: _slides[i],
                                  active:
                                      _page == i,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        AppTextStyles.fig(24),
                        0,
                        AppTextStyles.fig(24),
                        AppTextStyles.fig(20),
                      ),
                      child: Row(
                        children: [
                          DotIndicator(
                            count: _slideCount,
                            activeIndex: _page,
                          ),
                          const Spacer(),
                          PremiumCtaButton(
                            expanded: isLast,
                            onTap: _next,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One splash slide.
class _ApplianceSlide
    extends StatelessWidget {
  const _ApplianceSlide({
    required this.data,
    required this.active,
  });

  static const _artWidthFraction = 0.82;
  static const _titleLine1Size = 26.0;
  static const _titleLine2Size = 27.0;

  final _SlideData data;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final artWidth =
        MediaQuery.of(context).size.width *
            _artWidthFraction;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(
            horizontal:
                AppTextStyles.fig(24),
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(
              minHeight:
                  constraints.maxHeight,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.max,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                SizedBox(
                  height:
                      AppTextStyles.fig(10),
                ),

                CinematicHeading(
                  active: active,
                  lines: [
                    HeadlineLine(
                      data.titleLine1,
                      AppTextStyles.display(
                        figmaSize:
                            _titleLine1Size,
                        weight:
                            FontWeight.w700,
                        color:
                            AppColors.navy,
                      ),
                    ),
                    HeadlineLine(
                      data.titleLine2,
                      AppTextStyles.display(
                        figmaSize:
                            _titleLine2Size,
                        weight:
                            FontWeight.w700,
                        color:
                            AppColors.purple,
                        shadows: [
                          Shadow(
                            color: AppColors
                                .purple
                                .withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height:
                      AppTextStyles.fig(12),
                ),

                FadeSlideIn(
                  active: active,
                  delay:
                      const Duration(
                    milliseconds: 160,
                  ),
                  child: Text(
                    data.description,
                    textAlign:
                        TextAlign.center,
                    style:
                        AppTextStyles.of(
                      figmaSize: 14,
                      weight:
                          FontWeight.w400,
                      color:
                          AppColors.textGray,
                    ),
                  ),
                ),

                SizedBox(
                  height:
                      AppTextStyles.fig(22),
                ),

                AnimatedFeatureRow(
                  items: data.features,
                  active: active,
                ),

                SizedBox(
                  height:
                      AppTextStyles.fig(30),
                ),

                FadeSlideIn(
                  active: active,
                  delay:
                      const Duration(
                    milliseconds: 260,
                  ),
                  offset: 24,
                  child: FloatingProductArt(
                    assetPath:
                        data.assetPath,
                    width: artWidth,
                  ),
                ),

                SizedBox(
                  height:
                      AppTextStyles.fig(26),
                ),

                FadeSlideIn(
                  active: active,
                  delay:
                      const Duration(
                    milliseconds: 380,
                  ),
                  child: Text(
                    data.caption,
                    style:
                        AppTextStyles.display(
                      figmaSize: 18,
                      weight:
                          FontWeight.w700,
                      color:
                          AppColors.navy,
                    ),
                  ),
                ),

                SizedBox(
                  height:
                      AppTextStyles.fig(12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}