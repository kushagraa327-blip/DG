import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:mighty_fitness/services/food_validation_service.dart';

class FoodRecognitionService {
  /// Generate AI analysis of the nutritional values
  static Future<String> generateNutritionAnalysis(Map<String, double> nutrition) async {
    try {
      double calories = nutrition['calories'] ?? 0;
      double protein = nutrition['protein'] ?? 0;
      double carbs = nutrition['carbs'] ?? 0;
      double fat = nutrition['fat'] ?? 0;
      double fiber = nutrition['fiber'] ?? 0;

      // Generate targeted suggestions based on nutritional profile
      String suggestion = _generateNutritionSuggestion(calories, protein, carbs, fat, fiber);
      
      return suggestion;
    } catch (e) {
      print('Error generating nutrition analysis: $e');
      return 'Moderate nutritional profile. Consider pairing with vegetables and lean proteins for balanced nutrition.';
    }
  }

  /// Generate specific nutrition suggestions within 20-39 words
  static String _generateNutritionSuggestion(double calories, double protein, double carbs, double fat, double fiber) {
    // High protein foods
    if (protein > 15) {
      if (fiber < 3) {
        return 'Excellent protein source! Pair with fiber-rich vegetables or whole grains to enhance satiety and digestive health.';
      } else {
        return 'Great protein and fiber balance! This food supports muscle maintenance and keeps you feeling full longer.';
      }
    }
    
    // High calorie foods
    if (calories > 400) {
      if (protein < 10) {
        return 'High calorie content with low protein. Consider smaller portions and pair with lean protein sources for balance.';
      } else {
        return 'Calorie-dense but protein-rich. Enjoy in moderation as part of active days or post-workout nutrition.';
      }
    }
    
    // High carb foods
    if (carbs > 30) {
      if (fiber > 5) {
        return 'Good complex carbohydrates with fiber! Ideal for sustained energy. Best consumed before or after physical activity.';
      } else {
        return 'High in simple carbs. Pair with protein and healthy fats to slow absorption and stabilize blood sugar.';
      }
    }
    
    // High fat foods
    if (fat > 15) {
      if (calories < 300) {
        return 'Rich in healthy fats! Great for hormone production and nutrient absorption. Enjoy in appropriate portions.';
      } else {
        return 'High fat and calorie content. Use sparingly and balance with low-fat, high-fiber foods throughout the day.';
      }
    }
    
    // High fiber foods
    if (fiber > 8) {
      return 'Excellent fiber content! Supports digestive health and helps maintain stable blood sugar levels throughout the day.';
    }
    
    // Low calorie foods
    if (calories < 100) {
      if (protein > 5) {
        return 'Low calorie, protein-rich option! Perfect for weight management while maintaining muscle mass and satiety.';
      } else {
        return 'Light and low-calorie choice. Great for snacking or adding volume to meals without excess calories.';
      }
    }
    
    // Balanced foods
    if (protein >= 8 && carbs <= 25 && fat <= 12 && calories <= 300) {
      return 'Well-balanced nutritional profile! Good mix of macronutrients that supports steady energy and overall health.';
    }
    
    // Default suggestion for moderate profiles
    return 'Moderate nutritional profile. Consider pairing with colorful vegetables and staying hydrated for optimal nutrition benefits.';
  }

