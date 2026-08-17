import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rentmitra_app/screens/ac_screen.dart';
import 'package:rentmitra_app/screens/combo_screen.dart';
import 'package:rentmitra_app/screens/home_screen.dart';
import 'package:rentmitra_app/screens/onboarding_screen.dart';
import 'package:rentmitra_app/screens/refrigerator_screen.dart';
import 'package:rentmitra_app/screens/splash_screen.dart';
import 'package:rentmitra_app/screens/splash_slider_screen.dart';
import 'package:rentmitra_app/screens/washing_machine_screen.dart';

/// Pumps every screen at a set of real device widths (the narrowest common
/// phones through a small tablet) and asserts nothing threw — catches
/// RenderFlex overflow and layout exceptions that `flutter analyze` can't
/// see, without needing a browser or display.
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

  final screens = <String, WidgetBuilder>{
    'Splash': (_) => const SplashScreen(),
    'Splash Slider': (_) => const SplashSliderScreen(),
    'Onboarding': (_) => const OnboardingScreen(),
    'Home': (_) => const HomeScreen(),
    'AC': (_) => const AcScreen(),
    'Refrigerator': (_) => const RefrigeratorScreen(),
    'Washing Machine': (_) => const WashingMachineScreen(),
    'Combo': (_) => const ComboScreen(),
  };

  for (final size in sizes) {
    group('at ${size.width.toInt()}x${size.height.toInt()}', () {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} renders without overflow', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(home: Builder(builder: entry.value)),
          );
          // Home kicks off a fire-and-forget, timeout-bounded GPS lookup in
          // initState; flush well past that bound so its fake-async Timer
          // doesn't outlive the widget tree teardown.
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
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Home: tapping the AC category card navigates to AcScreen and back',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Smart Inverter Split AC').first);
      await tester.pumpAndSettle();

      expect(find.byType(AcScreen), findsOneWidget);
      expect(find.text('1 Ton'), findsWidgets);
      expect(find.text('1.5 Ton'), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('Home: tapping the location chip opens the picker sheet', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Chennai').first);
    await tester.pumpAndSettle();

    expect(find.text('Select Your Location'), findsOneWidget);
    expect(find.text('Use current location'), findsOneWidget);
    expect(find.text('Bangalore'), findsOneWidget);
  });
}
