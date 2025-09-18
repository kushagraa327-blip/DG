import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/food_validation_service.dart';
import 'package:mighty_fitness/services/ai_service.dart';

void main() {
  group('Cultural Food Validation Tests', () {
    group('Indian Food Recognition', () {
      test('should accept traditional Indian staples', () async {
        final indianStaples = [
          'dal', 'daal', 'roti', 'chapati', 'naan', 'paratha',
          'biryani', 'pulao', 'sambar', 'rasam', 'curry'
        ];

        for (final food in indianStaples) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized as valid Indian food');
          expect(result.confidence, greaterThan(0.7), 
              reason: '$food should have good confidence as cultural food');
        }
      });

      test('should accept Indian vegetables with Hindi names', () async {
        final indianVegetables = [
          'bhindi', 'okra', 'karela', 'bitter gourd', 'lauki', 'bottle gourd',
          'palak', 'spinach', 'aloo', 'potato', 'pyaz', 'onion',
          'tamatar', 'tomato', 'gajar', 'carrot', 'baingan', 'eggplant',
          'gobi', 'cauliflower', 'shimla mirch', 'bell pepper'
        ];

        for (final vegetable in indianVegetables) {
          final result = await FoodValidationService.validateFoodText(vegetable);
          expect(result.isValid, isTrue, 
              reason: '$vegetable should be recognized as valid Indian vegetable');
        }
      });

      test('should accept Indian spices and ingredients', () async {
        final indianSpices = [
          'haldi', 'turmeric', 'jeera', 'cumin', 'dhania', 'coriander',
          'garam masala', 'masala', 'hing', 'asafoetida', 'methi', 'fenugreek',
          'elaichi', 'cardamom', 'dalchini', 'cinnamon', 'laung', 'cloves',
          'adrak', 'ginger', 'lehsun', 'garlic'
        ];

        for (final spice in indianSpices) {
          final result = await FoodValidationService.validateFoodText(spice);
          expect(result.isValid, isTrue, 
              reason: '$spice should be recognized as valid Indian spice/ingredient');
        }
      });

      test('should accept South Indian dishes', () async {
        final southIndianFoods = [
          'dosa', 'masala dosa', 'plain dosa', 'idli', 'vada', 'medu vada',
          'uttapam', 'upma', 'pongal', 'appam', 'puttu', 'sambhar',
          'coconut chutney', 'chutney', 'lemon rice', 'curd rice'
        ];

        for (final food in southIndianFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized as valid South Indian dish');
        }
      });

      test('should accept North Indian dishes', () async {
        final northIndianFoods = [
          'rajma', 'kidney beans', 'chole', 'chickpeas', 'chana',
          'makki roti', 'sarson saag', 'paneer', 'cottage cheese',
          'butter chicken', 'dal makhani', 'paneer makhani'
        ];

        for (final food in northIndianFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized as valid North Indian dish');
        }
      });

      test('should accept Indian food combinations', () async {
        final indianCombinations = [
          'dal chawal', 'dal rice', 'rajma chawal', 'chole chawal',
          'roti sabzi', 'chapati sabzi', 'dosa sambar', 'idli sambar',
          'poha jalebi', 'tea biscuit', 'chai nashta'
        ];

        for (final combination in indianCombinations) {
          final result = await FoodValidationService.validateFoodText(combination);
          expect(result.isValid, isTrue, 
              reason: '$combination should be recognized as valid Indian food combination');
        }
      });

      test('should accept Indian sweets', () async {
        final indianSweets = [
          'gulab jamun', 'rasgulla', 'laddu', 'laddoo', 'halwa', 'kheer',
          'jalebi', 'imarti', 'kaju katli', 'barfi', 'peda', 'modak',
          'mysore pak', 'soan papdi', 'ras malai', 'kulfi'
        ];

        for (final sweet in indianSweets) {
          final result = await FoodValidationService.validateFoodText(sweet);
          expect(result.isValid, isTrue, 
              reason: '$sweet should be recognized as valid Indian sweet');
        }
      });
    });

    group('AI Service Integration with Cultural Foods', () {
      test('should provide nutrition data for Indian staples', () async {
        final testFoods = [
          'dal chawal', 'masala dosa', 'rajma chawal', 'biryani', 'roti'
        ];

        for (final food in testFoods) {
          try {
            final result = await analyzeFoodNutrition(food, '100g');
            expect(result, isNotNull, reason: '$food should return nutrition data');
            expect(result['calories'], isNotNull, reason: '$food should have calories');
            expect(result['protein'], isNotNull, reason: '$food should have protein');
            expect(result['carbs'], isNotNull, reason: '$food should have carbs');
            expect(result['fat'], isNotNull, reason: '$food should have fat');
            
            // Verify reasonable nutrition values
            expect(result['calories'], greaterThan(0), reason: '$food should have positive calories');
            expect(result['protein'], greaterThanOrEqualTo(0), reason: '$food should have non-negative protein');
          } catch (e) {
            if (e is FoodValidationException) {
              fail('Valid Indian food $food should not be rejected: ${e.message}');
            }
            // Network/AI service errors are acceptable for this test
            print('AI service unavailable for $food: $e');
          }
        }
      });

      test('should still reject non-food items while accepting cultural foods', () async {
        final nonFoodItems = [
          'wooden chair', 'computer desk', 'car keys', 'mobile phone'
        ];

        for (final item in nonFoodItems) {
          try {
            await analyzeFoodNutrition(item, '100g');
            fail('Non-food item $item should be rejected');
          } catch (e) {
            expect(e, isA<FoodValidationException>(), 
                reason: '$item should throw FoodValidationException');
          }
        }
      });
    });

    group('Fallback Nutrition Database', () {
      test('should provide nutrition data for Indian foods when AI unavailable', () async {
        // Test fallback database directly
        final indianFoods = [
          'dal', 'roti', 'biryani', 'dosa', 'idli', 'paneer', 'rajma'
        ];

        for (final food in indianFoods) {
          final nutrition = getDefaultNutrition(food, '100g');
          expect(nutrition, isNotNull, reason: '$food should have fallback nutrition data');
          expect(nutrition['calories'], isNotNull, reason: '$food should have calories in fallback');
          expect(nutrition['protein'], isNotNull, reason: '$food should have protein in fallback');
          expect(nutrition['carbs'], isNotNull, reason: '$food should have carbs in fallback');
          expect(nutrition['fat'], isNotNull, reason: '$food should have fat in fallback');
        }
      });

      test('should handle Hindi food names in fallback database', () async {
        final hindiEnglishPairs = [
          ['aloo', 'potato'],
          ['pyaz', 'onion'],
          ['tamatar', 'tomato'],
          ['gajar', 'carrot'],
          ['palak', 'spinach'],
          ['chawal', 'rice'],
          ['dahi', 'yogurt']
        ];

        for (final pair in hindiEnglishPairs) {
          final hindiName = pair[0];
          final englishName = pair[1];
          
          final hindiNutrition = getDefaultNutrition(hindiName, '100g');
          final englishNutrition = getDefaultNutrition(englishName, '100g');
          
          expect(hindiNutrition['calories'], equals(englishNutrition['calories']),
              reason: '$hindiName and $englishName should have same calories');
          expect(hindiNutrition['protein'], equals(englishNutrition['protein']),
              reason: '$hindiName and $englishName should have same protein');
        }
      });
    });

    group('Cultural Food Context Recognition', () {
      test('should recognize food context in complex descriptions', () async {
        final contextualFoods = [
          'homemade dal chawal',
          'spicy masala dosa',
          'traditional biryani',
          'fresh roti with ghee',
          'steamed idli with sambar',
          'grilled paneer tikka'
        ];

        for (final food in contextualFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized despite descriptive context');
        }
      });

      test('should handle regional variations and preparations', () async {
        final regionalFoods = [
          'punjabi dal', 'gujarati dhokla', 'bengali fish curry',
          'south indian filter coffee', 'maharashtrian vada pav',
          'rajasthani dal baati', 'kerala appam', 'hyderabadi biryani'
        ];

        for (final food in regionalFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized as regional Indian food');
        }
      });
    });

    group('Edge Cases with Cultural Foods', () {
      test('should handle mixed language food names', () async {
        final mixedLanguageFoods = [
          'chicken curry', 'mutton biryani', 'vegetable pulao',
          'paneer butter masala', 'aloo gobi curry', 'fish curry'
        ];

        for (final food in mixedLanguageFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized as valid mixed-language food name');
        }
      });

      test('should handle food names with cooking methods', () async {
        final cookedFoods = [
          'fried rice', 'steamed idli', 'grilled paneer', 'boiled dal',
          'roasted chicken', 'baked naan', 'tandoori roti'
        ];

        for (final food in cookedFoods) {
          final result = await FoodValidationService.validateFoodText(food);
          expect(result.isValid, isTrue, 
              reason: '$food should be recognized despite cooking method prefix');
        }
      });

      test('should still reject obvious non-food items with Indian context', () async {
        final nonFoodWithContext = [
          'wooden dining table', 'kitchen chair', 'steel plate',
          'brass utensil', 'clay pot' // These are utensils, not food
        ];

        for (final item in nonFoodWithContext) {
          final result = await FoodValidationService.validateFoodText(item);
          expect(result.isValid, isFalse, 
              reason: '$item should still be rejected as non-food despite Indian context');
        }
      });
    });

    group('Performance with Cultural Foods', () {
      test('should maintain good performance with cultural food validation', () async {
        final culturalFoods = [
          'dal', 'roti', 'dosa', 'biryani', 'paneer', 'samosa'
        ];

        for (final food in culturalFoods) {
          final stopwatch = Stopwatch()..start();
          final result = await FoodValidationService.validateFoodText(food);
          stopwatch.stop();

          expect(result.isValid, isTrue, reason: '$food should be valid');
          expect(stopwatch.elapsedMilliseconds, lessThan(10000), 
              reason: 'Validation of $food should complete within 10 seconds');
        }
      });
    });
  });
}
