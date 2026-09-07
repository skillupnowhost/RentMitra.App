import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    this.onViewCombos,
    this.startingPrice,
    this.stretchToFill = false,
  });

  final VoidCallback? onViewCombos;

  /// Formatted "starting at" combo price (e.g. "₹2,112"), computed by the
  /// caller from live pricing — null shows a loading placeholder instead of
  /// a stale hardcoded figure.
  final String? startingPrice;

  /// True only on the Home screen, where this card sits inside an
  /// IntrinsicHeight + CrossAxisAlignment.stretch row (to line its button up
  /// with HelpCard's) and so gets a genuinely bounded height — safe for a
  /// [Spacer] to push the button flush to the bottom. Every other call site
  /// (e.g. OffersScreen) places this in a plain scrolling Column, which hands
  /// down an unbounded height; a Spacer there throws "RenderFlex... incoming
  /// height constraints are unbounded", so those use a fixed gap instead.
  final bool stretchToFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 215),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.promoCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: stretchToFill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _AnimatedDiscountBadge(),
              const SizedBox(height: 12),
              Text(
                'Save 10% on Appliance Combos',
                textAlign: TextAlign.center,
                style: AppTextStyles.of(
                  figmaSize: 15,
                  weight: FontWeight.w700,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                startingPrice == null
                    ? 'Starting at ₹—/months'
                    : 'Starting at $startingPrice/months',
                textAlign: TextAlign.center,
                style: AppTextStyles.of(
                  figmaSize: 13,
                  weight: FontWeight.w600,
                  color: AppColors.textGrayMed,
                ),
              ),
              stretchToFill
                  ? const Spacer()
                  : const SizedBox(height: 16),
              GestureDetector(
                onTap: onViewCombos,
                child: Container(
                  width: double.infinity,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.purple, AppColors.ctaPurple],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Combos',
                          style: AppTextStyles.of(
                            figmaSize: 12,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ),
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
      width: 46,
      height: 46,
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
                  figmaSize: 16,
                  weight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                'OFF',
                style: AppTextStyles.of(
                  figmaSize: 12,
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
