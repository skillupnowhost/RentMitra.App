import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The onboarding "Skip" affordance: a frosted, translucent pill that fades
/// in and then idles with a barely-there float — reads as glass sitting
/// above the scene rather than a normal flat button.
class GlassSkipButton extends StatefulWidget {
  const GlassSkipButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<GlassSkipButton> createState() => _GlassSkipButtonState();
}

class _GlassSkipButtonState extends State<GlassSkipButton>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    final floatCurve = CurvedAnimation(parent: _float, curve: Curves.easeInOut);

    return AnimatedBuilder(
      animation: Listenable.merge([entranceCurve, floatCurve]),
      builder: (context, child) {
        final bob = (floatCurve.value - 0.5) * 5;
        final settle = (1 - entranceCurve.value) * 10;
        return Opacity(
          opacity: entranceCurve.value,
          child: Transform.translate(
            offset: Offset(0, bob - settle),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTextStyles.fig(22),
                vertical: AppTextStyles.fig(13),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.22),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Skip',
                style: AppTextStyles.of(
                  figmaSize: 14,
                  weight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
