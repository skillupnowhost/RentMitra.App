import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/appliance_art.dart';
import '../widgets/appliance_showcase_card.dart';
import '../widgets/category_card.dart';
import '../widgets/help_card.dart';

/// The full product catalog opened from the hamburger menu's "Products"
/// item — the same category grid and appliance showcase cards shown on the
/// home screen, on their own dedicated page.
class ProductsCatalogScreen extends StatelessWidget {
  const ProductsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppTextStyles.fig(16),
                      0,
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _categoryGrid(context),
                        SizedBox(height: AppTextStyles.fig(24)),
                        Text(
                          'All Appliances',
                          style: AppTextStyles.of(
                            figmaSize: 20,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(14)),
                        _showcaseCards(context),
                        SizedBox(height: AppTextStyles.fig(20)),
                        HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          ),
          Text(
            'All Products',
            style: AppTextStyles.of(
              figmaSize: 24,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CategoryCard(
              iconAsset: 'assets/images/air-conditioner icon.png',
              title: 'Smart Inverter Split AC',
              price: '₹999',
              iconColor: AppColors.categoryBlue,
              priceColor: AppColors.categoryBlue,
              bgColor: AppColors.bgCardPurple,
              iconAnimationDelay: const Duration(milliseconds: 0),
              onTap: () => context.push('/ac'),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: CategoryCard(
              iconAsset: 'assets/images/fridge icon.png',
              title: 'Refrigerator',
              price: '₹499',
              iconColor: AppColors.categoryGreen,
              priceColor: AppColors.categoryGreen,
              bgColor: AppColors.bgCardNeutral,
              iconAnimationDelay: const Duration(milliseconds: 150),
              onTap: () => context.push('/refrigerator'),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: CategoryCard(
              iconAsset: 'assets/images/washing-machine icon.png',
              title: 'Washing Machine',
              price: '₹599',
              iconColor: AppColors.categoryOrange,
              priceColor: AppColors.categoryOrange,
              bgColor: AppColors.bgCardPeach,
              iconAnimationDelay: const Duration(milliseconds: 300),
              onTap: () => context.push('/washing-machine'),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: CategoryCard(
              iconWidget: const ComboIconRow(color: Colors.white),
              title: 'Combo Plans',
              price: '₹1,887',
              iconColor: AppColors.pricePurple,
              priceColor: AppColors.pricePurple,
              bgColor: AppColors.bgCardLavender,
              gradientColors: const [
                AppColors.comboBlueDeep,
                AppColors.comboBlueBright,
              ],
              badgeText: 'Best Value',
              iconAnimationDelay: const Duration(milliseconds: 450),
              onTap: () => context.push('/combo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _showcaseCards(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ApplianceShowcaseCard(
            title: 'Smart Inverter\nSplit AC',
            titleColor: AppColors.titleBlue,
            checklist: const [
              'Powerful cooling',
              'Low power consumption',
              'Smart Plug Included',
            ],
            images: const [
              AcProductImage(width: 130),
              AcProductImage(width: 130),
            ],
            tabs: const ['1 Ton', '1.5 Ton'],
            tabIcon: Icons.ac_unit,
            onTap: () => context.push('/ac'),
          ),
        ),
        SizedBox(width: AppTextStyles.fig(8)),
        Expanded(
          child: ApplianceShowcaseCard(
            title: 'Refrigerator',
            titleColor: AppColors.titleGreen,
            checklist: const [
              'Freshness that lasts longer.',
              'Energy efficient',
              'Spacious storage',
            ],
            images: const [
              FridgeSingleDoorProductImage(width: 105),
              FridgeDoubleDoorProductImage(width: 105),
            ],
            tabs: const ['Single Door', 'Double Door'],
            onTap: () => context.push('/refrigerator'),
          ),
        ),
        SizedBox(width: AppTextStyles.fig(8)),
        Expanded(
          child: ApplianceShowcaseCard(
            title: 'Washing Machine',
            titleColor: AppColors.titleTerracotta,
            checklist: const [
              'Powerful cleaning',
              'Multiple wash programs',
              'Gentle on clothes',
            ],
            images: const [
              WasherTopLoadProductImage(width: 112, height: 106),
              WasherProductImage(width: 112, height: 106),
            ],
            tabs: const ['Top Load', 'Front Load'],
            onTap: () => context.push('/washing-machine'),
          ),
        ),
      ],
    );
  }
}
