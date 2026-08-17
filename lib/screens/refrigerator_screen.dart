import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'product_listing_screen.dart';

class RefrigeratorScreen extends StatelessWidget {
  const RefrigeratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Refrigerator',
      description: 'Keep your food fresh for longer with reliable performance and efficient cooling.',
      heroArt: const FridgeProductImage(width: 70),
      badgeFeatures: const [
        (Icons.eco_outlined, 'Energy\nEfficient'),
        (Icons.ac_unit, 'Powerful\nCooling'),
        (Icons.volume_off, 'Low Noise\nOperation'),
        (Icons.shield_outlined, 'Long\nLasting'),
      ],
      sectionTitle: 'Choose Your Refrigerator',
      footerText: 'All Refrigerators come with free delivery, free installation and maintenance & service included.',
      options: [
        ProductOptionCard(
          badge: 'Single Door',
          title: 'Single Door Refrigerator',
          checklist: const [
            'Efficient cooling',
            'Spacious storage',
            'Low power consumption',
            'Sturdy & durable design',
          ],
          art: const FridgeProductImage(width: 70),
          price: '₹499',
          onContinue: () => _selected(context, 'Single Door Refrigerator'),
        ),
        ProductOptionCard(
          badge: 'Double Door',
          title: 'Double Door Refrigerator',
          checklist: const [
            'Powerful cooling',
            'Large storage capacity',
            'Low power consumption',
            'Sturdy & durable design',
          ],
          art: const FridgeProductImage(width: 70),
          price: '₹749',
          onContinue: () => _selected(context, 'Double Door Refrigerator'),
        ),
      ],
    );
  }

  void _selected(BuildContext context, String plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $plan'),
        backgroundColor: AppColors.ctaPurple,
      ),
    );
  }
}
