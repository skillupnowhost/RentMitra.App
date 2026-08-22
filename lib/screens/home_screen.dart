import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/whatsapp_launcher.dart';
import '../widgets/animated_service_icons.dart';
import '../widgets/appliance_art.dart';
import '../widgets/appliance_showcase_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/feature_strip.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _navIndex = 0;
  final GlobalKey _categorySectionKey = GlobalKey();

  /// Drives the hamburger menu end to end: the panel's slide-in, the
  /// backdrop's blur/dim, the hamburger↔close icon morph, and each drawer
  /// row's staggered entrance (see [AppDrawer]) — one controller so all of
  /// it reads as a single deliberate motion instead of separate effects.
  late final AnimationController _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocationController.instance.autoDetectOnce();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _menuController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationController.instance.recheckIfNeeded();
    }
  }

  void _openMenu() => _menuController.forward();
  void _closeMenu() => _menuController.reverse();

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
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              AppTextStyles.fig(16),
                              0,
                              AppTextStyles.fig(16),
                              AppTextStyles.fig(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroBanner(onExplore: _scrollToCategories),
                                SizedBox(height: AppTextStyles.fig(10)),
                                KeyedSubtree(
                                  key: _categorySectionKey,
                                  child: _sectionTitle('Shop by Category'),
                                ),
                                // Fixed (not fig-scaled) so it reliably clears
                                // the Combo Plans card's "Best Value" badge,
                                // which floats above that card's top edge.
                                const SizedBox(height: 20),
                                _sectionCategoryGrid(),
                                SizedBox(height: AppTextStyles.fig(20)),
                                PromoBanner(onViewCombos: _openCombos),
                                SizedBox(height: AppTextStyles.fig(14)),
                                _sectionShowcaseCards(),
                                SizedBox(height: AppTextStyles.fig(20)),
                                const FeatureStrip(),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          Positioned(
                            right: AppTextStyles.fig(16),
                            bottom: AppTextStyles.fig(16),
                            child: const _FloatingSupportButtons(),
                          ),
                        ],
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
          _MenuBackdrop(animation: _menuController, onTap: _closeMenu),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: _AnimatedDrawerPanel(
              animation: _menuController,
              child: AppDrawer(animation: _menuController, onClose: _closeMenu),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          GestureDetector(
            onTap: _openMenu,
            behavior: HitTestBehavior.opaque,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _menuController,
              color: AppColors.navy,
              size: 17,
            ),
          ),
          SizedBox(width: AppTextStyles.fig(10)),
          const LogoMark(width: 21),
          SizedBox(width: AppTextStyles.fig(7)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    // .end (not .center) so the ".app" pill's bottom edge
                    // lines up with the bottom of "Rent"/"Mitra" instead of
                    // floating mid-height — matches the main lockup in
                    // logo_full.png, where the badge sits on the wordmark's
                    // baseline rather than centered beside it.
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rent',
                        style: AppTextStyles.of(
                          figmaSize: 20,
                          weight: FontWeight.w700,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      Text(
                        'Mitra',
                        style: AppTextStyles.of(
                          figmaSize: 20,
                          weight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                      Padding(
                        // Nudges the pill down those last couple of px so it
                        // truly sits on the letters' bottom edge rather than
                        // just close to it — the Row's own .end alignment
                        // gets it close but the pill's rounded padding still
                        // reads as slightly high without this.
                        padding: EdgeInsets.only(
                          left: AppTextStyles.fig(1),
                          bottom: AppTextStyles.fig(0.5),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTextStyles.fig(3.5),
                            vertical: AppTextStyles.fig(2),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '.app',
                            style: AppTextStyles.of(
                              figmaSize: 7.5,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'RENT MADE EASY',
                  style: AppTextStyles.of(
                    figmaSize: 9,
                    weight: FontWeight.w500,
                    color: AppColors.textGraySoft,
                    letterSpacing: 1.2,
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
              iconColor: AppColors.categoryBlue,
              priceColor: AppColors.categoryBlue,
              bgColor: AppColors.bgCardPurple,
              iconAnimationDelay: const Duration(milliseconds: 0),
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
              iconColor: AppColors.categoryGreen,
              priceColor: AppColors.categoryGreen,
              bgColor: AppColors.bgCardNeutral,
              iconAnimationDelay: const Duration(milliseconds: 150),
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
              iconColor: AppColors.categoryOrange,
              priceColor: AppColors.categoryOrange,
              bgColor: AppColors.bgCardPeach,
              iconAnimationDelay: const Duration(milliseconds: 300),
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
              iconAnimationDelay: const Duration(milliseconds: 450),
              onTap: _openCombos,
            ),
          ),
        ],
      ),
    );
  }

  /// The three appliance cards — Smart Inverter Split AC, Refrigerator and
  /// Washing Machine — side by side in one row, each a compact checklist +
  /// product photo + variant-tabs card.
  Widget _sectionShowcaseCards() {
    // Plain Row with top-aligned cards rather than IntrinsicHeight +
    // stretch: forcing all three to one shared intrinsic height is fragile
    // once Google Fonts' Inter face swaps in after the fallback font's
    // first layout pass — the two passes' line metrics can differ just
    // enough to overflow the row's cached height by a few pixels. Card
    // content is symmetric enough (3 checklist items each) that natural
    // heights land within a pixel of each other anyway.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ApplianceShowcaseCard(
            title: 'Smart Inverter\nSplit AC',
            titleColor: AppColors.titleBlue,
            checklist: const [
              'Powerful cooling',
              'Low power consumption',
              'Smart Plug Included',
            ],
            images: const [
              AcProductImage(width: 105),
              AcProductImage(width: 105),
            ],
            tabs: const ['1 Ton', '1.5 Ton'],
            tabIcon: Icons.ac_unit,
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const AcScreen())),
          ),
        ),
        SizedBox(width: AppTextStyles.fig(8)),
        Expanded(
          child: ApplianceShowcaseCard(
            title: 'Refrigerator',
            titleColor: AppColors.titleGreen,
            checklist: const [
              'Freshness that lasts longer.',
              'Energy efficient',
              'Spacious storage',
            ],
            images: const [
              FridgeSingleDoorProductImage(width: 85),
              FridgeProductImage(width: 85),
            ],
            tabs: const ['Single Door', 'Double Door'],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RefrigeratorScreen()),
            ),
          ),
        ),
        SizedBox(width: AppTextStyles.fig(8)),
        Expanded(
          child: ApplianceShowcaseCard(
            title: 'Washing Machine',
            titleColor: AppColors.titleTerracotta,
            checklist: const [
              'Powerful cleaning',
              'Multiple wash programs',
              'Gentle on clothes',
            ],
            images: const [
              WasherTopLoadProductImage(width: 90, height: 85),
              WasherProductImage(width: 90, height: 85),
            ],
            tabs: const ['Top Load', 'Front Load'],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WashingMachineScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dimmed, blurred scrim behind the hamburger menu — tapping it closes the
/// menu. Skips painting entirely once fully closed so it never eats touches
/// meant for the home screen underneath.
class _MenuBackdrop extends StatelessWidget {
  const _MenuBackdrop({required this.animation, required this.onTap});

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        if (animation.value == 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 4 * animation.value,
                sigmaY: 4 * animation.value,
              ),
              child: Container(
                color: AppColors.navyDeep.withValues(
                  alpha: 0.45 * animation.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Slides [child] in from the left on an eased curve and stops it from
/// intercepting touches while fully closed.
class _AnimatedDrawerPanel extends StatelessWidget {
  const _AnimatedDrawerPanel({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(animation.value);
        return IgnorePointer(
          ignoring: animation.value == 0,
          child: Transform.translate(
            offset: Offset((curved - 1) * 263, 0),
            child: child,
          ),
        );
      },
      child: child,
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
      padding: const EdgeInsets.fromLTRB(14, 5, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroBanner,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A true 50/50 split — text and product art get equal width — with
          // a taller floor via the outer [ConstrainedBox] so the image
          // slider renders large and dominant instead of shrinking to the
          // text column's natural height. [BoxFit.contain] on the slides
          // themselves still guarantees nothing is ever cropped. Kept
          // compact (client feedback: the hero was eating the whole first
          // screen) so "Shop by Category" lands within the same viewport.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 158),
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
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Rent Smart.\n',
                                style: AppTextStyles.of(
                                  figmaSize: 22,
                                  weight: FontWeight.w800,
                                  color: AppColors.navy,
                                  height: 1.08,
                                ),
                              ),
                              TextSpan(
                                text: 'Live Easy.',
                                style: AppTextStyles.of(
                                  figmaSize: 24,
                                  weight: FontWeight.w800,
                                  color: AppColors.purple,
                                  height: 1.08,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Premium Appliances on Rent at affordable prices.',
                          style: AppTextStyles.of(
                            figmaSize: 11,
                            weight: FontWeight.w500,
                            color: AppColors.textGray,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navyDeep,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDeep.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
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
                                  figmaSize: 10,
                                  weight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
                DeliveryTruckIcon(size: 10, startDelay: delay),
          ),
        ),
        Expanded(
          child: _HeroBenefitItem(
            label: 'Free\nInstallation',
            iconBuilder: (delay) =>
                InstallationIcon(size: 10, startDelay: delay),
            startDelay: const Duration(milliseconds: 150),
          ),
        ),
        Expanded(
          child: _HeroBenefitItem(
            label: 'Service &\nMaintenance',
            iconBuilder: (delay) =>
                MaintenanceIcon(size: 10, startDelay: delay),
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
  });

  final Widget Function(Duration delay) iconBuilder;
  final String label;
  final Duration startDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(child: iconBuilder(startDelay)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.of(
            figmaSize: 8,
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
    'assets/images/main_splash.png',
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
                width: AppTextStyles.fig(170),
                height: AppTextStyles.fig(170),
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
                width: AppTextStyles.fig(85),
                height: AppTextStyles.fig(13),
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

/// Bottom-right floating support stack — replaces the old inline "Need
/// Help?" card. Pinned to the same screen corner regardless of scroll
/// position (a [Positioned] sibling of the scroll view, not part of its
/// content) so support is always one tap away without eating vertical space
/// in the feed. The small purple "Need Help" launcher sits above the
/// primary green WhatsApp action, mirroring the common chat-widget pattern.
class _FloatingSupportButtons extends StatelessWidget {
  const _FloatingSupportButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FloatingActionCircle(
          diameter: 46,
          background: Colors.white,
          onTap: () => _showHelpSheet(context),
          child: Image.asset(
            'assets/images/Need help.png',
            width: 21,
            height: 21,
            color: AppColors.purple,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 10),
        _FloatingActionCircle(
          diameter: 50,
          background: Colors.white,
          onTap: launchSupportWhatsAppChat,
          child: Image.asset(
            'assets/images/whatsapp icon.png',
            width: 26,
            height: 26,
          ),
        ),
      ],
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: AppTextStyles.of(
                figmaSize: 18,
                weight: FontWeight.w700,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Our team is here to assist you.',
              style: AppTextStyles.of(
                figmaSize: 13,
                weight: FontWeight.w400,
                color: AppColors.textGrayMed,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                launchSupportWhatsAppChat();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                    Image.asset(
                      'assets/images/whatsapp icon.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chat on WhatsApp',
                      style: AppTextStyles.of(
                        figmaSize: 14,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingActionCircle extends StatelessWidget {
  const _FloatingActionCircle({
    required this.diameter,
    required this.background,
    required this.onTap,
    required this.child,
  });

  final double diameter;
  final Color background;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
