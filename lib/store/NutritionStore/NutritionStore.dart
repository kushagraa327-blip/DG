import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import '../../extensions/shared_pref.dart';
import '../../models/meal_entry_model.dart';
import '../../utils/app_constants.dart';
import '../../main.dart';

part 'NutritionStore.g.dart';

class NutritionStore = NutritionStoreBase with _$NutritionStore;

abstract class NutritionStoreBase with Store {
  @observable
  ObservableList<MealEntry> mealEntries = ObservableList<MealEntry>();

  @observable
  AvatarMood avatarMood = AvatarMood.neutral;

  @observable
  bool isAvatarMoodManuallySet = false;

  @observable
  NutritionGoals? nutritionGoals;

  @observable
  bool isLoading = false;

  @observable
  int streakCount = 0;

  @observable
  String lastSyncDate = '';

  // Initialize store with saved data
  @action
  Future<void> initializeStore() async {
    try {
      await loadMealEntries();
      await loadNutritionGoals();
      calculateStreakCount();
      updateAvatarMood();
    } catch (e) {
      debugPrint('Error initializing nutrition store: $e');
      // Ensure we have default values even if initialization fails
      nutritionGoals ??= NutritionGoals(
        dailyCalories: 2000,
        dailyProtein: 150,
        dailyCarbs: 225,
        dailyFat: 67,
        dailyFiber: 25,
        goal: 'maintenance',
      );
    }
  }

  // Load meal entries from shared preferences
  @action
  Future<void> loadMealEntries() async {
    try {
      final String savedMeals = getStringAsync(MEAL_ENTRIES_KEY);
      if (savedMeals.isNotEmpty) {
        final List<dynamic> mealsJson = jsonDecode(savedMeals);
        final List<MealEntry> meals = mealsJson
            .map((json) => MealEntry.fromJson(json as Map<String, dynamic>))
            .toList();
        mealEntries.clear();
        mealEntries.addAll(meals);
      }
    } catch (e) {
      debugPrint('Error loading meal entries: $e');
    }
  }

  // Save meal entries to shared preferences
  @action
  Future<void> saveMealEntries() async {
    try {
      final String mealsJson = jsonEncode(
        mealEntries.map((meal) => meal.toJson()).toList(),
      );
      await setValue(MEAL_ENTRIES_KEY, mealsJson);
    } catch (e) {
      debugPrint('Error saving meal entries: $e');
    }
  }

  // Load nutrition goals from shared preferences
  @action
  Future<void> loadNutritionGoals() async {
    try {
      final String savedGoals = getStringAsync(NUTRITION_GOALS_KEY);
      if (savedGoals.isNotEmpty) {
        final Map<String, dynamic> goalsJson = jsonDecode(savedGoals);
        nutritionGoals = NutritionGoals.fromJson(goalsJson);
      } else {
        // Create default goals based on user profile
        await updateNutritionGoalsFromProfile();
      }
    } catch (e) {
      debugPrint('Error loading nutrition goals: $e');
      await updateNutritionGoalsFromProfile();
    }
  }

  // Save nutrition goals to shared preferences
  @action
  Future<void> saveNutritionGoals() async {
    if (nutritionGoals != null) {
      try {
        final String goalsJson = jsonEncode(nutritionGoals!.toJson());
        await setValue(NUTRITION_GOALS_KEY, goalsJson);
      } catch (e) {
        debugPrint('Error saving nutrition goals: $e');
      }
    }
  }

  // Update nutrition goals based on current user profile
  @action
  Future<void> updateNutritionGoalsFromProfile() async {
    try {
      final double weight = double.tryParse(userStore.weight) ?? 70.0;
      final double height = double.tryParse(userStore.height) ?? 170.0;
      final int age = int.tryParse(userStore.age) ?? 25;
      final String gender = userStore.gender.isNotEmpty ? userStore.gender : 'male';
      final String goal = userStore.goal.isNotEmpty
          ? userStore.goal
          : 'maintenance';

      nutritionGoals = NutritionGoals.fromUserProfile(
        weight: weight,
        height: height,
        age: age,
        gender: gender,
        goal: goal,
        exerciseDuration: 30, // Default 30 minutes
      );

      await saveNutritionGoals();
    } catch (e) {
      debugPrint('Error updating nutrition goals: $e');
      // Fallback to default goals
      nutritionGoals = NutritionGoals(
        dailyCalories: 2000,
        dailyProtein: 150,
        dailyCarbs: 225,
        dailyFat: 67,
        dailyFiber: 25,
        goal: 'maintenance',
      );
    }
  }

  // Add a new meal entry
  @action
  Future<void> addMealEntry(MealEntry meal) async {
    mealEntries.add(meal);
    await saveMealEntries();
    calculateStreakCount();
    updateAvatarMood();
  }

  // Update an existing meal entry
  @action
  Future<void> updateMealEntry(String mealId, MealEntry updatedMeal) async {
    final index = mealEntries.indexWhere((meal) => meal.id == mealId);
    if (index != -1) {
      mealEntries[index] = updatedMeal;
      await saveMealEntries();
      updateAvatarMood();
    }
  }

  // Delete a meal entry
  @action
  Future<void> deleteMealEntry(String mealId) async {
    mealEntries.removeWhere((meal) => meal.id == mealId);
    await saveMealEntries();
    calculateStreakCount();
    updateAvatarMood();
  }

