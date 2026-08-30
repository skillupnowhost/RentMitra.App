import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../theme/app_colors.dart';
import '../widgets/appliance_art.dart';
import '../widgets/combo_comparison_table.dart';
import '../widgets/product_option_card.dart';
import 'checkout_screen.dart';
import 'product_listing_screen.dart';

const _comboDescription = 'Complete appliance solutions designed for modern homes.';
const _comboFooterText =
    'All Combo Plans come with free delivery, free installation and maintenance & service included for every appliance — plus 18% GST applicable on every plan.';

// ============================================================
// SHARED APPLIANCE SPEC BULLETS
// ============================================================

const _acSpecs1Ton = [
  '1 Ton Capacity',
  'Energy Efficient',
  'Fast Cooling Technology',
  'Smart Temperature Control',
];
const _acSpecs1p5Ton = [
  '1.5 Ton Capacity',
  'Energy Efficient',
  'Fast Cooling Technology',
  'Smart Temperature Control',
];
const _fridgeSpecsDoubleDoor = [
  'Double Door Design',
  'Spacious Storage',
  'Energy Saving Technology',
];
const _washerSpecsFrontLoad = [
  'Front Loading Technology',
  'Advanced Cleaning System',
  'Low Noise Operation',
];
const _washerSpecsTopLoad = [
  'Top Loading Technology',
  'Easy Operation',
  'Powerful Washing Performance',
];

