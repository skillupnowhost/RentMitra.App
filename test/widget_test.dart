import 'package:flutter_test/flutter_test.dart';

import 'package:rentmitra_app/main.dart';

void main() {
  testWidgets('App renders the splash screen on launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RentMitraApp());
    await tester.pump();

    expect(find.text('RENT MADE EASY'), findsOneWidget);
  });
}
