import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    this.iconAsset,
    required this.title,
    required this.price,
    required this.iconColor,
    required this.priceColor,
    required this.bgColor,
    this.iconWidget,
    this.onTap,
    this.gradientColors,
    this.badgeText,
  }) : assert(
         iconAsset != null || iconWidget != null,
         'Provide either iconAsset or iconWidget',
       );

  /// Path to a line-art icon asset (e.g. the AC/fridge/washer glyphs), tinted
  /// with [iconColor] via a color filter — the source PNGs are solid black.
  final String? iconAsset;
  final String title;
  final String price;
  final Color iconColor;
  final Color priceColor;
  final Color bgColor;

  /// Overrides [iconAsset] with a custom glyph (e.g. the combo-pack icon
  /// row) when a single image can't represent the card.
  final Widget? iconWidget;
  final VoidCallback? onTap;

  /// When set, paints a gradient background (white icon/text) instead of the
  /// flat [bgColor] — reserved for the Combo Plans card so it reads as a
  /// distinct premium tier against the other flat pastel cards.
  final List<Color>? gradientColors;

  /// Small pill badge (e.g. "Best Value") shown top-right when [gradientColors]
  /// is set.
  final String? badgeText;

  bool get _highlighted => gradientColors != null;

  @override
  Widget build(BuildContext context) {
    final onGradientColor = _highlighted ? Colors.white : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: _highlighted ? null : bgColor,
          gradient: _highlighted
              ? LinearGradient(
                  colors: gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _highlighted
              ? [
                  BoxShadow(
                    color: gradientColors!.last.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        // Stack clips to its own bounds by default (Clip.hardEdge), which
        // would slice off the "Best Value" badge floating above the card's
        // top edge below — Clip.none lets it overflow and render in full.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small uniform gap on every card — the Combo Plans card's
                // "Best Value" badge floats *above* the card via a
                // negative-top [Positioned] below instead of reserving
                // space in this Column, so it no longer forces empty
                // headroom onto the other three cards.
                const SizedBox(height: 4),
                SizedBox(
                  height: 34,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child:
                        iconWidget ??
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            onGradientColor ?? iconColor,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            iconAsset!,
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                          ),
                        ),
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(7)),
                // Fixed to a 2-line height so "Starting at" / price / +GST
                // land on the same row across every card regardless of
                // whether this card's title wraps to 1 or 2 lines.
                SizedBox(
                  height: AppTextStyles.fig(34),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.of(
                        figmaSize: 12,
                        weight: FontWeight.w700,
                        color: onGradientColor ?? AppColors.navy,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(8)),
                Container(
                  width: AppTextStyles.fig(24),
                  height: 2,
                  color: onGradientColor ?? iconColor,
                ),
                SizedBox(height: AppTextStyles.fig(9)),
                Text(
                  'Starting at',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.of(
                    figmaSize: 9,
                    weight: FontWeight.w300,
                    color:
                        onGradientColor?.withValues(alpha: 0.7) ??
                        AppColors.textGraySoft,
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(6)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: AppTextStyles.of(
                          figmaSize: 20,
                          weight: FontWeight.w700,
                          color: onGradientColor ?? priceColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '/month',
                        style: AppTextStyles.of(
                          figmaSize: 11,
                          weight: FontWeight.w400,
                          color: (onGradientColor ?? priceColor).withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTextStyles.fig(2)),
                Text(
                  '+ GST',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.of(
                    figmaSize: 11,
                    weight: FontWeight.w400,
                    color:
                        onGradientColor?.withValues(alpha: 0.7) ??
                        AppColors.textGraySoft,
                  ),
                ),
              ],
            ),
            // Floats above the card's own top edge (negative offset) rather
            // than reserving space inside it — a hanging-ribbon badge, not
            // one that pushes this card's content down relative to its
            // three siblings.
            if (badgeText != null)
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(child: _BestValueBadge(text: badgeText!)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The "Best Value" call-out — centered inside the card's top padding (fully
/// contained, never overflowing the card bounds) with a slow glow-and-breathe
/// loop plus an occasional soft light sweep across its face, so the Combo
/// Plans card's headline offer is the first thing a glance lands on without
/// being distracting.
class _BestValueBadge extends StatefulWidget {
  const _BestValueBadge({required this.text});

  final String text;

  @override
  State<_BestValueBadge> createState() => _BestValueBadgeState();
}

class _BestValueBadgeState extends State<_BestValueBadge>
    with TickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _glow.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _glow, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + curved.value * 0.035,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.comboBadgeBg.withValues(
                    alpha: 0.35 + curved.value * 0.25,
                  ),
                  blurRadius: 6 + curved.value * 8,
                  spreadRadius: curved.value * 1.1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            color: AppColors.comboBadgeBg,
            // FittedBox is a safety net: real-device font metrics can measure
            // a hair wider than the layout pass expects at this tight size,
            // which would otherwise overflow by a few pixels instead of
            // gracefully scaling down.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: AppColors.comboBlueDeep,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.text,
                    style: AppTextStyles.of(
                      figmaSize: 9,
                      weight: FontWeight.w700,
                      color: AppColors.comboBlueDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // A thin, faint highlight streak drifting left-to-right on a slow
          // loop — the "premium badge" cue — rather than a continuous shimmer
          // that would compete with the text for attention.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shine,
              builder: (context, _) {
                return FractionalTranslation(
                  translation: Offset(_shine.value * 3.2 - 1.1, 0),
                  child: Transform.rotate(
                    angle: 0.6,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The Combo Plans glyph: the AC, fridge and washing-machine line icons
/// strung together with "+" marks, all tinted to the card's accent color —
/// reads as "these three appliances bundled" at a glance.
class ComboIconRow extends StatelessWidget {
  const ComboIconRow({super.key, required this.color, this.iconSize = 26});

  final Color color;
  final double iconSize;

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
        for (var i = 0; i < _icons.length; i++) ...[
          if (i != 0) _plus(),
          ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset(
              _icons[i],
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ],
    );
  }

  Widget _plus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '+',
        style: AppTextStyles.of(
          figmaSize: iconSize * 0.7,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
