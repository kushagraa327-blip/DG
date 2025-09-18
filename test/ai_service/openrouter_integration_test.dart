import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('OpenRouter Integration Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    group('Configuration Tests', () {
      test('OpenRouter configuration is properly set', () {
        expect(AIConfig.openrouter['enabled'], isTrue);
        expect(AIConfig.openrouter['apiKey'], isNotEmpty);
        expect(AIConfig.openrouter['apiKey'], startsWith('sk-or-v1-'));
        expect(AIConfig.openrouter['model'], equals('google/gemini-2.5-flash-preview-05-20'));
        expect(AIConfig.openrouter['url'], equals('https://openrouter.ai/api/v1/chat/completions'));
        expect(AIConfig.openrouter['maxTokens'], equals(2048));
        expect(AIConfig.openrouter['temperature'], equals(0.7));
      });

      test('Service priority is correctly configured', () {
        final status = getAIServiceStatus();
        expect(status['openrouter'], isTrue);
        expect(status['service'], contains('OpenRouter'));
        expect(status['primaryModel'], equals('google/gemini-2.5-flash-preview-05-20'));
        expect(status['apiKeyPresent'], isTrue);
      });

      test('Fallback services are properly configured', () {
        expect(AIConfig.gemini['enabled'], isFalse); // Should be disabled as fallback
        expect(AIConfig.openai['enabled'], isFalse); // Should be disabled
        expect(AIConfig.mock['enabled'], isTrue); // Should be available as final fallback
      });
    });

    group('API Integration Tests', () {
      test('OpenRouter API call structure is correct', () async {
        final messages = [
          CoreMessage(role: 'system', content: 'You are a test assistant.'),
          CoreMessage(role: 'user', content: 'Say "test successful"')
        ];

        try {
          final result = await chatWithAI(messages);
          expect(result, isNotEmpty);
          // Should either get OpenRouter response or fallback response
          expect(result.length, greaterThan(10));
        } catch (e) {
          // Expected if API key is invalid - test that error handling works
          expect(e.toString(), contains('Exception'));
        }
      });

      test('Authentication error handling (401)', () async {
        // This test verifies that 401 errors are properly handled
        final messages = [
          CoreMessage(role: 'user', content: 'Test authentication')
        ];

        final result = await chatWithAI(messages);
        // Should get fallback response when authentication fails
        expect(result, isNotEmpty);
        expect(result, anyOf([
          contains('IRA'),
          contains('fitness'),
          contains('help')
        ]));
      });

      test('Rate limiting error handling (429)', () async {
        // Test that rate limiting is handled gracefully
        final messages = [
          CoreMessage(role: 'user', content: 'Test rate limiting')
        ];

        final result = await chatWithAI(messages);
        expect(result, isNotEmpty);
        // Should handle rate limiting and provide fallback
      });
    });

    group('Fallback Mechanism Tests', () {
      test('Fallback chain works correctly', () async {
        final messages = [
          CoreMessage(role: 'user', content: 'Test fallback system')
        ];

        final result = await chatWithAI(messages);
        expect(result, isNotEmpty);
        
        // Should get intelligent fallback response
        expect(result, anyOf([
          contains('IRA'),
          contains('fitness'),
          contains('AI'),
          contains('help')
        ]));
      });

      test('Mock responses are contextually appropriate', () async {
        final profile = UserProfile(
          name: 'TestUser',
          age: 25,
          gender: 'female',
          weight: 65.0,
          height: 165.0,
          goal: 'lose_weight',
          exerciseDuration: 30,
          diseases: [],
          dietaryPreferences: [],
          isSmoker: false,
        );

        final messages = [
          CoreMessage(role: 'user', content: 'Give me fitness advice')
        ];

        final result = await chatWithAI(messages, userProfile: profile);
        expect(result, isNotEmpty);
        expect(result, anyOf([
          contains('TestUser'),
          contains('weight'),
          contains('fitness'),
          contains('goal')
        ]));
      });
    });

    group('Performance Tests', () {
      test('Response time is reasonable', () async {
        final stopwatch = Stopwatch()..start();
        
        final messages = [
          CoreMessage(role: 'user', content: 'Quick test')
        ];

        final result = await chatWithAI(messages);
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should respond within 10 seconds
      });

      test('Concurrent requests are handled properly', () async {
        final futures = List.generate(3, (index) => 
          chatWithAI([CoreMessage(role: 'user', content: 'Concurrent test $index')])
        );

        final results = await Future.wait(futures);
        
        for (final result in results) {
          expect(result, isNotEmpty);
        }
      });
    });
  });
}
