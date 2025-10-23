// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mayora/main.dart';

void main() {
  testWidgets('Mayora app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MayoraApp());

    // Wait for splash screen animation to complete
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that we're on the home page with counter at 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('Welcome to Mayora!'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Mayora home page direct test', (WidgetTester tester) async {
    // Test the home page directly without splash screen
    await tester.pumpWidget(
      MaterialApp(
        home: const MayoraHomePage(title: 'Mayora'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF673AB7)),
        ),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Welcome to Mayora!'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('1'), findsOneWidget);
  });
}