class ComboScreen extends StatelessWidget {
  const ComboScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductListingScreen(
      title: 'Choose Your Perfect Home Combo',

      description: _comboDescription,

      heroArt: const ApplianceClusterImage(width: 130),

      badgeFeatures: const [
        (Icons.local_shipping_outlined, 'Free\nDelivery'),
        (Icons.build_outlined, 'Free\nInstallation'),
        (Icons.verified_user_outlined, 'Service &\nMaintenance'),
        (Icons.percent, 'Save\n10%'),
      ],

      sectionTitle: 'Choose Your Combo',

      footerText: _comboFooterText,
      footerImage: 'assets/images/All install.png',

      trailingSection: const ComboComparisonTable(
        headers: [
          'Smart\nLiving',
          'Family\nEssentials',
          'Premium\nFamily',
          'Ultimate\nPremium',
        ],
        rows: [
          ComboComparisonRow(
            label: 'AC Capacity',
            values: ['1 Ton', '1 Ton', '1.5 Ton', '1.5 Ton'],
          ),
          ComboComparisonRow(
            label: 'Fridge Type',
            values: [
              'Double Door',
              'Double Door',
              'Double Door',
              'Double Door',
            ],
          ),
          ComboComparisonRow(
            label: 'Washer Type',
            values: ['Front Load', 'Top Load', 'Top Load', 'Front Load'],
          ),
          ComboComparisonRow(
            label: 'Monthly Rental',
            values: ['₹2,337', '₹2,112', '₹2,382', '₹2,607'],
          ),
          ComboComparisonRow(
            label: 'You Save',
            values: ['₹260', '₹237', '₹265', '₹290'],
          ),
        ],
      ),

      options: [
        // ============================================================
        // SMART LIVING COMBO — Best Value
        // ============================================================
        ProductOptionCard(
          badge: 'Best Value Combo',
          badgeColor: AppColors.comboBlueBright,

          title: 'Smart Living Combo',

          checklist: const [
            '1 Ton Smart Inverter Split AC',
            'Double Door Refrigerator',
            'Front Load Washing Machine',
            'Free installation for all 3 appliances',
          ],

          art: const ApplianceClusterImage(width: 90),

          originalPrice: '₹2,597',
          discountBadge: '10% OFF',
          price: '₹2,337',

          ctaLabel: 'Rent This Combo',

          onContinue: () => context.push(
            '/product-details',
            extra: Product(
              badge: 'Best Value Combo',
              title: 'Smart Living Combo',
              description: _comboDescription,
              checklist: const [
                '1 Ton Smart Inverter Split AC',
                'Double Door Refrigerator',
                'Front Load Washing Machine',
                'Free installation for all 3 appliances',
              ],
              art: const ApplianceClusterImage(width: 140),
              originalPrice: '₹2,597',
              discountBadge: '10% OFF',
              price: '₹2,337',
              checkoutProduct: CheckoutProduct.smartLivingCombo,
              footerText: _comboFooterText,
              ctaLabel: 'Rent This Combo',
              applianceBreakdown: [
                (
                  'Air Conditioner',
                  const AcProductImage(width: 130),
                  _acSpecs1Ton,
                ),
                (
                  'Refrigerator',
                  const FridgeDoubleDoorProductImage(width: 130),
                  _fridgeSpecsDoubleDoor,
                ),
                (
                  'Washing Machine',
                  const WasherFrontLoadImage(width: 130),
                  _washerSpecsFrontLoad,
                ),
              ],
            ),
          ),
        ),

        // ============================================================
        // FAMILY ESSENTIALS COMBO — Most Popular
        // ============================================================
        ProductOptionCard(
          badge: 'Most Popular',
          badgeColor: AppColors.checkGreen,

          title: 'Family Essentials Combo',

          checklist: const [
            '1 Ton Smart Inverter Split AC',
            'Double Door Refrigerator',
            'Top Load Washing Machine',
            'Free installation for all 3 appliances',
          ],

          art: const ApplianceClusterImage(width: 90),

          originalPrice: '₹2,349',
          discountBadge: '10% OFF',
          price: '₹2,112',

          ctaLabel: 'Rent This Combo',

          onContinue: () => context.push(
            '/product-details',
            extra: Product(
              badge: 'Most Popular',
              title: 'Family Essentials Combo',
              description: _comboDescription,
              checklist: const [
                '1 Ton Smart Inverter Split AC',
                'Double Door Refrigerator',
                'Top Load Washing Machine',
                'Free installation for all 3 appliances',
              ],
              art: const ApplianceClusterImage(width: 140),
              originalPrice: '₹2,349',
              discountBadge: '10% OFF',
              price: '₹2,112',
              checkoutProduct: CheckoutProduct.familyEssentialsCombo,
              footerText: _comboFooterText,
              ctaLabel: 'Rent This Combo',
              applianceBreakdown: [
                (
                  'Air Conditioner',
                  const AcProductImage(width: 130),
                  _acSpecs1Ton,
                ),
                (
                  'Refrigerator',
                  const FridgeDoubleDoorProductImage(width: 130),
                  _fridgeSpecsDoubleDoor,
                ),
                (
                  'Washing Machine',
                  const WasherTopLoadImage(width: 130),
                  _washerSpecsTopLoad,
                ),
              ],
            ),
          ),
        ),

        // ============================================================
        // PREMIUM FAMILY COMBO — Premium Choice
        // ============================================================
        ProductOptionCard(
          badge: 'Premium Choice',

          title: 'Premium Family Combo',

          checklist: const [
            '1.5 Ton Smart Inverter Split AC',
            'Double Door Refrigerator',
            'Top Load Washing Machine',
            'Free installation for all 3 appliances',
          ],

          art: const ApplianceClusterImage(width: 90),

          originalPrice: '₹2,647',
          discountBadge: '10% OFF',
          price: '₹2,382',

          ctaLabel: 'Rent This Combo',

          onContinue: () => context.push(
            '/product-details',
            extra: Product(
              badge: 'Premium Choice',
              title: 'Premium Family Combo',
              description: _comboDescription,
              checklist: const [
                '1.5 Ton Smart Inverter Split AC',
                'Double Door Refrigerator',
                'Top Load Washing Machine',
                'Free installation for all 3 appliances',
              ],
              art: const ApplianceClusterImage(width: 140),
              originalPrice: '₹2,647',
              discountBadge: '10% OFF',
              price: '₹2,382',
              checkoutProduct: CheckoutProduct.premiumFamilyCombo,
              footerText: _comboFooterText,
              ctaLabel: 'Rent This Combo',
              applianceBreakdown: [
                (
                  'Air Conditioner',
                  const AcProductImage(width: 130),
                  _acSpecs1p5Ton,
                ),
                (
                  'Refrigerator',
                  const FridgeDoubleDoorProductImage(width: 130),
                  _fridgeSpecsDoubleDoor,
                ),
                (
                  'Washing Machine',
                  const WasherTopLoadImage(width: 130),
                  _washerSpecsTopLoad,
                ),
              ],
            ),
          ),
        ),

        // ============================================================
        // ULTIMATE PREMIUM COMBO — Luxury Home Package
        // ============================================================
        ProductOptionCard(
          badge: 'Luxury Home Package',
          badgeColor: AppColors.comboBlueDeep,

          title: 'Ultimate Premium Combo',

          checklist: const [
            '1.5 Ton Smart Inverter Split AC',
            'Double Door Refrigerator',
            'Front Load Washing Machine',
            'Free installation for all 3 appliances',
          ],

          art: const ApplianceClusterImage(width: 90),

          originalPrice: '₹2,897',
          discountBadge: '10% OFF',
          price: '₹2,607',

          ctaLabel: 'Rent This Combo',

          onContinue: () => context.push(
            '/product-details',
            extra: Product(
              badge: 'Luxury Home Package',
              title: 'Ultimate Premium Combo',
              description: _comboDescription,
              checklist: const [
                '1.5 Ton Smart Inverter Split AC',
                'Double Door Refrigerator',
                'Front Load Washing Machine',
                'Free installation for all 3 appliances',
              ],
              art: const ApplianceClusterImage(width: 140),
              originalPrice: '₹2,897',
              discountBadge: '10% OFF',
              price: '₹2,607',
              checkoutProduct: CheckoutProduct.ultimatePremiumCombo,
              footerText: _comboFooterText,
              ctaLabel: 'Rent This Combo',
              applianceBreakdown: [
                (
                  'Air Conditioner',
                  const AcProductImage(width: 130),
                  _acSpecs1p5Ton,
                ),
                (
                  'Refrigerator',
                  const FridgeDoubleDoorProductImage(width: 130),
                  _fridgeSpecsDoubleDoor,
                ),
                (
                  'Washing Machine',
                  const WasherFrontLoadImage(width: 130),
                  _washerSpecsFrontLoad,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
