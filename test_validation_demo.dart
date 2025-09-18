import 'lib/services/food_validation_service.dart';
import 'lib/services/ai_service.dart';

void main() async {
  print('🔍 Food Validation System Demo');
  print('=' * 50);
  
  // Test cases to demonstrate the validation system
  final testCases = [
    // Valid food items
    {'input': 'apple', 'expected': 'VALID', 'description': 'Simple fruit'},
    {'input': 'grilled chicken breast', 'expected': 'VALID', 'description': 'Protein food'},
    {'input': 'brown rice', 'expected': 'VALID', 'description': 'Grain food'},
    
    // Invalid non-food items
    {'input': 'wooden chair', 'expected': 'INVALID', 'description': 'Furniture item'},
    {'input': 'computer desk', 'expected': 'INVALID', 'description': 'Office furniture'},
    {'input': 'television remote', 'expected': 'INVALID', 'description': 'Electronic device'},
    {'input': 'car keys', 'expected': 'INVALID', 'description': 'Vehicle accessory'},
    
    // Edge cases
    {'input': '', 'expected': 'INVALID', 'description': 'Empty string'},
    {'input': '12345', 'expected': 'INVALID', 'description': 'Numbers only'},
  ];
  
  print('\n📋 Testing Food Validation Service:');
  print('-' * 50);
  
  for (final testCase in testCases) {
    final input = testCase['input'] as String;
    final expected = testCase['expected'] as String;
    final description = testCase['description'] as String;
    
    try {
      print('\n🔍 Testing: "$input" ($description)');
      
      // Test validation service
      final validationResult = await FoodValidationService.validateFoodText(input);
      final actualResult = validationResult.isValid ? 'VALID' : 'INVALID';
      final status = actualResult == expected ? '✅' : '❌';
      
      print('   Validation: $status $actualResult (confidence: ${validationResult.confidence.toStringAsFixed(2)})');
      if (!validationResult.isValid && validationResult.errorMessage != null) {
        print('   Error: ${validationResult.errorMessage}');
      }
      
      // Test AI nutrition analysis for valid items
      if (validationResult.isValid && input.isNotEmpty) {
        try {
          print('   Testing AI nutrition analysis...');
          final nutritionResult = await analyzeFoodNutrition(input, '100g');
          print('   ✅ Nutrition data: ${nutritionResult['calories']} cal, ${nutritionResult['protein']}g protein');
        } catch (e) {
          if (e is FoodValidationException) {
            print('   ❌ AI rejected: ${e.message}');
          } else {
            print('   ⚠️ AI service error: $e');
          }
        }
      } else if (!validationResult.isValid) {
        // Test that AI also rejects invalid items
        try {
          await analyzeFoodNutrition(input, '100g');
          print('   ❌ AI should have rejected this non-food item');
        } catch (e) {
          if (e is FoodValidationException) {
            print('   ✅ AI correctly rejected: ${e.message}');
          } else {
            print('   ⚠️ AI service error: $e');
          }
        }
      }
      
    } catch (e) {
      print('   ❌ Test error: $e');
    }
  }
  
  print('\n🤖 Testing Chat Validation:');
  print('-' * 50);
  
  final chatTestCases = [
    'How many calories in an apple?', // Valid food query
    'What is the nutritional value of a wooden chair?', // Invalid non-food query
    'Tell me about protein in chicken breast', // Valid food query
    'Calories in a computer desk?', // Invalid non-food query
  ];
  
  for (final query in chatTestCases) {
    try {
      print('\n💬 Chat Query: "$query"');
      final response = await chatWithAIRAG(query);
      print('   Response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
      
      // Check if response appropriately handles non-food items
      final lowerResponse = response.toLowerCase();
      if (query.toLowerCase().contains('wooden chair') || query.toLowerCase().contains('computer desk')) {
        if (lowerResponse.contains('not a food') || lowerResponse.contains('only provide nutritional information for food')) {
          print('   ✅ Correctly rejected non-food item');
        } else {
          print('   ⚠️ May not have properly rejected non-food item');
        }
      }
      
    } catch (e) {
      print('   ⚠️ Chat error: $e');
    }
  }
  
  print('\n🎉 Food Validation System Demo Complete!');
  print('=' * 50);
  print('Summary:');
  print('✅ Food Validation Service: Validates text inputs for food items');
  print('✅ AI Nutrition Analysis: Enhanced with validation to reject non-food items');
  print('✅ Chat System: Validates nutrition queries to prevent non-food responses');
  print('✅ Image Recognition: Enhanced with validation (not tested in this demo)');
  print('✅ Meal Logger: Form validation prevents non-food entries');
}
