import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/feature_item.dart';
import '../widgets/logo_mark.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Per-appliance splash carousel — AC / Washing Machine / Refrigerator,
/// each with its own headline, feature badges, product shot and tagline
/// (matches the "RentMitra.app" marketing slide set). Swipeable, slider
/// mode, additive: sits between [SplashScreen]'s brand splash and the
/// existing [OnboardingScreen] without changing either.
class SplashSliderScreen extends StatefulWidget {
  const SplashSliderScreen({super.key});

  @override
  State<SplashSliderScreen> createState() => _SplashSliderScreenState();
}

class _SplashSliderScreenState extends State<SplashSliderScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slideCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _skipToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _next() {
    if (_page == _slideCount - 1) {
      _goToOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > 520 ? 480.0 : size.width;
    final isLast = _page == _slideCount - 1;

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
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTextStyles.fig(24),
                        AppTextStyles.fig(10),
                        AppTextStyles.fig(24),
                        0,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: BrandWordmark(
                              figmaWordmarkSize: 40,
                              figmaLogoWidth: 100,
                            ),
                          ),
                          if (!isLast)
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _skipToHome,
                                child: Text(
                                  'Skip',
                                  style: AppTextStyles.of(
                                    figmaSize: 14,
                                    weight: FontWeight.w600,
                                    color: AppColors.textGrayMed,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: const [
                          _ApplianceSlide(
                            titleLine1: 'Rental AC —',
                            titleLine2: 'Cool Comfort, On Your Terms',
                            description:
                                'Rent premium air conditioners with hassle-free installation and maintenance.',
                            features: [
                              FeatureItem(
                                icon: Icons.ac_unit,
                                label: 'Fast\nCooling',
                                figmaLabelSize: 13,
                              ),
                              FeatureItem(
                                icon: Icons.build_outlined,
                                label: 'Free\nInstallation',
                                figmaLabelSize: 13,
                                labelWeight: FontWeight.w400,
                              ),
                              FeatureItem(
                                icon: Icons.verified_user_outlined,
                                label: 'Service &\nMaintenance',
                                figmaLabelSize: 12,
                              ),
                            ],
                            assetPath: 'assets/images/ac_product.png',
                            caption: 'Stay Cool, Save More',
                          ),
                          _ApplianceSlide(
                            titleLine1: 'Rental Washing Machine —',
                            titleLine2: 'Laundry Made Effortless',
                            description:
                                'Get fully automatic washing machines on rent with free delivery and setup.',
                            features: [
                              FeatureItem(
                                icon: Icons.local_shipping_outlined,
                                label: 'Free\nDelivery',
                                figmaLabelSize: 13,
                              ),
                              FeatureItem(
                                icon: Icons.settings_outlined,
                                label: 'Easy\nInstallation',
                                figmaLabelSize: 13,
                                labelWeight: FontWeight.w400,
                              ),
                              FeatureItem(
                                icon: Icons.shopping_basket_outlined,
                                label: 'Premium\nMachines',
                                figmaLabelSize: 12,
                              ),
                            ],
                            assetPath: 'assets/images/washer_product.png',
                            caption: 'Fresh Clothes, Zero Hassle',
                          ),
                          _ApplianceSlide(
                            titleLine1: 'Rental Refrigerator —',
                            titleLine2: 'Freshness That Lasts',
                            description:
                                'Rent energy-efficient refrigerators for every home and lifestyle.',
                            features: [
                              FeatureItem(
                                icon: Icons.eco_outlined,
                                label: 'Fresh Food\nStorage',
                                figmaLabelSize: 12,
                              ),
                              FeatureItem(
                                icon: Icons.bolt,
                                label: 'Energy\nEfficient',
                                figmaLabelSize: 13,
                                labelWeight: FontWeight.w400,
                              ),
                              FeatureItem(
                                icon: Icons.handyman_outlined,
                                label: 'Free Service\nSupport',
                                figmaLabelSize: 12,
                              ),
                            ],
                            assetPath: 'assets/images/fridge_product.png',
                            caption: 'Keep It Fresh, Every Day',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTextStyles.fig(24),
                        0,
                        AppTextStyles.fig(24),
                        AppTextStyles.fig(24),
                      ),
                      child: Row(
                        children: [
                          DotIndicator(count: _slideCount, activeIndex: _page),
                          const Spacer(),
                          GestureDetector(
                            onTap: _next,
                            child: Container(
                              padding: isLast
                                  ? EdgeInsets.symmetric(
                                      horizontal: AppTextStyles.fig(26),
                                      vertical: AppTextStyles.fig(14),
                                    )
                                  : EdgeInsets.all(AppTextStyles.fig(14)),
                              decoration: BoxDecoration(
                                color: AppColors.ctaPurple,
                                borderRadius: BorderRadius.circular(
                                  isLast ? 10 : 30,
                                ),
                              ),
                              child: isLast
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Next',
                                          style: AppTextStyles.of(
                                            figmaSize: 15,
                                            weight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: AppTextStyles.fig(8)),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    )
                                  : const Icon(
                                      Icons.arrow_forward,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                            ),
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

/// One appliance highlight slide: two-tone headline, description, feature
/// badge row, product photo on a spotlight pedestal, and a bold caption.
class _ApplianceSlide extends StatelessWidget {
  const _ApplianceSlide({
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
  final List<FeatureItem> features;
  final String assetPath;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final pedestalWidth = MediaQuery.of(context).size.width * 0.56;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppTextStyles.fig(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppTextStyles.fig(14)),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$titleLine1\n',
                  style: AppTextStyles.of(
                    figmaSize: 23,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: titleLine2,
                  style: AppTextStyles.of(
                    figmaSize: 24,
                    weight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTextStyles.fig(12)),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
          SizedBox(height: AppTextStyles.fig(22)),
          FeatureRow(items: features),
          SizedBox(height: AppTextStyles.fig(32)),
          _Pedestal(assetPath: assetPath, width: pedestalWidth),
          SizedBox(height: AppTextStyles.fig(28)),
          Text(
            caption,
            style: AppTextStyles.of(
              figmaSize: 17,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: AppTextStyles.fig(12)),
        ],
      ),
    );
  }
}

/// Product photo framed in a soft card and lifted on a light purple
/// "spotlight" pedestal — stands in for the podium/glow treatment in the
/// reference art, built from the existing product photography instead of
/// new transparent cutouts.
class _Pedestal extends StatelessWidget {
  const _Pedestal({required this.assetPath, required this.width});

  final String assetPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cardHeight = width * 0.85;

    return SizedBox(
      width: width * 1.18,
      height: cardHeight + width * 0.12,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: width * 1.15,
            height: width * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withValues(alpha: 0.20),
                  AppColors.purple.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Positioned(
            bottom: width * 0.06,
            child: Container(
              width: width,
              height: cardHeight,
              padding: EdgeInsets.all(AppTextStyles.fig(14)),
              decoration: BoxDecoration(
                color: AppColors.bgCardPurple,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
