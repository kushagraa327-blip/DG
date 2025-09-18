import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/services/ai_service.dart';
import 'package:mighty_fitness/services/ira_rag_service.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mighty_fitness/main.dart';

void main() {
  group('IRA Chat System Tests', () {
    late UserProfile testProfile;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      
      testProfile = UserProfile(
        name: 'Alice',
        age: 28,
        gender: 'female',
        weight: 68.0,
        height: 170.0,
        goal: 'lose_weight',
        exerciseDuration: 45,
        diseases: [],
        dietaryPreferences: ['vegetarian'],
        isSmoker: false,
      );
    });

    group('RAG Implementation Tests', () {
      test('RAG service initializes correctly', () async {
        final ragService = IRARAGService();
        expect(ragService, isNotNull);
        
        // Test context retrieval
        final context = await ragService.getRelevantContext('What is my weight?', testProfile);
        expect(context, isNotNull);
        expect(context.contextItems, isNotEmpty);
      });

      test('Personal data queries are handled correctly', () async {
        final queries = [
          'What is my weight?',
          'How tall am I?',
          'What is my fitness goal?',
          'Tell me about my profile'
        ];

        for (final query in queries) {
          final result = await chatWithAIRAG(query, userProfile: testProfile);
          expect(result, isNotEmpty);
          expect(result, anyOf([
            contains('68'),     // weight
            contains('170'),    // height
            contains('lose'),   // goal
            contains('Alice'),  // name
          ]));
        }
      });

      test('Context-aware responses include user information', () async {
        final result = await chatWithAIRAG(
          'Give me a personalized workout plan',
          userProfile: testProfile
        );
        
        expect(result, isNotEmpty);
        expect(result, anyOf([
          contains('Alice'),
          contains('weight loss'),
          contains('vegetarian'),
          contains('45 minutes')
        ]));
      });
    });

    group('Chat History Management', () {
      test('Chat responses are contextually consistent', () async {
        final queries = [
          'Hello, I want to start my fitness journey',
          'What should I eat for breakfast?',
          'How many calories should I consume daily?'
        ];

        String previousResponse = '';
        for (final query in queries) {
          final result = await chatWithAI([
            CoreMessage(role: 'user', content: query)
          ], userProfile: testProfile);
          
          expect(result, isNotEmpty);
          expect(result, isNot(equals(previousResponse))); // Responses should be different
          previousResponse = result;
        }
      });

      test('IRA branding is consistent', () async {
        final result = await chatWithAI([
          CoreMessage(role: 'user', content: 'Who are you?')
        ], userProfile: testProfile);
        
        expect(result, contains('IRA'));
        expect(result, isNot(contains('FitBot'))); // Should not use old branding
      });
    });

    group('Personalized Response Tests', () {
      test('Goal-based recommendations are appropriate', () async {
        final goals = ['lose_weight', 'gain_weight', 'maintain_healthy_lifestyle', 'gain_muscles'];
        
        for (final goal in goals) {
          final profile = UserProfile(
            name: 'TestUser',
            age: 25,
            gender: 'male',
            weight: 70.0,
            height: 175.0,
            goal: goal,
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [],
            isSmoker: false,
          );

          final result = await chatWithAI([
            CoreMessage(role: 'user', content: 'Give me fitness advice')
          ], userProfile: profile);

          expect(result, isNotEmpty);
          
          switch (goal) {
            case 'lose_weight':
              expect(result, anyOf([
                contains('weight loss'),
                contains('calorie deficit'),
                contains('cardio')
              ]));
              break;
            case 'gain_weight':
              expect(result, anyOf([
                contains('weight gain'),
                contains('calorie surplus'),
                contains('protein')
              ]));
              break;
            case 'gain_muscles':
              expect(result, anyOf([
                contains('muscle'),
                contains('strength'),
                contains('protein')
              ]));
              break;
            case 'maintain_healthy_lifestyle':
              expect(result, anyOf([
                contains('maintain'),
                contains('healthy'),
                contains('balance')
              ]));
              break;
          }
        }
      });

      test('Dietary preferences are considered', () async {
        final preferences = ['vegetarian', 'vegan', 'keto', 'gluten_free'];
        
        for (final preference in preferences) {
          final profile = UserProfile(
            name: 'TestUser',
            age: 25,
            gender: 'female',
            weight: 60.0,
            height: 165.0,
            goal: 'lose_weight',
            exerciseDuration: 30,
            diseases: [],
            dietaryPreferences: [preference],
            isSmoker: false,
          );

          final result = await chatWithAI([
            CoreMessage(role: 'user', content: 'What should I eat for lunch?')
          ], userProfile: profile);

          expect(result, isNotEmpty);
          // Should consider dietary preferences in recommendations
        }
      });
    });

    group('Error Handling Tests', () {
      test('Handles empty user queries gracefully', () async {
        final result = await chatWithAI([
          CoreMessage(role: 'user', content: '')
        ], userProfile: testProfile);
        
        expect(result, isNotEmpty);
        expect(result, contains('help'));
      });

      test('Handles very long queries appropriately', () async {
        final longQuery = 'Tell me about fitness ' * 100; // Very long query
        
        final result = await chatWithAI([
          CoreMessage(role: 'user', content: longQuery)
        ], userProfile: testProfile);
        
        expect(result, isNotEmpty);
        expect(result.length, lessThan(5000)); // Should not return extremely long responses
      });

      test('Handles null user profile gracefully', () async {
        final result = await chatWithAI([
          CoreMessage(role: 'user', content: 'Give me advice')
        ]); // No user profile provided
        
        expect(result, isNotEmpty);
        expect(result, contains('User')); // Should use default name
      });
    });
  });
}
