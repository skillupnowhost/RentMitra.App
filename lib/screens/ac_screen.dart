import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'product_listing_screen.dart';

class AcScreen extends StatelessWidget {
  const AcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Smart Inverter Split AC',
      description: 'Experience powerful cooling, energy efficiency and smart performance.',
      heroArt: const AcProductImage(width: 110),
      badgeFeatures: const [
        (Icons.bolt, 'Energy\nEfficient'),
        (Icons.ac_unit, 'Powerful\nCooling'),
        (Icons.volume_off, 'Low Noise\nOperation'),
        (Icons.shield_outlined, 'Smart\nPerformance'),
      ],
      sectionTitle: 'Choose Your AC',
      footerText: 'All ACs come with free delivery, free installation and maintenance & service included.',
      options: [
        ProductOptionCard(
          badge: '1 Ton',
          title: 'Smart Inverter Split AC',
          checklist: const [
            'Powerful cooling',
            'Low power consumption',
            'Smart performance',
            'Smart Plug included',
          ],
          art: const AcProductImage(width: 90),
          price: '₹999',
          specs: const [
            ProductSpec(
              icon: Icons.ac_unit,
              label: 'Cooling Capacity',
              value: '1 Ton',
            ),
            ProductSpec(
              icon: Icons.bolt,
              label: 'Power Consumption',
              value: 'Low',
            ),
          ],
          onContinue: () => _selected(context, '1 Ton Smart Inverter Split AC'),
        ),
        ProductOptionCard(
          badge: '1.5 Ton',
          title: 'Smart Inverter Split AC',
          checklist: const [
            'Powerful cooling',
            'Low power consumption',
            'Smart performance',
            'Smart Plug included',
          ],
          art: const AcProductImage(width: 90),
          price: '₹1,299',
          specs: const [
            ProductSpec(
              icon: Icons.ac_unit,
              label: 'Cooling Capacity',
              value: '1.5 Ton',
            ),
            ProductSpec(
              icon: Icons.bolt,
              label: 'Power Consumption',
              value: 'Low',
            ),
          ],
          onContinue: () =>
              _selected(context, '1.5 Ton Smart Inverter Split AC'),
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
