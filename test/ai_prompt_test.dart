import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('AI Prompt Tests', () {
    setUpAll(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    test('AI should generate goal-specific greeting', () async {
      final profile = UserProfile(
        name: 'John',
        age: 30,
        gender: 'male',
        weight: 80.0,
        height: 180.0,
        goal: 'lose_weight',
        exerciseDuration: 45,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final greeting = await getPersonalizedGreeting(profile, 'motivated');
      
      print('Generated greeting: $greeting');
      
      // Check that greeting is personalized and mentions goal
      expect(greeting, isNotEmpty);
      expect(greeting.toLowerCase(), anyOf([
        contains('john'),
        contains('weight'),
        contains('lose'),
        contains('loss'),
        contains('goal')
      ]));
    });

    test('AI should generate goal-specific meal plan', () async {
      final profile = UserProfile(
        name: 'Sarah',
        age: 25,
        gender: 'female',
        weight: 65.0,
        height: 165.0,
        goal: 'gain_muscles',
        exerciseDuration: 60,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final mealPlan = await generateMealPlan(profile, <MealEntry>[]);
      
      print('Generated meal plan: $mealPlan');
      
      // Check that meal plan is goal-specific
      expect(mealPlan, isNotEmpty);
      expect(mealPlan.toLowerCase(), anyOf([
        contains('muscle'),
        contains('protein'),
        contains('gain'),
        contains('strength'),
        contains('building')
      ]));
    });

    test('AI should generate goal-specific health insights', () async {
      final profile = UserProfile(
        name: 'Mike',
        age: 35,
        gender: 'male',
        weight: 90.0,
        height: 175.0,
        goal: 'maintain_healthy_lifestyle',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final insights = await getHealthInsights(profile);
      
      print('Generated health insights: $insights');
      
      // Check that insights are goal-specific
      expect(insights, isNotEmpty);
      expect(insights.toLowerCase(), anyOf([
        contains('maintain'),
        contains('healthy'),
        contains('lifestyle'),
        contains('balance'),
        contains('wellness')
      ]));
    });

    test('Mock responses should be goal-specific', () {
      final profiles = [
        UserProfile(name: 'Test1', goal: 'lose_weight', age: 25, gender: 'male', weight: 80, height: 175, exerciseDuration: 30),
        UserProfile(name: 'Test2', goal: 'gain_muscles', age: 30, gender: 'female', weight: 60, height: 165, exerciseDuration: 45),
        UserProfile(name: 'Test3', goal: 'maintain_healthy_lifestyle', age: 28, gender: 'male', weight: 70, height: 180, exerciseDuration: 30),
      ];

      for (final profile in profiles) {
        final greeting = MockResponses.greeting(profile, 'energetic');
        final motivation = MockResponses.motivation(profile, 'daily_check_in');
        final mealPlan = MockResponses.mealPlan(profile);
        final healthInsights = MockResponses.healthInsights(profile);

        print('Goal: ${profile.goal}');
        print('Greeting: $greeting');
        print('Motivation: $motivation');
        print('Meal Plan: $mealPlan');
        print('Health Insights: $healthInsights');
        print('---');

        // All responses should mention the goal
        expect(greeting.toLowerCase(), contains(profile.goal.replaceAll('_', ' ')));
        expect(mealPlan.toLowerCase(), contains(profile.goal.replaceAll('_', ' ')));
        expect(healthInsights.toLowerCase(), contains(profile.goal.replaceAll('_', ' ')));
      }
    });
  });
}
