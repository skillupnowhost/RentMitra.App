import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../services/api_service.dart';

// ============================================================
// CUSTOMER SCREENS
// ============================================================

import '../../screens/ac_screen.dart';
import '../../screens/checkout_screen.dart';
import '../../screens/combo_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/my_rentals_screen.dart';
import '../../screens/offers_screen.dart';
import '../../screens/product_details_screen.dart';
import '../../screens/products_catalog_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/refrigerator_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/splash_slider_screen.dart';
import '../../screens/washing_machine_screen.dart';

import '../../utils/cinematic_route.dart';

// ============================================================
// ADMIN SCREENS
// ============================================================

import '../../admin/screens/admin_dashboard_screen.dart';
import '../../admin/screens/admin_orders_screen.dart';
import '../../admin/screens/admin_customers_screen.dart';
import '../../admin/screens/admin_products_screen.dart';
import '../../admin/screens/admin_variants_screen.dart';
import '../../admin/screens/admin_payments_screen.dart';
import '../../admin/screens/admin_rentals_screen.dart';
import '../../admin/screens/admin_installations_screen.dart';
import '../../admin/screens/admin_addresses_screen.dart';
import '../../admin/screens/admin_login_screen.dart';

// ============================================================
// ADMIN ROUTE AUTHORIZATION
// ============================================================
//
// This checks whether the currently signed-in Firebase user
// is actually authorized as an admin by the backend.
//
// IMPORTANT:
// We do NOT hardcode the admin email here.
//
// The existing backend endpoint:
//
// POST /auth/admin-login
//
// performs the real admin authorization using ADMIN_EMAIL
// from the backend .env file.
//
// Therefore:
//
// Firebase user
//      ↓
// Firebase ID token
//      ↓
// ApiService.firebaseAdminLogin()
//      ↓
// Backend /auth/admin-login
//      ↓
// Authorized admin?
// ============================================================

Future<bool> _isAuthorizedAdmin() async {
  try {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // No Firebase user means the user is not logged in.
    if (firebaseUser == null) {
      return false;
    }

    // Get the current Firebase ID token.
    final idToken = await firebaseUser.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      return false;
    }

    // Reuse the existing backend admin authentication.
    final response = await ApiService.firebaseAdminLogin(
      idToken: idToken,
    );

    // Backend returns:
    //
    // {
    //   success: true,
    //   message: "Admin login successful",
    //   admin: {
    //      email: "...",
    //      role: "admin"
    //   }
    // }
    //
    // We additionally check the success field so that
    // an unexpected response cannot authorize the route.
    return response['success'] == true;
  } catch (error) {
    debugPrint('Admin route authorization failed: $error');
    return false;
  }
}

// ============================================================
// ROUTE TABLE
// ============================================================

