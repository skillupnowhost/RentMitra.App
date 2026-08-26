import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../widgets/appliance_art.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

const _acDescription =
    'Experience powerful cooling, energy efficiency and smart performance.';
const _acFooterText =
    'All ACs come with free delivery, free installation and maintenance & service included.';

class AcScreen extends StatelessWidget {
  const AcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Smart Inverter Split AC',
      description: _acDescription,
      heroArt: const AcProductImage(width: 110),

      badgeFeatures: const [
        (Icons.bolt, 'Energy\nEfficient'),
        (Icons.ac_unit, 'Powerful\nCooling'),
        (Icons.volume_off, 'Low Noise\nOperation'),
        (Icons.shield_outlined, 'Smart\nPerformance'),
      ],

      sectionTitle: 'Choose Your AC',

      footerText: _acFooterText,

      options: [
        // ============================================================
        // 1 TON AC
        // ============================================================
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

          // 1 TON AC → PRODUCT DETAILS
          onContinue: () => context.push(
            '/product-details',
            extra: const Product(
              badge: '1 Ton',
              title: 'Smart Inverter Split AC',
              description: _acDescription,
              checklist: [
                'Powerful cooling',
                'Low power consumption',
                'Smart performance',
                'Smart Plug included',
              ],
              art: AcProductImage(width: 140),
              price: '₹999',
              checkoutProduct: CheckoutProduct.acOneTon,
              specs: [
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
              footerText: _acFooterText,
            ),
          ),
        ),

        // ============================================================
        // 1.5 TON AC
        // ============================================================
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

          // 1.5 TON AC → PRODUCT DETAILS
          onContinue: () => context.push(
            '/product-details',
            extra: const Product(
              badge: '1.5 Ton',
              title: 'Smart Inverter Split AC',
              description: _acDescription,
              checklist: [
                'Powerful cooling',
                'Low power consumption',
                'Smart performance',
                'Smart Plug included',
              ],
              art: AcProductImage(width: 140),
              price: '₹1,299',
              checkoutProduct: CheckoutProduct.acOnePointFiveTon,
              specs: [
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
              footerText: _acFooterText,
            ),
          ),
        ),
      ],
    );
  }
}
