import '../main.dart';
import '../services/ai_service.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../models/meal_entry_model.dart';

/// Enhanced user context service for IRA interactions
class IRAUserContext {
  static final IRAUserContext _instance = IRAUserContext._internal();
  factory IRAUserContext() => _instance;
  IRAUserContext._internal();

  /// Build comprehensive user profile for AI interactions
  UserProfile buildEnhancedUserProfile() {
    // Debug: Print user store values
    print('🔍 Building user profile:');
    print('  Name: ${userStore.fName}');
    print('  Age: ${userStore.age}');
    print('  Gender: ${userStore.gender}');
    print('  Weight: ${userStore.weight}');
    print('  Height: ${userStore.height}');
    print('  Goal: ${userStore.goal}');

    final profile = UserProfile(
      name: userStore.fName.isNotEmpty ? userStore.fName : 'User',
      age: int.tryParse(userStore.age.validate()),
      gender: userStore.gender.isNotEmpty ? userStore.gender : null,
      weight: double.tryParse(userStore.weight.validate()),
      height: double.tryParse(userStore.height.validate()),
      goal: userStore.goal.isNotEmpty ? userStore.goal : 'general_fitness',
      exerciseDuration: 30, // Default 30 minutes
      diseases: _extractHealthConditions(),
      dietaryPreferences: _extractDietaryPreferences(),
      isSmoker: false, // Could be added to user profile later
    );

    // Debug: Print parsed profile
    print('📋 Parsed profile:');
    print('  Name: ${profile.name}');
    print('  Age: ${profile.age}');
    print('  Gender: ${profile.gender}');
    print('  Weight: ${profile.weight}');
    print('  Height: ${profile.height}');
    print('  Goal: ${profile.goal}');

    return profile;
  }

  /// Get user's current fitness context
  Map<String, dynamic> getFitnessContext() {
    final profile = buildEnhancedUserProfile();
    final context = <String, dynamic>{};
    
    // Basic demographics
    context['name'] = profile.name;
    context['age'] = profile.age;
    context['gender'] = profile.gender;
    
    // Physical stats
    if (profile.weight != null && profile.height != null) {
      final bmi = profile.weight! / ((profile.height! / 100) * (profile.height! / 100));
      context['bmi'] = bmi;
      context['bmi_category'] = _getBMICategory(bmi);
    }
    
    // Goals and preferences
    context['primary_goal'] = profile.goal;
    context['goal_description'] = _getGoalDescription(profile.goal);
    context['exercise_duration'] = profile.exerciseDuration;
    
    // Health considerations
    if (profile.diseases?.isNotEmpty == true) {
      context['health_conditions'] = profile.diseases;
    }
    
    if (profile.dietaryPreferences?.isNotEmpty == true) {
      context['dietary_preferences'] = profile.dietaryPreferences;
    }
    
    return context;
  }

  /// Get user's nutrition context from recent meals
  Map<String, dynamic> getNutritionContext() {
    // Get meals from the last 3 days instead of just first 7 meals in list
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final recentMeals = <MealEntry>[];

    // Collect meals from last 3 days
    for (int i = 0; i < 3; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = date.toIso8601String().split('T')[0];
      final dayMeals = nutritionStore.getMealsForDate(dateString);
      recentMeals.addAll(dayMeals);
    }

    final context = <String, dynamic>{};
    
    if (recentMeals.isEmpty) {
      context['status'] = 'no_recent_meals';
      context['message'] = 'No recent meals tracked';
      return context;
    }
    
    // Calculate nutrition totals
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    final mealTypes = <String, int>{};
    final foodFrequency = <String, int>{};
    
    for (final meal in recentMeals) {
      // Count meal types
      mealTypes[meal.mealType] = (mealTypes[meal.mealType] ?? 0) + 1;
      
      // Sum nutrition
      for (final food in meal.foods) {
        totalCalories += food.calories;
        totalProtein += food.protein;
        totalCarbs += food.carbs;
        totalFat += food.fat;
        
        // Track food frequency
        foodFrequency[food.name] = (foodFrequency[food.name] ?? 0) + 1;
      }
    }
    
    // Calculate averages
    final mealCount = recentMeals.length;
    context['recent_meals_count'] = mealCount;
    context['avg_calories_per_meal'] = totalCalories / mealCount;
    context['avg_protein_per_meal'] = totalProtein / mealCount;
    context['avg_carbs_per_meal'] = totalCarbs / mealCount;
    context['avg_fat_per_meal'] = totalFat / mealCount;
    
    // Meal patterns
    context['meal_types'] = mealTypes;
    context['most_common_foods'] = _getTopItems(foodFrequency, 5);
    
    // Nutrition goals comparison
    final goals = nutritionStore.nutritionGoals;
    if (goals != null) {
      final dailyCalories = totalCalories * (3 / mealCount); // Estimate daily intake
      context['calorie_goal_progress'] = dailyCalories / goals.dailyCalories;
      context['protein_goal_progress'] = (totalProtein * (3 / mealCount)) / goals.dailyProtein;
    }
    
    // Recent meal summary
    context['recent_meals_summary'] = recentMeals.take(3).map((meal) => 
      '${meal.mealType}: ${meal.foods.map((f) => f.name).join(', ')}'
    ).join('; ');
    
    return context;
  }

