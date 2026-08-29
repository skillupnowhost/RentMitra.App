import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

const _washerFooterText =
    'All Washing Machines come with free delivery, free installation and maintenance & service included.';

class WashingMachineScreen extends StatelessWidget {
  const WashingMachineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Washing Machine',
      description: 'Powerful cleaning, better care and energy efficiency.',
      heroArt: const WasherTopLoadImage(width: 100),
      heroBlobImage: 'assets/images/Background shape.png',

      badgeFeatures: const [
        (Icons.eco_outlined, 'Energy\nEfficient'),
        (Icons.local_laundry_service_outlined, 'Powerful\nCleaning'),
        (Icons.volume_off, 'Low Noise\nOperation'),
        (Icons.shield_outlined, 'Long\nLasting'),
      ],

      sectionTitle: 'Choose Your Washing Machine',

      footerText: _washerFooterText,
      footerImage: 'assets/images/Washing machine install.png',

      options: [
        // ==========================================================
        // TOP LOAD WASHING MACHINE
        // ==========================================================

        ProductOptionCard(
          badge: 'Top Load',
          title: 'Top Load Washing Machine',

          checklist: const [
            'Powerful cleaning',
            'Large capacity',
            'Low water consumption',
            'Sturdy & durable design',
          ],

          art: const WasherTopLoadImage(width: 110),
          artColumnWidth: 145,

          price: '₹599',

          onContinue: () => context.push(
            '/product-details',
            extra: const Product(
              badge: 'Top Load',
              title: 'Top Load Washing Machine',
              description: 'Powerful cleaning, better care and energy efficiency.',
              checklist: [
                'Powerful cleaning',
                'Large capacity',
                'Low water consumption',
                'Sturdy & durable design',
              ],
              art: WasherTopLoadImage(width: 110),
              price: '₹599',
              checkoutProduct: CheckoutProduct.washingMachineTopLoad,
              specs: [
                ProductSpec(
                  icon: Icons.local_laundry_service_outlined,
                  label: 'Capacity',
                  value: '7 Kg',
                ),
                ProductSpec(
                  icon: Icons.speed,
                  label: 'Spin Speed',
                  value: '700 RPM',
                ),
              ],
              footerText: _washerFooterText,
            ),
          ),
        ),

        // ==========================================================
        // FRONT LOAD WASHING MACHINE
        // ==========================================================
        ProductOptionCard(
          badge: 'Front Load',
          title: 'Front Load Washing Machine',

          checklist: const [
            'Advanced fabric care',
            'High energy efficiency',
            'Low water consumption',
            'Sturdy & durable design',
          ],

          art: const WasherFrontLoadImage(width: 110),
          artColumnWidth: 145,

          price: '₹849',

          onContinue: () => context.push(
            '/product-details',
            extra: const Product(
              badge: 'Front Load',
              title: 'Front Load Washing Machine',
              description: 'Powerful cleaning, better care and energy efficiency.',
              checklist: [
                'Advanced fabric care',
                'High energy efficiency',
                'Low water consumption',
                'Sturdy & durable design',
              ],
              art: WasherFrontLoadImage(width: 110),
              price: '₹849',
              checkoutProduct: CheckoutProduct.washingMachineFrontLoad,
              specs: [
                ProductSpec(
                  icon: Icons.local_laundry_service_outlined,
                  label: 'Capacity',
                  value: '6 Kg',
                ),
                ProductSpec(
                  icon: Icons.speed,
                  label: 'Spin Speed',
                  value: '1000 RPM',
                ),
              ],
              footerText: _washerFooterText,
            ),
          ),
        ),
      ],
    );
  }
}
