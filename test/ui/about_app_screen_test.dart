import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/screens/about_app_screen.dart';
import 'package:mighty_fitness/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('About App Screen Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    testWidgets('About App screen displays correctly', (WidgetTester tester) async {
      // Build the About App screen
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify the app bar title is displayed
      expect(find.text('About App'), findsOneWidget);

      // Verify key sections are present
      expect(find.text('About MightyFitness'), findsOneWidget);
      expect(find.text('Key Features'), findsOneWidget);
      expect(find.text('IRA - Your AI Assistant'), findsOneWidget);
      expect(find.text('Technical Information'), findsOneWidget);
      expect(find.text('Important Disclaimer'), findsOneWidget);
    });

    testWidgets('App header displays app information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app name and version are displayed
      expect(find.text('Dietary Guide'), findsOneWidget);
      expect(find.text('Your AI-Powered Wellness Companion'), findsOneWidget);
      expect(find.text('Version 1.0.0+12'), findsOneWidget);
    });

    testWidgets('Key features section displays all features', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify key features are listed
      expect(find.text('Smart Food Recognition'), findsOneWidget);
      expect(find.text('Meal Logging & Tracking'), findsOneWidget);
      expect(find.text('Progress Monitoring'), findsOneWidget);
      expect(find.text('Personalized Workouts'), findsOneWidget);
      expect(find.text('Goal-Based Planning'), findsOneWidget);
      expect(find.text('Smart Reminders'), findsOneWidget);
    });

    testWidgets('AI features section displays IRA capabilities', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AI features are listed
      expect(find.text('Personalized Nutrition Advice'), findsOneWidget);
      expect(find.text('Smart Health Insights'), findsOneWidget);
      expect(find.text('AI Meal Planning'), findsOneWidget);
      expect(find.text('Interactive Chat Support'), findsOneWidget);
      expect(find.text('Food Recognition'), findsOneWidget);
    });

    testWidgets('Technical information displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify technical information is displayed
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('AI Technology'), findsOneWidget);
      expect(find.text('Package Name'), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);
    });

    testWidgets('Disclaimer section is present and visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify disclaimer is displayed
      expect(find.text('Important Disclaimer'), findsOneWidget);
      expect(find.textContaining('This app is designed to support'), findsOneWidget);
      expect(find.textContaining('Always consult with qualified healthcare'), findsOneWidget);
    });

    testWidgets('Screen is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutAppScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the screen has a scrollable widget
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
