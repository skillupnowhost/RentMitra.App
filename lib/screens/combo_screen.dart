import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

class ComboScreen extends StatelessWidget {
  const ComboScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Combo Plans',

      description:
          'AC, refrigerator and washing machine bundled together — save 10% versus renting separately.',

      heroArt: const ApplianceClusterImage(width: 130),

      badgeFeatures: const [
        (Icons.local_shipping_outlined, 'Free\nDelivery'),
        (Icons.build_outlined, 'Free\nInstallation'),
        (Icons.verified_user_outlined, 'Service &\nMaintenance'),
        (Icons.percent, 'Save\n10%'),
      ],

      sectionTitle: 'Choose Your Combo',

      footerText:
          'All Combo Plans come with free delivery, free installation and maintenance & service included for every appliance.',

      options: [
        // ============================================================
        // ESSENTIAL COMBO
        // ============================================================
        ProductOptionCard(
          badge: 'Essential Combo',

          title: '1 Ton AC + Fridge + Washing Machine',

          checklist: const [
            '1 Ton Smart Inverter Split AC',
            'Single Door Refrigerator',
            'Top Load Washing Machine',
            'Free installation for all 3 appliances',
          ],

          art: const ApplianceClusterImage(width: 90),

          price: '₹1,887',

          badgeColor: AppColors.priceGreen,

          // ESSENTIAL COMBO → CHECKOUT
          onContinue: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CheckoutScreen(
                  product: CheckoutProduct.essentialCombo,
                ),
              ),
            );
          },
        ),

        // ============================================================
        // PREMIUM COMBO
        // ============================================================
        ProductOptionCard(
          badge: 'Premium Combo',

          title: '1.5 Ton AC + Fridge + Washing Machine',

          checklist: const [
            '1.5 Ton Smart Inverter Split AC',
            'Double Door Refrigerator',
            'Front Load Washing Machine',
            'Free installation for all 3 appliances',
          ],

          art: const ApplianceClusterImage(width: 90),

          price: '₹2,652',

          // PREMIUM COMBO → CHECKOUT
          onContinue: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CheckoutScreen(
                  product: CheckoutProduct.premiumCombo,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}