import 'dart:io';
import 'dart:convert';
import 'lib/services/food_validation_service.dart';
import 'lib/services/ai_service.dart';

class TestResult {
  final String testName;
  final String input;
  final String expected;
  final String actual;
  final bool passed;
  final double? confidence;
  final String? errorMessage;
  final int responseTimeMs;
  final String? additionalInfo;

  TestResult({
    required this.testName,
    required this.input,
    required this.expected,
    required this.actual,
    required this.passed,
    this.confidence,
    this.errorMessage,
    required this.responseTimeMs,
    this.additionalInfo,
  });

  @override
  String toString() {
    final status = passed ? '✅ PASS' : '❌ FAIL';
    final confidenceStr = confidence != null ? ' (${confidence!.toStringAsFixed(2)})' : '';
    final timeStr = '${responseTimeMs}ms';
    return '$status [$timeStr] $testName: "$input" → $actual$confidenceStr';
  }
}

class ComprehensiveValidationTester {
  final List<TestResult> results = [];
  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;

  void addResult(TestResult result) {
    results.add(result);
    totalTests++;
    if (result.passed) {
      passedTests++;
    } else {
      failedTests++;
    }
  }

  Future<void> runAllTests() async {
    print('🧪 COMPREHENSIVE FOOD VALIDATION SYSTEM TESTING');
    print('=' * 80);
    print('Starting systematic testing of all validation components...\n');

    await test1_FoodValidationService();
    await test2_AIServiceIntegration();
    await test3_ChatSystemValidation();
    await test4_EdgeCasesAndPerformance();
    
    generateFinalReport();
  }

  // Test 1: Food Validation Service Testing
  Future<void> test1_FoodValidationService() async {
    print('📋 TEST 1: FOOD VALIDATION SERVICE');
    print('-' * 50);

    // Valid food items
    final validFoods = [
      'apple', 'banana', 'orange', 'strawberry', 'blueberry',
      'chicken breast', 'salmon', 'beef', 'pork', 'turkey',
      'broccoli', 'spinach', 'carrot', 'tomato', 'lettuce',
      'brown rice', 'quinoa', 'oats', 'whole wheat bread', 'pasta',
      'milk', 'yogurt', 'cheese', 'eggs', 'almonds'
    ];

    print('\n🥗 Testing Valid Food Items:');
    for (final food in validFoods) {
      await testFoodValidation(food, 'VALID', 'Valid food item');
    }

    // Non-food items
    final nonFoodItems = [
      'wooden chair', 'computer desk', 'television remote', 'car keys',
      'mobile phone', 'laptop computer', 'kitchen table', 'office chair',
      'bedroom furniture', 'cleaning detergent', 'washing machine',
      'refrigerator', 'microwave oven', 'dining table', 'sofa couch'
    ];

    print('\n🪑 Testing Non-Food Items:');
    for (final item in nonFoodItems) {
      await testFoodValidation(item, 'INVALID', 'Non-food item');
    }

    // Edge cases
    final edgeCases = [
      {'input': '', 'expected': 'INVALID', 'desc': 'Empty string'},
      {'input': '   ', 'expected': 'INVALID', 'desc': 'Whitespace only'},
      {'input': '12345', 'expected': 'INVALID', 'desc': 'Numbers only'},
      {'input': '!@#\$%^&*()', 'expected': 'INVALID', 'desc': 'Special characters'},
      {'input': 'a' * 200, 'expected': 'INVALID', 'desc': 'Very long string'},
      {'input': 'food\nwith\nnewlines', 'expected': 'INVALID', 'desc': 'Multiline input'},
    ];

    print('\n⚠️ Testing Edge Cases:');
    for (final testCase in edgeCases) {
      await testFoodValidation(
        testCase['input']!, 
        testCase['expected']!, 
        testCase['desc']!
      );
    }

    // Ambiguous cases
    final ambiguousCases = [
      'protein powder', 'vitamin C supplement', 'energy drink',
      'diet coke', 'protein bar', 'multivitamin', 'fish oil capsule'
    ];

    print('\n🤔 Testing Ambiguous Cases:');
    for (final item in ambiguousCases) {
      await testFoodValidation(item, 'EITHER', 'Ambiguous case');
    }
  }

