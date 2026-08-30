import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:rentmitra_app/core/router/app_router.dart';
import 'package:rentmitra_app/models/order.dart';
import 'package:rentmitra_app/models/product.dart';
import 'package:rentmitra_app/providers/order_provider.dart';
import 'package:rentmitra_app/screens/ac_screen.dart';
import 'package:rentmitra_app/screens/checkout_screen.dart';
import 'package:rentmitra_app/screens/home_screen.dart';
import 'package:rentmitra_app/screens/onboarding_screen.dart';

/// Pumps every screen at a set of real device widths (the narrowest common
/// phones through a small tablet) and asserts nothing threw — catches
/// RenderFlex overflow and layout exceptions that `flutter analyze` can't
/// see, without needing a browser or display.
///
/// Every screen except `Onboarding` (dead code, not reachable from the app,
/// exercised only by its own dedicated test below) now navigates via
/// `context.go`/`context.push`, which requires a `GoRouter` ancestor — so
/// each is pumped through a real (minimal) `GoRouter` built from the app's
/// own [appRoutes], not a bare `MaterialApp`. Screens that read
/// `OrderProvider` (MyRentals, OrderSuccess) also need that provider above
/// the router, exactly as `main.dart` wires it in production.
void main() {
  // Prevents google_fonts from attempting a real network fetch in the test
  // sandbox (no internet access here), which otherwise stalls every test
  // that renders text until the 10-minute per-test timeout fires.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const sizes = [
    Size(320, 690), // iPhone SE
    Size(360, 800), // common small Android
    Size(390, 844), // iPhone 12/13/14
    Size(430, 932), // iPhone 14 Pro Max
    Size(600, 1024), // small tablet
  ];

  final sampleProduct = Product(
    badge: '1 Ton',
    title: 'Smart Inverter Split AC',
    description: 'Sample product for widget tests.',
    checklist: const ['Powerful cooling'],
    art: const Icon(Icons.ac_unit),
    price: '₹999',
    checkoutProduct: CheckoutProduct.acOneTon,
  );

  final sampleOrder = Order(
    id: 'TEST-ORDER-1',
    productName: 'Smart Inverter Split AC',
    amount: 999,
    paymentMethod: 'UPI',
    placedAt: DateTime(2026, 1, 1),
  );

  // name -> (route path, extra). `null` path means "pump the widget
  // directly, no router" — only Onboarding, which isn't a registered route.
  final screens = <String, (String?, Object?)>{
    'Splash': ('/', null),
    'Splash Slider': ('/splash-slider', null),
    'Onboarding': (null, null),
    'Home': ('/home', null),
    'AC': ('/ac', null),
    'Refrigerator': ('/refrigerator', null),
    'Washing Machine': ('/washing-machine', null),
    'Combo': ('/combo', null),
    'Product Details': ('/product-details', sampleProduct),
    'Checkout': ('/checkout', CheckoutProduct.acOneTon),
    'Payment': ('/payment', CheckoutProduct.acOneTon),
    'Order Success': ('/order-success', sampleOrder),
    'My Rentals': ('/my-rentals', null),
    'Profile': ('/profile', null),
    'Offers': ('/offers', null),
    'Settings': ('/settings', null),
  };

  Widget pumpableFor(String? path, Object? extra) {
    if (path == null) {
      return const MaterialApp(home: OnboardingScreen());
    }
    return ChangeNotifierProvider<OrderProvider>(
      create: (_) => OrderProvider(),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: appRoutes,
          initialLocation: path,
          initialExtra: extra,
        ),
      ),
    );
  }

  for (final size in sizes) {
    group('at ${size.width.toInt()}x${size.height.toInt()}', () {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} renders without overflow', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final (path, extra) = entry.value;
          await tester.pumpWidget(pumpableFor(path, extra));
          // Home kicks off a fire-and-forget, timeout-bounded GPS lookup in
          // initState, and Splash/Splash Slider auto-advance on their own
          // timers; flush well past all of those bounds so no fake-async
          // Timer outlives the widget tree teardown.
          await tester.pump(const Duration(seconds: 13));

          expect(tester.takeException(), isNull);
        }, timeout: const Timeout(Duration(seconds: 30)));
      }
    });
  }

  testWidgets(
    'Onboarding: swipe through all 3 slides reaches Home via Get Started',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Skip'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.text('Get Started'));
      // Home has several continuously-repeating decorative animations
      // (glow, float, rotate…), so pumpAndSettle would never converge —
      // pump a bounded number of frames past the page transition instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Home: tapping the AC category card navigates to AcScreen and back',
    (tester) async {
      await tester.pumpWidget(pumpableFor('/home', null));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Smart Inverter Split AC').first);
      // Home has continuously-repeating decorative animations, so
      // pumpAndSettle would never converge — bounded pump instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(AcScreen), findsOneWidget);
      expect(find.text('1 Ton'), findsWidgets);
      expect(find.text('1.5 Ton'), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_back));
      // Back on Home, whose animations still repeat forever.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Combo: tapping a card opens Product Details with the appliance '
    'breakdown, discount price and combo CTA',
    (tester) async {
      await tester.pumpWidget(pumpableFor('/combo', null));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Choose Your Perfect Home Combo'), findsWidgets);
      expect(find.text('Smart Living Combo'), findsOneWidget);
      expect(find.text('Family Essentials Combo'), findsOneWidget);
      expect(find.text('Premium Family Combo'), findsOneWidget);
      expect(find.text('Ultimate Premium Combo'), findsOneWidget);
      expect(find.text('Compare Combo Plans'), findsOneWidget);

      await tester.tap(find.text('Rent This Combo').first);
      await tester.pumpAndSettle();

      expect(find.text('Air Conditioner'), findsOneWidget);
      expect(find.text('Refrigerator'), findsOneWidget);
      expect(find.text('Washing Machine'), findsOneWidget);
      expect(find.text('₹2,597'), findsOneWidget);
      expect(find.text('10% OFF'), findsOneWidget);
      // The final price renders inside a RichText (price + "/month + GST"
      // as separate TextSpans), so find.text (Text widgets only) can't see
      // it — match on the RichText's flattened plain text instead.
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('₹2,337'),
        ),
        findsOneWidget,
      );
      expect(find.text('Rent This Combo'), findsOneWidget);
    },
  );

  testWidgets('Home: tapping the location chip opens the picker sheet', (
    tester,
  ) async {
    await tester.pumpWidget(pumpableFor('/home', null));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Chennai').first);
    // Home has continuously-repeating decorative animations, so
    // pumpAndSettle would never converge — bounded pump instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Select Your Location'), findsOneWidget);
    expect(find.text('Use current location'), findsOneWidget);
    expect(find.text('Tamil Nadu'), findsOneWidget);
    expect(find.text('Madurai'), findsOneWidget);

    // "Other States" and its cities are further down the grouped list;
    // scroll incrementally (row heights aren't worth hardcoding) until one
    // comes into view.
    for (
      var i = 0;
      i < 10 && find.text('Bangalore').evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
    }

    expect(find.text('Bangalore'), findsOneWidget);
  });
}