final List<RouteBase> appRoutes = [
  // ==========================================================
  // CUSTOMER ROUTES
  // ==========================================================

  GoRoute(
    path: '/',
    builder: (context, state) => const SplashScreen(),
  ),

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

  GoRoute(
    path: '/ac',
    builder: (context, state) => const AcScreen(),
  ),

  GoRoute(
    path: '/refrigerator',
    builder: (context, state) => const RefrigeratorScreen(),
  ),

  GoRoute(
    path: '/washing-machine',
    builder: (context, state) => const WashingMachineScreen(),
  ),

  GoRoute(
    path: '/combo',
    builder: (context, state) => const ComboScreen(),
  ),

  GoRoute(
    path: '/catalog',
    builder: (context, state) => const ProductsCatalogScreen(),
  ),

  GoRoute(
    path: '/product-details',
    builder: (context, state) {
      final product = state.extra;

      if (product is Product) {
        return ProductDetailsScreen(product: product);
      }

      return const ProductsCatalogScreen();
    },
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
    path: '/login',
    builder: (context, state) => const LoginScreen(),
  ),

  GoRoute(
    path: '/my-rentals',
    builder: (context, state) => const MyRentalsScreen(),
  ),

  GoRoute(
    path: '/profile',
    builder: (context, state) => const ProfileScreen(),
  ),

  GoRoute(
    path: '/offers',
    builder: (context, state) => const OffersScreen(),
  ),

  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),

  // ==========================================================
  // ADMIN LOGIN
  // ==========================================================
  //
  // This route MUST remain public.
  //
  // A logged-out admin needs to be able to reach this page
  // before authenticating.
  //
  GoRoute(
    path: '/admin-login',
    name: 'admin-login',
    builder: (context, state) => const AdminLoginScreen(),
  ),

  // ==========================================================
  // ADMIN DASHBOARD
  // ==========================================================

  GoRoute(
    path: '/admin',
    builder: (context, state) => const AdminDashboardScreen(),
  ),

  // ==========================================================
  // ADMIN ORDERS
  // ==========================================================

  GoRoute(
    path: '/admin/orders',
    builder: (context, state) => const AdminOrdersScreen(),
  ),

  // ==========================================================
  // ADMIN CUSTOMERS
  // ==========================================================

  GoRoute(
    path: '/admin/customers',
    builder: (context, state) => const AdminCustomersScreen(),
  ),

  // ==========================================================
  // ADMIN PRODUCTS
  // ==========================================================

  GoRoute(
    path: '/admin/products',
    builder: (context, state) => const AdminProductsScreen(),
  ),

  // ==========================================================
  // ADMIN VARIANTS
  // ==========================================================

  GoRoute(
    path: '/admin/variants',
    builder: (context, state) => const AdminVariantsScreen(),
  ),

  // ==========================================================
  // ADMIN PAYMENTS
  // ==========================================================

  GoRoute(
    path: '/admin/payments',
    builder: (context, state) => const AdminPaymentsScreen(),
  ),

  // ==========================================================
  // ADMIN RENTALS
  // ==========================================================

  GoRoute(
    path: '/admin/rentals',
    builder: (context, state) => const AdminRentalsScreen(),
  ),

  // ==========================================================
  // ADMIN INSTALLATIONS
  // ==========================================================

  GoRoute(
    path: '/admin/installations',
    builder: (context, state) => const AdminInstallationsScreen(),
  ),

  // ==========================================================
  // ADMIN ADDRESSES
  // ==========================================================

  GoRoute(
    path: '/admin/addresses',
    builder: (context, state) => const AdminAddressesScreen(),
  ),
];

// ============================================================
// GO ROUTER
// ============================================================

final GoRouter appRouter = GoRouter(
  routes: appRoutes,

  // Keep the existing customer startup flow.
  initialLocation: '/',

  // ==========================================================
  // GLOBAL ROUTE GUARD
  // ==========================================================

  redirect: (context, state) async {
    final location = state.matchedLocation;

    // --------------------------------------------------------
    // ADMIN LOGIN IS ALWAYS ACCESSIBLE
    // --------------------------------------------------------

    if (location == '/admin-login') {
      return null;
    }

    // --------------------------------------------------------
    // CHECK WHETHER THIS IS AN ADMIN ROUTE
    // --------------------------------------------------------

    final isAdminRoute =
        location == '/admin' || location.startsWith('/admin/');

    // --------------------------------------------------------
    // CUSTOMER ROUTES ARE NOT AFFECTED
    // --------------------------------------------------------

    if (!isAdminRoute) {
      return null;
    }

    // --------------------------------------------------------
    // ADMIN ROUTE
    // --------------------------------------------------------
    //
    // Verify Firebase user + backend admin authorization.
    //

    final isAuthorized = await _isAuthorizedAdmin();

    if (isAuthorized) {
      // Authorized admin can continue normally.
      return null;
    }

    // --------------------------------------------------------
    // NOT AUTHORIZED
    // --------------------------------------------------------
    //
    // Prevent direct access to:
    //
    // /admin
    // /admin/orders
    // /admin/customers
    // /admin/products
    // /admin/variants
    // /admin/payments
    // /admin/rentals
    // /admin/installations
    // /admin/addresses
    //
    // Send the user to the existing admin login screen.
    //

    return '/admin-login';
  },
);