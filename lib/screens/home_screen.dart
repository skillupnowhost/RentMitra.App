import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/animated_service_icons.dart';
import '../widgets/appliance_art.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/help_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/location_selector.dart';
import '../widgets/logo_mark.dart';
import '../widgets/promo_banner.dart';
import 'ac_screen.dart';
import 'combo_screen.dart';
import 'refrigerator_screen.dart';
import 'washing_machine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final GlobalKey _categorySectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    LocationController.instance.autoDetectOnce();
  }

  void _openCombos() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ComboScreen()));
  }

  void _scrollToCategories() {
    final ctx = _categorySectionKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(12),
                      AppTextStyles.fig(16),
                      AppTextStyles.fig(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroBanner(onExplore: _scrollToCategories),
                        SizedBox(height: AppTextStyles.fig(24)),
                        KeyedSubtree(
                          key: _categorySectionKey,
                          child: _sectionTitle('Shop by Category'),
                        ),
                        // Fixed (not fig-scaled) so it reliably clears the
                        // Combo Plans card's "Best Value" badge, which floats
                        // above that card's top edge.
                        const SizedBox(height: 20),
                        _sectionCategoryGrid(),
                        SizedBox(height: AppTextStyles.fig(20)),
                        PromoBanner(onViewCombos: _openCombos),
                        SizedBox(height: AppTextStyles.fig(24)),
                        _sectionTitle('Popular Picks'),
                        SizedBox(height: AppTextStyles.fig(12)),
                        _sectionProductGrid(),
                        SizedBox(height: AppTextStyles.fig(24)),
                        HelpCard(onWhatsApp: () {}),
                      ],
                    ),
                  ),
                ),
                AppBottomNavBar(
                  currentIndex: _navIndex,
                  onTap: (i) {
                    setState(() => _navIndex = i);
                    if (i != 0) {
                      final label = i == 1 ? 'My Rentals' : 'Profile';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label — coming soon')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          const Icon(Icons.menu, color: AppColors.navy, size: 24),
          SizedBox(width: AppTextStyles.fig(14)),
          const LogoMark(width: 42),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rent',
                        style: AppTextStyles.of(
                          figmaSize: 34,
                          weight: FontWeight.w700,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      Text(
                        'Mitra',
                        style: AppTextStyles.of(
                          figmaSize: 34,
                          weight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                      SizedBox(width: AppTextStyles.fig(4)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTextStyles.fig(9),
                          vertical: AppTextStyles.fig(4),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '.app',
                          style: AppTextStyles.of(
                            figmaSize: 12,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'RENT MADE EASY',
                  style: AppTextStyles.of(
                    figmaSize: 11,
                    weight: FontWeight.w500,
                    color: AppColors.textGraySoft,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          ValueListenableBuilder<String>(
            valueListenable: LocationController.instance.city,
            builder: (context, city, _) {
              return ValueListenableBuilder<LocationStatus>(
                valueListenable: LocationController.instance.status,
                builder: (context, status, _) {
                  return LocationSelector(
                    city: city,
                    status: status,
                    onTap: () => LocationPickerSheet.show(context),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Wraps a product image with a soft blurred ellipse beneath it, so the
  /// appliance reads as resting on a surface instead of floating.
  Widget _groundedArt(Widget art) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        art,
        Positioned(
          bottom: -2,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 4),
            child: Container(
              width: AppTextStyles.fig(60),
              height: AppTextStyles.fig(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.of(
        figmaSize: 20,
        weight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  Widget _sectionCategoryGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CategoryCard(
              iconAsset: 'assets/images/air-conditioner icon.png',
              title: 'Smart Inverter Split AC',
              price: '₹999',
              iconColor: AppColors.pricePurple,
              priceColor: AppColors.pricePurple,
              bgColor: AppColors.bgCardPurple,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AcScreen())),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: CategoryCard(
              iconAsset: 'assets/images/fridge icon.png',
              title: 'Refrigerator',
              price: '₹499',
              iconColor: AppColors.priceGreen,
              priceColor: AppColors.priceGreen,
              bgColor: AppColors.bgCardNeutral,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RefrigeratorScreen()),
              ),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: CategoryCard(
              iconAsset: 'assets/images/washing-machine icon.png',
              title: 'Washing Machine',
              price: '₹599',
              iconColor: AppColors.priceOrange,
              priceColor: AppColors.priceOrange,
              bgColor: AppColors.bgCardPeach,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WashingMachineScreen()),
              ),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(8)),
          Expanded(
            child: CategoryCard(
              iconWidget: const ComboIconRow(color: Colors.white),
              title: 'Combo Plans',
              price: '₹1,887',
              iconColor: AppColors.pricePurple,
              priceColor: AppColors.pricePurple,
              bgColor: AppColors.bgCardLavender,
              gradientColors: const [
                AppColors.comboBlueDeep,
                AppColors.comboBlueBright,
              ],
              badgeText: 'Best Value',
              onTap: _openCombos,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionProductGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ProductPreviewCard(
              art: _groundedArt(const AcProductImage(width: 58, height: 40)),
              title: 'Smart Inverter\nSplit AC',
              titleColor: AppColors.titleBlue,
              price: '₹999',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AcScreen())),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(10)),
          Expanded(
            child: _ProductPreviewCard(
              art: _groundedArt(const FridgeProductImage(width: 36)),
              title: 'Refrigerator',
              titleColor: AppColors.titleGreen,
              price: '₹499',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RefrigeratorScreen()),
              ),
            ),
          ),
          SizedBox(width: AppTextStyles.fig(10)),
          Expanded(
            child: _ProductPreviewCard(
              art: _groundedArt(
                const WasherProductImage(width: 42, height: 42),
              ),
              title: 'Washing\nMachine',
              titleColor: AppColors.titleTerracotta,
              price: '₹599',
              stockBadge: 'Few Left',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WashingMachineScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tap-through card for the 3-across AC/Refrigerator/Washing Machine
/// row: product photo, title, starting price and an arrow — the checklist
/// and size-selector that the full-width card used to show now live on the
/// product's own detail screen (reachable via [onTap]).
class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({
    required this.art,
    required this.title,
    required this.titleColor,
    required this.price,
    this.onTap,
    this.stockBadge,
  });

  final Widget art;
  final String title;
  final Color titleColor;
  final String price;
  final VoidCallback? onTap;

  /// Optional premium urgency tag (e.g. "Few Left") shown as a small pill
  /// poking above the card's top-left corner — used sparingly, not on every
  /// card, so it keeps its urgency signal instead of becoming wallpaper.
  final String? stockBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 46, child: Center(child: art)),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 16,
                    weight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Starting at',
                  style: AppTextStyles.of(
                    figmaSize: 9,
                    weight: FontWeight.w400,
                    color: AppColors.textGraySoft,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: AppTextStyles.of(
                                figmaSize: 15,
                                weight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            TextSpan(
                              text: '/mo',
                              style: AppTextStyles.of(
                                figmaSize: 10,
                                weight: FontWeight.w400,
                                color: titleColor.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: titleColor, size: 18),
                  ],
                ),
              ],
            ),
          ),
          if (stockBadge != null)
            Positioned(
              top: -8,
              left: 10,
              child: _StockBadge(text: stockBadge!),
            ),
        ],
      ),
    );
  }
}

/// Small premium urgency pill ("Few Left") with a soft pulsing dot rather
/// than a loud warning color — a quiet nudge, not an alarm.
class _StockBadge extends StatefulWidget {
  const _StockBadge({required this.text});

  final String text;

  @override
  State<_StockBadge> createState() => _StockBadgeState();
}

class _StockBadgeState extends State<_StockBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.comboBadgeBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: curved,
            builder: (context, _) => Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.comboBlueDeep.withValues(
                  alpha: 0.5 + curved.value * 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
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
    );
  }
}

class _HeroBanner extends StatefulWidget {
  const _HeroBanner({this.onExplore});

  final VoidCallback? onExplore;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  int _activeSlide = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 14, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroBanner,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A true 50/50 split — text and product art get equal width — with
          // a taller floor via the outer [ConstrainedBox] so the image
          // slider renders large and dominant instead of shrinking to the
          // text column's natural height. [BoxFit.contain] on the slides
          // themselves still guarantees nothing is ever cropped.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 232),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'SMART RENTING, BETTER LIVING',
                              style: AppTextStyles.of(
                                figmaSize: 9,
                                weight: FontWeight.w600,
                                color: AppColors.purpleSoft,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Rent Smart.\n',
                                style: AppTextStyles.of(
                                  figmaSize: 33,
                                  weight: FontWeight.w800,
                                  color: AppColors.navy,
                                  height: 1.08,
                                ),
                              ),
                              TextSpan(
                                text: 'Live Easy.',
                                style: AppTextStyles.of(
                                  figmaSize: 36,
                                  weight: FontWeight.w800,
                                  color: AppColors.purple,
                                  height: 1.08,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Premium Appliances on Rent at affordable prices.',
                          style: AppTextStyles.of(
                            figmaSize: 14,
                            weight: FontWeight.w500,
                            color: AppColors.textGray,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // The primary hero CTA — tappable (scrolls straight
                        // to the category grid), with a soft lifted shadow so
                        // it still reads as a real button; kept minimal (no
                        // arrow glyph). Shortened category labels (vs. the
                        // full "Refrigerator" / "Washing Machine" / "Combo
                        // Plans") so this fits on one line at a comfortable
                        // size. No FittedBox here — it's a direct child of
                        // this left-aligned column like the headline and
                        // description above it, so its left edge lines up
                        // with theirs exactly rather than through a scaling
                        // wrapper.
                        GestureDetector(
                          onTap: widget.onExplore,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navyDeep,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDeep.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            // FittedBox rather than a fixed font size so the
                            // full Figma copy ("AC • Refrigerator • Washing
                            // Machine • Combo Plans") always fits this fixed-
                            // chrome pill instead of ellipsizing.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'AC • Refrigerator • Washing Machine • Combo Plans',
                                maxLines: 1,
                                style: AppTextStyles.of(
                                  figmaSize: 11,
                                  weight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Fills the remaining vertical space the text column
                        // would otherwise leave empty below the CTA, so the
                        // hero content matches the image column's height
                        // instead of stopping short of it.
                        const _HeroBenefitsRow(),
                      ],
                    ),
                  ),
                  SizedBox(width: AppTextStyles.fig(10)),
                  Expanded(
                    flex: 1,
                    child: _HeroImageSlider(
                      onSlideChanged: (i) {
                        if (mounted) setState(() => _activeSlide = i);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: DotIndicator(count: 4, activeIndex: _activeSlide)),
        ],
      ),
    );
  }
}

/// The Free Delivery / Free Installation / Service & Maintenance benefits,
/// now living inside the hero's own text column (below the CTA) instead of
/// as a separate section — this is what fills the vertical space that used
/// to sit empty under the CTA once the text column stopped short of the
/// image column's height. Icon-above-label, matching the compact treatment
/// used elsewhere in the app ([FeatureItem]) rather than the wider
/// icon-beside-label row that only fit at full card width. Each icon plays
/// its own purpose-built animation — a truck driving, a wrench tightening, a
/// gear + wrench servicing — via [DeliveryTruckIcon], [InstallationIcon] and
/// [MaintenanceIcon], sized down to fit a ~50%-width column.
class _HeroBenefitsRow extends StatelessWidget {
  const _HeroBenefitsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeroBenefitItem(
            label: 'Free\nDelivery',
            iconBuilder: (delay) =>
                DeliveryTruckIcon(size: 15, startDelay: delay),
            alignStart: true,
          ),
        ),
        Expanded(
          child: _HeroBenefitItem(
            label: 'Free\nInstallation',
            iconBuilder: (delay) =>
                InstallationIcon(size: 15, startDelay: delay),
            startDelay: const Duration(milliseconds: 150),
          ),
        ),
        Expanded(
          child: _HeroBenefitItem(
            label: 'Service &\nMaintenance',
            iconBuilder: (delay) =>
                MaintenanceIcon(size: 15, startDelay: delay),
            startDelay: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }
}

class _HeroBenefitItem extends StatelessWidget {
  const _HeroBenefitItem({
    required this.iconBuilder,
    required this.label,
    this.startDelay = Duration.zero,
    this.alignStart = false,
  });

  final Widget Function(Duration delay) iconBuilder;
  final String label;
  final Duration startDelay;

  /// True only for the first ("Free Delivery") item, so its icon's left
  /// edge lines up with the headline/CTA above it instead of sitting
  /// centered in its own third of the row.
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(child: iconBuilder(startDelay)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: alignStart ? TextAlign.left : TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.of(
            figmaSize: 10,
            weight: FontWeight.w600,
            color: AppColors.textGrayMed,
          ),
        ),
      ],
    );
  }
}

