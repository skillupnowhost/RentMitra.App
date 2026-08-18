import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, this.onViewCombos});

  final VoidCallback? onViewCombos;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.promoCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const _AnimatedDiscountBadge(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save 10% on Appliance Combos',
                  style: AppTextStyles.of(
                    figmaSize: 16,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Starting at ₹1,887/month',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w400,
                    color: AppColors.textGrayMed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onViewCombos,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.ctaPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Combos',
                    style: AppTextStyles.of(
                      figmaSize: 13,
                      weight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
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
      width: 64,
      height: 64,
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
                  figmaSize: 24,
                  weight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                'OFF',
                style: AppTextStyles.of(
                  figmaSize: 17,
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
