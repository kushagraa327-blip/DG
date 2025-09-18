import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('Improved AI Tests', () {
    setUpAll(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    test('AI should provide personalized greeting with user info', () async {
      final profile = UserProfile(
        name: 'Sarah',
        age: 28,
        gender: 'female',
        weight: 65.0,
        height: 165.0,
        goal: 'gain_muscles',
        exerciseDuration: 45,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final greeting = await getPersonalizedGreeting(profile, 'motivated');
      
      print('🎯 Personalized Greeting: $greeting');
      
      // Should contain user's name and goal
      expect(greeting.toLowerCase(), contains('sarah'));
      expect(greeting.toLowerCase(), anyOf([
        contains('muscle'),
        contains('gain'),
        contains('strength')
      ]));
      expect(greeting.length, lessThan(200)); // Should be concise
    });

    test('AI should provide goal-specific meal plan', () async {
      final profile = UserProfile(
        name: 'Mike',
        age: 35,
        gender: 'male',
        weight: 80.0,
        height: 180.0,
        goal: 'lose_weight',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final mealPlan = await generateMealPlan(profile, <MealEntry>[]);
      
      print('🍽️ Personalized Meal Plan: $mealPlan');
      
      // Should contain meal structure and be goal-specific
      expect(mealPlan, contains('🍳')); // Breakfast emoji
      expect(mealPlan, contains('🥗')); // Lunch emoji
      expect(mealPlan.toLowerCase(), anyOf([
        contains('weight loss'),
        contains('lose weight'),
        contains('calorie'),
        contains('1200'),
        contains('1400')
      ]));
    });

    test('AI should provide personalized health insights', () async {
      final profile = UserProfile(
        name: 'Alex',
        age: 25,
        gender: 'male',
        weight: 70.0,
        height: 175.0,
        goal: 'maintain_healthy_lifestyle',
        exerciseDuration: 40,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      final insights = await getHealthInsights(profile);
      
      print('💡 Personalized Health Insights: $insights');
      
      // Should contain insights structure and be goal-specific
      expect(insights, contains('✅')); // Checkmark structure
      expect(insights.toLowerCase(), anyOf([
        contains('alex'),
        contains('maintain'),
        contains('healthy'),
        contains('lifestyle'),
        contains('balance')
      ]));
    });

    test('AI should handle user questions with context', () async {
      final profile = UserProfile(
        name: 'Emma',
        age: 30,
        gender: 'female',
        weight: 60.0,
        height: 160.0,
        goal: 'lose_weight',
        exerciseDuration: 35,
        diseases: [],
        dietaryPreferences: ['vegetarian'],
        isSmoker: false,
      );

      // Create a meal entry for context
      final recentMeals = [
        MealEntry(
          id: '1',
          date: DateTime.now().toIso8601String().split('T')[0],
          mealType: 'breakfast',
          timestamp: DateTime.now(),
          foods: [
            FoodItem(
              id: '1',
              name: 'Oatmeal',
              quantity: '100',
              calories: 300,
              protein: 10,
              carbs: 50,
              fat: 5,
            ),
            FoodItem(
              id: '2',
              name: 'Banana',
              quantity: '1',
              calories: 100,
              protein: 1,
              carbs: 25,
              fat: 0,
            ),
          ],
        ),
      ];

      final messages = [
        CoreMessage(
          role: 'user',
          content: 'What should I eat for lunch today? I want something healthy for my weight loss goal.'
        )
      ];

      final response = await chatWithAI(messages, userProfile: profile, recentMeals: recentMeals);
      
      print('💬 Contextual AI Response: $response');
      
      // Should be personalized and consider context
      expect(response.toLowerCase(), anyOf([
        contains('emma'),
        contains('weight loss'),
        contains('vegetarian'),
        contains('lunch'),
        contains('healthy')
      ]));
      expect(response.length, greaterThan(50)); // Should be substantial
      expect(response.length, lessThan(500)); // But not too long
    });

    test('AI should provide different responses for different goals', () async {
      final profiles = [
        UserProfile(name: 'John', goal: 'lose_weight', age: 30, gender: 'male', weight: 85, height: 180, exerciseDuration: 30),
        UserProfile(name: 'Jane', goal: 'gain_muscles', age: 25, gender: 'female', weight: 55, height: 165, exerciseDuration: 45),
        UserProfile(name: 'Bob', goal: 'maintain_healthy_lifestyle', age: 40, gender: 'male', weight: 75, height: 175, exerciseDuration: 25),
      ];

      for (final profile in profiles) {
        final greeting = await getPersonalizedGreeting(profile, 'energetic');
        final mealPlan = await generateMealPlan(profile, <MealEntry>[]);
        
        print('\n🎯 Goal: ${profile.goal}');
        print('👋 Greeting: $greeting');
        print('🍽️ Meal Plan Preview: ${mealPlan.substring(0, mealPlan.length > 100 ? 100 : mealPlan.length)}...');
        
        // Each should be different and goal-specific
        expect(greeting.toLowerCase(), contains(profile.name!.toLowerCase()));
        expect(mealPlan, contains('🍳'));
        
        // Goal-specific content
        switch (profile.goal) {
          case 'lose_weight':
            expect(mealPlan.toLowerCase(), anyOf([contains('weight loss'), contains('1200'), contains('1400')]));
            break;
          case 'gain_muscles':
            expect(mealPlan.toLowerCase(), anyOf([contains('muscle'), contains('protein'), contains('2000')]));
            break;
          case 'maintain_healthy_lifestyle':
            expect(mealPlan.toLowerCase(), anyOf([contains('maintain'), contains('balance'), contains('1600')]));
            break;
        }
      }
    });
  });
}
