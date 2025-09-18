import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('Meal Logging Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    group('Meal Entry Creation Tests', () {
      test('Valid meal entry is created correctly', () {
        final foodItems = [
          FoodItem(
            id: 'food_1',
            name: 'Grilled Chicken Breast',
            quantity: '150g',
            calories: 248.0,
            protein: 46.2,
            carbs: 0.0,
            fat: 5.4,
            fiber: 0.0,
          ),
          FoodItem(
            id: 'food_2',
            name: 'Brown Rice',
            quantity: '100g',
            calories: 111.0,
            protein: 2.6,
            carbs: 23.0,
            fat: 0.9,
            fiber: 1.8,
          )
        ];

        final mealEntry = MealEntry(
          id: 'meal_1',
          mealType: 'lunch',
          foods: foodItems,
          timestamp: DateTime.now(),
          totalCalories: 359.0,
          totalProtein: 48.8,
          totalCarbs: 23.0,
          totalFat: 6.3,
          totalFiber: 1.8,
        );

        expect(mealEntry.isValid(), isTrue);
        expect(mealEntry.foods, hasLength(2));
        expect(mealEntry.totalCalories, equals(359.0));
        expect(mealEntry.mealType, equals('lunch'));
      });

      test('Nutritional calculations are accurate', () {
        final foodItems = [
          FoodItem(
            id: 'food_1',
            name: 'Apple',
            quantity: '1 medium',
            calories: 95.0,
            protein: 0.5,
            carbs: 25.0,
            fat: 0.3,
            fiber: 4.0,
          ),
          FoodItem(
            id: 'food_2',
            name: 'Almonds',
            quantity: '30g',
            calories: 174.0,
            protein: 6.4,
            carbs: 6.1,
            fat: 15.0,
            fiber: 3.5,
          )
        ];

        final mealEntry = MealEntry.fromFoodItems(
          id: 'snack_1',
          mealType: 'snack',
          foods: foodItems,
          timestamp: DateTime.now(),
        );

        expect(mealEntry.totalCalories, equals(269.0)); // 95 + 174
        expect(mealEntry.totalProtein, equals(6.9)); // 0.5 + 6.4
        expect(mealEntry.totalCarbs, equals(31.1)); // 25 + 6.1
        expect(mealEntry.totalFat, equals(15.3)); // 0.3 + 15.0
        expect(mealEntry.totalFiber, equals(7.5)); // 4.0 + 3.5
      });

      test('Meal type validation works correctly', () {
        final validMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
        final invalidMealTypes = ['brunch', 'dessert', '', 'LUNCH'];

        for (final mealType in validMealTypes) {
          expect(MealEntry.isValidMealType(mealType), isTrue);
        }

        for (final mealType in invalidMealTypes) {
          expect(MealEntry.isValidMealType(mealType), isFalse);
        }
      });
    });

    group('Photo Upload Functionality Tests', () {
      test('Food item supports image path', () {
        final foodItem = FoodItem(
          id: 'food_with_image',
          name: 'Grilled Salmon',
          quantity: '200g',
          calories: 412.0,
          protein: 58.0,
          carbs: 0.0,
          fat: 18.0,
          fiber: 0.0,
          imagePath: '/path/to/salmon_image.jpg',
        );

        expect(foodItem.hasImage(), isTrue);
        expect(foodItem.imagePath, isNotEmpty);
        expect(foodItem.imagePath, endsWith('.jpg'));
      });

      test('Multiple images per meal are supported', () {
        final foodItems = [
          FoodItem(
            id: 'food_1',
            name: 'Chicken Breast',
            quantity: '150g',
            calories: 248.0,
            protein: 46.2,
            carbs: 0.0,
            fat: 5.4,
            fiber: 0.0,
            imagePath: '/images/chicken.jpg',
          ),
          FoodItem(
            id: 'food_2',
            name: 'Vegetables',
            quantity: '100g',
            calories: 25.0,
            protein: 2.0,
            carbs: 5.0,
            fat: 0.2,
            fiber: 3.0,
            imagePath: '/images/vegetables.jpg',
          )
        ];

        final mealEntry = MealEntry.fromFoodItems(
          id: 'meal_with_images',
          mealType: 'dinner',
          foods: foodItems,
          timestamp: DateTime.now(),
        );

        final itemsWithImages = mealEntry.foods.where((food) => food.hasImage()).toList();
        expect(itemsWithImages, hasLength(2));
      });

      test('Image validation works correctly', () {
        final validImagePaths = [
          '/path/image.jpg',
          '/path/image.jpeg',
          '/path/image.png',
          '/path/image.webp'
        ];

        final invalidImagePaths = [
          '/path/document.pdf',
          '/path/video.mp4',
          '',
          '/path/image.txt'
        ];

        for (final path in validImagePaths) {
          expect(FoodItem.isValidImagePath(path), isTrue);
        }

        for (final path in invalidImagePaths) {
          expect(FoodItem.isValidImagePath(path), isFalse);
        }
      });
    });

    group('Data Validation Tests', () {
      test('Rejects invalid nutritional values', () {
        final invalidFoodItems = [
          // Negative calories
          FoodItem(
            id: 'invalid_1',
            name: 'Invalid Food',
            quantity: '100g',
            calories: -50.0,
            protein: 10.0,
            carbs: 20.0,
            fat: 5.0,
            fiber: 2.0,
          ),
          // Negative protein
          FoodItem(
            id: 'invalid_2',
            name: 'Invalid Food',
            quantity: '100g',
            calories: 200.0,
            protein: -5.0,
            carbs: 20.0,
            fat: 5.0,
            fiber: 2.0,
          )
        ];

        for (final foodItem in invalidFoodItems) {
          expect(foodItem.isValid(), isFalse);
        }
      });

      test('Validates reasonable nutritional ranges', () {
        final foodItem = FoodItem(
          id: 'test_food',
          name: 'Test Food',
          quantity: '100g',
          calories: 250.0,
          protein: 20.0,
          carbs: 30.0,
          fat: 10.0,
          fiber: 5.0,
        );

        expect(foodItem.isValid(), isTrue);
        expect(foodItem.hasReasonableNutrition(), isTrue);
        
        // Test macronutrient balance
        final totalMacros = foodItem.protein + foodItem.carbs + foodItem.fat;
        expect(totalMacros, lessThanOrEqualTo(foodItem.calories / 4)); // Rough calorie check
      });

      test('Empty meal entries are rejected', () {
        final emptyMeal = MealEntry(
          id: 'empty_meal',
          mealType: 'lunch',
          foods: [],
          timestamp: DateTime.now(),
          totalCalories: 0.0,
          totalProtein: 0.0,
          totalCarbs: 0.0,
          totalFat: 0.0,
          totalFiber: 0.0,
        );

        expect(emptyMeal.isValid(), isFalse);
        expect(emptyMeal.isEmpty(), isTrue);
      });
    });

    group('Meal History Management Tests', () {
      test('Meals are stored chronologically', () async {
        final meals = [
          MealEntry.fromFoodItems(
            id: 'breakfast_1',
            mealType: 'breakfast',
            foods: [_createTestFoodItem('Oatmeal', 150.0)],
            timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          ),
          MealEntry.fromFoodItems(
            id: 'lunch_1',
            mealType: 'lunch',
            foods: [_createTestFoodItem('Sandwich', 300.0)],
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          MealEntry.fromFoodItems(
            id: 'dinner_1',
            mealType: 'dinner',
            foods: [_createTestFoodItem('Pasta', 400.0)],
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          )
        ];

        await MealEntry.saveMealsToHistory(meals);
        final retrievedMeals = await MealEntry.loadMealHistory();

        expect(retrievedMeals, hasLength(3));
        
        // Check chronological order (most recent first)
        for (int i = 0; i < retrievedMeals.length - 1; i++) {
          expect(
            retrievedMeals[i].timestamp.isAfter(retrievedMeals[i + 1].timestamp),
            isTrue
          );
        }
      });

      test('Daily nutrition totals are calculated correctly', () async {
        final todaysMeals = [
          MealEntry.fromFoodItems(
            id: 'breakfast_today',
            mealType: 'breakfast',
            foods: [_createTestFoodItem('Breakfast', 300.0)],
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          MealEntry.fromFoodItems(
            id: 'lunch_today',
            mealType: 'lunch',
            foods: [_createTestFoodItem('Lunch', 450.0)],
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          )
        ];

        final dailyTotals = MealEntry.calculateDailyTotals(todaysMeals);
        
        expect(dailyTotals['calories'], equals(750.0));
        expect(dailyTotals['protein'], equals(40.0)); // 20 + 20
        expect(dailyTotals['carbs'], equals(60.0)); // 30 + 30
        expect(dailyTotals['fat'], equals(20.0)); // 10 + 10
      });
    });

    group('Performance Tests', () {
      test('Large meal entries are handled efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        final largeMeal = MealEntry.fromFoodItems(
          id: 'large_meal',
          mealType: 'dinner',
          foods: List.generate(50, (index) => 
            _createTestFoodItem('Food Item $index', 100.0 + index)
          ),
          timestamp: DateTime.now(),
        );

        stopwatch.stop();
        
        expect(largeMeal.foods, hasLength(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete quickly
        expect(largeMeal.totalCalories, greaterThan(0));
      });

      test('Meal history loading is efficient', () async {
        final stopwatch = Stopwatch()..start();
        
        // Create a large meal history
        final mealHistory = List.generate(100, (index) =>
          MealEntry.fromFoodItems(
            id: 'meal_$index',
            mealType: ['breakfast', 'lunch', 'dinner', 'snack'][index % 4],
            foods: [_createTestFoodItem('Food $index', 200.0)],
            timestamp: DateTime.now().subtract(Duration(days: index)),
          )
        );

        await MealEntry.saveMealsToHistory(mealHistory);
        final loadedMeals = await MealEntry.loadMealHistory();
        
        stopwatch.stop();
        
        expect(loadedMeals, hasLength(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should load within 5 seconds
      });
    });
  });
}

// Helper function to create test food items
FoodItem _createTestFoodItem(String name, double calories) {
  return FoodItem(
    id: 'test_${name.toLowerCase().replaceAll(' ', '_')}',
    name: name,
    quantity: '100g',
    calories: calories,
    protein: calories * 0.2 / 4, // 20% of calories from protein
    carbs: calories * 0.5 / 4,   // 50% of calories from carbs
    fat: calories * 0.3 / 9,     // 30% of calories from fat
    fiber: 3.0,
  );
}

// Extension methods for testing
extension MealEntryTest on MealEntry {
  static bool isValidMealType(String mealType) {
    final validTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    return validTypes.contains(mealType);
  }

  bool isValid() {
    return id.isNotEmpty &&
           MealEntryTest.isValidMealType(mealType) &&
           foods.isNotEmpty &&
           foods.every((food) => food.isValid()) &&
           totalCalories >= 0 &&
           totalProtein >= 0 &&
           totalCarbs >= 0 &&
           totalFat >= 0 &&
           totalFiber >= 0;
  }

  bool isEmpty() {
    return foods.isEmpty || totalCalories == 0;
  }

  static MealEntry fromFoodItems({
    required String id,
    required String mealType,
    required List<FoodItem> foods,
    required DateTime timestamp,
  }) {
    final totalCalories = foods.fold(0.0, (sum, food) => sum + food.calories);
    final totalProtein = foods.fold(0.0, (sum, food) => sum + food.protein);
    final totalCarbs = foods.fold(0.0, (sum, food) => sum + food.carbs);
    final totalFat = foods.fold(0.0, (sum, food) => sum + food.fat);
    final totalFiber = foods.fold(0.0, (sum, food) => sum + food.fiber);

    return MealEntry(
      id: id,
      mealType: mealType,
      foods: foods,
      timestamp: timestamp,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalFiber: totalFiber,
    );
  }

  static Future<void> saveMealsToHistory(List<MealEntry> meals) async {
    // Mock implementation for testing
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<List<MealEntry>> loadMealHistory() async {
    // Mock implementation for testing
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  static Map<String, double> calculateDailyTotals(List<MealEntry> meals) {
    return {
      'calories': meals.fold(0.0, (sum, meal) => sum + meal.totalCalories),
      'protein': meals.fold(0.0, (sum, meal) => sum + meal.totalProtein),
      'carbs': meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs),
      'fat': meals.fold(0.0, (sum, meal) => sum + meal.totalFat),
      'fiber': meals.fold(0.0, (sum, meal) => sum + meal.totalFiber),
    };
  }
}

extension FoodItemTest on FoodItem {
  bool hasImage() {
    return imagePath != null && imagePath!.isNotEmpty;
  }

  static bool isValidImagePath(String? path) {
    if (path == null || path.isEmpty) return false;
    
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  bool isValid() {
    return id.isNotEmpty &&
           name.isNotEmpty &&
           quantity.isNotEmpty &&
           calories >= 0 &&
           protein >= 0 &&
           carbs >= 0 &&
           fat >= 0 &&
           fiber >= 0;
  }

  bool hasReasonableNutrition() {
    // Basic sanity checks for nutritional values
    final proteinCalories = protein * 4;
    final carbCalories = carbs * 4;
    final fatCalories = fat * 9;
    final totalMacroCalories = proteinCalories + carbCalories + fatCalories;
    
    // Allow some variance in calorie calculations
    return (totalMacroCalories - calories).abs() <= calories * 0.2;
  }
}
