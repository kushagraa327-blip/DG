
/// Represents a single food item with its nutritional information
class FoodItem {
  final String id;
  final String name;
  final String quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String unit;
  final String? imagePath; // Path to the food item image
  final int? healthScore; // Health score percentage

  FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.unit = 'g',
    this.imagePath,
    this.healthScore,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      unit: json['unit']?.toString() ?? 'g',
      imagePath: json['imagePath']?.toString(),
      healthScore: json['healthScore'] != null ? int.tryParse(json['healthScore'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'unit': unit,
      'imagePath': imagePath,
      'healthScore': healthScore,
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? quantity,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? unit,
    String? imagePath,
    int? healthScore,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      healthScore: healthScore ?? this.healthScore,
    );
  }
}

/// Represents a complete meal entry with multiple food items
class MealEntry {
  final String id;
  final String date; // YYYY-MM-DD format
  final String mealType; // breakfast, lunch, dinner, snack
  final List<FoodItem> foods;
  final DateTime timestamp;
  final String? notes;

  MealEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.foods,
    required this.timestamp,
    this.notes,
  });

  // Calculate total nutrition for this meal
  double get totalCalories => foods.fold(0.0, (sum, food) => sum + food.calories);
  double get totalProtein => foods.fold(0.0, (sum, food) => sum + food.protein);
  double get totalCarbs => foods.fold(0.0, (sum, food) => sum + food.carbs);
  double get totalFat => foods.fold(0.0, (sum, food) => sum + food.fat);
  double get totalFiber => foods.fold(0.0, (sum, food) => sum + food.fiber);

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      mealType: json['mealType']?.toString() ?? 'meal',
      foods: (json['foods'] as List<dynamic>?)
          ?.map((food) => FoodItem.fromJson(food as Map<String, dynamic>))
          .toList() ?? [],
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'mealType': mealType,
      'foods': foods.map((food) => food.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  MealEntry copyWith({
    String? id,
    String? date,
    String? mealType,
    List<FoodItem>? foods,
    DateTime? timestamp,
    String? notes,
  }) {
    return MealEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foods: foods ?? this.foods,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}

/// Represents daily nutrition summary
class DailyNutrition {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final int mealCount;
  final List<MealEntry> meals;

  DailyNutrition({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.mealCount,
    required this.meals,
  });

  factory DailyNutrition.fromMeals(String date, List<MealEntry> meals) {
    return DailyNutrition(
      date: date,
      totalCalories: meals.fold(0.0, (sum, meal) => sum + meal.totalCalories),
      totalProtein: meals.fold(0.0, (sum, meal) => sum + meal.totalProtein),
      totalCarbs: meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs),
      totalFat: meals.fold(0.0, (sum, meal) => sum + meal.totalFat),
      totalFiber: meals.fold(0.0, (sum, meal) => sum + meal.totalFiber),
      mealCount: meals.length,
      meals: meals,
    );
  }

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    return DailyNutrition(
      date: json['date']?.toString() ?? '',
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
      totalProtein: (json['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (json['totalCarbs'] ?? 0).toDouble(),
      totalFat: (json['totalFat'] ?? 0).toDouble(),
      totalFiber: (json['totalFiber'] ?? 0).toDouble(),
      mealCount: json['mealCount'] ?? 0,
      meals: (json['meals'] as List<dynamic>?)
          ?.map((meal) => MealEntry.fromJson(meal as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalFiber': totalFiber,
      'mealCount': mealCount,
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }
}

/// Avatar mood states based on nutrition and health metrics
enum AvatarMood {
  joyful,     // Great nutrition, on track
  happy,      // Good nutrition
  neutral,    // Average nutrition
  concerned,  // Below target
  worried,    // Poor nutrition
  excited,    // Exceeded goals positively
}

extension AvatarMoodExtension on AvatarMood {
  String get emoji {
    switch (this) {
      case AvatarMood.joyful:
        return '😊';
      case AvatarMood.happy:
        return '🙂';
      case AvatarMood.neutral:
        return '😐';
      case AvatarMood.concerned:
        return '😕';
      case AvatarMood.worried:
        return '😟';
      case AvatarMood.excited:
        return '🤩';
    }
  }

  String get description {
    switch (this) {
      case AvatarMood.joyful:
        return 'Feeling great! Your nutrition is on point! 🌟';
      case AvatarMood.happy:
        return 'Good job! You\'re doing well with your nutrition! 👍';
      case AvatarMood.neutral:
        return 'Not bad! Let\'s aim for better nutrition today! 💪';
      case AvatarMood.concerned:
        return 'I\'m a bit concerned. Let\'s focus on better nutrition! 🤔';
      case AvatarMood.worried:
        return 'I\'m worried about your nutrition. Let\'s make better choices! 😰';
      case AvatarMood.excited:
        return 'Wow! You\'re crushing your nutrition goals! 🎉';
    }
  }
}

/// Nutrition goals based on user profile
class NutritionGoals {
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;
  final double dailyFiber;
  final String goal; // weight_loss, weight_gain, maintenance

  NutritionGoals({
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
    required this.dailyFiber,
    required this.goal,
  });

  factory NutritionGoals.fromUserProfile({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String goal,
    required int exerciseDuration,
  }) {
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Calculate TDEE based on exercise duration
    double activityMultiplier = 1.2; // Sedentary
    if (exerciseDuration >= 60) {
      activityMultiplier = 1.725; // Very active
    } else if (exerciseDuration >= 30) {
      activityMultiplier = 1.55; // Moderately active
    } else if (exerciseDuration >= 15) {
      activityMultiplier = 1.375; // Lightly active
    }

    double tdee = bmr * activityMultiplier;

    // Adjust for goal
    double dailyCalories = tdee;
    if (goal == 'weight_loss') {
      dailyCalories -= 500; // 1 lb per week
    } else if (goal == 'weight_gain') {
      dailyCalories += 500; // 1 lb per week
    }

    // Calculate macros (protein: 25%, carbs: 45%, fat: 30%)
    double dailyProtein = (dailyCalories * 0.25) / 4; // 4 cal per gram
    double dailyCarbs = (dailyCalories * 0.45) / 4; // 4 cal per gram
    double dailyFat = (dailyCalories * 0.30) / 9; // 9 cal per gram
    double dailyFiber = weight * 0.5; // 0.5g per kg body weight

    return NutritionGoals(
      dailyCalories: dailyCalories.roundToDouble(),
      dailyProtein: dailyProtein.roundToDouble(),
      dailyCarbs: dailyCarbs.roundToDouble(),
      dailyFat: dailyFat.roundToDouble(),
      dailyFiber: dailyFiber.roundToDouble(),
      goal: goal,
    );
  }

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      dailyCalories: (json['dailyCalories'] ?? 2000).toDouble(),
      dailyProtein: (json['dailyProtein'] ?? 150).toDouble(),
      dailyCarbs: (json['dailyCarbs'] ?? 225).toDouble(),
      dailyFat: (json['dailyFat'] ?? 67).toDouble(),
      dailyFiber: (json['dailyFiber'] ?? 25).toDouble(),
      goal: json['goal']?.toString() ?? 'maintenance',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyCalories': dailyCalories,
      'dailyProtein': dailyProtein,
      'dailyCarbs': dailyCarbs,
      'dailyFat': dailyFat,
      'dailyFiber': dailyFiber,
      'goal': goal,
    };
  }
}
