import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexa_app/main.dart';

void main() {
  testWidgets('NexaApp shows the login screen when logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const NexaApp());
    await tester.pumpAndSettle();

    expect(find.text('NEXA'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
  });
}