  // Test 2: AI Service Integration Testing
  Future<void> test2_AIServiceIntegration() async {
    print('\n\n🤖 TEST 2: AI SERVICE INTEGRATION');
    print('-' * 50);

    // Test analyzeFoodNutrition with valid foods
    final validFoodsForAI = ['apple', 'chicken breast', 'brown rice', 'salmon', 'broccoli'];
    
    print('\n🍎 Testing AI Nutrition Analysis - Valid Foods:');
    for (final food in validFoodsForAI) {
      await testAINutritionAnalysis(food, 'VALID', 'Should return nutrition data');
    }

    // Test analyzeFoodNutrition with non-food items
    final nonFoodsForAI = ['wooden chair', 'computer desk', 'car keys', 'television', 'phone'];
    
    print('\n🪑 Testing AI Nutrition Analysis - Non-Food Items:');
    for (final item in nonFoodsForAI) {
      await testAINutritionAnalysis(item, 'INVALID', 'Should throw FoodValidationException');
    }
  }

  // Test 3: Chat System Validation Testing
  Future<void> test3_ChatSystemValidation() async {
    print('\n\n💬 TEST 3: CHAT SYSTEM VALIDATION');
    print('-' * 50);

    final chatTestCases = [
      // Valid food nutrition queries
      {'query': 'How many calories in an apple?', 'expected': 'VALID', 'desc': 'Valid food nutrition query'},
      {'query': 'What is the protein content of chicken breast?', 'expected': 'VALID', 'desc': 'Valid protein query'},
      {'query': 'Tell me about the nutrition in salmon', 'expected': 'VALID', 'desc': 'Valid nutrition info query'},
      {'query': 'Calories in brown rice per cup', 'expected': 'VALID', 'desc': 'Valid calorie query'},
      
      // Invalid non-food nutrition queries
      {'query': 'How many calories in a wooden chair?', 'expected': 'INVALID', 'desc': 'Non-food nutrition query'},
      {'query': 'What is the nutritional value of a computer?', 'expected': 'INVALID', 'desc': 'Electronics nutrition query'},
      {'query': 'Tell me about protein in a car', 'expected': 'INVALID', 'desc': 'Vehicle nutrition query'},
      {'query': 'Calories in television remote', 'expected': 'INVALID', 'desc': 'Device nutrition query'},
      
      // General health questions (should pass through)
      {'query': 'What is my BMI?', 'expected': 'VALID', 'desc': 'General health query'},
      {'query': 'How much should I exercise?', 'expected': 'VALID', 'desc': 'Exercise query'},
      {'query': 'What are my fitness goals?', 'expected': 'VALID', 'desc': 'Goals query'},
    ];

    print('\n💭 Testing Chat Queries:');
    for (final testCase in chatTestCases) {
      await testChatValidation(
        testCase['query']!, 
        testCase['expected']!, 
        testCase['desc']!
      );
    }
  }

  // Test 4: Edge Cases and Performance Testing
  Future<void> test4_EdgeCasesAndPerformance() async {
    print('\n\n⚡ TEST 4: EDGE CASES & PERFORMANCE');
    print('-' * 50);

    // Performance test - measure response times
    print('\n⏱️ Performance Testing:');
    final performanceTests = ['apple', 'wooden chair', 'chicken breast', 'computer desk'];
    
    for (final item in performanceTests) {
      final stopwatch = Stopwatch()..start();
      try {
        final result = await FoodValidationService.validateFoodText(item);
        stopwatch.stop();
        
        final responseTime = stopwatch.elapsedMilliseconds;
        final status = responseTime < 5000 ? '✅ FAST' : '⚠️ SLOW';
        print('   $status ${responseTime}ms - "$item" → ${result.isValid ? 'VALID' : 'INVALID'}');
        
        addResult(TestResult(
          testName: 'Performance Test',
          input: item,
          expected: 'UNDER_5000MS',
          actual: '${responseTime}MS',
          passed: responseTime < 5000,
          responseTimeMs: responseTime,
        ));
      } catch (e) {
        stopwatch.stop();
        print('   ❌ ERROR ${stopwatch.elapsedMilliseconds}ms - "$item" → $e');
      }
    }

    // Concurrent requests test
    print('\n🔄 Concurrent Requests Test:');
    final concurrentItems = ['apple', 'wooden chair', 'salmon'];
    final futures = concurrentItems.map((item) => 
      FoodValidationService.validateFoodText(item)
    ).toList();
    
    try {
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(futures);
      stopwatch.stop();
      
      print('   ✅ Concurrent validation completed in ${stopwatch.elapsedMilliseconds}ms');
      for (int i = 0; i < results.length; i++) {
        print('      "${concurrentItems[i]}" → ${results[i].isValid ? 'VALID' : 'INVALID'}');
      }
    } catch (e) {
      print('   ❌ Concurrent test failed: $e');
    }
  }

