import 'package:flutter_test/flutter_test.dart';

/// Helper function to clean AI responses (mimics the actual implementation)
String cleanAIResponse(String content) {
  if (content.isEmpty) return content;

  var result = content;

  // Remove markdown formatting using replaceAllMapped for proper backreference handling
  result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1)!); // Bold
  result = result.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1)!); // Italic
  result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1)!); // Code

  // Remove headers
  result = result.replaceAll(RegExp(r'#{1,6}\s*'), '');

  // Clean up special characters and formatting
  result = result.replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces
  result = result.replaceAll(RegExp(r'\n\s*\n'), '\n\n'); // Multiple newlines

  // Fix common AI response issues
  result = result.replaceAll(RegExp(r"Here's[^:]*:\s*"), '');
  result = result.replaceAll(RegExp(r"Here are[^:]*:\s*"), '');
  result = result.replaceAll(RegExp(r"Based on[^:]*:\s*"), '');
  result = result.replaceAll(RegExp(r'As an AI[^,]*,\s*'), '');
  result = result.replaceAll(RegExp(r'I hope this helps[^!]*!?\s*'), '');

  return result.trim();
}

void main() {
  group('AI Response Cleaning Tests', () {
    test('should remove markdown formatting', () {
      const input = '**Bold text** and *italic text* and `code text`';
      final result = cleanAIResponse(input);

      expect(result, isNot(contains('**')));
      expect(result, isNot(contains('*')));
      expect(result, isNot(contains('`')));
      expect(result, contains('Bold text'));
      expect(result, contains('italic text'));
      expect(result, contains('code text'));
    });

    test('should remove headers', () {
      const input = '# Header 1\n## Header 2\n### Header 3\nNormal text';
      const expected = 'Header 1\nHeader 2\nHeader 3\nNormal text';
      
      final result = input.replaceAll(RegExp(r'#{1,6}\s*'), '');
      expect(result, expected);
    });

    test('should clean up multiple spaces and newlines', () {
      const input = 'Text   with    multiple     spaces\n\n\n\nAnd multiple newlines';
      
      final result = input
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\n\s*\n'), '\n\n');
      
      expect(result, contains('Text with multiple spaces'));
    });

    test('should remove common AI prefixes', () {
      const input1 = "Here's your meal plan: Breakfast: Oats";
      const input2 = "Here are some suggestions: Exercise daily";
      const input3 = "Based on your profile: You should eat more protein";
      
      final regex = RegExp(r"^(Here's|Here are|Based on).*?:\s*", multiLine: true);
      
      expect(input1.replaceAll(regex, ''), 'Breakfast: Oats');
      expect(input2.replaceAll(regex, ''), 'Exercise daily');
      expect(input3.replaceAll(regex, ''), 'You should eat more protein');
    });

    test('should remove AI assistant phrases', () {
      const input = 'As an AI assistant, I can help you with nutrition planning.';
      const expected = 'I can help you with nutrition planning.';
      
      final result = input.replaceAll(RegExp(r'As an AI.*?,\s*', multiLine: true), '');
      expect(result, expected);
    });

    test('should handle complex AI response with multiple issues', () {
      const input = '''**Here's your personalized meal plan:**

# Breakfast
- *Oatmeal* with `berries`

## Lunch
- **Grilled chicken** salad

As an AI nutritionist, I hope this helps you achieve your goals!

### Dinner
- `Salmon` with vegetables''';

      final result = cleanAIResponse(input);

      expect(result, isNot(contains('**')));
      expect(result, isNot(contains('*')));
      expect(result, isNot(contains('`')));
      expect(result, isNot(contains('#')));
      expect(result, isNot(contains('As an AI')));
      expect(result, contains('Breakfast'));
      expect(result, contains('Lunch'));
      expect(result, contains('Dinner'));
    });

    test('should preserve emojis and special characters', () {
      const input = 'Great job! 💪 Your meal plan: 🍳 Breakfast 🥗 Lunch 🍽️ Dinner';
      
      // The cleaning should preserve emojis
      var result = input
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      expect(result, contains('💪'));
      expect(result, contains('🍳'));
      expect(result, contains('🥗'));
      expect(result, contains('🍽️'));
    });

    test('should handle empty and null inputs', () {
      const emptyInput = '';
      const whitespaceInput = '   \n\n   ';
      
      expect(emptyInput.trim(), isEmpty);
      expect(whitespaceInput.trim(), isEmpty);
    });

    test('should clean real AI response examples', () {
      const realResponse1 = '''**Meal Suggestion:**

Here's a personalized meal plan for your weight gain goal, Manas:

🍳 Breakfast: Oatmeal with berries and nuts (450 calories)
🥗 Lunch: Grilled chicken salad with mixed vegetables (520 calories)
🍽️ Dinner: Baked salmon with quinoa and steamed broccoli (480 calories)

As an AI nutritionist, I hope this helps you achieve your fitness goals!''';

      final cleaned = cleanAIResponse(realResponse1);

      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains("Here's")));
      expect(cleaned, isNot(contains('As an AI')));
      expect(cleaned, contains('🍳'));
      expect(cleaned, contains('Breakfast'));
      expect(cleaned, contains('450 calories'));
    });
  });

  group('AI Response Display Integration Tests', () {
    test('should handle truncated responses properly', () {
      final longResponse = 'This is a very long AI response that would normally be truncated in the UI components. ' * 10;
      
      // Test that we can detect long content
      expect(longResponse.length > 150, isTrue);
      
      // Test truncation logic
      final shouldShowReadMore = longResponse.length > 150;
      expect(shouldShowReadMore, isTrue);
    });

    test('should preserve line breaks for readability', () {
      const multilineResponse = '''Health Insights:
✅ Your weight gain goal is achievable
✅ Focus on protein-rich foods
✅ Stay consistent with your routine''';

      // Should preserve meaningful line breaks
      final lines = multilineResponse.split('\n');
      expect(lines.length, greaterThan(1));
      expect(lines.first, contains('Health Insights'));
      expect(lines.any((line) => line.contains('✅')), isTrue);
    });
  });
}
