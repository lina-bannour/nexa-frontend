// Basic smoke test for the real app. The default `flutter create` template
// test (testing a counter app that doesn't exist in this project, and
// referencing a `MyApp` class that was never here) was left in place
// unmodified and failed to even compile.
//
// This replaces it with a minimal smoke test: with no stored session, the
// app should boot straight into the login screen rather than crashing or
// showing a blank page.

import 'package:flutter/material.dart';
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