/// The hero product art fills its 50%-width column edge-to-edge, stretched
/// (via the parent [IntrinsicHeight] row) to the full height the text column
/// occupies, and auto-cycles through four slides — home appliances, AC,
/// refrigerator, washing machine — via [DotIndicator] above.
///
/// Built on [FractionalTranslation] rather than [PageView]: a real
/// `PageView`'s `RenderViewport` explicitly refuses to report intrinsic
/// dimensions, which crashes the [IntrinsicHeight] ancestor this slider sits
/// under. Each cycle just slides the current slide fully off to the left
/// while the next one slides in from the right — always the same direction
/// — then silently rewinds to a fresh 0..1 range once the incoming slide has
/// landed, so slide 4 -> slide 1 plays as one more forward step rather than
/// a jump back to the start.
class _HeroImageSlider extends StatefulWidget {
  const _HeroImageSlider({required this.onSlideChanged});

  final ValueChanged<int> onSlideChanged;

  @override
  State<_HeroImageSlider> createState() => _HeroImageSliderState();
}

class _HeroImageSliderState extends State<_HeroImageSlider>
    with TickerProviderStateMixin {
  // Each slide's source photo has a different amount of built-in empty
  // margin around the appliance, so BoxFit.contain alone leaves some slides
  // (AC, washing machine) looking much smaller than others (combo, fridge)
  // once fit into this slider's portrait-ish box. [_scales] applies a
  // per-slide extra zoom — tuned by eye against this box's proportions so
  // the appliance, airflow/water effects and pot plant all stay fully in
  // frame — to even that out without touching the box's own size.
  static const _images = [
    'assets/images/appliance_cluster.png',
    'assets/images/ac_splash.png',
    'assets/images/fridge_splash.png',
    'assets/images/washing_machine_splash.png',
  ];
  static const _scales = [1.0, 1.25, 1.1, 1.2];
  static const _autoplayInterval = Duration(milliseconds: 3200);
  static const _transitionDuration = Duration(milliseconds: 700);

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: _transitionDuration,
  );
  late final AnimationController _bobController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);
  Timer? _autoTimer;
  int _currentSlide = 0;

  int get _nextSlide => (_currentSlide + 1) % _images.length;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(_autoplayInterval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || _slideController.isAnimating) return;
    widget.onSlideChanged(_nextSlide);
    _slideController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _currentSlide = _nextSlide);
      // The incoming slide just landed at t=1 (offset 0); snapping the
      // controller back to 0 keeps it drawn at that same offset as the new
      // "current" slide, so the reset itself is invisible.
      _slideController.value = 0;
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _slideController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  Widget _slideArt(int index) {
    // contain (never cover) so the whole photo always stays visible; the
    // extra per-slide [_scales] zoom only ever trims into each photo's own
    // empty margin (verified per asset), never the appliance itself, with
    // the surrounding [ClipRect] catching whatever spills past the box.
    return Transform.scale(
      scale: _scales[index],
      child: Image.asset(_images[index], fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _bobController,
      curve: Curves.easeInOut,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -curved.value * 7),
          child: child,
        );
      },
      // fit: expand forces the (non-positioned) slider to fill exactly the
      // stretched box handed down by the parent row.
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // A soft color-wash glow behind the appliance. The source photos
          // originally had this baked into their dark vignette background
          // (a moody blue/purple bloom); stripping that vignette to make the
          // background transparent removed the glow along with it, leaving
          // the mostly-silver/white appliances reading as flat/monochrome
          // against the pale hero background. This restores the vividness
          // without bringing back the dark box.
          Center(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: AppTextStyles.fig(260),
                height: AppTextStyles.fig(260),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.comboBlueBright.withValues(alpha: 0.75),
                      AppColors.purple.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // A bare Positioned(bottom: ...) with no left/right hands its
          // child unbounded width, so the shadow uses a fixed size rather
          // than a width-relative FractionallySizedBox.
          Positioned(
            bottom: -8,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 6),
              child: Container(
                width: AppTextStyles.fig(110),
                height: AppTextStyles.fig(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(
                  _slideController.value,
                );
                // Sequential, not simultaneous: the outgoing slide fades out
                // over the first half of the transition, the incoming one
                // only starts fading in over the second half. Fading both
                // at once (opacity 1-t / t the whole time) meant two
                // differently-hued photos — e.g. blue AC airflow over a
                // silver washing machine — sat semi-transparent on top of
                // each other simultaneously, which blends additively into a
                // muddy gray smear right where they overlap.
                final outOpacity = (1 - t * 2).clamp(0.0, 1.0);
                final inOpacity = (t * 2 - 1).clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: outOpacity,
                      child: FractionalTranslation(
                        translation: Offset(-t, 0),
                        child: _slideArt(_currentSlide),
                      ),
                    ),
                    if (t > 0)
                      Opacity(
                        opacity: inOpacity,
                        child: FractionalTranslation(
                          translation: Offset(1 - t, 0),
                          child: _slideArt(_nextSlide),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
