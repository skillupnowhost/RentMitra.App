import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/help_card.dart';

/// The drawer's "Settings" destination. Honestly-scoped placeholder — a
/// few static rows, no real functionality — since implementing settings is
/// out of scope for this navigation-architecture task; wired in so the
/// drawer item isn't a dead end.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _rows = [
    (Icons.notifications_outlined, 'Notifications'),
    (Icons.lock_outline, 'Privacy & Security'),
    (Icons.language_outlined, 'Language'),
    (Icons.info_outline, 'About RentMitra'),
  ];

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
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTextStyles.fig(16),
                    ),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppTextStyles.fig(10)),
                    itemBuilder: (context, i) {
                      final (icon, label) = _rows[i];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTextStyles.fig(14),
                          vertical: AppTextStyles.fig(14),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: AppColors.purple),
                            SizedBox(width: AppTextStyles.fig(12)),
                            Expanded(
                              child: Text(
                                label,
                                style: AppTextStyles.of(
                                  figmaSize: 14,
                                  weight: FontWeight.w600,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.textGraySoft.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTextStyles.fig(16),
                    AppTextStyles.fig(10),
                    AppTextStyles.fig(16),
                    0,
                  ),
                  child: HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                ),
                SizedBox(height: AppTextStyles.fig(16)),
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
            'Settings',
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