  /// Analyze nutrition label image and extract nutritional information
  static Future<List<FoodItem>> analyzeLabelImage(File imageFile) async {
    try {
      print('🏷️ Starting nutrition label analysis...');

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Use OpenRouter Gemini for label analysis
      final result = await _callOpenRouterLabelAnalysis(base64Image);

      print('🔍 Label Analysis Response: $result');

      // Parse the JSON response
      final foodItems = _parseFoodItemsFromResponse(result);

      if (foodItems.isEmpty) {
        print('⚠️ No nutrition information detected in label');
        // Return a default item with basic structure for manual editing
        return [
          FoodItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Product from Label',
            quantity: '1 serving',
            calories: 0.0,
            protein: 0.0,
            carbs: 0.0,
            fat: 0.0,
            fiber: 0.0,
            healthScore: 50,
          )
        ];
      }

      // Calculate health score for label items and create new instances
      final updatedFoodItems = foodItems.map((item) {
        final healthScore = _calculateHealthScore(item);
        return FoodItem(
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          calories: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fat: item.fat,
          fiber: item.fiber,
          unit: item.unit,
          imagePath: item.imagePath,
          healthScore: healthScore,
        );
      }).toList();

      print('✅ Successfully analyzed nutrition label with ${updatedFoodItems.length} items');
      return updatedFoodItems;

    } catch (e) {
      print('❌ Label analysis error: $e');
      // Return a default item on error
      return [
        FoodItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Product from Label',
          quantity: '1 serving',
          calories: 0.0,
          protein: 0.0,
          carbs: 0.0,
          fat: 0.0,
          fiber: 0.0,
          healthScore: 50,
        )
      ];
    }
  }

  /// Calculate health score based on nutritional values
  static int _calculateHealthScore(FoodItem item) {
    int score = 50; // Base score
    
    // Protein bonus (up to +20)
    if (item.protein > 0) {
      score += (item.protein * 2).clamp(0, 20).toInt();
    }
    
    // Fiber bonus (up to +15)
    if (item.fiber > 0) {
      score += (item.fiber * 3).clamp(0, 15).toInt();
    }
    
    // Calorie penalty for high calorie items
    if (item.calories > 400) {
      score -= ((item.calories - 400) / 50).clamp(0, 20).toInt();
    }
    
    // Fat penalty for high fat items
    if (item.fat > 15) {
      score -= ((item.fat - 15) * 2).clamp(0, 15).toInt();
    }
    
    return score.clamp(0, 100);
  }

  /// Analyze food image and return recognized food items with nutritional data
  static Future<List<FoodItem>> analyzeFoodImage(File imageFile) async {
    try {
      print('🍽️ Starting food image analysis with validation...');

      // First, validate that the image contains food items
      final validation = await FoodValidationService.validateFoodImage(imageFile);
      print('🔍 Image validation result: $validation');

      if (!validation.isValid) {
        print('❌ Image validation failed: ${validation.errorMessage}');
        if (validation.detectedType == 'non-food') {
          throw FoodValidationException('No food items detected in image. Please upload an image containing food.');
        } else {
          throw FoodValidationException(validation.errorMessage ?? 'Could not analyze image');
        }
      }

      // If validation passes with low confidence, add a warning but continue
      if (validation.confidence < 0.7) {
        print('⚠️ Low confidence image validation (${validation.confidence}), proceeding with caution');
      }

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Use OpenRouter Gemini for vision analysis (better reliability and performance)
      final result = await _callOpenRouterGeminiVision(base64Image);

      print('🔍 OpenRouter Gemini Vision Response: $result');

      // Parse the JSON response
      final foodItems = _parseFoodItemsFromResponse(result);

      if (foodItems.isEmpty) {
        print('⚠️ No food items detected in detailed analysis');
        throw FoodValidationException('No food items detected in the image. Please ensure the image contains visible food items.');
      }

      // Additional validation: check if detected items are actually food
      final validatedFoodItems = <FoodItem>[];
      for (final item in foodItems) {
        try {
          final itemValidation = await FoodValidationService.validateFoodText(item.name);
          if (itemValidation.isValid) {
            validatedFoodItems.add(item);
          } else {
            print('⚠️ Filtered out non-food item: ${item.name}');
          }
        } catch (e) {
          print('⚠️ Could not validate item ${item.name}, including anyway: $e');
          validatedFoodItems.add(item); // Include on validation error to avoid being too strict
        }
      }

      if (validatedFoodItems.isEmpty) {
        throw FoodValidationException('No valid food items found in image after validation.');
      }

      print('✅ Successfully identified ${validatedFoodItems.length} validated food items');
      return validatedFoodItems;

    } catch (e) {
      print('❌ Food recognition error: $e');
      // Re-throw FoodValidationException as-is, wrap others
      if (e is FoodValidationException) {
        rethrow;
      }
      throw Exception('Failed to analyze food image: ${e.toString()}');
    }
  }

  /// Call OpenRouter Gemini for nutrition label analysis
  static Future<String> _callOpenRouterLabelAnalysis(String base64Image) async {
    try {
      print('🌐 Making API call to OpenRouter Gemini for label analysis...');

      final requestBody = {
        'model': 'google/gemini-2.5-flash',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '''Analyze this nutrition label image and extract the nutritional information. Look for standard nutrition facts panels, ingredient lists, and serving size information.

IMPORTANT: Extract ONLY the nutritional values from the label. Look for:
- Product name (if visible)
- Serving size
- Calories per serving
- Protein content
- Total carbohydrates
- Total fat
- Dietary fiber
- Any other nutritional information clearly visible

If this is NOT a nutrition label or no nutritional information is visible, respond with an empty array: []

For the nutrition information you can extract, provide it in this exact JSON format:
[
  {
    "name": "product name from label or 'Product from Label' if not visible",
    "quantity": "serving size from label (e.g., '1 cup', '100g', '1 serving')",
    "calories": calories_per_serving_as_number,
    "protein": protein_grams_as_number,
    "carbs": total_carbs_grams_as_number,
    "fat": total_fat_grams_as_number,
    "fiber": fiber_grams_as_number_or_0_if_not_available,
    "confidence": confidence_percentage_0_to_100,
    "isFood": true
  }
]

Guidelines:
1. Extract values exactly as shown on the label
2. Use the serving size specified on the label
3. If a value is not visible or unclear, use 0
4. Only respond with the JSON array, no additional text
5. Be precise with numerical values from the label'''
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'max_tokens': 2048,
        'temperature': 0.1,
      };

      const url = 'https://openrouter.ai/api/v1/chat/completions';
      print('🌐 OpenRouter Label Analysis API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer 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',
          'HTTP-Referer': 'https://github.com/CodeWithJainendra/Dietary-Guide',
          'X-Title': 'Mighty Fitness AI Assistant',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 OpenRouter Label Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📋 OpenRouter Label Raw response: ${response.body}');

        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {

          final content = responseData['choices'][0]['message']['content'];
          print('🔍 OpenRouter Label Extracted content: $content');

          return content;
        }
      }

      print('❌ OpenRouter Label API call failed with status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      throw Exception('OpenRouter Label API failed with status ${response.statusCode}: ${response.body}');

    } catch (e) {
      print('❌ Error in OpenRouter Label API call: $e');
      throw Exception('Label analysis failed: $e');
    }
  }

  /// Call OpenRouter Gemini 2.5 Flash for food analysis (Primary method)
  static Future<String> _callOpenRouterGeminiVision(String base64Image) async {
    try {
      print('🌐 Making API call to OpenRouter Gemini 2.5 Flash...');

      final requestBody = {
        'model': 'google/gemini-2.5-flash', // Updated to use Gemini 2.5 Flash
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '''Analyze this image and identify ONLY actual food items that can be consumed by humans. Be inclusive of ALL cultural cuisines including Indian, Asian, African, Middle Eastern, and other traditional foods.

IMPORTANT: Recognize foods from ALL cultures and cuisines:
- Indian foods: dal, curry, roti, naan, dosa, idli, biryani, sambar, rasam, sabzi, etc.
- Traditional dishes: thali presentations, regional specialties, cultural preparations
- Spices and ingredients: turmeric, cumin, masala preparations, traditional seasonings
- Cultural cooking methods: tandoori, fried, steamed, traditional preparations

CRITICAL: Only identify items that are actual food, beverages, or edible ingredients. Do NOT identify:
- Non-food objects (plates, utensils, furniture, decorations, etc.)
- Inedible items (flowers, candles, napkins, etc.)
- People, hands, or body parts
- Kitchen equipment or appliances

If the image contains NO food items, respond with an empty array: []

For each FOOD item you can identify, estimate the quantity based on visual portion size and provide detailed nutritional information.

Important guidelines:
- ONLY identify actual edible food items, beverages, or ingredients from ANY culture
- Be INCLUSIVE of cultural foods - recognize traditional presentations and names
- Identify EVERY food item you can see, even small portions
- Consider the actual visual quantity/portion size for each item
- If there are multiple pieces of the same food, count them (e.g., "3 pieces of chicken", "2 rotis")
- Be specific about quantities based on what you actually see
- Include condiments, sauces, and garnishes if they are edible
- Use both common and cultural names when appropriate (e.g., "dal (lentil curry)")

Respond with a JSON array of ONLY food items in this exact format:
[
  {
    "name": "specific food item name",
    "quantity": "estimated quantity based on visual portion (e.g., 150g chicken breast, 2 slices bread, 1/2 cup rice)",
    "calories": estimated_calories_for_this_portion,
    "protein": estimated_protein_grams_for_this_portion,
    "carbs": estimated_carbs_grams_for_this_portion,
    "fat": estimated_fat_grams_for_this_portion,
    "fiber": estimated_fiber_grams_for_this_portion,
    "confidence": confidence_percentage_0_to_100,
    "isFood": true
  }
]

Make sure to:
1. ONLY identify actual food items - ignore all non-food objects
2. Return empty array [] if no food is visible
3. Base nutritional values on the ACTUAL visual portion size
4. Be specific with quantities (use grams, cups, pieces, slices as appropriate)
5. Only respond with the JSON array, no additional text'''
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'max_tokens': 4096,
        'temperature': 0.1,
      };

      const url = 'https://openrouter.ai/api/v1/chat/completions';
      print('🌐 OpenRouter Gemini API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer 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',
          'HTTP-Referer': 'https://github.com/CodeWithJainendra/Dietary-Guide',
          'X-Title': 'Mighty Fitness AI Assistant',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 OpenRouter Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📋 OpenRouter Raw response: ${response.body}');

        // Handle OpenRouter response format
        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {

          final content = responseData['choices'][0]['message']['content'];
          print('🔍 OpenRouter Extracted content: $content');

          return content;
        }
      }

      print('❌ OpenRouter Gemini API call failed with status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      throw Exception('OpenRouter API failed with status ${response.statusCode}: ${response.body}');

    } catch (e) {
      print('❌ Error in OpenRouter Gemini API call: $e');
      throw Exception('Food image analysis failed: $e');
    }
  }

  /// Call Gemini Vision API for food analysis (Fallback method)
  static Future<String> _callGeminiVision(String base64Image) async {
    try {
      print('🌐 Making API call to Gemini Vision...');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''Analyze this image and identify ONLY actual food items that can be consumed by humans. Be inclusive of ALL cultural cuisines including Indian, Asian, African, Middle Eastern, and other traditional foods.

IMPORTANT: Recognize foods from ALL cultures and cuisines:
- Indian foods: dal, curry, roti, naan, dosa, idli, biryani, sambar, rasam, sabzi, etc.
- Traditional dishes: thali presentations, regional specialties, cultural preparations
- Spices and ingredients: turmeric, cumin, masala preparations, traditional seasonings
- Cultural cooking methods: tandoori, fried, steamed, traditional preparations

CRITICAL: Only identify items that are actual food, beverages, or edible ingredients. Do NOT identify:
- Non-food objects (plates, utensils, furniture, decorations, etc.)
- Inedible items (flowers, candles, napkins, etc.)
- People, hands, or body parts
- Kitchen equipment or appliances

If the image contains NO food items, respond with an empty array: []

For each FOOD item you can identify, estimate the quantity based on visual portion size and provide detailed nutritional information.

Important guidelines:
- ONLY identify actual edible food items, beverages, or ingredients from ANY culture
- Be INCLUSIVE of cultural foods - recognize traditional presentations and names
- Identify EVERY food item you can see, even small portions
- Consider the actual visual quantity/portion size for each item
- If there are multiple pieces of the same food, count them (e.g., "3 pieces of chicken", "2 rotis")
- Be specific about quantities based on what you actually see
- Include condiments, sauces, and garnishes if they are edible
- Use both common and cultural names when appropriate (e.g., "dal (lentil curry)")

Respond with a JSON array of ONLY food items in this exact format:
[
  {
    "name": "specific food item name",
    "quantity": "estimated quantity based on visual portion (e.g., 150g chicken breast, 2 slices bread, 1/2 cup rice)",
    "calories": estimated_calories_for_this_portion,
    "protein": estimated_protein_grams_for_this_portion,
    "carbs": estimated_carbs_grams_for_this_portion,
    "fat": estimated_fat_grams_for_this_portion,
    "fiber": estimated_fiber_grams_for_this_portion,
    "confidence": confidence_percentage_0_to_100,
    "isFood": true
  }
]

Make sure to:
1. ONLY identify actual food items - ignore all non-food objects
2. Return empty array [] if no food is visible
3. Base nutritional values on the ACTUAL visual portion size
4. Be specific with quantities (use grams, cups, pieces, slices as appropriate)
5. Only respond with the JSON array, no additional text'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
        }
      };

      const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=YOUR_API_KEY';
      print('🌐 Gemini Vision API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Gemini Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📋 Gemini Raw response: ${response.body}');

        // Handle Gemini response format
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {

          final content = responseData['candidates'][0]['content']['parts'][0]['text'];
          print('🔍 Gemini Extracted content: $content');

          return content;
        }
      }

      print('❌ Gemini Vision API call failed or returned unexpected response');
      print('📄 Response body: ${response.body}');
      throw Exception('Failed to get response from Gemini Vision API');

    } catch (e) {
      print('❌ Error in Gemini Vision API call: $e');
      throw Exception('Gemini Vision API error: ${e.toString()}');
    }
  }

  /// Parse food items from AI response
  static List<FoodItem> _parseFoodItemsFromResponse(String content) {
    try {
      // Clean the response to extract JSON
      String cleanedContent = content.trim();
      if (cleanedContent.startsWith('```json')) {
        cleanedContent = cleanedContent.substring(7);
      }
      if (cleanedContent.endsWith('```')) {
        cleanedContent = cleanedContent.substring(0, cleanedContent.length - 3);
      }
      cleanedContent = cleanedContent.trim();

      final List<dynamic> foodData = jsonDecode(cleanedContent);
      print('✅ Successfully parsed ${foodData.length} food items');

      return foodData.map<FoodItem>((item) {
        return FoodItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${(item['name']?.toString() ?? 'unknown').replaceAll(' ', '_')}',
          name: item['name']?.toString() ?? 'Unknown Food',
          quantity: item['quantity']?.toString() ?? '1 serving',
          calories: (item['calories'] as num?)?.toDouble() ?? 0.0,
          protein: (item['protein'] as num?)?.toDouble() ?? 0.0,
          carbs: (item['carbs'] as num?)?.toDouble() ?? 0.0,
          fat: (item['fat'] as num?)?.toDouble() ?? 0.0,
          fiber: (item['fiber'] as num?)?.toDouble() ?? 0.0,
          healthScore: (item['confidence'] as num?)?.toInt() ?? 50,
        );
      }).toList();

    } catch (parseError) {
      print('❌ Error parsing JSON response: $parseError');
      print('📄 Content that failed to parse: $content');

      // Fallback: try to extract food names using simple text analysis
      return _fallbackFoodExtraction(content);
    }
  }
  
  /// Fallback method to extract food items from text response
  static List<FoodItem> _fallbackFoodExtraction(String content) {
    print('🔄 Using fallback food extraction...');
    
    // Simple fallback - create a generic food item
    return [
      FoodItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_fallback',
        name: 'Food Item (from image)',
        quantity: '1 serving',
        calories: 200.0,
        protein: 10.0,
        carbs: 25.0,
        fat: 8.0,
        fiber: 3.0,
        // Note: imagePath not included in fallback as we don't have the image file reference here
      )
    ];
  }
  
  /// Get meal type suggestion based on current time
  static String suggestMealType() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 11) {
      return 'breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'lunch';
    } else if (hour >= 16 && hour < 21) {
      return 'dinner';
    } else {
      return 'snack';
    }
  }
  
  /// Aggregate multiple food items into a single combined food item for form filling
  static FoodItem aggregateFoodItems(List<FoodItem> foodItems) {
    if (foodItems.isEmpty) {
      return FoodItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_empty',
        name: 'Mixed Food Items',
        quantity: '1 serving',
        calories: 0.0,
        protein: 0.0,
        carbs: 0.0,
        fat: 0.0,
        fiber: 0.0,
      );
    }

    if (foodItems.length == 1) {
      return foodItems.first;
    }

    // Aggregate nutritional information
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;

    List<String> foodNames = [];
    List<String> quantities = [];

    for (final food in foodItems) {
      totalCalories += food.calories;
      totalProtein += food.protein;
      totalCarbs += food.carbs;
      totalFat += food.fat;
      totalFiber += food.fiber;

      foodNames.add(food.name);
      quantities.add('${food.name} (${food.quantity})');
    }

    // Create combined name and quantity description
    String combinedName = foodNames.length <= 3
        ? foodNames.join(', ')
        : '${foodNames.take(2).join(', ')} + ${foodNames.length - 2} more items';

    String combinedQuantity = 'Mixed: ${quantities.join(', ')}';

    // Limit quantity description length
    if (combinedQuantity.length > 100) {
      combinedQuantity = 'Mixed meal with ${foodItems.length} items';
    }

    return FoodItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_aggregated',
      name: combinedName,
      quantity: combinedQuantity,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      imagePath: foodItems.first.imagePath, // Use the image path from the first item
    );
  }

  /// Create individual food items for meal logging (keeps all items separate)
  static List<FoodItem> createIndividualFoodItems(List<FoodItem> recognizedFoods) {
    return recognizedFoods.map((food) => FoodItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${food.name.replaceAll(' ', '_')}',
      name: food.name,
      quantity: food.quantity,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      fiber: food.fiber,
      imagePath: food.imagePath,
    )).toList();
  }

  /// Create a meal entry from recognized food items
  static MealEntry createMealFromRecognition(List<FoodItem> foodItems, {String? customMealType}) {
    return MealEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String().split('T')[0],
      mealType: customMealType ?? suggestMealType(),
      foods: foodItems,
      timestamp: DateTime.now(),
      notes: 'Auto-detected from image',
    );
  }
}
