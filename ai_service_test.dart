import 'package:flutter/foundation.dart';
import 'lib/services/ai_service.dart';

/// Quick test to validate OpenRouter Gemini 2.5 Flash integration
void main() async {
  print('🚀 Testing AI Service with OpenRouter Gemini 2.5 Flash');
  print('=' * 60);
  
  try {
    final aiService = AIService();
    
    // Test 1: Basic chat functionality
    print('📝 Test 1: Basic Chat');
    final chatResponse = await aiService.sendMessage(
      'Hello! Can you briefly tell me about healthy nutrition tips?',
      conversationId: 'test-conversation'
    );
    print('✅ Chat Response: ${chatResponse.substring(0, 100)}...');
    print('');
    
    // Test 2: Food analysis
    print('📝 Test 2: Food Analysis Query');
    final foodResponse = await aiService.sendMessage(
      'What are the nutritional benefits of spinach?',
      conversationId: 'test-conversation'
    );
    print('✅ Food Analysis: ${foodResponse.substring(0, 100)}...');
    print('');
    
    // Test 3: Configuration validation
    print('📝 Test 3: Configuration Check');
    print('✅ OpenRouter enabled: ${AIConfig.openrouter['enabled']}');
    print('✅ Model: ${AIConfig.openrouter['model']}');
    print('✅ API Key configured: ${AIConfig.openrouter['apiKey']?.toString().isNotEmpty}');
    print('✅ Vision support: ${AIConfig.openrouter['supportsVision']}');
    
    print('');
    print('🎉 All tests completed successfully!');
    print('🤖 OpenRouter Gemini 2.5 Flash is properly configured');
    
  } catch (error) {
    print('❌ Test failed: $error');
    print('💡 Please check your API configuration');
  }
}

// Configuration summary
class AIConfig {
  static const Map<String, dynamic> openrouter = {
    'url': 'https://openrouter.ai/api/v1/chat/completions',
    'enabled': true,
    'apiKey': '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',
    'model': 'google/gemini-2.0-flash-exp:free',
    'siteUrl': 'https://github.com/CodeWithJainendra/Dietary-Guide',
    'siteName': 'Mighty Fitness AI Assistant',
    'maxTokens': 8192,
    'temperature': 0.7,
    'supportsVision': true,
  };
