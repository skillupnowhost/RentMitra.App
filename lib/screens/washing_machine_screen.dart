import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/pricing_provider.dart';
import '../utils/rent_pricing.dart';
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
    final pricing = context.watch<PricingProvider>();

    final topLoadRent = pricing.rentFor(
      CheckoutProduct.washingMachineTopLoad.variantId,
    );
    final frontLoadRent = pricing.rentFor(
      CheckoutProduct.washingMachineFrontLoad.variantId,
    );

    final topLoadPrice = topLoadRent == null ? '₹—' : formatRupees(topLoadRent);
    final frontLoadPrice = frontLoadRent == null
        ? '₹—'
        : formatRupees(frontLoadRent);

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
      footerImageBleedRight: 20,

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

          price: topLoadPrice,

          onContinue: () => context.push(
            '/product-details',
            extra: Product(
              badge: 'Top Load',
              title: 'Top Load Washing Machine',
              description: 'Powerful cleaning, better care and energy efficiency.',
              checklist: const [
                'Powerful cleaning',
                'Large capacity',
                'Low water consumption',
                'Sturdy & durable design',
              ],
              art: const WasherTopLoadImage(width: 110),
              price: topLoadPrice,
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

          price: frontLoadPrice,

          onContinue: () => context.push(
            '/product-details',
            extra: Product(
              badge: 'Front Load',
              title: 'Front Load Washing Machine',
              description: 'Powerful cleaning, better care and energy efficiency.',
              checklist: const [
                'Advanced fabric care',
                'High energy efficiency',
                'Low water consumption',
                'Sturdy & durable design',
              ],
              art: const WasherFrontLoadImage(width: 110),
              price: frontLoadPrice,
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
