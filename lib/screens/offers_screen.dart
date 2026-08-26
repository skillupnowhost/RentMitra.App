import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/help_card.dart';
import '../widgets/promo_banner.dart';

/// The drawer's "Offers" destination — reuses the existing [PromoBanner]
/// (the combo-discount banner already shown on Home) rather than
/// duplicating its copy/art, plus a short note that more offers are on the
/// way. Drawer-only, no bottom nav, matching [ProductsCatalogScreen]'s
/// existing precedent for non-hub destinations.
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
                        ),
                        SizedBox(height: AppTextStyles.fig(20)),
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
