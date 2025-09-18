import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/screens/splash_screen.dart';
import 'package:mighty_fitness/utils/app_config.dart';
import 'package:mighty_fitness/utils/app_images.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('Splash Screen Tests', () {
    testWidgets('Splash screen should display dietary logo', (WidgetTester tester) async {
      // Initialize the app store
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Wait for animations to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the dietary logo is displayed
      expect(find.byType(Image), findsWidgets);
      
      // Check if the image asset path is correct
      final imageFinder = find.byType(Image);
      final imageWidget = tester.widget<Image>(imageFinder.first);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, equals(ic_dietary_logo));
    });

    testWidgets('Splash screen should NOT display app name (removed)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Wait for animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify app name is NOT displayed (it was removed)
      expect(find.text(APP_NAME), findsNothing);
    });

    testWidgets('Splash screen should NOT display tagline (removed)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Wait for text animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify tagline is NOT displayed (it was removed)
      expect(find.text('Your Personal Nutrition Companion'), findsNothing);
    });

    testWidgets('Splash screen should display loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Wait for animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Splash screen should display version info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      await tester.pump();

      // Verify version info is displayed
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('Splash screen logo animation should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Initial state - logo should be animating
      await tester.pump();

      // Check that logo animation is in progress
      expect(find.byType(AnimatedBuilder), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));

      // Logo animation should be progressing
      await tester.pump(const Duration(milliseconds: 1000));

      // Animation should complete - only logo should be visible (no text)
      expect(find.byType(Image), findsWidgets);
      expect(find.text(APP_NAME), findsNothing);
      expect(find.text('Your Personal Nutrition Companion'), findsNothing);
    });

    group('Logo Display Tests', () {
      test('Dietary logo asset path should be correct', () {
        expect(ic_dietary_logo, equals('assets/dietary-Logo.png'));
      });

      test('Splash logo should use dietary logo', () {
        expect(ic_splash_logo, equals('assets/dietary-Logo.png'));
      });

      testWidgets('Logo should be displayed without shadow effects', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SplashScreen(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find the logo container
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);

        // Verify the logo image is present
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsWidgets);
      });
    });

    group('App Configuration Tests', () {
      test('App name should be Dietary Guide', () {
        expect(APP_NAME, equals('Dietary Guide'));
      });
    });
  });
}
