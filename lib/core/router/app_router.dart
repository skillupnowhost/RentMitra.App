import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../screens/ac_screen.dart';
import '../../screens/checkout_screen.dart';
import '../../screens/combo_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/my_rentals_screen.dart';
import '../../screens/offers_screen.dart';
import '../../screens/order_success_screen.dart';
import '../../screens/payment_screen.dart';
import '../../screens/product_details_screen.dart';
import '../../screens/products_catalog_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/refrigerator_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/splash_slider_screen.dart';
import '../../screens/washing_machine_screen.dart';
import '../../utils/cinematic_route.dart';

/// The app's full route table. Exported separately from [appRouter] so
/// tests can build a second, minimal `GoRouter` from the same table
/// (different `initialLocation`/`initialExtra`) without duplicating routes.
final List<RouteBase> appRoutes = [
  GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
  GoRoute(
    path: '/splash-slider',
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 560),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      child: const SplashSliderScreen(),
      transitionsBuilder: cinematicTransitionsBuilder,
    ),
  ),
  GoRoute(
    path: '/home',
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 560),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      child: const HomeScreen(),
      transitionsBuilder: cinematicTransitionsBuilder,
    ),
  ),
  GoRoute(path: '/ac', builder: (context, state) => const AcScreen()),
  GoRoute(
    path: '/refrigerator',
    builder: (context, state) => const RefrigeratorScreen(),
  ),
  GoRoute(
    path: '/washing-machine',
    builder: (context, state) => const WashingMachineScreen(),
  ),
  GoRoute(path: '/combo', builder: (context, state) => const ComboScreen()),
  GoRoute(
    path: '/catalog',
    builder: (context, state) => const ProductsCatalogScreen(),
  ),
  GoRoute(
    path: '/product-details',
    builder: (context, state) =>
        ProductDetailsScreen(product: state.extra as Product),
  ),
  GoRoute(
    path: '/checkout',
    builder: (context, state) {
      final extra = state.extra;
      return extra is CheckoutProduct
          ? CheckoutScreen(product: extra)
          : const CheckoutScreen();
    },
  ),
  GoRoute(
    path: '/payment',
    builder: (context, state) =>
        PaymentScreen(args: state.extra as PaymentScreenArgs),
  ),
  GoRoute(
    path: '/order-success',
    builder: (context, state) =>
        OrderSuccessScreen(order: state.extra as Order),
  ),
  GoRoute(
    path: '/my-rentals',
    builder: (context, state) => const MyRentalsScreen(),
  ),
  GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  GoRoute(path: '/offers', builder: (context, state) => const OffersScreen()),
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),
];

final GoRouter appRouter = GoRouter(
  routes: appRoutes,
  initialLocation: '/',
);
