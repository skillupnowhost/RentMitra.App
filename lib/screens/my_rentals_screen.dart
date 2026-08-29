import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/help_card.dart';

/// The "My Rentals" bottom-nav tab — one of Home's hub destinations. Lists
/// orders placed via the Checkout → Payment flow ([OrderProvider]), which
/// is also how a rental placed through the flow becomes visible outside it.
class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width;
    final orders = context.watch<OrderProvider>().orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTextStyles.fig(16),
                    AppTextStyles.fig(16),
                    AppTextStyles.fig(16),
                    AppTextStyles.fig(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Rentals',
                      style: AppTextStyles.of(
                        figmaSize: 22,
                        weight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? _EmptyState(onBrowse: () => context.push('/catalog'))
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTextStyles.fig(16),
                          ),
                          itemCount: orders.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: AppTextStyles.fig(12)),
                          itemBuilder: (context, i) =>
                              _OrderTile(order: orders[i]),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTextStyles.fig(16),
                    AppTextStyles.fig(10),
                    AppTextStyles.fig(16),
                    AppTextStyles.fig(10),
                  ),
                  child: HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                ),
                AppBottomNavBar(
                  currentIndex: 1,
                  onTap: (i) {
                    if (i == 0) {
                      context.go('/home');
                    } else if (i == 2) {
                      context.go('/profile');
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTextStyles.fig(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: AppTextStyles.fig(56),
              color: AppColors.textGraySoft,
            ),
            SizedBox(height: AppTextStyles.fig(14)),
            Text(
              'No rentals yet',
              style: AppTextStyles.of(
                figmaSize: 16,
                weight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            SizedBox(height: AppTextStyles.fig(6)),
            Text(
              'Rent an AC, refrigerator or washing machine and it will show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w400,
                color: AppColors.textGray,
                height: 1.4,
              ),
            ),
            SizedBox(height: AppTextStyles.fig(18)),
            ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: AppTextStyles.fig(24),
                  vertical: AppTextStyles.fig(14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Browse Appliances',
                style: AppTextStyles.of(
                  figmaSize: 14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTextStyles.fig(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: AppTextStyles.fig(44),
            height: AppTextStyles.fig(44),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgCardPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          SizedBox(width: AppTextStyles.fig(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '${order.id} · ${order.paymentMethod}',
                  style: AppTextStyles.of(
                    figmaSize: 11,
                    weight: FontWeight.w400,
                    color: AppColors.textGraySoft,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.amount}',
            style: AppTextStyles.of(
              figmaSize: 15,
              weight: FontWeight.w700,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
