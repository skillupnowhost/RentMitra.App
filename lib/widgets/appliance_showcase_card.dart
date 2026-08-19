import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Compact product card used in the home screen's third section — three of
/// these sit side by side in a single row, so everything (title, checklist,
/// photo, variant tabs) is sized to fit a roughly one-third-screen-width
/// column rather than a full-width card.
class ApplianceShowcaseCard extends StatelessWidget {
  const ApplianceShowcaseCard({
    super.key,
    required this.title,
    required this.titleColor,
    required this.checklist,
    required this.image,
    required this.tabs,
    this.overlayButton = false,
    this.tabIcon,
    this.onTap,
  });

  final String title;
  final Color titleColor;
  final List<String> checklist;
  final Widget image;

  /// The two variant labels shown below the divider, e.g.
  /// `['1 Ton', '1.5 Ton']` — the first reads as the selected one.
  final List<String> tabs;

  /// Small glyph shown before each tab label (only the AC card uses this,
  /// per the Figma design's "AC icon + tonnage" tabs).
  final IconData? tabIcon;

  /// Floats a round arrow button over the bottom-right of the product
  /// photo — only the Washing Machine card uses this.
  final bool overlayButton;

  final VoidCallback? onTap;

  Widget _imageArea() {
    if (!overlayButton) return Center(child: image);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Center(child: image),
        Align(
          alignment: const Alignment(0.7, 0.8),
          child: _OverlayArrowButton(color: titleColor, onTap: onTap),
        ),
      ],
    );
  }

  Widget _tabsColumn() {
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: [
        for (var i = 0; i < tabs.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tabIcon != null) ...[
                Icon(
                  tabIcon,
                  size: 10,
                  color: i == 0 ? titleColor : AppColors.textGraySoft,
                ),
                const SizedBox(width: 2),
              ],
              Text(
                tabs[i],
                style: AppTextStyles.of(
                  figmaSize: 9,
                  weight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                  color: i == 0 ? AppColors.navy : AppColors.textGraySoft,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTextStyles.fig(10),
          vertical: AppTextStyles.fig(12),
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
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.of(
                figmaSize: 12,
                weight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            SizedBox(height: AppTextStyles.fig(6)),
            SizedBox(height: AppTextStyles.fig(52), child: _imageArea()),
            SizedBox(height: AppTextStyles.fig(6)),
            for (final item in checklist)
              Padding(
                padding: EdgeInsets.only(bottom: AppTextStyles.fig(4)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 10,
                      color: AppColors.check,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.of(
                          figmaSize: 8.5,
                          weight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: AppTextStyles.fig(4)),
            Divider(height: 1, color: AppColors.divider),
            SizedBox(height: AppTextStyles.fig(6)),
            _tabsColumn(),
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
        width: 22,
        height: 22,
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
        child: Icon(Icons.chevron_right, color: color, size: 13),
      ),
    );
  }
}