  // Helper method to test food validation
  Future<void> testFoodValidation(String input, String expected, String description) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await FoodValidationService.validateFoodText(input);
      stopwatch.stop();
      
      final actual = result.isValid ? 'VALID' : 'INVALID';
      final passed = (expected == 'EITHER') || (actual == expected);
      
      final testResult = TestResult(
        testName: 'Food Validation',
        input: input,
        expected: expected,
        actual: actual,
        passed: passed,
        confidence: result.confidence,
        errorMessage: result.errorMessage,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        additionalInfo: description,
      );
      
      addResult(testResult);
      print('   ${testResult.toString()}');
      
      if (!passed && expected != 'EITHER') {
        print('      ⚠️ Expected: $expected, Got: $actual');
        if (result.errorMessage != null) {
          print('      📝 Error: ${result.errorMessage}');
        }
      }
      
    } catch (e) {
      stopwatch.stop();
      print('   ❌ ERROR [${stopwatch.elapsedMilliseconds}ms] $input → Exception: $e');
      
      addResult(TestResult(
        testName: 'Food Validation',
        input: input,
        expected: expected,
        actual: 'ERROR',
        passed: false,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      ));
    }
  }

  // Helper method to test AI nutrition analysis
  Future<void> testAINutritionAnalysis(String input, String expected, String description) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await analyzeFoodNutrition(input, '100g');
      stopwatch.stop();
      
      const actual = 'VALID';
      final passed = (actual == expected);
      
      print('   ✅ PASS [${stopwatch.elapsedMilliseconds}ms] AI Nutrition: "$input" → Got nutrition data');
      print('      📊 Calories: ${result['calories']}, Protein: ${result['protein']}g, Carbs: ${result['carbs']}g, Fat: ${result['fat']}g');
      
      addResult(TestResult(
        testName: 'AI Nutrition Analysis',
        input: input,
        expected: expected,
        actual: actual,
        passed: passed,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        additionalInfo: 'Calories: ${result['calories']}',
      ));
      
    } catch (e) {
      stopwatch.stop();
      
      if (e is FoodValidationException) {
        const actual = 'INVALID';
        final passed = (actual == expected);
        
        print('   ${passed ? '✅ PASS' : '❌ FAIL'} [${stopwatch.elapsedMilliseconds}ms] AI Nutrition: "$input" → Validation Exception');
        print('      📝 ${e.message}');
        
        addResult(TestResult(
          testName: 'AI Nutrition Analysis',
          input: input,
          expected: expected,
          actual: actual,
          passed: passed,
          responseTimeMs: stopwatch.elapsedMilliseconds,
          errorMessage: e.message,
        ));
      } else {
        print('   ❌ ERROR [${stopwatch.elapsedMilliseconds}ms] AI Nutrition: "$input" → $e');
        
        addResult(TestResult(
          testName: 'AI Nutrition Analysis',
          input: input,
          expected: expected,
          actual: 'ERROR',
          passed: false,
          responseTimeMs: stopwatch.elapsedMilliseconds,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  // Helper method to test chat validation
  Future<void> testChatValidation(String query, String expected, String description) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await chatWithAIRAG(query);
      stopwatch.stop();
      
      final lowerResponse = response.toLowerCase();
      bool isRejected = lowerResponse.contains('not a food') || 
                       lowerResponse.contains('only provide nutritional information for food') ||
                       lowerResponse.contains('please ask about actual foods');
      
      final actual = isRejected ? 'INVALID' : 'VALID';
      final passed = (actual == expected);
      
      print('   ${passed ? '✅ PASS' : '❌ FAIL'} [${stopwatch.elapsedMilliseconds}ms] Chat: "$query"');
      print('      💬 Response: ${response.substring(0, response.length > 80 ? 80 : response.length)}...');
      
      addResult(TestResult(
        testName: 'Chat Validation',
        input: query,
        expected: expected,
        actual: actual,
        passed: passed,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        additionalInfo: response.substring(0, response.length > 100 ? 100 : response.length),
      ));
      
    } catch (e) {
      stopwatch.stop();
      print('   ❌ ERROR [${stopwatch.elapsedMilliseconds}ms] Chat: "$query" → $e');
      
      addResult(TestResult(
        testName: 'Chat Validation',
        input: query,
        expected: expected,
        actual: 'ERROR',
        passed: false,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      ));
    }
  }

  void generateFinalReport() {
    print('\n\n📊 COMPREHENSIVE TEST REPORT');
    print('=' * 80);
    
    print('\n📈 SUMMARY STATISTICS:');
    print('   Total Tests: $totalTests');
    print('   Passed: $passedTests (${(passedTests/totalTests*100).toStringAsFixed(1)}%)');
    print('   Failed: $failedTests (${(failedTests/totalTests*100).toStringAsFixed(1)}%)');
    
    // Performance statistics
    final responseTimes = results.map((r) => r.responseTimeMs).toList();
    if (responseTimes.isNotEmpty) {
      responseTimes.sort();
      final avgTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final medianTime = responseTimes[responseTimes.length ~/ 2];
      final maxTime = responseTimes.last;
      
      print('\n⏱️ PERFORMANCE METRICS:');
      print('   Average Response Time: ${avgTime.toStringAsFixed(0)}ms');
      print('   Median Response Time: ${medianTime}ms');
      print('   Maximum Response Time: ${maxTime}ms');
    }
    
    // Failed tests details
    final failedResults = results.where((r) => !r.passed).toList();
    if (failedResults.isNotEmpty) {
      print('\n❌ FAILED TESTS DETAILS:');
      for (final result in failedResults) {
        print('   ${result.testName}: "${result.input}"');
        print('      Expected: ${result.expected}, Got: ${result.actual}');
        if (result.errorMessage != null) {
          print('      Error: ${result.errorMessage}');
        }
      }
    }
    
    // Test category breakdown
    final categoryStats = <String, Map<String, int>>{};
    for (final result in results) {
      categoryStats[result.testName] ??= {'passed': 0, 'failed': 0};
      if (result.passed) {
        categoryStats[result.testName]!['passed'] = categoryStats[result.testName]!['passed']! + 1;
      } else {
        categoryStats[result.testName]!['failed'] = categoryStats[result.testName]!['failed']! + 1;
      }
    }
    
    print('\n📋 TEST CATEGORY BREAKDOWN:');
    categoryStats.forEach((category, stats) {
      final total = stats['passed']! + stats['failed']!;
      final passRate = (stats['passed']! / total * 100).toStringAsFixed(1);
      print('   $category: ${stats['passed']}/$total passed ($passRate%)');
    });
    
    print('\n🎯 RECOMMENDATIONS:');
    if (failedTests == 0) {
      print('   ✅ All tests passed! The validation system is working correctly.');
    } else {
      print('   ⚠️ $failedTests tests failed. Review failed test details above.');
      print('   🔧 Consider adjusting validation logic or test expectations.');
    }
    
    final avgResponseTime = responseTimes.isNotEmpty ? 
        responseTimes.reduce((a, b) => a + b) / responseTimes.length : 0;
    if (avgResponseTime > 3000) {
      print('   ⚡ Consider optimizing response times (current avg: ${avgResponseTime.toStringAsFixed(0)}ms)');
    }
    
    print('\n✅ TESTING COMPLETE');
    print('=' * 80);
  }
}

void main() async {
  final tester = ComprehensiveValidationTester();
  await tester.runAllTests();
}
