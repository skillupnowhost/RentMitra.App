import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/appliance_art.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/feature_item.dart';
import '../widgets/feature_strip.dart';
import '../widgets/help_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/location_selector.dart';
import '../widgets/logo_mark.dart';
import '../widgets/product_detail_card.dart';
import '../widgets/promo_banner.dart';
import 'ac_screen.dart';
import 'combo_screen.dart';
import 'my_rentals_screen.dart';
import 'refrigerator_screen.dart';
import 'washing_machine_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    LocationController.instance.autoDetectOnce();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                Expanded(child: _buildCurrentPage()),

                // ------------------------------------------------
                // BOTTOM NAVIGATION
                // ------------------------------------------------
                AppBottomNavBar(
                  currentIndex: _navIndex,
                  onTap: _onBottomNavTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavTap(int index) {
    if (index == _navIndex) {
      return;
    }

    setState(() {
      _navIndex = index;
    });
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_navIndex) {
      case 1:
        return const MyRentalsScreen();

      case 2:
        return const ProfileScreen();

      case 0:
      default:
        return _buildHomePage();
    }
  }

  // ============================================================
  // HOME PAGE
  // ============================================================

  Widget _buildHomePage() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppTextStyles.fig(16),
              AppTextStyles.fig(12),
              AppTextStyles.fig(16),
              AppTextStyles.fig(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroBanner(),

                SizedBox(height: AppTextStyles.fig(24)),

                _sectionCategoryGrid(),

                SizedBox(height: AppTextStyles.fig(20)),

                PromoBanner(
                  onViewCombos: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ComboScreen()),
                  ),
                ),

                SizedBox(height: AppTextStyles.fig(24)),

                ProductDetailCard(
                  title: 'Smart Inverter\nSplit AC',
                  titleColor: AppColors.titleBlue,
                  checklist: const [
                    'Powerful cooling',
                    'Low power consumption',
                    'Smart Plug Included',
                  ],
                  options: const ['1 Ton', '1.5 Ton'],
                  art: const AcProductImage(width: 100),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AcScreen())),
                ),

                SizedBox(height: AppTextStyles.fig(16)),

                ProductDetailCard(
                  title: 'Refrigerator',
                  titleColor: AppColors.titleGreen,
                  checklist: const [
                    'Freshness that lasts longer',
                    'Energy efficient',
                    'Spacious storage',
                  ],
                  options: const ['Single Door', 'Double Door'],
                  art: const FridgeProductImage(width: 55),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RefrigeratorScreen(),
                    ),
                  ),
                ),

                SizedBox(height: AppTextStyles.fig(16)),

                ProductDetailCard(
                  title: 'Washing Machine',
                  titleColor: AppColors.titleTerracotta,
                  checklist: const [
                    'Powerful cleaning',
                    'Multiple wash programs',
                    'Gentle on clothes',
                  ],
                  options: const ['Top Load', 'Front Load'],
                  art: const WasherProductImage(width: 68),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WashingMachineScreen(),
                    ),
                  ),
                ),

                SizedBox(height: AppTextStyles.fig(24)),

                const FeatureStrip(),

                SizedBox(height: AppTextStyles.fig(18)),

                HelpCard(onWhatsApp: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HOME APP BAR
  // ============================================================

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTextStyles.fig(16),
        AppTextStyles.fig(14),
        AppTextStyles.fig(16),
        AppTextStyles.fig(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: AppColors.navy, size: 24),

          SizedBox(width: AppTextStyles.fig(14)),

          LogoMark(width: AppTextStyles.fig(48)),

          SizedBox(width: AppTextStyles.fig(6)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rent',
                        style: AppTextStyles.of(
                          figmaSize: 27,
                          weight: FontWeight.w700,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      Text(
                        'Mitra',
                        style: AppTextStyles.of(
                          figmaSize: 27,
                          weight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  'RENT MADE EASY',
                  style: AppTextStyles.of(
                    figmaSize: 10,
                    weight: FontWeight.w400,
                    color: AppColors.textGraySoft,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: AppTextStyles.fig(8)),

          ValueListenableBuilder<String>(
            valueListenable: LocationController.instance.city,
            builder: (context, city, _) {
              return ValueListenableBuilder<LocationStatus>(
                valueListenable: LocationController.instance.status,
                builder: (context, status, _) {
                  return LocationSelector(
                    city: city,
                    status: status,
                    onTap: () => LocationPickerSheet.show(context),
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
  // CATEGORY GRID
  // ============================================================

  Widget _sectionCategoryGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CategoryCard(
            icon: Icons.ac_unit,
            title: 'Smart Inverter Split AC',
            price: '₹999',
            iconColor: AppColors.pricePurple,
            priceColor: AppColors.pricePurple,
            bgColor: AppColors.bgCardPurple,
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const AcScreen())),
          ),
        ),

        SizedBox(width: AppTextStyles.fig(8)),

        Expanded(
          child: CategoryCard(
            icon: Icons.kitchen_outlined,
            title: 'Refrigerator',
            price: '₹499',
            iconColor: AppColors.priceGreen,
            priceColor: AppColors.priceGreen,
            bgColor: AppColors.bgCardNeutral,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RefrigeratorScreen()),
            ),
          ),
        ),

        SizedBox(width: AppTextStyles.fig(8)),

        Expanded(
          child: CategoryCard(
            icon: Icons.local_laundry_service_outlined,
            title: 'Washing Machine',
            price: '₹599',
            iconColor: AppColors.priceOrange,
            priceColor: AppColors.priceOrange,
            bgColor: AppColors.bgCardPeach,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WashingMachineScreen()),
            ),
          ),
        ),

        SizedBox(width: AppTextStyles.fig(8)),

        Expanded(
          child: CategoryCard(
            icon: Icons.dashboard_customize_outlined,
            title: 'Combo Plans',
            price: '₹1,887',
            iconColor: AppColors.pricePurple,
            priceColor: AppColors.pricePurple,
            bgColor: AppColors.bgCardLavender,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ComboScreen())),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// HERO BANNER
// ================================================================

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroBanner,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTextStyles.fig(14),
                        vertical: AppTextStyles.fig(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SMART RENTING, BETTER LIVING',
                        style: AppTextStyles.of(
                          figmaSize: 9,
                          weight: FontWeight.w600,
                          color: AppColors.purpleSoft,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    SizedBox(height: AppTextStyles.fig(14)),

                    RichText(
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
                              figmaSize: 34,
                              weight: FontWeight.w700,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppTextStyles.fig(12)),

                    Text(
                      'Premium Appliances on Rent\n'
                      'at affordable prices.',
                      style: AppTextStyles.of(
                        figmaSize: 13,
                        weight: FontWeight.w400,
                        color: AppColors.textGray,
                      ),
                    ),

                    SizedBox(height: AppTextStyles.fig(14)),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTextStyles.fig(12),
                        vertical: AppTextStyles.fig(8),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'AC · Refrigerator · Washing Machine · Combo Plans',
                        style: AppTextStyles.of(
                          figmaSize: 9,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: AppTextStyles.fig(8)),

              ApplianceClusterImage(width: AppTextStyles.fig(120)),
            ],
          ),

          SizedBox(height: AppTextStyles.fig(18)),

          Row(
            children: [
              Expanded(
                child: FeatureItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Free\nDelivery',
                  figmaLabelSize: 10,
                  badgeSize: AppTextStyles.fig(40),
                  iconSize: 16,
                ),
              ),

              Expanded(
                child: FeatureItem(
                  icon: Icons.build_outlined,
                  label: 'Free\nInstallation',
                  figmaLabelSize: 10,
                  labelWeight: FontWeight.w400,
                  badgeSize: AppTextStyles.fig(40),
                  iconSize: 16,
                ),
              ),

              Expanded(
                child: FeatureItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Service &\nMaintenance',
                  figmaLabelSize: 10,
                  badgeSize: AppTextStyles.fig(40),
                  iconSize: 16,
                ),
              ),
            ],
          ),

          SizedBox(height: AppTextStyles.fig(14)),

          const Center(child: DotIndicator(count: 4, activeIndex: 0)),
        ],
      ),
    );
  }
}
