import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The onboarding flow's forward-progress control.
///
/// Two visual states share one press/scale/glow interaction: a compact
/// circular arrow for "next slide", and an expanded gradient pill for the
/// closing "Get Started" action. [expanded] morphs between them with a
/// scale+fade — the button stays otherwise still, with no idle motion.
class PremiumCtaButton extends StatefulWidget {
  const PremiumCtaButton({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  State<PremiumCtaButton> createState() => _PremiumCtaButtonState();
}

class _PremiumCtaButtonState extends State<PremiumCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 160),
    lowerBound: 0,
    upperBound: 0.06,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const compactSize = 52.0;

    return SizedBox(
      width: widget.expanded ? 190 : compactSize,
      height: compactSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: AnimatedBuilder(
              animation: _press,
              builder: (context, child) {
                final scale = 1.0 - _press.value;
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTapDown: (_) => _press.forward(),
                onTapUp: (_) => _press.reverse(),
                onTapCancel: () => _press.reverse(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onTap();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: widget.expanded
                      ? _ExpandedCta(
                          key: const ValueKey('cta-expanded'),
                          size: compactSize,
                        )
                      : _CompactCta(
                          key: const ValueKey('cta-compact'),
                          size: compactSize,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCta extends StatelessWidget {
  const _CompactCta({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.ctaPurple, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}

class _ExpandedCta extends StatelessWidget {
  const _ExpandedCta({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        gradient: const LinearGradient(
          colors: [AppColors.ctaPurple, AppColors.purple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: AppTextStyles.of(
              figmaSize: 15,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
