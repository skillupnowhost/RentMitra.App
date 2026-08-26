import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

const _refrigeratorFooterText =
    'All Refrigerators come with free delivery, free installation and maintenance & service included.';

class RefrigeratorScreen extends StatelessWidget {
  const RefrigeratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Refrigerator',
      description:
          'Keep your food fresh for longer with reliable performance and efficient cooling.',

      heroArt: const FridgeProductImage(width: 70),

      badgeFeatures: const [
        (Icons.eco_outlined, 'Energy\nEfficient'),
        (Icons.ac_unit, 'Powerful\nCooling'),
        (Icons.volume_off, 'Low Noise\nOperation'),
        (Icons.shield_outlined, 'Long\nLasting'),
      ],

      sectionTitle: 'Choose Your Refrigerator',

      footerText: _refrigeratorFooterText,

      options: [
        // ============================================================
        // SINGLE DOOR REFRIGERATOR
        // ============================================================
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

          // SINGLE DOOR → PRODUCT DETAILS
          onContinue: () => context.push(
            '/product-details',
            extra: const Product(
              badge: 'Single Door',
              title: 'Single Door Refrigerator',
              description:
                  'Keep your food fresh for longer with reliable performance and efficient cooling.',
              checklist: [
                'Efficient cooling',
                'Spacious storage',
                'Low power consumption',
                'Sturdy & durable design',
              ],
              art: FridgeProductImage(width: 110),
              price: '₹499',
              checkoutProduct: CheckoutProduct.refrigeratorSingleDoor,
              footerText: _refrigeratorFooterText,
            ),
          ),
        ),

        // ============================================================
        // DOUBLE DOOR REFRIGERATOR
        // ============================================================
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

          // DOUBLE DOOR → PRODUCT DETAILS
          onContinue: () => context.push(
            '/product-details',
            extra: const Product(
              badge: 'Double Door',
              title: 'Double Door Refrigerator',
              description:
                  'Keep your food fresh for longer with reliable performance and efficient cooling.',
              checklist: [
                'Powerful cooling',
                'Large storage capacity',
                'Low power consumption',
                'Sturdy & durable design',
              ],
              art: FridgeProductImage(width: 110),
              price: '₹749',
              checkoutProduct: CheckoutProduct.refrigeratorDoubleDoor,
              footerText: _refrigeratorFooterText,
            ),
          ),
        ),
      ],
    );
  }
}
