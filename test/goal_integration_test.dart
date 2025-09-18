import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/store/UserStore/UserStore.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('Goal Integration Tests', () {
    late UserStore userStore;

    setUpAll(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    setUp(() {
      userStore = UserStore();
    });

    test('UserStore should save and retrieve goal correctly', () async {
      // Test goal setting
      const testGoal = 'lose_weight';
      await userStore.setGoal(testGoal);

      expect(userStore.goal, equals(testGoal));
    });

    test('AI Service should use user goal in personalized responses', () async {
      // Create a test user profile with a specific goal
      final profile = UserProfile(
        name: 'Test User',
        age: 25,
        gender: 'male',
        weight: 70.0,
        height: 175.0,
        goal: 'lose_weight',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      // Test personalized greeting
      final greeting = await getPersonalizedGreeting(profile, 'energetic');
      expect(greeting.toLowerCase(), anyOf([
        contains('lose'),
        contains('weight loss'),
        contains('loss')
      ]));

      // Test motivational message
      final motivation = await getMotivationalMessage(profile, 'daily_check_in');
      expect(motivation, isNotEmpty);

      // Test meal plan generation
      final mealPlan = await generateMealPlan(profile, <MealEntry>[]);
      expect(mealPlan.toLowerCase(), anyOf([
        contains('lose'),
        contains('weight loss'),
        contains('loss')
      ]));
    });

    test('AI Service should handle different goal types', () async {
      final goals = ['lose_weight', 'gain_weight', 'maintain_healthy_lifestyle', 'gain_muscles'];
      
      for (final goal in goals) {
        final profile = UserProfile(
          name: 'Test User',
          age: 25,
          gender: 'male',
          weight: 70.0,
          height: 175.0,
          goal: goal,
          exerciseDuration: 30,
          diseases: [],
          dietaryPreferences: [],
          isSmoker: false,
        );

        final greeting = await getPersonalizedGreeting(profile, 'energetic');
        expect(greeting, isNotEmpty);
        // Just verify the greeting is personalized and contains goal-related content
        expect(greeting.toLowerCase(), anyOf([
          contains('goal'),
          contains('weight'),
          contains('muscle'),
          contains('healthy'),
          contains('fitness')
        ]));
      }
    });

    test('Mock responses should include goal-specific content', () {
      final profile = UserProfile(
        name: 'Test User',
        age: 25,
        gender: 'male',
        weight: 70.0,
        height: 175.0,
        goal: 'gain_muscles',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final greeting = MockResponses.greeting(profile, 'energetic');
      expect(greeting.toLowerCase(), contains('gain muscles'));
      
      final motivation = MockResponses.motivation(profile, 'daily_check_in');
      expect(motivation, isNotEmpty);
      
      final mealPlan = MockResponses.mealPlan(profile);
      expect(mealPlan.toLowerCase(), contains('gain muscles'));
      
      final healthInsights = MockResponses.healthInsights(profile);
      expect(healthInsights.toLowerCase(), contains('gain muscles'));
    });
  });
}
