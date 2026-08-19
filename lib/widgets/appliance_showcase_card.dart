import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Compact product card used in the home screen's third section — three of
/// these sit side by side in a single row, so everything (title, checklist,
/// photo, variant tabs) is sized to fit a roughly one-third-screen-width
/// column rather than a full-width card.
///
/// [images] auto-advances on a loop (crossfading to the next variant every
/// few seconds and wrapping back to the first) so the card keeps showing
/// off every variant without the visitor needing to tap anything. The
/// variant tabs are still tappable — picking one jumps straight to that
/// photo, restyles the tabs to show which is active, and resets the loop
/// timer so it doesn't immediately fight the manual choice. Tapping the
/// card body itself still fires [onTap] (navigates into the full product
/// listing) independently of the tabs/loop.
class ApplianceShowcaseCard extends StatefulWidget {
  const ApplianceShowcaseCard({
    super.key,
    required this.title,
    required this.titleColor,
    required this.checklist,
    required this.images,
    required this.tabs,
    this.overlayButton = false,
    this.tabIcon,
    this.onTap,
  }) : assert(
         images.length == tabs.length,
         'images must have one entry per tab',
       );

  final String title;
  final Color titleColor;
  final List<String> checklist;

  /// One product photo per entry in [tabs], same index order.
  final List<Widget> images;

  /// The variant labels shown below the divider, e.g. `['1 Ton', '1.5 Ton']`
  /// — the first is selected by default.
  final List<String> tabs;

  /// Small glyph shown before each tab label (only the AC card uses this,
  /// per the Figma design's "AC icon + tonnage" tabs).
  final IconData? tabIcon;

  /// Floats a round arrow button over the bottom-right of the product
  /// photo — only the Washing Machine card uses this.
  final bool overlayButton;

  final VoidCallback? onTap;

  @override
  State<ApplianceShowcaseCard> createState() => _ApplianceShowcaseCardState();
}

class _ApplianceShowcaseCardState extends State<ApplianceShowcaseCard>
    with SingleTickerProviderStateMixin {
  static const _loopInterval = Duration(milliseconds: 2800);

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  int _selected = 0;
  int _previous = 0;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  void _startLoop() {
    if (widget.images.length < 2) return;
    _loopTimer = Timer.periodic(_loopInterval, (_) {
      if (mounted) _goTo((_selected + 1) % widget.images.length);
    });
  }

  void _goTo(int i) {
    if (i == _selected) return;
    setState(() {
      _previous = _selected;
      _selected = i;
    });
    _slide.forward(from: 0);
  }

  void _selectTab(int i) {
    _loopTimer?.cancel();
    _goTo(i);
    _startLoop();
  }

  /// A single continuous left-to-right filmstrip motion — the outgoing
  /// photo always exits left while the incoming one always enters from the
  /// right, regardless of which direction `_selected` moved — the same
  /// technique the home screen's hero banner slider uses, so this reads as
  /// the same "premium slider" motion rather than a generic crossfade.
  Widget _slidingImages() {
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_slide.value);
        final outOpacity = (1 - t * 2).clamp(0.0, 1.0);
        final inOpacity = (t * 2 - 1).clamp(0.0, 1.0);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: outOpacity,
                child: FractionalTranslation(
                  translation: Offset(-t, 0),
                  child: Center(child: widget.images[_previous]),
                ),
              ),
              if (t > 0)
                Opacity(
                  opacity: inOpacity,
                  child: FractionalTranslation(
                    translation: Offset(1 - t, 0),
                    child: Center(child: widget.images[_selected]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageArea() {
    if (!widget.overlayButton) return _slidingImages();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _slidingImages()),
        Align(
          alignment: const Alignment(0.7, 0.8),
          child: _OverlayArrowButton(
            color: widget.titleColor,
            onTap: widget.onTap,
          ),
        ),
      ],
    );
  }

  // Wrapped in a full-width, opaque swallow layer: without it, a tap that
  // lands in the row's height band but just past a tab label's tight text
  // bounds falls through to the card's own onTap (navigating into the full
  // product page) instead of doing nothing — confirmed on-device, where a
  // near-miss on "Double Door" launched the Refrigerator listing screen.
  Widget _tabsColumn() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: SizedBox(
        width: double.infinity,
        // FittedBox (not Wrap) so the tabs always render as a single line —
        // longer label pairs like "Single Door" / "Double Door" don't fit
        // this card's narrow width at full size and would otherwise wrap to
        // a second line; scaling the whole row down keeps it on one line
        // instead.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.tabs.length; i++) ...[
                if (i != 0) const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectTab(i),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.tabIcon != null) ...[
                        Icon(
                          widget.tabIcon,
                          size: 12,
                          color: i == _selected
                              ? widget.titleColor
                              : AppColors.textGraySoft,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        widget.tabs[i],
                        style: AppTextStyles.of(
                          figmaSize: 10.5,
                          weight: i == _selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: i == _selected
                              ? widget.titleColor
                              : AppColors.textGraySoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTextStyles.fig(14),
          vertical: AppTextStyles.fig(14),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Every row below has an explicit fixed height rather than
            // sizing to its own text — three cards sit side by side and
            // must line up exactly, but Google Fonts' Inter face swaps in
            // a frame after the fallback font's first layout pass with
            // subtly different line metrics, and checklist copy varies in
            // length card to card ("Freshness that lasts longer." wraps
            // where "Powerful cleaning" doesn't). Either alone is enough to
            // throw the three cards out of alignment (or overflow) if
            // height came from content instead.
            SizedBox(
              height: AppTextStyles.fig(34),
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(
                  figmaSize: 13,
                  weight: FontWeight.w700,
                  color: widget.titleColor,
                ),
              ),
            ),
            SizedBox(height: AppTextStyles.fig(6)),
            SizedBox(height: AppTextStyles.fig(120), child: _imageArea()),
            SizedBox(height: AppTextStyles.fig(6)),
            for (final item in widget.checklist)
              SizedBox(
                height: AppTextStyles.fig(28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppColors.check,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.of(
                          figmaSize: 10.5,
                          weight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: AppTextStyles.fig(5)),
            Divider(height: 1, color: AppColors.divider),
            SizedBox(height: AppTextStyles.fig(6)),
            SizedBox(height: AppTextStyles.fig(24), child: _tabsColumn()),
          ],
        ),
      ),
    );
  }
}

class _OverlayArrowButton extends StatelessWidget {
  const _OverlayArrowButton({required this.color, this.onTap});

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.chevron_right, color: color, size: 15),
      ),
    );
  }
}
