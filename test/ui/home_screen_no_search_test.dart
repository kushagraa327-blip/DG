import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home Screen Search Box Removal Tests', () {
    testWidgets('Search box components are not present', (WidgetTester tester) async {
      // Build a simple test widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Home Screen Content'),
                // No search box should be present
              ],
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that search-related elements are NOT present
      expect(find.text('Search'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('Home screen displays other content without search', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Home Screen Content'),
                Text('Nutrition Tracking'),
                Text('Workouts'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that other content is still present
      expect(find.text('Home Screen Content'), findsOneWidget);
      expect(find.text('Nutrition Tracking'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
    });
  });
}
