import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'reveal_text.dart';

/// The onboarding "Skip" affordance: plain text, no background box, that
/// fades in once on mount and dips in opacity on press — no idle motion.
class SkipButton extends StatefulWidget {
  const SkipButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      active: true,
      offset: 0,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: _pressed ? 0.5 : 1.0,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTextStyles.fig(10),
              vertical: AppTextStyles.fig(10),
            ),
            child: Text(
              'Skip',
              style: AppTextStyles.of(
                figmaSize: 15,
                weight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