  /// Get user's activity and mood context
  Map<String, dynamic> getActivityContext() {
    final context = <String, dynamic>{};
    
    // Avatar mood
    context['current_mood'] = nutritionStore.avatarMood.toString().split('.').last;
    
    // Streak information
    context['nutrition_streak'] = nutritionStore.streakCount;
    context['streak_status'] = _getStreakStatus(nutritionStore.streakCount);
    
    // Last sync date
    if (nutritionStore.lastSyncDate.isNotEmpty) {
      context['last_sync'] = nutritionStore.lastSyncDate;
    }
    
    return context;
  }

  /// Build personalized greeting based on user context
  String buildPersonalizedGreeting() {
    final profile = buildEnhancedUserProfile();
    final mood = nutritionStore.avatarMood.toString().split('.').last;
    final streak = nutritionStore.streakCount;
    
    final greetings = <String>[];
    
    // Name-based greeting
    greetings.add('Hello ${profile.name}! 😊');
    
    // Goal-based motivation
    final goalText = profile.goal.replaceAll('_', ' ');
    greetings.add('Ready to continue your $goalText journey?');
    
    // Mood-based response
    switch (mood) {
      case 'joyful':
        greetings.add('You seem energetic today! 🌟');
        break;
      case 'happy':
        greetings.add('Great to see you in good spirits! 😄');
        break;
      case 'neutral':
        greetings.add('How are you feeling today?');
        break;
      case 'concerned':
        greetings.add('Let\'s work together to get back on track! 💪');
        break;
      case 'worried':
        greetings.add('I\'m here to help you feel better! 🤗');
        break;
    }
    
    // Streak motivation
    if (streak > 0) {
      greetings.add('Keep up that $streak-day streak! 🔥');
    }
    
    return greetings.join(' ');
  }

  /// Generate context-aware conversation starters
  List<String> generateConversationStarters() {
    final profile = buildEnhancedUserProfile();
    final nutritionContext = getNutritionContext();
    final starters = <String>[];
    
    // Goal-based starters
    switch (profile.goal) {
      case 'lose_weight':
        starters.addAll([
          'What healthy meals are you planning today?',
          'How can I help with your weight loss journey?',
          'Need some low-calorie meal ideas?',
        ]);
        break;
      case 'gain_weight':
        starters.addAll([
          'Looking for high-calorie, nutritious meal ideas?',
          'How\'s your muscle-building progress going?',
          'Need help planning protein-rich meals?',
        ]);
        break;
      case 'gain_muscles':
        starters.addAll([
          'Ready to discuss your workout routine?',
          'How\'s your protein intake looking today?',
          'Need some muscle-building tips?',
        ]);
        break;
      default:
        starters.addAll([
          'How can I help with your fitness goals today?',
          'What would you like to know about nutrition?',
          'Ready to plan some healthy meals?',
        ]);
    }
    
    // Nutrition-based starters
    if (nutritionContext['recent_meals_count'] == 0) {
      starters.add('Let\'s start tracking your meals today!');
    } else {
      starters.add('How did your recent meals make you feel?');
    }
    
    return starters.take(3).toList();
  }

  /// Extract health conditions from user data (placeholder for future implementation)
  List<String> _extractHealthConditions() {
    // This could be expanded to include health conditions from user profile
    return [];
  }

  /// Extract dietary preferences from user data (placeholder for future implementation)
  List<String> _extractDietaryPreferences() {
    // This could be expanded to include dietary preferences from user profile
    return [];
  }

  /// Get BMI category
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  /// Get goal description
  String _getGoalDescription(String goal) {
    switch (goal) {
      case 'lose_weight':
        return 'lose weight and improve body composition';
      case 'gain_weight':
        return 'gain healthy weight and build mass';
      case 'gain_muscles':
        return 'build muscle and increase strength';
      case 'maintain_healthy_lifestyle':
        return 'maintain a healthy and balanced lifestyle';
      default:
        return 'achieve general fitness goals';
    }
  }

  /// Get streak status message
  String _getStreakStatus(int streak) {
    if (streak == 0) return 'starting_fresh';
    if (streak < 7) return 'building_momentum';
    if (streak < 30) return 'great_progress';
    return 'amazing_consistency';
  }

  /// Get top items from frequency map
  List<String> _getTopItems(Map<String, int> frequency, int count) {
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => e.key).toList();
  }
}