  // Get meals for a specific date
  List<MealEntry> getMealsForDate(String date) {
    return mealEntries.where((meal) => meal.date == date).toList();
  }

  // Get today's meals
  @computed
  List<MealEntry> get todayMeals {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return getMealsForDate(today);
  }

  // Get today's nutrition summary
  @computed
  DailyNutrition get todayNutrition {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final meals = getMealsForDate(today);
      return DailyNutrition.fromMeals(today, meals);
    } catch (e) {
      debugPrint('Error computing today nutrition: $e');
      return DailyNutrition(
        date: DateTime.now().toIso8601String().split('T')[0],
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        totalFiber: 0,
        mealCount: 0,
        meals: [],
      );
    }
  }

  // Calculate calorie progress percentage
  @computed
  double get calorieProgress {
    try {
      if (nutritionGoals == null) return 0.0;
      return (todayNutrition.totalCalories / nutritionGoals!.dailyCalories) * 100;
    } catch (e) {
      debugPrint('Error computing calorie progress: $e');
      return 0.0;
    }
  }

  // Calculate protein progress percentage
  @computed
  double get proteinProgress {
    if (nutritionGoals == null) return 0.0;
    return (todayNutrition.totalProtein / nutritionGoals!.dailyProtein) * 100;
  }

  // Calculate carbs progress percentage
  @computed
  double get carbsProgress {
    if (nutritionGoals == null) return 0.0;
    return (todayNutrition.totalCarbs / nutritionGoals!.dailyCarbs) * 100;
  }

  // Calculate fat progress percentage
  @computed
  double get fatProgress {
    if (nutritionGoals == null) return 0.0;
    return (todayNutrition.totalFat / nutritionGoals!.dailyFat) * 100;
  }

  // Calculate streak count
  @action
  void calculateStreakCount() {
    if (mealEntries.isEmpty) {
      streakCount = 0;
      return;
    }

    final sortedEntries = mealEntries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];

    // Check if there's an entry for today
    bool hasToday = sortedEntries.any((entry) => entry.date == today);
    bool hasYesterday = sortedEntries.any((entry) => entry.date == yesterday);

    if (!hasToday && !hasYesterday) {
      streakCount = 0;
      return;
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // If no entry today, start from yesterday
    if (!hasToday) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Count consecutive days with entries
    while (true) {
      final dateString = checkDate.toIso8601String().split('T')[0];
      final hasEntry = sortedEntries.any((entry) => entry.date == dateString);

      if (hasEntry) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    streakCount = streak;
  }

  // Update avatar mood based on nutrition and goals
  @action
  void updateAvatarMood() {
    // Don't auto-update if user has manually set the mood
    if (isAvatarMoodManuallySet) {
      return;
    }

    if (nutritionGoals == null) {
      avatarMood = AvatarMood.neutral;
      return;
    }

    final progress = calorieProgress;
    final proteinRatio = proteinProgress;

    // Determine mood based on calorie progress and protein intake
    if (progress >= 90 && progress <= 110 && proteinRatio >= 80) {
      avatarMood = AvatarMood.joyful;
    } else if (progress >= 80 && progress <= 120 && proteinRatio >= 60) {
      avatarMood = AvatarMood.happy;
    } else if (progress >= 70 && progress <= 130) {
      avatarMood = AvatarMood.neutral;
    } else if (progress < 70 || (progress > 130 && progress < 150)) {
      avatarMood = AvatarMood.concerned;
    } else if (progress < 50 || progress > 150) {
      avatarMood = AvatarMood.worried;
    } else if (progress > 110 && progress <= 130 && proteinRatio >= 90) {
      avatarMood = AvatarMood.excited;
    } else {
      avatarMood = AvatarMood.neutral;
    }
  }

  // Set avatar mood manually (for interactions)
  @action
  void setAvatarMood(AvatarMood mood) {
    avatarMood = mood;
    isAvatarMoodManuallySet = true;
    debugPrint('🎯 Avatar mood manually set to: $mood');
  }

  // Reset avatar mood to auto-update mode
  @action
  void resetAvatarMoodToAuto() {
    isAvatarMoodManuallySet = false;
    updateAvatarMood();
    debugPrint('🔄 Avatar mood reset to auto-update mode: $avatarMood');
  }

  // Clear all meal entries
  @action
  Future<void> clearAllMeals() async {
    mealEntries.clear();
    await saveMealEntries();
    streakCount = 0;
    updateAvatarMood();
  }

  // Get nutrition summary for date range
  List<DailyNutrition> getNutritionSummary(DateTime startDate, DateTime endDate) {
    final List<DailyNutrition> summary = [];

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateString = currentDate.toIso8601String().split('T')[0];
      final meals = getMealsForDate(dateString);
      summary.add(DailyNutrition.fromMeals(dateString, meals));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return summary;
  }

  // Get weekly average calories
  @computed
  double get weeklyAverageCalories {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    final summary = getNutritionSummary(startDate, endDate);
    
    if (summary.isEmpty) return 0.0;
    
    final totalCalories = summary.fold(0.0, (sum, day) => sum + day.totalCalories);
    return totalCalories / summary.length;
  }

  // Check if user is on track with goals
  @computed
  bool get isOnTrackWithGoals {
    if (nutritionGoals == null) return false;
    
    final progress = calorieProgress;
    return progress >= 80 && progress <= 120;
  }
}
