# 🍽️ Meal Logging System - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Data Flow Architecture](#data-flow-architecture)
3. [Backend Integration](#backend-integration)
4. [Data Storage](#data-storage)
5. [AI Analysis](#ai-analysis)
6. [Component Structure](#component-structure)
7. [API Endpoints](#api-endpoints)
8. [Data Models](#data-models)
9. [User Journey](#user-journey)
10. [Code Examples](#code-examples)

---

## Overview

The Dietary Guide app uses a **client-side storage system** for meal logging with AI-powered nutritional analysis. Currently, meal data is **NOT saved to the backend server**, but instead stored locally on the device using SharedPreferences.

### Key Features
- ✅ Local meal logging and storage
- ✅ AI-powered food recognition from images
- ✅ Automatic nutritional analysis via OpenRouter API
- ✅ Real-time nutrition tracking and goal monitoring
- ✅ Streak tracking for user engagement
- ❌ Backend API integration (not implemented)
- ❌ Cloud synchronization (not implemented)

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   LogMealFormComponent                       │
│  • User enters food name                                     │
│  • User uploads image (optional)                             │
│  • User selects meal type (breakfast/lunch/dinner/snack)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AI ANALYSIS (Optional)                   │
│  ┌────────────────────┐        ┌──────────────────────┐    │
│  │ Image Recognition  │   OR   │  Text Analysis       │    │
│  │ FoodRecognition    │        │  analyzeFoodNutrition│    │
│  │ Service            │        │  (AI Service)        │    │
│  └────────────────────┘        └──────────────────────┘    │
│         │                               │                   │
│         └───────────┬───────────────────┘                   │
│                     ▼                                        │
│        Returns: calories, protein, carbs, fat, fiber        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MEAL ENTRY CREATION                       │
│  MealEntry {                                                 │
│    id: timestamp-based unique ID                             │
│    date: "YYYY-MM-DD" format                                 │
│    mealType: breakfast/lunch/dinner/snack                    │
│    foods: List<FoodItem>                                     │
│    timestamp: DateTime                                       │
│    notes: optional user notes                                │
│  }                                                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    NUTRITION STORE (MobX)                    │
│  • addMealEntry(meal) - adds to observable list              │
│  • saveMealEntries() - saves to SharedPreferences            │
│  • updateAvatarMood() - updates UI feedback                  │
│  • calculateStreakCount() - tracks daily logging             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   LOCAL STORAGE (Device)                     │
│  SharedPreferences                                           │
│  Key: MEAL_ENTRIES_KEY                                       │
│  Format: JSON array of meal entries                          │
│  Location: App's private storage                             │
│  Persistence: Until app is uninstalled                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         UI UPDATES                           │
│  • Home Screen nutrition cards                               │
│  • Today's meals list                                        │
│  • Progress tracking                                         │
│  • Streak counter                                            │
│  • Avatar mood changes                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Backend Integration

### ❌ Current Status: **NOT INTEGRATED**

The meal logging system currently **does NOT save data to the backend**. All data is stored locally on the device.

### Why No Backend Integration?

Looking at the codebase:

1. **No API Endpoint** - There's no REST API call in the meal logging flow
2. **Local Storage Only** - Uses SharedPreferences via `setValue(MEAL_ENTRIES_KEY, mealsJson)`
3. **No Network Calls** - `NutritionStore` doesn't make HTTP requests
4. **Client-Side Only** - All operations happen on device

### Backend URL Configuration

```dart
// lib/utils/app_config.dart
const mBackendURL = "https://app.dietaryguide.in";
const mBaseUrl = '$mBackendURL/api/';
```

**However**, these URLs are used for:
- User authentication
- Profile management
- Other features

**But NOT for meal logging!**

---

## Data Storage

### Storage Mechanism: SharedPreferences

```dart
// File: lib/store/NutritionStore/NutritionStore.dart

@action
Future<void> saveMealEntries() async {
  try {
    // Convert meal entries to JSON
    final String mealsJson = jsonEncode(
      mealEntries.map((meal) => meal.toJson()).toList(),
    );
    
    // Save to SharedPreferences (LOCAL STORAGE)
    await setValue(MEAL_ENTRIES_KEY, mealsJson);
  } catch (e) {
    debugPrint('Error saving meal entries: $e');
  }
}
```

### Storage Key
```dart
// Defined in app_constants.dart
const MEAL_ENTRIES_KEY = 'meal_entries';
```

### Data Format

Stored as a JSON array in SharedPreferences:

```json
[
  {
    "id": "1735497600000",
    "date": "2025-12-29",
    "mealType": "breakfast",
    "timestamp": "2025-12-29T08:00:00.000Z",
    "notes": "Healthy morning meal",
    "foods": [
      {
        "id": "food_1735497600001",
        "name": "Oatmeal with Berries",
        "quantity": "150",
        "unit": "g",
        "calories": 250,
        "protein": 8,
        "carbs": 45,
        "fat": 5,
        "fiber": 6,
        "imagePath": "/path/to/image.jpg",
        "healthScore": 85
      }
    ]
  }
]
```

### Storage Limitations

| Aspect | Details |
|--------|---------|
| **Type** | Key-Value storage (SharedPreferences) |
| **Size Limit** | ~2-4 MB (varies by platform) |
| **Persistence** | Until app uninstall |
| **Sync** | None (local only) |
| **Backup** | None (data lost on uninstall) |
| **Multi-device** | No synchronization |

---

## AI Analysis

### Two Methods of AI Analysis

#### 1. Image Recognition

```dart
// File: lib/services/food_recognition_service.dart

static Future<List<FoodItem>> analyzeFoodImage(File imageFile) async {
  // 1. Upload image to OpenRouter API
  // 2. AI analyzes image and identifies foods
  // 3. Returns list of detected food items with nutrition
  
  // Example response:
  return [
    FoodItem(
      id: generated_id,
      name: "Grilled Chicken Breast",
      quantity: "150",
      unit: "g",
      calories: 248,
      protein: 47,
      carbs: 0,
      fat: 5,
      fiber: 0,
      imagePath: imageFile.path,
    )
  ];
}
```

**API Used**: OpenRouter with google/gemini-2.0-flash-exp

**Process**:
1. Image converted to base64
2. Sent to OpenRouter API with prompt
3. AI analyzes visual content
4. Extracts food items, quantities, nutrition
5. Validates data (ensures food items only)
6. Returns structured FoodItem objects

#### 2. Text-Based Analysis

```dart
// File: lib/services/ai_service.dart

Future<Map<String, double>> analyzeFoodNutrition(
  String foodName, 
  String quantity
) async {
  // 1. Send food name to OpenRouter API
  // 2. AI calculates nutrition based on food database
  // 3. Returns nutritional breakdown
  
  // Example response:
  return {
    'calories': 248.0,
    'protein': 47.0,
    'carbs': 0.0,
    'fat': 5.0,
    'fiber': 0.0,
  };
}
```

**API Used**: OpenRouter with google/gemini-2.0-flash-exp

**Validation**: Both methods include food validation to prevent non-food entries:

```dart
// Non-food keywords blocked
final nonFoodKeywords = [
  'chair', 'table', 'phone', 'car', 'book',
  'computer', 'clothes', 'furniture', etc.
];

// Throws FoodValidationException if non-food detected
if (detectedNonFood) {
  throw FoodValidationException(
    'Invalid input, please enter food items only'
  );
}
```

---

## Component Structure

### Main Components

#### 1. LogMealFormComponent
**Location**: `lib/components/log_meal_form_component.dart` (2217 lines)

**Responsibilities**:
- Meal type selection (breakfast/lunch/dinner/snack)
- Food item management (add/remove)
- Image upload and recognition
- AI-powered auto-fill
- Form validation
- Meal submission

**Key Features**:
```dart
- _addFoodItem() - Opens dialog to add food
- _analyzeFood() - Text-based AI analysis
- _pickImage() - Camera/gallery selection
- _analyzeImageNutrition() - Image-based AI analysis
- _submitMeal() - Creates MealEntry and calls onSubmit callback
```

#### 2. AddFoodDialog
**Location**: Same file as LogMealFormComponent

**Responsibilities**:
- Individual food item creation
- Manual nutrition input
- Photo upload per food item
- AI auto-fill for single items

**Fields**:
```dart
- Food Name (with validation)
- Quantity + Unit (g, ml, cup, piece, etc.)
- Calories
- Protein (g)
- Carbs (g)
- Fat (g)
- Photo (optional)
```

#### 3. NutritionStore (MobX)
**Location**: `lib/store/NutritionStore/NutritionStore.dart`

**Responsibilities**:
- State management for meals
- Local storage operations
- Nutrition calculations
- Streak tracking
- Avatar mood updates

**Key Methods**:
```dart
@action
Future<void> addMealEntry(MealEntry meal) async {
  mealEntries.add(meal);
  await saveMealEntries(); // Saves to SharedPreferences
  calculateStreakCount();
  updateAvatarMood();
}

@action
Future<void> loadMealEntries() async {
  final String savedMeals = getStringAsync(MEAL_ENTRIES_KEY);
  if (savedMeals.isNotEmpty) {
    final List<dynamic> mealsJson = jsonDecode(savedMeals);
    mealEntries.addAll(/* parsed meals */);
  }
}

@computed
List<MealEntry> get todayMeals {
  final today = DateTime.now().toIso8601String().split('T')[0];
  return getMealsForDate(today);
}

@computed
DailyNutrition get todayNutrition {
  // Calculates total calories, protein, carbs, fat for today
}
```

---

## API Endpoints

### ❌ Meal Logging API: **DOES NOT EXIST**

### ✅ Other Backend APIs (for reference)

The app DOES use backend APIs for other features:

```dart
// Authentication
POST {mBaseUrl}/login
POST {mBaseUrl}/register

// User Profile
GET  {mBaseUrl}/user/{userId}
PUT  {mBaseUrl}/user/{userId}

// Progress Tracking
GET  {mBaseUrl}/progress?type=weight
POST {mBaseUrl}/progress

// But NO meal logging endpoints!
```

### 🔮 Future Backend Integration (Recommendation)

**If you want to add backend integration**, you would need:

```dart
// Recommended API Endpoints to Add:

// Create meal
POST {mBaseUrl}/meals
Body: {
  "user_id": "123",
  "date": "2025-12-29",
  "meal_type": "breakfast",
  "foods": [...],
  "notes": "..."
}

// Get meals for date range
GET {mBaseUrl}/meals?user_id=123&start_date=2025-12-01&end_date=2025-12-31

// Update meal
PUT {mBaseUrl}/meals/{mealId}

// Delete meal
DELETE {mBaseUrl}/meals/{mealId}

// Sync local meals to server
POST {mBaseUrl}/meals/sync
Body: {
  "meals": [...]
}
```

---

## Data Models

### MealEntry Model

```dart
class MealEntry {
  final String id;              // Unique ID (timestamp-based)
  final String date;            // "YYYY-MM-DD" format
  final String mealType;        // breakfast/lunch/dinner/snack
  final List<FoodItem> foods;   // List of food items
  final DateTime timestamp;     // Full timestamp
  final String? notes;          // Optional user notes

  // Computed properties
  double get totalCalories => foods.fold(0, (sum, f) => sum + f.calories);
  double get totalProtein => foods.fold(0, (sum, f) => sum + f.protein);
  double get totalCarbs => foods.fold(0, (sum, f) => sum + f.carbs);
  double get totalFat => foods.fold(0, (sum, f) => sum + f.fat);
  double get totalFiber => foods.fold(0, (sum, f) => sum + f.fiber);
  
  // Serialization
  factory MealEntry.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### FoodItem Model

```dart
class FoodItem {
  final String id;              // Unique ID
  final String name;            // Food name
  final String quantity;        // Amount (can be "100" or "1 cup")
  final double calories;        // Total calories
  final double protein;         // Protein in grams
  final double carbs;           // Carbs in grams
  final double fat;             // Fat in grams
  final double fiber;           // Fiber in grams (optional)
  final String unit;            // g, ml, cup, piece, etc.
  final String? imagePath;      // Path to food image (optional)
  final int? healthScore;       // Health score 0-100 (optional)
  
  // Serialization
  factory FoodItem.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### NutritionGoals Model

```dart
class NutritionGoals {
  final double dailyCalories;   // Daily calorie target
  final double dailyProtein;    // Daily protein target (g)
  final double dailyCarbs;      // Daily carbs target (g)
  final double dailyFat;        // Daily fat target (g)
  final double dailyFiber;      // Daily fiber target (g)
  final String goal;            // weight_loss/maintenance/muscle_gain
  
  // Calculate from user profile
  factory NutritionGoals.fromUserProfile({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String goal,
    required int exerciseDuration,
  });
}
```

### DailyNutrition Model

```dart
class DailyNutrition {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final int mealCount;
  
  // Calculated from all meals for the day
}
```

---

## User Journey

### Complete Meal Logging Flow

```
1. USER OPENS HOME SCREEN
   ↓
   Home Screen displays:
   - Today's nutrition summary (if meals logged)
   - Today's meals list
   - "Log Meal" button
   
2. USER TAPS "LOG MEAL" BUTTON
   ↓
   Bottom sheet opens with LogMealFormComponent
   
3. USER SELECTS MEAL TYPE
   ↓
   Dropdown: Breakfast / Lunch / Dinner / Snack
   
4. USER ADDS FOOD ITEM
   ↓
   Taps "Add Food" button
   ↓
   AddFoodDialog opens
   
5a. MANUAL ENTRY PATH:
    ├─ Enter food name: "Chicken Breast"
    ├─ Enter quantity: "150" + unit: "g"
    ├─ Option 1: Enter nutrition manually
    │  └─ Calories: 248
    │  └─ Protein: 47g
    │  └─ Carbs: 0g
    │  └─ Fat: 5g
    │
    └─ Option 2: Use AI Auto-fill
       └─ Tap "Auto-fill with AI"
       └─ AI analyzes "Chicken Breast 150g"
       └─ Nutrition fields auto-populated
       └─ User can edit if needed

5b. IMAGE PATH:
    ├─ Tap "Camera" or "Gallery"
    ├─ Select/capture food image
    ├─ Tap "Auto-Fill" button
    ├─ AI analyzes image
    │  └─ Detects: "Grilled Chicken Breast"
    │  └─ Estimates quantity: "150g"
    │  └─ Calculates nutrition
    ├─ All fields auto-populated
    └─ User can edit if needed

6. REVIEW FOOD ITEM
   ↓
   Food item card shows:
   - Name
   - Quantity + unit
   - Calories
   - Protein, Carbs, Fat breakdown
   - Photo (if uploaded)
   
7. ADD MORE FOODS (OPTIONAL)
   ↓
   Repeat steps 4-6 for additional items
   
8. ADD NOTES (OPTIONAL)
   ↓
   Text field for meal notes
   
9. SUBMIT MEAL
   ↓
   Tap "Log Meal" button
   ↓
   Validation:
   ├─ At least one food item? ✓
   ├─ All nutrition fields filled? ✓
   └─ Valid food names (not objects)? ✓
   
10. SAVE TO STORAGE
    ↓
    MealEntry created:
    {
      id: "1735497600000",
      date: "2025-12-29",
      mealType: "breakfast",
      foods: [...],
      timestamp: DateTime.now(),
      notes: "..."
    }
    ↓
    NutritionStore.addMealEntry(meal)
    ↓
    Saved to SharedPreferences
    ↓
    NOT sent to backend
    
11. UI UPDATES
    ↓
    ├─ Success message: "Meal logged successfully! 🍽️"
    ├─ Home screen refreshes
    ├─ Nutrition cards update
    ├─ Meal appears in "Today's Meals"
    ├─ Streak counter updates
    └─ Avatar mood may change
    
12. PERSISTENCE
    ↓
    Data remains on device until:
    - App is uninstalled, OR
    - User manually deletes meal
```

---

## Code Examples

### Example 1: How Meal is Logged (Home Screen)

```dart
// File: lib/screens/home_screen.dart

void _showLogMealDialog() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      child: LogMealFormComponent(
        onSubmit: (meal) async {
          // This callback is called when user submits the form
          
          // 1. Add meal to nutrition store
          await nutritionStore.addMealEntry(meal);
          
          // 2. Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meal logged successfully! 🍽️'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
          
          // 3. Update UI
          setState(() {});
        },
      ),
    ),
  );
}
```

### Example 2: How Data is Saved

```dart
// File: lib/store/NutritionStore/NutritionStore.dart

@action
Future<void> addMealEntry(MealEntry meal) async {
  // 1. Add to observable list (triggers UI update)
  mealEntries.add(meal);
  
  // 2. Save to local storage
  await saveMealEntries();
  
  // 3. Recalculate streak
  calculateStreakCount();
  
  // 4. Update avatar mood based on nutrition goals
  updateAvatarMood();
}

@action
Future<void> saveMealEntries() async {
  try {
    // Convert all meals to JSON
    final String mealsJson = jsonEncode(
      mealEntries.map((meal) => meal.toJson()).toList(),
    );
    
    // Save to SharedPreferences (LOCAL ONLY)
    await setValue(MEAL_ENTRIES_KEY, mealsJson);
    
    // ❌ NO BACKEND CALL HERE
    // ❌ NO API REQUEST
    // ✅ ONLY LOCAL STORAGE
    
  } catch (e) {
    debugPrint('Error saving meal entries: $e');
  }
}
```

### Example 3: How AI Analyzes Food

```dart
// File: lib/services/ai_service.dart

Future<Map<String, double>> analyzeFoodNutrition(
  String foodName, 
  String quantity
) async {
  // 1. Validate food name
  if (_isNonFoodItem(foodName)) {
    throw FoodValidationException(
      'Invalid input, please enter food items only'
    );
  }
  
  // 2. Prepare AI prompt
  final prompt = '''
Analyze the nutritional content of:
Food: $foodName
Quantity: $quantity

Provide nutrition data in this exact JSON format:
{
  "calories": <number>,
  "protein": <number in grams>,
  "carbs": <number in grams>,
  "fat": <number in grams>,
  "fiber": <number in grams>
}
''';

  // 3. Call OpenRouter API
  final response = await http.post(
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'google/gemini-2.0-flash-exp',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    }),
  );
  
  // 4. Parse AI response
  final aiContent = jsonDecode(response.body)['choices'][0]['message']['content'];
  final nutritionData = jsonDecode(aiContent);
  
  // 5. Return structured data
  return {
    'calories': nutritionData['calories'].toDouble(),
    'protein': nutritionData['protein'].toDouble(),
    'carbs': nutritionData['carbs'].toDouble(),
    'fat': nutritionData['fat'].toDouble(),
    'fiber': nutritionData['fiber']?.toDouble() ?? 0.0,
  };
}
```

### Example 4: How Data is Retrieved for Display

```dart
// File: lib/store/NutritionStore/NutritionStore.dart

// Get today's meals
@computed
List<MealEntry> get todayMeals {
  final today = DateTime.now().toIso8601String().split('T')[0];
  return getMealsForDate(today);
}

// Get meals for specific date
List<MealEntry> getMealsForDate(String date) {
  return mealEntries.where((meal) => meal.date == date).toList();
}

// Calculate today's total nutrition
@computed
DailyNutrition get todayNutrition {
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  double totalFiber = 0;

  for (var meal in todayMeals) {
    totalCalories += meal.totalCalories;
    totalProtein += meal.totalProtein;
    totalCarbs += meal.totalCarbs;
    totalFat += meal.totalFat;
    totalFiber += meal.totalFiber;
  }

  return DailyNutrition(
    totalCalories: totalCalories,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    totalFiber: totalFiber,
    mealCount: todayMeals.length,
  );
}
```

---

## Summary

### ✅ What IS Implemented

1. **Local meal logging** - Users can log meals on device
2. **AI-powered nutrition analysis** - OpenRouter API calculates nutrition
3. **Image recognition** - AI can detect foods from photos
4. **Food validation** - Prevents logging non-food items
5. **Real-time tracking** - Nutrition goals and progress displayed
6. **Streak system** - Encourages daily logging
7. **Local persistence** - Data saved to SharedPreferences

### ❌ What is NOT Implemented

1. **Backend API for meals** - No server-side meal storage
2. **Cloud synchronization** - Data doesn't sync across devices
3. **Data backup** - Data lost when app is uninstalled
4. **Multi-device access** - Can't access meals from other devices
5. **Historical reports** - Limited to local device data
6. **Social features** - No sharing or community features

### 🔧 Technical Architecture

```
Frontend (Flutter) ──> AI Service (OpenRouter) ──> Returns Nutrition Data
       │                                                        │
       │                                                        │
       └──> Local Storage (SharedPreferences) <────────────────┘
       
       ❌ NO CONNECTION TO BACKEND SERVER FOR MEALS
```

### 💡 Recommendations for Future Development

If you want to implement backend integration:

1. **Create API Endpoints**
   - POST /api/meals (create)
   - GET /api/meals (read)
   - PUT /api/meals/{id} (update)
   - DELETE /api/meals/{id} (delete)

2. **Modify NutritionStore**
   ```dart
   @action
   Future<void> addMealEntry(MealEntry meal) async {
     mealEntries.add(meal);
     
     // ADD THIS: Save to backend
     await _saveMealToBackend(meal);
     
     // Keep local storage as backup
     await saveMealEntries();
     
     calculateStreakCount();
     updateAvatarMood();
   }
   
   Future<void> _saveMealToBackend(MealEntry meal) async {
     final response = await http.post(
       Uri.parse('${mBaseUrl}meals'),
       headers: {'Content-Type': 'application/json'},
       body: jsonEncode({
         'user_id': userStore.userId,
         ...meal.toJson(),
       }),
     );
     
     if (response.statusCode != 200) {
       throw Exception('Failed to save meal to backend');
     }
   }
   ```

3. **Implement Sync Strategy**
   - Offline-first approach
   - Queue failed requests
   - Sync when connection available
   - Handle conflicts

4. **Add Data Migration**
   - Move existing local data to backend
   - Provide sync button in settings

---

## Contact & Support

For questions about the meal logging system:
- Check the code in `lib/components/log_meal_form_component.dart`
- Review MobX store in `lib/store/NutritionStore/NutritionStore.dart`
- AI services in `lib/services/ai_service.dart` and `lib/services/food_recognition_service.dart`

**Backend URL**: https://app.dietaryguide.in  
**Status**: Meal logging NOT using backend (local storage only)

---

*Last Updated: December 29, 2025*
