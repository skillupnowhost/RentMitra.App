import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/help_card.dart';

/// The end of the funnel: Payment success → here → Back to Home. Reached
/// via `context.go('/order-success', ...)`, which replaces the whole
/// checkout/payment history, so a raw back gesture is blocked ([PopScope])
/// and routed through the same "Back to Home" action instead of exiting
/// the flow into an empty stack.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppTextStyles.fig(24)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                            width: AppTextStyles.fig(96),
                            height: AppTextStyles.fig(96),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.bgCardPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.purple,
                              size: AppTextStyles.fig(56),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            duration: 420.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 300.ms),
                      SizedBox(height: AppTextStyles.fig(24)),
                      Text(
                        'Order Placed!',
                        style: AppTextStyles.of(
                          figmaSize: 24,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(10)),
                      Text(
                        'Your rental for ${order.productName} is confirmed. '
                        'Our team will reach out to schedule delivery and '
                        'installation.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.of(
                          figmaSize: 13,
                          weight: FontWeight.w400,
                          color: AppColors.textGray,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(28)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppTextStyles.fig(18)),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(label: 'Order ID', value: order.id),
                            SizedBox(height: AppTextStyles.fig(10)),
                            _SummaryRow(
                              label: 'Product',
                              value: order.productName,
                            ),
                            SizedBox(height: AppTextStyles.fig(10)),
                            _SummaryRow(
                              label: 'Payment Method',
                              value: order.paymentMethod,
                            ),
                            SizedBox(height: AppTextStyles.fig(10)),
                            Divider(height: 1, color: AppColors.divider),
                            SizedBox(height: AppTextStyles.fig(10)),
                            _SummaryRow(
                              label: 'Amount Paid',
                              value: '₹${order.amount}',
                              emphasize: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(28)),
                      SizedBox(
                        width: double.infinity,
                        height: AppTextStyles.fig(52),
                        child: ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ctaPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Back to Home',
                            style: AppTextStyles.of(
                              figmaSize: 15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(12)),
                      TextButton(
                        onPressed: () => context.go('/my-rentals'),
                        child: Text(
                          'View My Rentals',
                          style: AppTextStyles.of(
                            figmaSize: 14,
                            weight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                      SizedBox(height: AppTextStyles.fig(28)),
                      HelpCard(onWhatsApp: launchSupportWhatsAppChat),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.of(
            figmaSize: 12,
            weight: FontWeight.w400,
            color: AppColors.textGraySoft,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: emphasize ? 16 : 13,
              weight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: emphasize ? AppColors.purple : AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}
