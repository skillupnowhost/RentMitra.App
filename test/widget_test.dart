import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentmitra_app/main.dart';
import 'package:rentmitra_app/screens/splash_screen.dart';

void main() {
  testWidgets('App renders the splash screen on launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RentMitraApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.image(const AssetImage('assets/images/logo_full.png')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
