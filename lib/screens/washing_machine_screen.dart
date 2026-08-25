import 'package:flutter/material.dart';

import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

class WashingMachineScreen extends StatelessWidget {
  const WashingMachineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Washing Machine',
      description:
          'Powerful cleaning and gentle care for your clothes, with programs for every fabric.',
      heroArt: const WasherProductImage(width: 84),

      badgeFeatures: const [
        (
          Icons.local_laundry_service_outlined,
          'Powerful\nCleaning',
        ),
        (
          Icons.bolt,
          'Energy\nEfficient',
        ),
        (
          Icons.volume_off,
          'Low Noise\nOperation',
        ),
        (
          Icons.shield_outlined,
          'Long\nLasting',
        ),
      ],

      sectionTitle: 'Choose Your Washing Machine',

      footerText:
          'All Washing Machines come with free delivery, free installation and maintenance & service included.',

      options: [
        // ==========================================================
        // TOP LOAD WASHING MACHINE
        // ==========================================================

        ProductOptionCard(
          badge: 'Top Load',
          title: 'Top Load Washing Machine',

          checklist: const [
            'Powerful cleaning',
            'Multiple wash programs',
            'Gentle on clothes',
            'Low power consumption',
          ],

          art: const WasherProductImage(
            width: 70,
          ),

          price: '₹599',

          onContinue: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const CheckoutScreen(
                  product:
                      CheckoutProduct
                          .washingMachineTopLoad,
                ),
              ),
            );
          },
        ),

        // ==========================================================
        // FRONT LOAD WASHING MACHINE
        // ==========================================================

        ProductOptionCard(
          badge: 'Front Load',
          title: 'Front Load Washing Machine',

          checklist: const [
            'Powerful cleaning',
            'Multiple wash programs',
            'Energy efficient',
            'Gentle on clothes',
          ],

          art: const WasherProductImage(
            width: 70,
          ),

          // Corrected price
          price: '₹899',

          onContinue: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const CheckoutScreen(
                  product:
                      CheckoutProduct
                          .washingMachineFrontLoad,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}