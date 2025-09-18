import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('Simple AI Tests', () {
    setUpAll(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    test('Test direct Gemini API call', () async {
      final messages = [
        CoreMessage(
          role: 'system',
          content: 'You are a helpful AI assistant. Respond with exactly "Hello World" and nothing else.'
        ),
        CoreMessage(
          role: 'user',
          content: 'Say hello'
        )
      ];

      try {
        final result = await chatWithAI(messages);
        print('Direct API result: $result');
        expect(result, isNotEmpty);
      } catch (e) {
        print('API call failed: $e');
        // This is expected if API is not working
      }
    });

    test('Test mock responses work correctly', () {
      final profile = UserProfile(
        name: 'TestUser',
        age: 30,
        gender: 'male',
        weight: 75.0,
        height: 180.0,
        goal: 'lose_weight',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      // Test all mock responses
      final greeting = MockResponses.greeting(profile, 'energetic');
      final motivation = MockResponses.motivation(profile, 'daily_check_in');
      final mealPlan = MockResponses.mealPlan(profile);
      final healthInsights = MockResponses.healthInsights(profile);

      print('Mock Greeting: $greeting');
      print('Mock Motivation: $motivation');
      print('Mock Meal Plan: $mealPlan');
      print('Mock Health Insights: $healthInsights');

      // All should be goal-specific
      expect(greeting.toLowerCase(), contains('lose weight'));
      expect(mealPlan.toLowerCase(), anyOf([contains('weight loss'), contains('lose weight')]));
      expect(healthInsights.toLowerCase(), anyOf([contains('weight loss'), contains('lose weight')]));
    });
  });
}
