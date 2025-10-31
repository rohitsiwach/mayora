// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mayora/firebase_options.dart';
import 'package:mayora/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // ignore if already initialized in a previous test run
    }
  }

  testWidgets('Mayora boots to Sign In for unauthenticated users', (
    WidgetTester tester,
  ) async {
    await _initFirebase();

    await tester.pumpWidget(const MayoraApp());
    // Allow the auth stream to emit and UI to settle
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Expect sign-in screen content
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign in to continue to Mayora'), findsOneWidget);
  });

  testWidgets('Mayora MaterialApp renders without crashing', (
    WidgetTester tester,
  ) async {
    await _initFirebase();

    await tester.pumpWidget(const MayoraApp());
    await tester.pump(const Duration(milliseconds: 100));

    // We should at least have a MaterialApp in the tree
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
