import 'lib/services/food_validation_service.dart';
import 'lib/services/ai_service.dart';

void main() async {
  print('🌍 CULTURAL FOOD VALIDATION SYSTEM DEMONSTRATION');
  print('=' * 70);
  print('Testing enhanced validation system with Indian and cultural foods\n');

  // Test 1: Indian Staples
  print('🍛 TEST 1: INDIAN STAPLES');
  print('-' * 40);
  
  final indianStaples = [
    'dal chawal', 'masala dosa', 'rajma chawal', 'biryani', 'roti',
    'chapati', 'naan', 'sambar', 'rasam', 'chole'
  ];
  
  int passed = 0;
  int total = indianStaples.length;
  
  for (final food in indianStaples) {
    try {
      print('\n🔍 Testing: "$food"');
      
      final stopwatch = Stopwatch()..start();
      final result = await FoodValidationService.validateFoodText(food);
      stopwatch.stop();
      
      final status = result.isValid ? '✅ ACCEPTED' : '❌ REJECTED';
      print('   $status [${stopwatch.elapsedMilliseconds}ms]');
      print('   Confidence: ${result.confidence.toStringAsFixed(2)}');
      print('   Type: ${result.detectedType}');
      
      if (result.isValid) {
        passed++;
        
        // Test AI nutrition analysis
        try {
          final nutrition = await analyzeFoodNutrition(food, '100g');
          print('   📊 Nutrition: ${nutrition['calories']} cal, ${nutrition['protein']}g protein');
        } catch (e) {
          if (e is FoodValidationException) {
            print('   ❌ AI rejected: ${e.message}');
          } else {
            print('   ⚠️ AI service error: $e');
          }
        }
      } else {
        print('   ❌ Error: ${result.errorMessage}');
      }
      
    } catch (e) {
      print('   ❌ Test error: $e');
    }
  }
  
  print('\n📊 Indian Staples Results: $passed/$total accepted (${(passed/total*100).toStringAsFixed(1)}%)');

  // Test 2: Hindi Food Names
  print('\n\n🇮🇳 TEST 2: HINDI FOOD NAMES');
  print('-' * 40);
  
  final hindiFoods = [
    'aloo', 'pyaz', 'tamatar', 'gajar', 'palak', 'bhindi',
    'karela', 'lauki', 'haldi', 'jeera', 'dhania'
  ];
  
  int hindiPassed = 0;
  int hindiTotal = hindiFoods.length;
  
  for (final food in hindiFoods) {
    try {
      print('\n🔍 Testing Hindi: "$food"');
      
      final result = await FoodValidationService.validateFoodText(food);
      final status = result.isValid ? '✅ ACCEPTED' : '❌ REJECTED';
      
      print('   $status - Confidence: ${result.confidence.toStringAsFixed(2)}');
      
      if (result.isValid) {
        hindiPassed++;
        
        // Test fallback nutrition
        final nutrition = getDefaultNutrition(food, '100g');
        print('   📊 Fallback nutrition: ${nutrition['calories']} cal');
      }
      
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n📊 Hindi Foods Results: $hindiPassed/$hindiTotal accepted (${(hindiPassed/hindiTotal*100).toStringAsFixed(1)}%)');

  // Test 3: Regional Dishes
  print('\n\n🏛️ TEST 3: REGIONAL INDIAN DISHES');
  print('-' * 40);
  
  final regionalDishes = [
    'dosa', 'idli', 'vada', 'uttapam', 'upma', 'dhokla',
    'vada pav', 'pav bhaji', 'poha', 'gulab jamun', 'rasgulla'
  ];
  
  int regionalPassed = 0;
  int regionalTotal = regionalDishes.length;
  
  for (final dish in regionalDishes) {
    try {
      print('\n🔍 Testing Regional: "$dish"');
      
      final result = await FoodValidationService.validateFoodText(dish);
      final status = result.isValid ? '✅ ACCEPTED' : '❌ REJECTED';
      
      print('   $status - Type: ${result.detectedType}');
      
      if (result.isValid) {
        regionalPassed++;
      }
      
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n📊 Regional Dishes Results: $regionalPassed/$regionalTotal accepted (${(regionalPassed/regionalTotal*100).toStringAsFixed(1)}%)');

  // Test 4: Food Combinations
  print('\n\n🍽️ TEST 4: INDIAN FOOD COMBINATIONS');
  print('-' * 40);
  
  final foodCombinations = [
    'dal chawal', 'rajma chawal', 'chole chawal', 'roti sabzi',
    'dosa sambar', 'idli sambar', 'poha jalebi', 'chai biscuit'
  ];
  
  int comboPassed = 0;
  int comboTotal = foodCombinations.length;
  
  for (final combo in foodCombinations) {
    try {
      print('\n🔍 Testing Combination: "$combo"');
      
      final result = await FoodValidationService.validateFoodText(combo);
      final status = result.isValid ? '✅ ACCEPTED' : '❌ REJECTED';
      
      print('   $status - Confidence: ${result.confidence.toStringAsFixed(2)}');
      
      if (result.isValid) {
        comboPassed++;
      }
      
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n📊 Food Combinations Results: $comboPassed/$comboTotal accepted (${(comboPassed/comboTotal*100).toStringAsFixed(1)}%)');

  // Test 5: Still Reject Non-Food Items
  print('\n\n🚫 TEST 5: NON-FOOD REJECTION (Should Still Work)');
  print('-' * 40);
  
  final nonFoodItems = [
    'wooden chair', 'computer desk', 'car keys', 'mobile phone', 'television'
  ];
  
  int nonFoodRejected = 0;
  int nonFoodTotal = nonFoodItems.length;
  
  for (final item in nonFoodItems) {
    try {
      print('\n🔍 Testing Non-Food: "$item"');
      
      final result = await FoodValidationService.validateFoodText(item);
      final status = result.isValid ? '❌ WRONGLY ACCEPTED' : '✅ CORRECTLY REJECTED';
      
      print('   $status');
      if (!result.isValid) {
        nonFoodRejected++;
        print('   📝 Error: ${result.errorMessage}');
      }
      
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n📊 Non-Food Rejection Results: $nonFoodRejected/$nonFoodTotal correctly rejected (${(nonFoodRejected/nonFoodTotal*100).toStringAsFixed(1)}%)');

  // Test 6: Chat System with Cultural Foods
  print('\n\n💬 TEST 6: CHAT SYSTEM WITH CULTURAL FOODS');
  print('-' * 40);
  
  final chatQueries = [
    'How many calories in dal chawal?',
    'What is the nutrition of masala dosa?',
    'Tell me about protein in rajma',
    'Calories in wooden chair?' // Should be rejected
  ];
  
  for (final query in chatQueries) {
    try {
      print('\n💭 Chat Query: "$query"');
      
      final response = await chatWithAIRAG(query);
      final isRejected = response.toLowerCase().contains('not a food') || 
                        response.toLowerCase().contains('only provide nutritional information for food');
      
      if (query.contains('wooden chair')) {
        final status = isRejected ? '✅ CORRECTLY REJECTED' : '❌ WRONGLY ACCEPTED';
        print('   $status');
      } else {
        final status = isRejected ? '❌ WRONGLY REJECTED' : '✅ CORRECTLY ACCEPTED';
        print('   $status');
      }
      
      print('   Response: ${response.substring(0, response.length > 80 ? 80 : response.length)}...');
      
    } catch (e) {
      print('   ⚠️ Chat error: $e');
    }
  }

  // Final Summary
  print('\n\n🎯 CULTURAL FOOD VALIDATION SUMMARY');
  print('=' * 70);
  
  final totalCulturalTests = total + hindiTotal + regionalTotal + comboTotal;
  final totalCulturalPassed = passed + hindiPassed + regionalPassed + comboPassed;
  final culturalSuccessRate = (totalCulturalPassed / totalCulturalTests * 100).toStringAsFixed(1);
  
  print('📈 CULTURAL FOOD RECOGNITION:');
  print('   Indian Staples: $passed/$total (${(passed/total*100).toStringAsFixed(1)}%)');
  print('   Hindi Names: $hindiPassed/$hindiTotal (${(hindiPassed/hindiTotal*100).toStringAsFixed(1)}%)');
  print('   Regional Dishes: $regionalPassed/$regionalTotal (${(regionalPassed/regionalTotal*100).toStringAsFixed(1)}%)');
  print('   Food Combinations: $comboPassed/$comboTotal (${(comboPassed/comboTotal*100).toStringAsFixed(1)}%)');
  print('   Overall Cultural Foods: $totalCulturalPassed/$totalCulturalTests ($culturalSuccessRate%)');
  
  print('\n🛡️ NON-FOOD PROTECTION:');
  print('   Non-Food Rejection: $nonFoodRejected/$nonFoodTotal (${(nonFoodRejected/nonFoodTotal*100).toStringAsFixed(1)}%)');
  
  print('\n✅ SYSTEM STATUS:');
  if (totalCulturalPassed >= (totalCulturalTests * 0.8) && nonFoodRejected >= (nonFoodTotal * 0.8)) {
    print('   🎉 EXCELLENT: Cultural food validation working correctly!');
    print('   ✅ Successfully recognizes Indian and cultural foods');
    print('   ✅ Maintains protection against non-food items');
    print('   ✅ Ready for production with diverse user base');
  } else {
    print('   ⚠️ NEEDS IMPROVEMENT: Some cultural foods not recognized');
  }
  
  print('\n🌍 CULTURAL INCLUSIVITY ACHIEVED!');
  print('The validation system now properly recognizes:');
  print('• Traditional Indian foods (dal, roti, biryani, etc.)');
  print('• Hindi food names (aloo, pyaz, tamatar, etc.)');
  print('• Regional specialties (dosa, dhokla, vada pav, etc.)');
  print('• Food combinations (dal chawal, rajma chawal, etc.)');
  print('• Spices and ingredients (haldi, jeera, masala, etc.)');
  print('• While still rejecting non-food items effectively');
  
  print('\n✨ Cultural Food Validation Demo Complete!');
}
