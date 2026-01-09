import 'dart:io';
import 'lib/services/ai_service.dart';

/// Test script to verify OpenRouter configuration with Gemini 2.5 Flash
void main() async {
  print('🧪 Testing OpenRouter Configuration with Gemini 2.5 Flash');
  print('=' * 60);
  
  // Test 1: Check configuration
  print('📋 Step 1: Checking AI Configuration...');
  final status = getAIServiceStatus();
  print('🔍 AI Service Status:');
  status.forEach((key, value) {
    print('   $key: $value');
  });
  print('');
  
  // Test 2: Test OpenRouter connection
  print('📋 Step 2: Testing OpenRouter Connection...');
  try {
    final connectionTest = await testOpenRouterConnection();
    if (connectionTest) {
      print('✅ OpenRouter connection test: PASSED');
    } else {
      print('❌ OpenRouter connection test: FAILED');
    }
  } catch (e) {
    print('❌ OpenRouter connection test error: $e');
  }
  print('');
  
  // Test 3: Test AI response generation
  print('📋 Step 3: Testing AI Response Generation...');
  try {
    final profile = UserProfile(
      name: 'TestUser',
      age: 25,
      gender: 'male',
      weight: 70.0,
      height: 175.0,
      goal: 'general_fitness',
      exerciseDuration: 30,
    );
    
    final messages = [
      CoreMessage(role: 'user', content: 'Hello! Can you tell me a healthy breakfast option?')
    ];
    
    final response = await chatWithAI(messages, userProfile: profile);
    print('✅ AI Response test: PASSED');
    print('🤖 Sample response preview: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
  } catch (e) {
    print('❌ AI Response test: FAILED');
    print('💥 Error: $e');
  }
  print('');
  
  // Test 4: Test RAG functionality
  print('📋 Step 4: Testing RAG with OpenRouter...');
  try {
    final profile = UserProfile(
      name: 'TestUser',
      age: 25,
      gender: 'male',
      weight: 70.0,
      height: 175.0,
      goal: 'weight_loss',
      exerciseDuration: 30,
    );
    
    final ragResponse = await chatWithAIRAG(
      'What should I eat for lunch to lose weight?',
      userProfile: profile,
    );
    print('✅ RAG test: PASSED');
    print('🧠 RAG response preview: ${ragResponse.substring(0, ragResponse.length > 100 ? 100 : ragResponse.length)}...');
  } catch (e) {
    print('❌ RAG test: FAILED');
    print('💥 Error: $e');
  }
  print('');
  
  print('🏁 Configuration Test Complete!');
  print('=' * 60);
  print('');
  print('✨ Summary:');
  print('   🔑 API Key: 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');
  print('   🤖 Model: google/gemini-2.5-flash');
  print('   🌐 Service: OpenRouter (Primary)');
  print('   🎯 Vision Support: Enabled');
  print('   💾 RAG: Enabled');
  
  // Exit the script
  exit(0);
}
