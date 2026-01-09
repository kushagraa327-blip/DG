import 'dart:convert';
import 'package:http/http.dart' as http;

/// Standalone test for OpenRouter configuration with Gemini 2.5 Flash
void main() async {
  print('🧪 Testing OpenRouter Configuration with Gemini 2.5 Flash');
  print('=' * 60);
  
  // Configuration
  const apiKey = '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';
  const model = 'google/gemini-2.5-flash';
  const url = 'https://openrouter.ai/api/v1/chat/completions';
  
  print('📋 Configuration:');
  print('   🔑 API Key: ${apiKey.substring(0, 20)}...');
  print('   🤖 Model: $model');
  print('   🌐 URL: $url');
  print('');
  
  // Test connection
  print('📋 Testing OpenRouter Connection...');
  try {
    final testMessages = [
      {
        'role': 'user',
        'content': 'Hello! Can you tell me one healthy breakfast option in exactly 20 words?'
      }
    ];

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://github.com/CodeWithJainendra/Dietary-Guide',
      'X-Title': 'Mighty Fitness AI Assistant',
    };

    final body = {
      'model': model,
      'messages': testMessages,
      'max_tokens': 100,
      'temperature': 0.7,
    };

    print('📤 Sending request to OpenRouter...');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('📡 Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        final content = message['content'] as String?;
        
        if (content != null && content.isNotEmpty) {
          print('✅ OpenRouter API test: PASSED');
          print('🤖 AI Response: $content');
          print('📊 Response length: ${content.length} characters');
          print('🏷️ Model used: ${data['model'] ?? 'unknown'}');
          
          if (data['usage'] != null) {
            print('📈 Token usage: ${data['usage']}');
          }
        } else {
          print('❌ Empty response content');
        }
      } else {
        print('❌ No choices in response');
      }
    } else {
      print('❌ OpenRouter API test: FAILED');
      print('💥 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
    }
  } catch (e) {
    print('❌ OpenRouter API test: ERROR');
    print('💥 Exception: $e');
  }
  
  print('');
  print('🏁 Test Complete!');
  print('=' * 60);
}
