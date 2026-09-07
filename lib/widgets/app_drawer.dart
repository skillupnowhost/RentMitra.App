import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The hamburger side menu panel: My Rentals, Products, Profile, Settings.
///
/// "Dashboard (Home)" was deliberately dropped from this list — with the
/// drawer only ever opened from the home screen itself, a "Home" entry here
/// just duplicated the bottom nav's Home tab.
///
/// This is a plain panel, not a [Drawer] — the containing [HomeScreen]
/// drives it with its own [AnimationController] (slide + backdrop blur +
/// a morphing hamburger/close icon) so the open/close motion reads as one
/// deliberately-designed gesture rather than Material's stock drawer swipe.
/// [animation] also staggers each item's fade/slide-in as the panel opens.
/// The panel itself is frosted glass — a blurred, translucent white plate
/// over whatever is behind it — for a lighter, more premium feel than a
/// flat white fill. The glass is static (no drifting sheen or other motion
/// inside the panel itself).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.animation, required this.onClose});

  final Animation<double> animation;
  final VoidCallback onClose;

  static const _items = [
    (Icons.receipt_long_outlined, 'My Rentals'),
    (Icons.grid_view_rounded, 'Products'),
    (Icons.local_offer_outlined, 'Offers'),
    (Icons.person_outline, 'Profile'),
    (Icons.settings_outlined, 'Settings'),
  ];

  void _handle(BuildContext context, int index) {
    onClose();
    switch (index) {
      case 0:
        context.go('/my-rentals');
      case 1:
        context.push('/catalog');
      case 2:
        context.push('/offers');
      case 3:
        context.go('/profile');
      case 4:
        context.push('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 215,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.32),
              blurRadius: 30,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(26),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Stack(
              children: [
                // The glass "body": a diagonal tint rather than a flat fill
                // — lighter at the top-left, thinner at the bottom-right —
                // so it reads as a slab catching light at an angle instead
                // of a uniform frosted sheet.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.62),
                          Colors.white.withValues(alpha: 0.30),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1,
                        ),
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(context),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _items.length; i++)
                          _StaggeredEntry(
                            animation: animation,
                            index: i,
                            count: _items.length,
                            child: _DrawerItem(
                              icon: _items[i].$1,
                              label: _items[i].$2,
                              onTap: () => _handle(context, i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo_full.png',
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 0,
              child: _AnimatedIconTap(
                onTap: onClose,
                size: 28,
                child: const Icon(
                  Icons.close,
                  size: 17,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides one drawer row in on its own delayed slice of [animation],
/// so the items cascade in one after another as the panel opens instead of
/// all popping in at once.
class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({
    required this.animation,
    required this.index,
    required this.count,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index / count) * 0.5;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + 0.55).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset((1 - curved.value) * 22, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _DrawerItem extends StatefulWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Icon(widget.icon, size: 18, color: AppColors.purple)
                        .animate(target: _pressed ? 1 : 0)
                        .scaleXY(
                          begin: 1,
                          end: 0.8,
                          curve: Curves.easeOut,
                          duration: 120.ms,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: AppTextStyles.of(
                    figmaSize: 16,
                    weight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 15,
                  color: AppColors.textGraySoft.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bare icon (no background plate) that scales + tilts down on press —
/// used for the hamburger drawer's own chrome (close button) so it reads as
/// a lightweight tap target rather than a boxed button.
class _AnimatedIconTap extends StatefulWidget {
  const _AnimatedIconTap({
    required this.onTap,
    required this.child,
    this.size = 32,
  });

  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  State<_AnimatedIconTap> createState() => _AnimatedIconTapState();
}

class _AnimatedIconTapState extends State<_AnimatedIconTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: widget.child
              .animate(target: _pressed ? 1 : 0)
              .scaleXY(
                begin: 1,
                end: 0.78,
                curve: Curves.easeOut,
                duration: 120.ms,
              )
              .rotate(begin: 0, end: 0.06),
        ),
      ),
    );
  }
}
