import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/help_card.dart';

/// The "Profile" bottom-nav tab. Scoped as an honest placeholder — real
/// account/profile management is out of scope for this navigation-flow
/// refactor — but wired into the hub so the tab isn't a dead end.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppTextStyles.fig(20)),
                    child: Column(
                      children: [
                        SizedBox(height: AppTextStyles.fig(24)),
                        Container(
                          width: AppTextStyles.fig(84),
                          height: AppTextStyles.fig(84),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.bgCardPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppColors.purple,
                            size: AppTextStyles.fig(44),
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(14)),
                        Text(
                          'Guest User',
                          style: AppTextStyles.of(
                            figmaSize: 18,
                            weight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(4)),
                        Text(
                          'Sign in to manage your account, addresses and rentals.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.of(
                            figmaSize: 12,
                            weight: FontWeight.w400,
                            color: AppColors.textGray,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: AppTextStyles.fig(28)),
                        _ProfileRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'My Rentals',
                          onTap: () => context.go('/my-rentals'),
                        ),
                        _ProfileRow(
                          icon: Icons.local_offer_outlined,
                          label: 'Offers',
                          onTap: () => context.push('/offers'),
                        ),
                        _ProfileRow(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () => context.push('/settings'),
                        ),
                        SizedBox(height: AppTextStyles.fig(10)),
                        HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                      ],
                    ),
                  ),
                ),
                AppBottomNavBar(
                  currentIndex: 2,
                  onTap: (i) {
                    if (i == 0) {
                      context.go('/home');
                    } else if (i == 1) {
                      context.go('/my-rentals');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTextStyles.fig(10)),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTextStyles.fig(14),
              vertical: AppTextStyles.fig(14),
            ),
            decoration: BoxDecoration(
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
                  color: AppColors.textGraySoft.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
