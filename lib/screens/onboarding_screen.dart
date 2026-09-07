import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/appliance_art.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/feature_item.dart';
import '../widgets/logo_mark.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slideCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _next() {
    if (_page == _slideCount - 1) {
      _goHome();
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
                        AppTextStyles.fig(12),
                        AppTextStyles.fig(24),
                        0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isLast)
                            GestureDetector(
                              onTap: _goHome,
                              child: Text(
                                'Skip',
                                style: AppTextStyles.of(
                                  figmaSize: 15,
                                  weight: FontWeight.w600,
                                  color: AppColors.textGrayMed,
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
                          _SlideOne(),
                          _SlideTwo(),
                          _SlideThree(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTextStyles.fig(24),
                        0,
                        AppTextStyles.fig(24),
                        AppTextStyles.fig(28),
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
                                          'Get Started',
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

class _SlideOne extends StatelessWidget {
  const _SlideOne();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppTextStyles.fig(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppTextStyles.fig(16)),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: BrandWordmark(figmaWidth: 700),
          ),
          SizedBox(height: AppTextStyles.fig(40)),
          FeatureRow(
            items: [
              const FeatureItem(
                icon: Icons.local_shipping_outlined,
                label: 'Free\nDelivery',
                figmaLabelSize: 13,
              ),
              FeatureItem(
                icon: Icons.build_outlined,
                label: 'Free\nInstallation',
                figmaLabelSize: 13,
                labelWeight: FontWeight.w400,
              ),
              const FeatureItem(
                icon: Icons.verified_user_outlined,
                label: 'Service &\nMaintenance',
                figmaLabelSize: 12,
              ),
            ],
          ),
          SizedBox(height: AppTextStyles.fig(44)),
          ApplianceClusterImage(
            width: MediaQuery.of(context).size.width * 0.55,
          ),
          SizedBox(height: AppTextStyles.fig(36)),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Rent Smart.\n',
                  style: AppTextStyles.of(
                    figmaSize: 30,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: 'Live Easy.',
                  style: AppTextStyles.of(
                    figmaSize: 31,
                    weight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTextStyles.fig(14)),
          Text(
            'Premium appliances on rent at affordable prices.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideTwo extends StatelessWidget {
  const _SlideTwo();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppTextStyles.fig(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppTextStyles.fig(48)),
          ApplianceClusterImage(width: MediaQuery.of(context).size.width * 0.6),
          SizedBox(height: AppTextStyles.fig(40)),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Quality Appliances.\n',
                  style: AppTextStyles.of(
                    figmaSize: 27,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: 'Flexible Rentals.',
                  style: AppTextStyles.of(
                    figmaSize: 28,
                    weight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTextStyles.fig(14)),
          Text(
            'Choose your appliance, select your plan and enjoy hassle-free service.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
          SizedBox(height: AppTextStyles.fig(36)),
          FeatureRow(
            items: [
              const FeatureItem(
                icon: Icons.touch_app_outlined,
                label: 'Easy\nBooking',
                figmaLabelSize: 13,
              ),
              FeatureItem(
                icon: Icons.savings_outlined,
                label: 'Affordable\nPlans',
                figmaLabelSize: 12,
                labelWeight: FontWeight.w400,
              ),
              const FeatureItem(
                icon: Icons.local_shipping_outlined,
                label: 'Quick\nDelivery',
                figmaLabelSize: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideThree extends StatelessWidget {
  const _SlideThree();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppTextStyles.fig(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppTextStyles.fig(60)),
          ApplianceClusterImage(width: MediaQuery.of(context).size.width * 0.6),
          SizedBox(height: AppTextStyles.fig(44)),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Your Home. Your Comfort.\n',
                  style: AppTextStyles.of(
                    figmaSize: 24,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: 'Our Responsibility.',
                  style: AppTextStyles.of(
                    figmaSize: 25,
                    weight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTextStyles.fig(14)),
          Text(
            'Get premium appliances delivered to your doorstep.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}
