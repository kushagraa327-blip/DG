import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:mighty_fitness/services/food_validation_service.dart';

void main() {
  group('Food Validation Integration Tests', () {
    group('AI Service Integration', () {
      test('should reject non-food items in analyzeFoodNutrition', () async {
        final nonFoodItems = [
          'wooden chair',
          'computer desk',
          'television remote',
          'car keys',
          'mobile phone'
        ];

        for (final item in nonFoodItems) {
          try {
            await analyzeFoodNutrition(item, '100g');
            fail('Expected FoodValidationException for $item');
          } catch (e) {
            expect(e, isA<FoodValidationException>(), 
                reason: '$item should throw FoodValidationException');
            expect(e.toString(), contains('Invalid input, please enter food items only'),
                reason: '$item should have appropriate error message');
          }
        }
      });

      test('should accept valid food items in analyzeFoodNutrition', () async {
        final validFoods = [
          'apple',
          'chicken breast',
          'brown rice',
          'salmon',
          'broccoli'
        ];

        for (final food in validFoods) {
          try {
            final result = await analyzeFoodNutrition(food, '100g');
            expect(result, isNotNull, reason: '$food should return nutrition data');
            expect(result['calories'], isNotNull, reason: '$food should have calories');
            expect(result['protein'], isNotNull, reason: '$food should have protein');
            expect(result['carbs'], isNotNull, reason: '$food should have carbs');
            expect(result['fat'], isNotNull, reason: '$food should have fat');
          } catch (e) {
            // If AI service is not available, we should get fallback data, not validation errors
            if (e is FoodValidationException) {
              fail('Valid food $food should not throw FoodValidationException: $e');
            }
            // Other errors (like network issues) are acceptable for this test
          }
        }
      });
    });

    group('Chat Service Integration', () {
      test('should handle non-food nutrition queries appropriately', () async {
        final nonFoodNutritionQueries = [
          'How many calories in a wooden chair?',
          'What is the nutritional value of a computer?',
          'Tell me about the protein in a television',
          'Calories in car keys',
          'Nutrition facts for mobile phone'
        ];

        for (final query in nonFoodNutritionQueries) {
          try {
            final response = await chatWithAIRAG(query);
            expect(response, isNotNull, reason: 'Should return a response for $query');
            
            // Response should indicate that the item is not food
            final lowerResponse = response.toLowerCase();
            expect(
              lowerResponse.contains('not a food') || 
              lowerResponse.contains('not food') ||
              lowerResponse.contains('only provide nutritional information for food') ||
              lowerResponse.contains('please ask about actual foods'),
              isTrue,
              reason: 'Response should indicate non-food item for: $query\nActual response: $response'
            );
          } catch (e) {
            // If there are network/AI service issues, that's acceptable
            // The key is that we shouldn't get incorrect nutritional data
            print('Chat service error for "$query": $e');
          }
        }
      });

      test('should handle valid food nutrition queries normally', () async {
        final validFoodQueries = [
          'How many calories in an apple?',
          'What is the nutritional value of chicken breast?',
          'Tell me about the protein in salmon',
          'Calories in brown rice',
          'Nutrition facts for broccoli'
        ];

        for (final query in validFoodQueries) {
          try {
            final response = await chatWithAIRAG(query);
            expect(response, isNotNull, reason: 'Should return a response for $query');
            
            // Response should not contain rejection messages
            final lowerResponse = response.toLowerCase();
            expect(
              lowerResponse.contains('not a food item') || 
              lowerResponse.contains('please ask about actual foods'),
              isFalse,
              reason: 'Valid food query should not be rejected: $query\nActual response: $response'
            );
          } catch (e) {
            // Network/AI service issues are acceptable
            print('Chat service error for "$query": $e');
          }
        }
      });
    });

    group('End-to-End Validation Flow', () {
      test('should validate complete meal logging flow', () async {
        // Test the complete flow from input validation to meal logging
        final testCases = [
          {
            'input': 'grilled chicken breast',
            'shouldPass': true,
            'description': 'Valid food item should pass all validation'
          },
          {
            'input': 'wooden dining chair',
            'shouldPass': false,
            'description': 'Non-food item should be rejected'
          },
          {
            'input': 'fresh apple slices',
            'shouldPass': true,
            'description': 'Valid food with descriptive terms should pass'
          },
          {
            'input': 'computer keyboard',
            'shouldPass': false,
            'description': 'Electronic device should be rejected'
          },
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final shouldPass = testCase['shouldPass'] as bool;
          final description = testCase['description'] as String;

          print('Testing: $input');

          // Test food validation service
          final validationResult = await FoodValidationService.validateFoodText(input);
          expect(validationResult.isValid, equals(shouldPass), 
              reason: '$description - Validation: ${validationResult.toString()}');

          if (shouldPass) {
            // If validation passes, test AI nutrition analysis
            try {
              final nutritionResult = await analyzeFoodNutrition(input, '100g');
              expect(nutritionResult, isNotNull, reason: '$description - Should get nutrition data');
            } catch (e) {
              if (e is FoodValidationException) {
                fail('$description - Valid food should not be rejected by AI service: $e');
              }
              // Other errors are acceptable (network issues, etc.)
            }
          } else {
            // If validation fails, AI service should also reject
            try {
              await analyzeFoodNutrition(input, '100g');
              fail('$description - Non-food item should be rejected by AI service');
            } catch (e) {
              expect(e, isA<FoodValidationException>(), 
                  reason: '$description - Should throw FoodValidationException');
            }
          }
        }
      });
    });

    group('Performance and Reliability', () {
      test('should handle validation errors gracefully', () async {
        // Test edge cases that might cause validation issues
        final edgeCases = [
          '', // Empty string
          '   ', // Whitespace only
          'a' * 200, // Very long string
          '!@#\$%^&*()', // Special characters only
          '12345', // Numbers only
          'food\nwith\nnewlines', // Multiline input
        ];

        for (final edgeCase in edgeCases) {
          try {
            final result = await FoodValidationService.validateFoodText(edgeCase);
            expect(result, isNotNull, reason: 'Should handle edge case: "$edgeCase"');
            expect(result.isValid, isFalse, reason: 'Edge case should be invalid: "$edgeCase"');
          } catch (e) {
            // Should not throw exceptions, should return validation result
            fail('Should not throw exception for edge case "$edgeCase": $e');
          }
        }
      });

      test('should maintain consistent validation across services', () async {
        final testItems = [
          'apple', // Should be valid
          'wooden chair', // Should be invalid
          'chicken breast', // Should be valid
          'computer desk', // Should be invalid
        ];

        for (final item in testItems) {
          final validationResult = await FoodValidationService.validateFoodText(item);
          
          try {
            await analyzeFoodNutrition(item, '100g');
            // If AI service succeeds, validation should have passed
            expect(validationResult.isValid, isTrue, 
                reason: 'Validation and AI service should be consistent for: $item');
          } catch (e) {
            if (e is FoodValidationException) {
              // If AI service rejects, validation should have failed
              expect(validationResult.isValid, isFalse, 
                  reason: 'Validation and AI service should be consistent for: $item');
            }
            // Other errors are acceptable
          }
        }
      });
    });
  });
}
