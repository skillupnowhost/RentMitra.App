import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, this.onViewCombos, this.startingPrice});

  final VoidCallback? onViewCombos;

  /// Formatted "starting at" combo price (e.g. "₹2,112"), computed by the
  /// caller from live pricing — null shows a loading placeholder instead of
  /// a stale hardcoded figure.
  final String? startingPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.promoCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const _AnimatedDiscountBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save 10% on Appliance Combos',
                  style: AppTextStyles.of(
                    figmaSize: 13,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 2),
                // Price and the AC+fridge+washer glyph trio read as one
                // line — wrapped in [Wrap] rather than [Row] so they stay
                // together on narrower screens instead of overflowing.
                Wrap(
                  spacing: 5,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      startingPrice == null
                          ? 'Starting at ₹—/month'
                          : 'Starting at $startingPrice/month',
                      style: AppTextStyles.of(
                        figmaSize: 11,
                        weight: FontWeight.w400,
                        color: AppColors.textGrayMed,
                      ),
                    ),
                    const _MiniApplianceIcons(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onViewCombos,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.ctaPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Combos',
                    style: AppTextStyles.of(
                      figmaSize: 11,
                      weight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The plain AC / fridge / washer glyph trio next to the promo price — no
/// "+" joiners or label, unlike [ComboIconRow] used on the category card,
/// so it reads as a quiet visual footnote rather than another headline.
class _MiniApplianceIcons extends StatelessWidget {
  const _MiniApplianceIcons();

  static const _icons = [
    'assets/images/air-conditioner icon.png',
    'assets/images/fridge icon.png',
    'assets/images/washing-machine icon.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _icons.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AppColors.purple,
                BlendMode.srcIn,
              ),
              child: Image.asset(_icons[i], width: 11, height: 11),
            ),
          ),
      ],
    );
  }
}

/// The "10% OFF" badge: the scalloped promo-badge shape (not a plain
/// circle), re-tinted blue-to-purple via a [ShaderMask] gradient instead of
/// its original yellow, spinning slowly through a full 360° on loop. The
/// "10%" / "OFF" text sits outside that rotating subtree in its own layer,
/// so it stays fixed and upright throughout.
class _AnimatedDiscountBadge extends StatefulWidget {
  const _AnimatedDiscountBadge();

  @override
  State<_AnimatedDiscountBadge> createState() => _AnimatedDiscountBadgeState();
}

class _AnimatedDiscountBadgeState extends State<_AnimatedDiscountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotate = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _rotate,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.comboBlueBright, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Image.asset(
                'assets/images/promo_badge.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '10%',
                style: AppTextStyles.of(
                  figmaSize: 15,
                  weight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                'OFF',
                style: AppTextStyles.of(
                  figmaSize: 11,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
