import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/food_validation_service.dart';

void main() {
  group('FoodValidationService', () {
    group('validateFoodText', () {
      test('should validate actual food items as valid', () async {
        final validFoods = [
          'apple',
          'chicken breast',
          'brown rice',
          'salmon',
          'broccoli',
          'whole wheat bread',
          'greek yogurt',
          'almonds',
          'spinach',
          'sweet potato'
        ];

        for (final food in validFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, reason: '$food should be valid');
          expect(result.confidence, greaterThan(0.5), reason: '$food should have reasonable confidence');
        }
      });

      test('should reject obvious non-food items', () async {
        final nonFoodItems = [
          'wooden chair',
          'computer desk',
          'television remote',
          'car keys',
          'mobile phone',
          'kitchen table',
          'office chair',
          'laptop computer',
          'bedroom furniture',
          'cleaning detergent'
        ];

        for (final item in nonFoodItems) {
          final result = await FoodValidationService.validateFoodText(item);
          expect(result.isValid, isFalse, reason: '$item should be invalid');
          expect(result.errorMessage, isNotNull, reason: '$item should have error message');
          expect(result.errorMessage, contains('Invalid input, please enter food items only'));
        }
      });

      test('should handle edge cases appropriately', () async {
        // Empty string
        final emptyResult = await FoodValidationService.validateFoodText('');
        expect(emptyResult.isValid, isFalse);

        // Very long string
        final longString = 'a' * 200;
        final longResult = await FoodValidationService.validateFoodText(longString);
        expect(longResult.isValid, isFalse);

        // Special characters only
        final specialResult = await FoodValidationService.validateFoodText('!@#\$%^&*()');
        expect(specialResult.isValid, isFalse);

        // Numbers only
        final numberResult = await FoodValidationService.validateFoodText('12345');
        expect(numberResult.isValid, isFalse);
      });

      test('should handle ambiguous cases with appropriate confidence', () async {
        final ambiguousCases = [
          'protein powder', // Could be food supplement
          'vitamin C', // Could be supplement
          'energy drink', // Beverage but processed
          'ice cream', // Food but processed
        ];

        for (final item in ambiguousCases) {
          final result = await FoodValidationService.validateFoodText(item);
          // These should either be valid with lower confidence or invalid with explanation
          if (result.isValid) {
            expect(result.confidence, lessThan(0.9), reason: '$item should have lower confidence if valid');
          } else {
            expect(result.errorMessage, isNotNull, reason: '$item should have error message if invalid');
          }
        }
      });
    });

    group('FoodValidationResult', () {
      test('should create result with all properties', () {
        final result = FoodValidationResult(
          isValid: true,
          errorMessage: null,
          confidence: 0.95,
          detectedType: 'food',
          reason: 'Common fruit',
          detectedFoods: ['apple'],
        );

        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.confidence, equals(0.95));
        expect(result.detectedType, equals('food'));
        expect(result.reason, equals('Common fruit'));
        expect(result.detectedFoods, equals(['apple']));
      });

      test('should have meaningful toString representation', () {
        final result = FoodValidationResult(
          isValid: false,
          errorMessage: 'Not a food item',
          confidence: 0.98,
          detectedType: 'non-food',
          reason: 'Furniture item',
        );

        final stringRep = result.toString();
        expect(stringRep, contains('isValid: false'));
        expect(stringRep, contains('confidence: 0.98'));
        expect(stringRep, contains('type: non-food'));
        expect(stringRep, contains('reason: Furniture item'));
      });
    });

    group('Pre-validation logic', () {
      test('should quickly identify obvious non-food keywords', () async {
        // Test the quick pre-validation by using items that should be caught immediately
        final quickRejectItems = [
          'wooden chair and table',
          'computer keyboard',
          'television screen',
          'car dashboard',
          'phone charger',
        ];

        for (final item in quickRejectItems) {
          final result = await FoodValidationService.validateFoodText(item);
          expect(result.isValid, isFalse, reason: '$item should be quickly rejected');
          expect(result.confidence, greaterThan(0.9), reason: '$item should have high confidence rejection');
        }
      });

      test('should allow food items to pass pre-validation', () async {
        final foodItems = [
          'grilled chicken with vegetables',
          'fresh fruit salad',
          'whole grain pasta',
          'organic spinach leaves',
        ];

        for (final item in foodItems) {
          // These should not be rejected by pre-validation
          // (though they may still be validated by AI)
          final result = await FoodValidationService.validateFoodText(item);
          // We expect these to either pass validation or be handled by AI
          // The key is they shouldn't be rejected with 0.95 confidence from pre-validation
          if (!result.isValid) {
            expect(result.confidence, lessThan(0.95), 
                reason: '$item should not be rejected with high confidence by pre-validation');
          }
        }
      });
    });

    group('Error handling', () {
      test('should handle AI service errors gracefully', () async {
        // Test with a food item that might cause AI service issues
        // The service should handle errors and provide a reasonable fallback
        final result = await FoodValidationService.validateFoodText('quinoa');
        
        // Should either succeed or fail gracefully with appropriate confidence
        if (!result.isValid) {
          expect(result.confidence, lessThan(0.8), 
              reason: 'On AI error, confidence should be lower');
        }
        
        // Should not throw exceptions
        expect(result, isNotNull);
        expect(result.detectedType, isNotNull);
      });
    });
  });

  group('Integration with AI Service', () {
    test('should work with analyzeFoodNutrition for valid foods', () async {
      // This test would require the AI service to be available
      // For now, we'll just test that the validation service can be called
      final result = await FoodValidationService.validateFoodText('banana');
      expect(result, isNotNull);
      expect(result.detectedType, isNotNull);
    });

    test('should reject non-food items before AI analysis', () async {
      final result = await FoodValidationService.validateFoodText('wooden chair');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid input, please enter food items only'));
    });
  });
}
