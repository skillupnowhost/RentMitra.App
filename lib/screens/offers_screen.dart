import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/pricing_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/rent_pricing.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/help_card.dart';
import '../widgets/promo_banner.dart';
import 'combo_screen.dart' show buildComboOptionCards, lowestComboRent;

/// The drawer's "Offers" destination — the [PromoBanner] (the combo-discount
/// banner already shown on Home) as a lead-in, followed by every combo offer
/// from [buildComboOptionCards] (the same cards [ComboScreen] lists) so all
/// current offers are visible here, not just the one generic banner.
/// Drawer-only, no bottom nav, matching [ProductsCatalogScreen]'s existing
/// precedent for non-hub destinations.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

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
                        PromoBanner(
                          onViewCombos: () => context.push('/combo'),
                          startingPrice: _comboStartingPrice(context),
                        ),
                        SizedBox(height: AppTextStyles.fig(20)),
                        Text(
                          'Combo Plan Offers',
                          style: AppTextStyles.of(
                            figmaSize: 18,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(4)),
                        Text(
                          'Bundle appliances together and save on every plan.',
                          style: AppTextStyles.of(
                            figmaSize: 13,
                            weight: FontWeight.w400,
                            color: AppColors.textGraySoft,
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(14)),
                        for (final card in buildComboOptionCards(context)) ...[
                          card,
                          SizedBox(height: AppTextStyles.fig(14)),
                        ],
                        Text(
                          'More offers coming soon',
                          style: AppTextStyles.of(
                            figmaSize: 13,
                            weight: FontWeight.w400,
                            color: AppColors.textGraySoft,
                          ),
                        ),
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

  String? _comboStartingPrice(BuildContext context) {
    final pricing = context.watch<PricingProvider>();
    final rent = lowestComboRent(pricing);
    return rent == null ? null : formatRupees(rent);
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          ),
          Text(
            'Offers',
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
}
