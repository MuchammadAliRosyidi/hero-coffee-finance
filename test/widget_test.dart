import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hero_coffee_finance/app.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HeroCoffeeFinanceApp());
    await tester.pumpAndSettle();

    expect(find.text('Hero Coffee Finance'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
