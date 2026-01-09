import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_entry_model.dart';
import 'ira_rag_service.dart';
import 'ira_user_context.dart';
import 'ira_conversation_memory.dart';
import 'food_validation_service.dart';
import '../main.dart';

/// Clean AI response text for better display while preserving readability
String _cleanAIResponse(String content) {
  if (content.isEmpty) return content;

  var result = content;

  // Remove markdown formatting using replaceAllMapped for proper backreference handling
  result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1)!); // Bold
  result = result.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1)!); // Italic
  result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1)!); // Code

  // Remove headers but preserve the content
  result = result.replaceAll(RegExp(r'#{1,6}\s*'), '');

  // Clean up excessive whitespace while preserving line breaks and structure
  result = result.replaceAll(RegExp(r'[ \t]+'), ' '); // Multiple spaces/tabs to single space
  result = result.replaceAll(RegExp(r'\n[ \t]*\n'), '\n\n'); // Clean up line breaks
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Max 2 consecutive newlines

  // Fix common AI response issues
  result = result.replaceAll(RegExp(r"Here's[^:]*:\s*"), '');
  result = result.replaceAll(RegExp(r"Here are[^:]*:\s*"), '');
  result = result.replaceAll(RegExp(r"Based on[^:]*:\s*"), '');
  result = result.replaceAll(RegExp(r'As an AI[^,]*,\s*'), '');
  result = result.replaceAll(RegExp(r'I hope this helps[^!]*!?\s*'), '');

  // Remove any remaining problematic characters that might cause display issues
  result = result.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), ''); // Zero-width characters
  result = result.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t\u00A0-\uFFFF]'), ''); // Non-printable chars

  return result.trim();
}

// Types
class UserProfile {
  final String? name;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;
  final String goal;
  final int exerciseDuration;
  final List<String>? diseases;
  final List<String>? dietaryPreferences;
  final bool isSmoker;

  UserProfile({
    this.name,
    this.age,
    this.gender,
    this.weight,
    this.height,
    required this.goal,
    required this.exerciseDuration,
    this.diseases,
    this.dietaryPreferences,
    this.isSmoker = false,
  });
}

// Note: MealEntry and FoodItem are now imported from meal_entry_model.dart

class CoreMessage {
  final String role;
  final dynamic content; // Can be String or other types

  CoreMessage({
    required this.role,
    required this.content,
  });
}

// AI Service Configuration
class AIConfig {
  // 🔧 OpenRouter Configuration - ENABLED (Primary AI Service with Gemini 2.5 Flash)
  static const Map<String, dynamic> openrouter = {
    'url': 'https://openrouter.ai/api/v1/chat/completions',
    'enabled': true, // 👈 Enabled as primary AI service
    'apiKey': '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', // 👈 Your OpenRouter API key
    'model': 'google/gemini-2.5-flash', // 👈 Using Google Gemini 2.5 Flash via OpenRouter
    'siteUrl': 'https://github.com/CodeWithJainendra/Dietary-Guide',
    'siteName': 'Mighty Fitness AI Assistant',
    'maxTokens': 8192, // Increased for better responses
    'temperature': 0.7,
    'supportsVision': true, // Gemini 2.5 Flash supports image analysis
  };

  // 🔧 Gemini AI Configuration - DISABLED (OpenRouter only)
  static const Map<String, dynamic> gemini = {
    'baseUrl': 'https://generativelanguage.googleapis.com/v1beta/models',
    'model': 'gemini-1.5-flash-latest', // Fast and efficient model for vision fallback
    'enabled': false, // 👈 Disabled - using OpenRouter only
    'apiKey': '', // 👈 Disabled
    'maxTokens': 2048,
    'temperature': 0.7,
    'supportsVision': true,
  };

  static const Map<String, dynamic> openai = {
    'url': 'https://api.openai.com/v1/chat/completions',
    'enabled': false, // Set to true if you have OpenAI API key
    'apiKey': '', // Add your OpenAI API key here
    'model': 'gpt-3.5-turbo',
  };

  static const Map<String, dynamic> primary = {
    'url': 'https://toolkit.rork.com/text/llm/',
    'enabled': false, // Disabled due to 500 errors
  };

  static const Map<String, dynamic> mock = {
    'enabled': true, // Always available as final fallback
  };
}

// Available OpenRouter models
class OpenRouterModels {
  // Free models
  static const Map<String, String> FREE = {
    'DEEPSEEK_V3_FREE': 'deepseek/deepseek-chat-v3:free', // Default - DeepSeek V3 0324 (FREE)
    'GEMINI_2_FLASH_EXP': 'google/gemini-2.0-flash-exp:free',
    'LLAMA_3_1_8B': 'meta-llama/llama-3.1-8b-instruct:free',
    'MISTRAL_7B': 'mistralai/mistral-7b-instruct:free',
    'PHI_3_MINI': 'microsoft/phi-3-mini-128k-instruct:free',
  };

  // Premium models (cost-effective)
  static const Map<String, String> PREMIUM = {
    'DEEPSEEK_V3': 'deepseek/deepseek-chat', // Latest DeepSeek V3 (Paid)
    'GEMINI_2_5_FLASH': 'google/gemini-2.5-flash',
    'GEMINI_2_FLASH_THINKING': 'google/gemini-2.0-flash-thinking-exp',
    'GPT_4O_MINI': 'openai/gpt-4o-mini',
    'CLAUDE_3_5_SONNET': 'anthropic/claude-3.5-sonnet',
    'GEMINI_PRO_1_5': 'google/gemini-pro-1.5',
  };
}

// Utility function to get current AI service status
Map<String, dynamic> getAIServiceStatus() {
  return {
    'openrouter': AIConfig.openrouter['enabled'],
    'gemini': AIConfig.gemini['enabled'],
    'openai': AIConfig.openai['enabled'],
    'primaryModel': AIConfig.openrouter['model'],
    'fallbackAvailable': AIConfig.mock['enabled'],
    'apiKeyPresent': AIConfig.openrouter['apiKey']?.toString().isNotEmpty ?? false,
    'apiKeyFormat': (AIConfig.openrouter['apiKey']?.toString().isNotEmpty == true)
        ? '${AIConfig.openrouter['apiKey']?.toString().substring(0, 15)}...'
        : 'No key',
    'service': 'OpenRouter (Gemini 2.5 Flash)',
  };
}

// Test Gemini connection
Future<bool> testGeminiConnection() async {
  if (!AIConfig.gemini['enabled'] || AIConfig.gemini['apiKey']?.toString().isEmpty == true) {
    return false;
  }

  try {
    final testMessages = [
      CoreMessage(role: 'user', content: 'Hello, please respond with just "Gemini working!"')
    ];

    final result = await _callGemini(testMessages);
    return true;
  } catch (error) {
    return false;
  }
}

// Simple direct test of Gemini API
Future<String> testGeminiDirect() async {
  try {
    final url = '${AIConfig.gemini['baseUrl']}/${AIConfig.gemini['model']}:generateContent?key=${AIConfig.gemini['apiKey']}';
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': 'Say "Hello from Gemini!" and nothing else.'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 50,
      }
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text.trim();
          }
        }
      }
    }

    throw Exception('Direct test failed: ${response.statusCode} - ${response.body}');
  } catch (error) {
    rethrow;
  }
}

// Test OpenRouter connection with manual API key (for debugging)
Future<bool> testOpenRouterWithKey(String apiKey) async {

  final testMessages = [
    {
      'role': 'user',
      'content': 'Hello, please respond with just "OpenRouter working!"'
    }
  ];

  try {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://github.com/CodeWithJainendra/Dietary-Guide',
      'X-Title': 'Mighty Fitness AI Assistant',
    };

    final body = {
      'model': 'deepseek/deepseek-chat-v3-0324:free',
      'messages': testMessages,
      'max_tokens': 50,
      'temperature': 0.1,
    };



    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return true;
    } else {
      final errorText = response.body;
      return false;
    }
  } catch (error) {
    return false;
  }
}

// Test OpenRouter connection
Future<bool> testOpenRouterConnection() async {
  if (!AIConfig.openrouter['enabled']) {
    print('❌ OpenRouter not enabled');
    return false;
  }

  if (AIConfig.openrouter['apiKey']?.toString().isEmpty ?? true) {
    print('❌ OpenRouter API key not found');
    return false;
  }

    print('🧪 Testing OpenRouter connection...');
    print('📊 Config: ${jsonEncode({
    'url': AIConfig.openrouter['url'],
    'model': AIConfig.openrouter['model'],
    'keyPresent': AIConfig.openrouter['apiKey']?.toString().isNotEmpty ?? false,
    'keyLength': AIConfig.openrouter['apiKey']?.toString().length,
    'keyFormat': (AIConfig.openrouter['apiKey']?.toString().isNotEmpty == true)
        ? '${AIConfig.openrouter['apiKey']?.toString().substring(0, 15)}...'
        : 'No key',
    'keyStartsWith': AIConfig.openrouter['apiKey']?.toString().startsWith('sk-or-v1-'),
  })}');

  final testMessages = [
    {
      'role': 'user',
      'content': 'Hello, please respond with just "OpenRouter working!"'
    }
  ];

  try {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AIConfig.openrouter['apiKey']}',
      'HTTP-Referer': AIConfig.openrouter['siteUrl'].toString(),
      'X-Title': AIConfig.openrouter['siteName'].toString(),
    };

    final body = {
      'model': AIConfig.openrouter['model'],
      'messages': testMessages,
      'max_tokens': 50,
      'temperature': 0.1,
    };

    print('📤 Request headers: ${jsonEncode({
      ...headers,
      'Authorization': 'Bearer ${AIConfig.openrouter['apiKey']?.toString().substring(0, 20)}...',
    })}');
    print('📤 Request body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(AIConfig.openrouter['url']),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
    print('✅ OpenRouter test successful!');
    print('🤖 Response: ${data['choices'][0]?['message']?['content']}');
      return true;
    } else {
      final errorText = response.body;
    print('❌ OpenRouter test failed: ${response.statusCode} ${response.reasonPhrase}');
    print('📄 Error details: $errorText');
      return false;
    }
  } catch (error) {
    print('❌ OpenRouter connection error: $error');
    return false;
  }
}

// Mock AI responses for development/fallback
class MockResponses {
  static String greeting(UserProfile profile, String mood, {List<MealEntry>? recentMeals}) {
    final name = profile.name ?? 'there';
    final mealContext = recentMeals?.isNotEmpty == true
        ? ' I see you\'ve been tracking your meals - great job!'
        : '';
    return 'Hello $name! 😊 Ready to continue your ${profile.goal.replaceAll('_', ' ')} journey today?$mealContext I\'m here to help you stay motivated! 💪✨';
  }

  static String motivation(UserProfile profile, String context, {List<MealEntry>? recentMeals}) {
    final name = profile.name ?? 'you';
    final nutritionMotivation = recentMeals?.isNotEmpty == true
        ? ' Your nutrition tracking shows real commitment!'
        : '';
    return 'You\'re doing amazing, $name!$nutritionMotivation Every healthy choice brings you closer to your goals. Keep it up! 🌟💪';
  }

  static String mealPlan(UserProfile profile, {List<MealEntry>? recentMeals}) {
    final name = profile.name ?? 'you';
    final recentFoods = recentMeals?.isNotEmpty == true
        ? recentMeals!.expand((m) => m.foods).map((f) => f.name).take(3).toSet().join(', ')
        : '';
    final varietyNote = recentFoods.isNotEmpty
        ? '\n\n💡 I noticed you\'ve had $recentFoods recently. Let\'s add some variety!'
        : '';

    // Goal-specific meal plans
    String mealPlan = '';
    switch (profile.goal.toLowerCase()) {
      case 'lose_weight':
      case 'weight_loss':
        mealPlan = '''🍳 Breakfast: Greek yogurt with berries (300 cal)
🥗 Lunch: Grilled chicken salad with olive oil dressing (400 cal)
🍽️ Dinner: Baked cod with steamed vegetables (350 cal)
🍎 Snack: Apple with almond butter (150 cal)

Total: ~1200 calories for healthy weight loss''';
        break;
      case 'gain_muscles':
      case 'muscle_gain':
        mealPlan = '''🍳 Breakfast: Protein smoothie with banana and oats (500 cal)
🥗 Lunch: Grilled chicken breast with quinoa and vegetables (600 cal)
🍽️ Dinner: Lean beef with sweet potato and broccoli (650 cal)
🥜 Snacks: Greek yogurt, nuts, protein bar (400 cal)

Total: ~2150 calories with high protein for muscle building''';
        break;
      case 'maintain_healthy_lifestyle':
      case 'maintenance':
        mealPlan = '''🍳 Breakfast: Whole grain toast with avocado and eggs (400 cal)
🥗 Lunch: Mediterranean bowl with chickpeas and vegetables (500 cal)
🍽️ Dinner: Grilled salmon with brown rice and asparagus (550 cal)
🍓 Snack: Mixed berries with nuts (200 cal)

Total: ~1650 calories for healthy maintenance''';
        break;
      default:
        mealPlan = '''🍳 Breakfast: Oatmeal with berries and nuts
🥗 Lunch: Grilled chicken salad with mixed vegetables
🍽️ Dinner: Baked salmon with quinoa and steamed broccoli''';
    }

    return '''Here's a personalized meal plan for your ${profile.goal.replaceAll('_', ' ')} goal, $name:

$mealPlan$varietyNote

💧 Stay hydrated and listen to your body's hunger cues!''';
  }

  static String healthInsights(UserProfile profile, {List<MealEntry>? recentMeals}) {
    final name = profile.name ?? 'you';
    final nutritionInsight = recentMeals?.isNotEmpty == true
        ? '\n✅ Your meal tracking shows great dedication'
        : '';

    // Goal-specific health insights
    String goalSpecificInsights = '';
    switch (profile.goal.toLowerCase()) {
      case 'lose_weight':
      case 'weight_loss':
        goalSpecificInsights = '''✅ Your weight loss goal is achievable with consistency
✅ Focus on creating a moderate calorie deficit
✅ Combine cardio with strength training for best results
✅ Track your progress weekly, not daily''';
        break;
      case 'gain_muscles':
      case 'muscle_gain':
        goalSpecificInsights = '''✅ Your muscle gain goal requires progressive overload
✅ Prioritize protein intake (1.6-2.2g per kg body weight)
✅ Focus on compound exercises and adequate rest
✅ Be patient - muscle growth takes time and consistency''';
        break;
      case 'maintain_healthy_lifestyle':
      case 'maintenance':
        goalSpecificInsights = '''✅ Your healthy lifestyle goal is about balance
✅ Focus on sustainable habits over quick fixes
✅ Include variety in both exercise and nutrition
✅ Listen to your body and adjust as needed''';
        break;
      default:
        goalSpecificInsights = '''✅ Your ${profile.goal.replaceAll('_', ' ')} goal is achievable
✅ ${profile.exerciseDuration} minutes of daily exercise is excellent
✅ Stay consistent with your healthy habits''';
    }

    return '''Great progress on your wellness journey, $name! Based on your profile, here are key insights:

$goalSpecificInsights$nutritionInsight

Keep up the fantastic work! 🌟💪''';
  }

  static Map<String, dynamic> foodAnalysis(String foodName) => {
        'foodName': foodName,
        'calories': 200,
        'protein': 10,
        'carbs': 20,
        'fat': 8
      };

  static Map<String, dynamic> recommendations({List<MealEntry>? recentMeals}) {
    final mealSuggestion = recentMeals?.isNotEmpty == true
        ? 'Based on your recent meals, try adding more variety with colorful vegetables and lean proteins!'
        : 'Try a balanced breakfast with protein, healthy fats, and complex carbohydrates to start your day right!';

    return {
      'mealSuggestion': mealSuggestion,
      'exerciseSuggestion': 'Consider a 30-minute walk or light workout to boost your energy and mood.',
      'additionalNotes': 'Remember to stay hydrated throughout the day and listen to your body\'s hunger cues.'
    };
  }
}

/// Enhanced chat function with RAG and Conversation Memory
Future<String> chatWithAIRAG(String userQuery, {UserProfile? userProfile, List<MealEntry>? recentMeals}) async {
  try {
    print('🧠 Starting enhanced chat with conversation memory...');
    
    // First, validate nutrition-related queries for non-food inputs
    if (_isNutritionQueryEnhanced(userQuery)) {
      final validationResult = await _validateNutritionQuery(userQuery);
      if (!validationResult['isValid']) {
        return validationResult['response'];
      }
    }

    // Initialize services
    final ragService = IRARagService();
    final memoryService = IRAConversationMemory();
    await ragService.initialize();

    // Use enhanced user profile if not provided
    final profile = userProfile ?? IRAUserContext().buildEnhancedUserProfile();

    // Analyze conversation history and user patterns
    print('🔍 Analyzing conversation memory for context...');
    final memoryAnalysis = await memoryService.analyzeConversationHistory(userQuery);
    
    // Analyze user input for dietary context
    final inputAnalysis = _analyzeDietaryInput(userQuery, profile, recentMeals);

    // Check if we can provide immediate dietary response
    final immediateResponse = _generateImmediateDietaryResponse(userQuery, profile, recentMeals, inputAnalysis);
    if (immediateResponse != null) {
      await ragService.saveUserMessage(userQuery);
      await ragService.saveAssistantResponse(immediateResponse);
      return immediateResponse;
    }

    // Save user message to conversation history
    await ragService.saveUserMessage(userQuery);

    // Get enhanced prompt with conversation memory
    print('💭 Building enhanced prompt with conversation memory...');
    final enhancedPrompt = await memoryService.getEnhancedPromptWithMemory(
      userQuery: userQuery,
      userProfile: profile,
      recentMeals: recentMeals,
    );

    // Retrieve additional context from RAG
    final contextResult = await ragService.retrieveContext(
      query: userQuery,
      userProfile: profile,
      recentMeals: recentMeals,
      maxContextItems: 5, // Reduced since we have memory context
    );

    // Combine memory prompt with RAG context
    final finalPrompt = _combineMemoryAndRAGContext(enhancedPrompt, contextResult, memoryAnalysis);

    // Create messages for AI
    final messages = [
      CoreMessage(role: 'system', content: finalPrompt),
      CoreMessage(role: 'user', content: userQuery),
    ];

    print('🤖 Sending request to AI with enhanced context...');
    // Get AI response
    final response = await _callAIWithMessages(messages);

    // Clean and save assistant response to conversation history
    final cleanedResponse = _cleanAIResponse(response);

    final contextSources = contextResult.contextItems.map((item) => item.id).toList();
    await ragService.saveAssistantResponse(cleanedResponse, contextSources: contextSources);
    
    print('✅ Enhanced conversation response generated with memory context');
    return cleanedResponse;

  } catch (e) {
    print('❌ Error in enhanced chat: $e');
    // Fallback to standard chat
    return await chatWithAI([
      CoreMessage(role: 'user', content: userQuery)
    ], userProfile: userProfile, recentMeals: recentMeals);
  }
}

/// Analyze user input for dietary and fitness context
Map<String, dynamic> _analyzeDietaryInput(String userQuery, UserProfile profile, List<MealEntry>? recentMeals) {
  final queryLower = userQuery.toLowerCase().trim();

  return {
    'isPersonalDataQuery': _isPersonalDataQuery(queryLower),
    'isNutritionQuery': _isNutritionQuery(queryLower),
    'isWorkoutQuery': _isWorkoutQuery(queryLower),
    'isMotivationQuery': _isMotivationQuery(queryLower),
    'isMealPlanQuery': _isMealPlanQuery(queryLower),
    'isHealthInsightQuery': _isHealthInsightQuery(queryLower),
    'mentionedFoods': _extractMentionedFoods(queryLower),
    'queryType': _determineQueryType(queryLower),
    'urgency': _determineUrgency(queryLower),
  };
}

/// Generate immediate dietary response for specific query types
String? _generateImmediateDietaryResponse(String userQuery, UserProfile profile, List<MealEntry>? recentMeals, Map<String, dynamic> inputAnalysis) {
  // Only handle very specific direct personal data queries immediately
  // Let most other queries go to the AI for better responses
  if (inputAnalysis['isPersonalDataQuery'] == true) {
    final personalResponse = _handleDirectPersonalDataQuery(userQuery, profile);
    if (personalResponse != null) {
    print('⚡ Providing immediate personal data response');
      return personalResponse;
    }
  }

  // Only handle very specific single-food nutrition queries immediately
  // Complex queries should go to AI
  if (inputAnalysis['isNutritionQuery'] == true && inputAnalysis['mentionedFoods'].isNotEmpty) {
    final foods = inputAnalysis['mentionedFoods'] as List<String>;
    final queryLower = userQuery.toLowerCase();
    // Only provide immediate response for very simple nutrition queries
    if (foods.length == 1 && (queryLower.contains('calories in') || queryLower.contains('nutrition'))) {
    print('⚡ Providing immediate nutrition info for ${foods.first}');
      return _getImmediateNutritionInfo(foods.first, profile);
    }
  }

    print('🤖 No immediate response - sending to AI for better answer');
  return null; // No immediate response available - let AI handle it
}

/// Helper functions for input analysis
bool _isPersonalDataQuery(String query) {
  final personalKeywords = ['my height', 'my weight', 'my age', 'how tall', 'how much do i weigh', 'my profile', 'about me', 'my info', 'my bmi'];
  return personalKeywords.any((keyword) => query.contains(keyword));
}

bool _isNutritionQuery(String query) {
  final nutritionKeywords = ['calorie', 'nutrition', 'protein', 'carbs', 'fat', 'vitamin', 'mineral', 'macro', 'micro'];
  return nutritionKeywords.any((keyword) => query.contains(keyword));
}

bool _isWorkoutQuery(String query) {
  final workoutKeywords = ['workout', 'exercise', 'training', 'gym', 'fitness', 'muscle', 'strength', 'cardio'];
  return workoutKeywords.any((keyword) => query.contains(keyword));
}

bool _isMotivationQuery(String query) {
  final motivationKeywords = ['motivation', 'inspire', 'encourage', 'help me', 'support', 'stuck', 'difficult'];
  return motivationKeywords.any((keyword) => query.contains(keyword));
}

bool _isMealPlanQuery(String query) {
  final mealPlanKeywords = ['meal plan', 'diet plan', 'what to eat', 'food plan', 'menu', 'breakfast', 'lunch', 'dinner'];
  return mealPlanKeywords.any((keyword) => query.contains(keyword));
}

bool _isHealthInsightQuery(String query) {
  final healthKeywords = ['health', 'insight', 'advice', 'tip', 'recommendation', 'progress', 'goal'];
  return healthKeywords.any((keyword) => query.contains(keyword));
}

List<String> _extractMentionedFoods(String query) {
  final commonFoods = ['apple', 'banana', 'chicken', 'rice', 'bread', 'egg', 'milk', 'potato', 'maggie', 'noodle', 'pasta', 'salad', 'fish', 'beef', 'pork'];
  return commonFoods.where((food) => query.contains(food)).toList();
}

String _determineQueryType(String query) {
  if (_isPersonalDataQuery(query)) return 'personal_data';
  if (_isNutritionQuery(query)) return 'nutrition';
  if (_isWorkoutQuery(query)) return 'workout';
  if (_isMotivationQuery(query)) return 'motivation';
  if (_isMealPlanQuery(query)) return 'meal_plan';
  if (_isHealthInsightQuery(query)) return 'health_insight';
  return 'general';
}

/// Combine memory context with RAG context for optimal AI response
String _combineMemoryAndRAGContext(String memoryPrompt, dynamic contextResult, Map<String, dynamic> memoryAnalysis) {
  final buffer = StringBuffer();
  
  // Start with memory-enhanced prompt
  buffer.writeln(memoryPrompt);
  
  // Add relevant conversation patterns
  final patterns = memoryAnalysis['patterns'] as Map<String, dynamic>? ?? {};
  final relevantConversations = memoryAnalysis['relevantConversations'] as List<dynamic>? ?? [];
  
  if (relevantConversations.isNotEmpty) {
    buffer.writeln('RELEVANT PAST CONVERSATIONS:');
    for (int i = 0; i < relevantConversations.length && i < 2; i++) {
      final conv = relevantConversations[i];
      final question = conv['question']?.toString() ?? '';
      final answer = conv['answer']?.toString() ?? '';
      
      buffer.writeln('Past Q${i + 1}: ${question.length > 80 ? '${question.substring(0, 80)}...' : question}');
      buffer.writeln('Past A${i + 1}: ${answer.length > 100 ? '${answer.substring(0, 100)}...' : answer}');
      buffer.writeln('');
    }
  }
  
  // Add conversation insights
  if (patterns.containsKey('commonTopics')) {
    final commonTopics = patterns['commonTopics'] as Map<String, dynamic>? ?? {};
    if (commonTopics.isNotEmpty) {
      final topTopics = commonTopics.entries.toList()..sort((a, b) => (b.value as int).compareTo(a.value as int));
      buffer.writeln('USER\'S FREQUENT TOPICS: ${topTopics.take(3).map((e) => '${e.key}(${e.value}x)').join(', ')}');
      buffer.writeln('');
    }
  }
  
  // Add additional RAG context if available
  if (contextResult != null && contextResult.contextItems?.isNotEmpty == true) {
    buffer.writeln('ADDITIONAL KNOWLEDGE BASE CONTEXT:');
    for (final item in contextResult.contextItems.take(2)) {
      buffer.writeln('${item.type}: ${item.content.length > 100 ? item.content.substring(0, 100) + '...' : item.content}');
    }
    buffer.writeln('');
  }
  
  // Enhanced response instructions
  buffer.writeln('ENHANCED RESPONSE INSTRUCTIONS:');
  buffer.writeln('- Reference and build upon relevant past conversations');
  buffer.writeln('- Show continuity in your advice and recommendations');
  buffer.writeln('- Acknowledge user\'s journey and progress over time');
  buffer.writeln('- Personalize response based on conversation history patterns');
  buffer.writeln('- If contradicting previous advice, explain why the change is beneficial');
  buffer.writeln('- Use insights from user\'s interaction patterns to optimize response');
  buffer.writeln('');
  
  return buffer.toString();
}

String _determineUrgency(String query) {
  final urgentKeywords = ['urgent', 'emergency', 'help', 'now', 'immediately'];
  return urgentKeywords.any((keyword) => query.contains(keyword)) ? 'high' : 'normal';
}

/// Get immediate nutrition information for common foods
String _getImmediateNutritionInfo(String food, UserProfile profile) {
  final nutrition = getDefaultNutrition(food, '100g');
  final name = profile.name ?? 'there';

  return '''🍎 **${food.toUpperCase()} Nutrition (100g):**

• **Calories**: ${nutrition['calories']} kcal
• **Protein**: ${nutrition['protein']}g
• **Carbs**: ${nutrition['carbs']}g
• **Fat**: ${nutrition['fat']}g

This fits well with your ${profile.goal.replaceAll('_', ' ')} goal, $name! 💪''';
}

/// Handle direct personal data queries with immediate responses
String? _handleDirectPersonalDataQuery(String query, UserProfile profile) {
  final queryLower = query.toLowerCase().trim();

  // Height queries
  if (queryLower.contains('height') || queryLower.contains('tall')) {
    if (profile.height != null) {
      // Get the actual height unit from userStore
      final heightUnit = userStore.heightUnit.isNotEmpty ? userStore.heightUnit : 'cm';
      final heightValue = profile.height!;

      String heightDisplay;
      if (heightUnit.toLowerCase() == 'feet' || heightUnit.toLowerCase() == 'ft') {
        // Height is in feet, display as feet and inches
        final feet = heightValue.floor();
        final inches = ((heightValue - feet) * 12).round();
        heightDisplay = '$feet\'$inches" (${(heightValue * 30.48).toStringAsFixed(1)} cm)';
      } else {
        // Height is in cm, display as cm and feet/inches
        final totalInches = heightValue / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();
        heightDisplay = '${heightValue.toStringAsFixed(1)} cm ($feet\'$inches")';
      }

      return 'Hi ${profile.name}! 📏 Your height is $heightDisplay. Is there anything specific about your height you\'d like to know for your fitness journey?';
    } else {
      return 'Hi ${profile.name}! I don\'t have your height information yet. Please update your profile with your height so I can provide personalized fitness advice! 📏';
    }
  }

  // Weight queries
  if (queryLower.contains('weight') || queryLower.contains('weigh')) {
    if (profile.weight != null) {
      return 'Hi ${profile.name}! ⚖️ Your current weight is ${profile.weight}kg (${(profile.weight! * 2.205).toStringAsFixed(1)} lbs). How can I help you with your ${profile.goal.replaceAll('_', ' ')} goal?';
    } else {
      return 'Hi ${profile.name}! I don\'t have your weight information yet. Please update your profile with your current weight so I can provide personalized advice! ⚖️';
    }
  }

  // Age queries
  if (queryLower.contains('age') || queryLower.contains('old')) {
    if (profile.age != null) {
      return 'Hi ${profile.name}! 🎂 You are ${profile.age} years old. Age is just a number when it comes to fitness - let\'s work on your ${profile.goal.replaceAll('_', ' ')} goal together!';
    } else {
      return 'Hi ${profile.name}! I don\'t have your age information yet. Please update your profile so I can provide age-appropriate fitness recommendations! 🎂';
    }
  }

  // BMI queries
  if (queryLower.contains('bmi') || queryLower.contains('body mass')) {
    if (profile.weight != null && profile.height != null) {
      final bmi = profile.weight! / ((profile.height! / 100) * (profile.height! / 100));
      String category;
      if (bmi < 18.5) {
        category = 'underweight';
      } else if (bmi < 25) category = 'normal weight';
      else if (bmi < 30) category = 'overweight';
      else category = 'obese';

      return 'Hi ${profile.name}! 📊 Your BMI is ${bmi.toStringAsFixed(1)}, which falls in the $category category. Remember, BMI is just one metric - muscle mass, body composition, and overall health are more important! How can I help with your fitness goals?';
    } else {
      return 'Hi ${profile.name}! I need both your height and weight to calculate your BMI. Please update your profile with this information! 📊';
    }
  }

  // General profile queries
  if (queryLower.contains('my profile') || queryLower.contains('about me') || queryLower.contains('my info')) {
    final info = StringBuffer();
    info.writeln('Hi ${profile.name}! 👤 Here\'s your profile information:');
    info.writeln('');
    info.writeln('📋 **Personal Details:**');
    info.writeln('• Name: ${profile.name}');
    if (profile.age != null) info.writeln('• Age: ${profile.age} years old');
    if (profile.gender != null) info.writeln('• Gender: ${profile.gender}');
    if (profile.height != null) info.writeln('• Height: ${profile.height}cm');
    if (profile.weight != null) info.writeln('• Weight: ${profile.weight}kg');
    info.writeln('• Goal: ${profile.goal.replaceAll('_', ' ')}');
    info.writeln('');
    info.writeln('Is there anything you\'d like to update or any specific advice you need? 💪');

    return info.toString();
  }

  return null; // Not a direct personal data query
}

Future<String> chatWithAI(List<CoreMessage> messages, {UserProfile? userProfile, List<MealEntry>? recentMeals}) async {
  // Enhance messages with user context if available
  List<CoreMessage> enhancedMessages = List.from(messages);

  if (userProfile != null) {
    // Create comprehensive user context
    final recentMealContext = recentMeals?.isNotEmpty == true
        ? recentMeals!.take(3).map((m) => m.foods.map((f) => f.name).join(', ')).join('; ')
        : 'No recent meals tracked';

    // Add user context as system message
    final contextMessage = CoreMessage(
      role: 'system',
      content: '''You are IRA, ${userProfile.name ?? 'User'}'s personal AI fitness companion.

USER PROFILE:
- Name: ${userProfile.name ?? 'User'}
- Primary Goal: ${userProfile.goal.replaceAll('_', ' ')}
- Age: ${userProfile.age}, Gender: ${userProfile.gender}
- Physical: ${userProfile.weight}kg, ${userProfile.height}cm
- Activity: ${userProfile.exerciseDuration} minutes exercise daily
- Recent Meals: $recentMealContext

RESPONSE RULES:
- Always personalize responses using their name and goal
- Provide specific, actionable advice for their ${userProfile.goal.replaceAll('_', ' ')} goal
- Reference their stats when relevant
- Be encouraging and supportive
- Keep responses concise and practical
- Use their recent meal data for nutrition advice
- For food/nutrition queries: provide specific nutritional information
- For calorie questions: give exact calorie counts and macros
- For workout questions: suggest exercises for their goal
- NO generic responses - everything must be personalized and specific'''
    );

    // Insert context at the beginning
    enhancedMessages.insert(0, contextMessage);
  }

  return await _callAIWithMessages(enhancedMessages);
}

/// Internal function to call AI with messages
Future<String> _callAIWithMessages(List<CoreMessage> messages) async {
  // Check AI service status
  print('🤖🤖🤖 AI CONFIG CHECK:');
  print('🤖🤖🤖 OpenRouter enabled: ${AIConfig.openrouter['enabled']}');
  print('🤖🤖🤖 OpenRouter API key present: ${AIConfig.openrouter['apiKey']?.toString().isNotEmpty}');
  print('🤖🤖🤖 Gemini enabled: ${AIConfig.gemini['enabled']}');

  if (!AIConfig.openrouter['enabled'] && !AIConfig.gemini['enabled']) {
    print('🤖 IRA AI: Using mock responses (AI service disabled)');
    print('💡 To enable AI: OpenRouter is now configured and ready to use!');
  }

  // Try OpenRouter first (primary service) - Enhanced error handling
  if (AIConfig.openrouter['enabled'] && AIConfig.openrouter['apiKey']?.toString().isNotEmpty == true) {
    try {
    print('🤖 Attempting OpenRouter API call with ${messages.length} messages');
      print('🤖🤖🤖 OPENROUTER API CALL STARTING');
    print('🔑 API Key present: ${AIConfig.openrouter['apiKey']?.toString().substring(0, 20)}...');
    print('🌐 URL: ${AIConfig.openrouter['url']}');
    print('🤖 Model: ${AIConfig.openrouter['model']}');

      final result = await _callOpenRouter(messages);
    print('✅ OpenRouter API call successful');
      print('🤖🤖🤖 OPENROUTER API SUCCESS - RETURNING RESPONSE');
      return result;
    } catch (error) {
    print('❌ OpenRouter API failed with error: $error');
      print('🤖🤖🤖 OPENROUTER API ERROR: $error');
    print('📊 Error type: ${error.runtimeType}');

      // Don't immediately fall back - try a few more times for transient errors
      if (error.toString().contains('429') || error.toString().contains('503')) {
    print('⏰ Rate limit or service unavailable, waiting before retry...');
        await Future.delayed(const Duration(seconds: 2));
        try {
          final retryResult = await _callOpenRouter(messages);
    print('✅ OpenRouter API retry successful');
          return retryResult;
        } catch (retryError) {
    print('❌ OpenRouter API retry failed: $retryError');
        }
      }
    }
  } else {
    print('⚠️ OpenRouter API not configured properly:');
    print('   - Enabled: ${AIConfig.openrouter['enabled']}');
    print('   - API Key present: ${AIConfig.openrouter['apiKey']?.toString().isNotEmpty}');
    print('   - API Key length: ${AIConfig.openrouter['apiKey']?.toString().length}');
  }

  // Since Gemini is disabled, skip fallback to it
  print('⚠️ Gemini fallback is disabled - using OpenRouter exclusively');

  // Try OpenAI as fallback (if enabled)
  if (AIConfig.openai['enabled'] && AIConfig.openai['apiKey']?.toString().isNotEmpty == true) {
    try {
      print('🤖 Attempting OpenAI fallback API call with ${messages.length} messages');
      final response = await http.post(
        Uri.parse(AIConfig.openai['url']),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AIConfig.openai['apiKey']}',
        },
        body: jsonEncode({
          'model': AIConfig.openai['model'],
          'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]?['message']?['content'];
        if (content != null) {
          print('✅ OpenAI fallback response generated successfully');
          return content;
        }
      } else {
        print('❌ OpenAI API failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (error) {
      print('❌ OpenAI API failed, falling back to mock responses: $error');
    }
  }

  // Try primary API if enabled (currently disabled due to 500 errors)
  if (AIConfig.primary['enabled']) {
    try {
      final response = await http.post(
        Uri.parse(AIConfig.primary['url']),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList()
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['completion'] ?? 'Sorry, I could not generate a response.';
      }
    } catch (error) {
      print('Primary AI API failed, falling back to mock responses: $error');
    }
  }

  // Final fallback - try to provide intelligent response based on context
  print('🤖 IRA AI: All AI services failed, providing intelligent contextual response');
  return _generateIntelligentFallbackResponse(messages);
}

/// Generate intelligent fallback response when AI services are unavailable
String _generateIntelligentFallbackResponse(List<CoreMessage> messages) {
  // Extract user profile and meals from context if available
  UserProfile? userProfile;
  List<MealEntry>? recentMeals;

  // Try to get user context
  try {
    final userContext = IRAUserContext();
    userProfile = userContext.buildEnhancedUserProfile();
    // Get recent meals from nutrition store
    recentMeals = [];
  } catch (e) {
    print('Could not get user context for fallback response: $e');
  }

  final userMessage = messages.where((m) => m.role == 'user').isNotEmpty
      ? messages.where((m) => m.role == 'user').last.content
      : '';
  final messageText = userMessage.toString().toLowerCase();

  // Get user's name for personalization
  final userName = userProfile?.name?.isNotEmpty == true ? userProfile!.name! : 'there';

  // Analyze the query type for better responses
  final inputAnalysis = _analyzeDietaryInput(userMessage.toString(), userProfile ?? UserProfile(goal: 'maintain_healthy_lifestyle', exerciseDuration: 30), recentMeals);

  // Try to provide immediate response for specific query types
  if (inputAnalysis['isPersonalDataQuery'] == true && userProfile != null) {
    final personalResponse = _handleDirectPersonalDataQuery(userMessage.toString(), userProfile);
    if (personalResponse != null) {
      return personalResponse;
    }
  }

  // Calculate recent nutrition data if available
  String nutritionContext = '';
  if (recentMeals != null && recentMeals.isNotEmpty) {
    final totalCalories = recentMeals.fold(0.0, (sum, meal) => sum + meal.totalCalories);
    // Calculate average calories for potential future use
    // final avgCalories = totalCalories / recentMeals.length;
    final lastMealFoods = recentMeals.isNotEmpty
        ? recentMeals.first.foods.map((f) => f.name).take(3).join(', ')
        : '';

    if (lastMealFoods.isNotEmpty) {
      nutritionContext = ' I see you\'ve been eating $lastMealFoods recently.';
    }
  }

  // Enhanced context-aware responses based on query analysis
  switch (inputAnalysis['queryType']) {
    case 'nutrition':
      if (inputAnalysis['mentionedFoods'].isNotEmpty) {
        final foods = inputAnalysis['mentionedFoods'] as List<String>;
        final food = foods.first;
        return _getImmediateNutritionInfo(food, userProfile ?? UserProfile(goal: 'maintain_healthy_lifestyle', exerciseDuration: 30));
      }
      return '''📊 **Nutrition Help Available, $userName!**
I can provide nutrition information for various foods! Just ask about specific foods like:
• Fruits, vegetables, grains
• Protein sources (chicken, fish, eggs)
• Snacks and processed foods
• Meal combinations

What specific food would you like to know about? 🍎$nutritionContext''';

    case 'workout':
      final goalContext = userProfile?.goal != null
          ? ' Since your goal is ${userProfile!.goal.replaceAll('_', ' ')}, I can suggest specific exercises that align with that.'
          : '';
      return 'Great question about workouts, $userName! 💪 I can help you with exercise routines, form tips, and workout planning.$goalContext What specific type of workout are you interested in?';

    case 'meal_plan':
      if (userProfile != null) {
        return _generateStructuredMealPlan(userProfile, recentMeals ?? []);
      }
      return 'I\'d love to help you with meal planning, $userName! 🍽️ To provide the best recommendations, I need to know your fitness goals. What are you working towards?';

    case 'motivation':
      final personalMotivation = userProfile?.goal != null
          ? ' Your ${userProfile!.goal.replaceAll('_', ' ')} goal is absolutely achievable!'
          : '';
      return 'You\'re doing amazing, $userName! 🌟$personalMotivation Every healthy choice brings you closer to your goals. Remember: consistency beats perfection. Keep pushing forward! 💪✨';

    case 'health_insight':
      if (userProfile != null) {
        return _generateStructuredHealthInsights(userProfile, null);
      }
      return 'I\'m here to provide health insights, $userName! 🏥 To give you personalized advice, tell me about your current fitness goals and any specific areas you\'d like to focus on.';

    default:
      // Handle greetings and general queries
      if (messageText.contains('hello') || messageText.contains('hi') || messageText.contains('hey')) {
        return 'Hello $userName! 👋 I\'m IRA, your AI fitness companion! 🤖💪 I\'m here to help you with workouts, nutrition, and health advice.$nutritionContext What would you like to know?';
      }

      if (messageText.contains('name')) {
        return 'I\'m IRA - your Intelligent Fitness Assistant! 🤖 Nice to meet you, $userName! I\'m here to help you achieve your ${userProfile?.goal.replaceAll('_', ' ') ?? 'fitness'} goals. How can I assist you today?';
      }
  }

  // Default intelligent response with service status
  final goalText = userProfile?.goal != null ? userProfile!.goal.replaceAll('_', ' ') : 'fitness';
  return '''Hi $userName! I'm IRA, your AI fitness companion! 🤖💪

⚠️ **Note**: AI services are temporarily unavailable, but I can still help with:
• Workout routines & exercises for your $goalText goals
• Nutrition & meal planning$nutritionContext
• Calorie counting and food analysis
• Health tips & motivation
• Progress tracking

For the best experience, please check your internet connection. What would you like to know about fitness or nutrition?''';
}

Future<String> generateMealPlan(UserProfile profile, List<MealEntry> recentMeals) async {
  final messages = [
    CoreMessage(
      role: 'system',
      content: '''You are a professional nutritionist. Create ONLY a meal plan, no introductions.

STRICT REQUIREMENTS:
- Goal: ${profile.goal.replaceAll('_', ' ')}
- User: ${profile.name ?? 'User'}, ${profile.age}yo, ${profile.gender}
- Stats: ${profile.weight}kg, ${profile.height}cm
- Exercise: ${profile.exerciseDuration}min daily
- Format: 🍳 Breakfast: [meal] ([calories])
         🥗 Lunch: [meal] ([calories])
         🍽️ Dinner: [meal] ([calories])
         Total: ~[total] calories for [goal]
- Keep under 150 words
- NO explanations, just the meal plan

GOAL-SPECIFIC CALORIES:
- Weight loss: 1200-1400 calories
- Muscle gain: 2000-2400 calories
- Maintenance: 1600-1800 calories'''
    ),
    CoreMessage(
      role: 'user',
      content: '''Create meal plan for ${profile.goal.replaceAll('_', ' ')} goal. Recent meals: ${recentMeals.isNotEmpty ? recentMeals.take(3).map((m) => m.foods.map((f) => f.name).join(', ')).join('; ') : 'none'}.'''
    )
  ];

  try {
    final result = await chatWithAI(messages, userProfile: profile, recentMeals: recentMeals);
    print('✅ AI meal plan generated: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');

    // Clean and validate response contains meal structure
    final cleanedResult = _cleanAIResponse(result);
    if (!cleanedResult.contains('🍳') || !cleanedResult.contains('🥗') || cleanedResult.length > 500) {
    print('⚠️ AI meal plan invalid format, using structured response');
      return _generateStructuredMealPlan(profile, recentMeals);
    }

    return cleanedResult;
  } catch (error) {
    print('❌ AI meal plan failed: $error');
    return _generateStructuredMealPlan(profile, recentMeals);
  }
}

String _generateStructuredMealPlan(UserProfile profile, List<MealEntry> recentMeals) {
  final name = profile.name ?? 'you';
  final goal = profile.goal.replaceAll('_', ' ');

  // Goal-specific meal plans
  switch (profile.goal.toLowerCase()) {
    case 'lose_weight':
    case 'weight_loss':
      return '''Here's your personalized meal plan for $goal, $name:

🍳 Breakfast: Greek yogurt with berries (300 cal)
🥗 Lunch: Grilled chicken salad with olive oil dressing (400 cal)
🍽️ Dinner: Baked cod with steamed vegetables (350 cal)
🍎 Snack: Apple with almond butter (150 cal)

Total: ~1200 calories for healthy weight loss
💧 Stay hydrated and track your progress!''';

    case 'gain_muscles':
    case 'muscle_gain':
      return '''Here's your personalized meal plan for $goal, $name:

🍳 Breakfast: Protein smoothie with banana and oats (500 cal)
🥗 Lunch: Grilled chicken breast with quinoa and vegetables (600 cal)
🍽️ Dinner: Lean beef with sweet potato and broccoli (650 cal)
🥜 Snacks: Greek yogurt, nuts, protein bar (400 cal)

Total: ~2150 calories with high protein for muscle building
💪 Focus on post-workout nutrition!''';

    default:
      return '''Here's your personalized meal plan for $goal, $name:

🍳 Breakfast: Whole grain toast with avocado and eggs (400 cal)
🥗 Lunch: Mediterranean bowl with chickpeas and vegetables (500 cal)
🍽️ Dinner: Grilled salmon with brown rice and asparagus (550 cal)
🍓 Snack: Mixed berries with nuts (200 cal)

Total: ~1650 calories for healthy maintenance
🌟 Balance is key to sustainable health!''';
  }
}

Future<String> getHealthInsights(UserProfile profile) async {
  final bmi = profile.height != null && profile.weight != null
      ? (profile.weight! / ((profile.height! / 100) * (profile.height! / 100))).toStringAsFixed(1)
      : null;

  final messages = [
    CoreMessage(
      role: 'system',
      content: '''You are a health advisor. Provide ONLY health insights, no introductions.

STRICT REQUIREMENTS:
- User: ${profile.name ?? 'User'}, ${profile.age}yo ${profile.gender}
- Goal: ${profile.goal.replaceAll('_', ' ')}
- BMI: ${bmi ?? 'Not calculated'}
- Exercise: ${profile.exerciseDuration}min daily
- Format: ✅ [Insight 1]
         ✅ [Insight 2]
         ✅ [Insight 3]
         ✅ [Insight 4]
- Keep under 120 words
- Focus on their specific goal
- Be actionable and encouraging
- NO generic advice

GOAL-SPECIFIC FOCUS:
- Weight loss: Calorie deficit, cardio + strength
- Muscle gain: Protein, progressive overload, rest
- Maintenance: Balance, sustainability, variety'''
    ),
    CoreMessage(
      role: 'user',
      content: '''Provide health insights for ${profile.goal.replaceAll('_', ' ')} goal. BMI: ${bmi ?? 'unknown'}, ${profile.exerciseDuration}min exercise daily.'''
    )
  ];

  try {
    final result = await chatWithAI(messages, userProfile: profile);
    print('✅ AI health insights generated: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');

    // Clean and validate response contains insights structure
    final cleanedResult = _cleanAIResponse(result);
    if (!cleanedResult.contains('✅') || cleanedResult.length > 400 || cleanedResult.toLowerCase().contains('as a health advisor')) {
    print('⚠️ AI health insights invalid format, using structured response');
      return _generateStructuredHealthInsights(profile, bmi);
    }

    return cleanedResult;
  } catch (error) {
    print('❌ AI health insights failed: $error');
    return _generateStructuredHealthInsights(profile, bmi);
  }
}

String _generateStructuredHealthInsights(UserProfile profile, String? bmi) {
  final name = profile.name ?? 'you';
  final goal = profile.goal.replaceAll('_', ' ');

  // Goal-specific health insights
  switch (profile.goal.toLowerCase()) {
    case 'lose_weight':
    case 'weight_loss':
      return '''Great progress on your wellness journey, $name! Here are key insights for your $goal goal:

✅ Your weight loss goal is achievable with consistency
✅ Focus on creating a moderate calorie deficit (300-500 calories)
✅ Combine cardio with strength training for best results
✅ Track progress weekly, not daily - weight fluctuates naturally

${bmi != null ? 'Your BMI of $bmi provides a good baseline for tracking progress.' : ''}
Keep up the fantastic work! 🌟💪''';

    case 'gain_muscles':
    case 'muscle_gain':
      return '''Excellent commitment to your $goal journey, $name! Here are key insights:

✅ Your muscle gain goal requires progressive overload in training
✅ Prioritize protein intake (1.6-2.2g per kg body weight daily)
✅ Focus on compound exercises and adequate rest between sessions
✅ Be patient - quality muscle growth takes 8-12 weeks to show

${profile.exerciseDuration} minutes daily is perfect for muscle development!
Stay consistent! 💪🌟''';

    default:
      return '''Great approach to your $goal journey, $name! Here are key insights:

✅ Your healthy lifestyle goal is about sustainable balance
✅ Focus on consistent habits over quick fixes
✅ Include variety in both exercise and nutrition choices
✅ Listen to your body and adjust intensity as needed

${profile.exerciseDuration} minutes of daily activity is excellent for overall health!
Keep building those healthy habits! 🌟💪''';
  }
}

Future<Map<String, dynamic>> analyzeFoodWithAI(String foodName, String quantity) async {
  final messages = [
    CoreMessage(
      role: 'system',
      content: 'You are a nutrition expert. Analyze food items and provide accurate nutritional information. Respond only with JSON format.'
    ),
    CoreMessage(
      role: 'user',
      content: '''Analyze this food and provide nutritional information:
      Food: $foodName
      Quantity: $quantity

      Respond with JSON format:
      {
        "foodName": "food name",
        "calories": number,
        "protein": number,
        "carbs": number,
        "fat": number
      }'''
    )
  ];

  try {
    final response = await chatWithAI(messages);

    // Try to extract JSON from the response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch != null) {
      final parsed = jsonDecode(jsonMatch.group(0)!);
      return {
        'foodName': parsed['foodName'] ?? foodName,
        'calories': parsed['calories'] ?? 200,
        'protein': parsed['protein'] ?? 10,
        'carbs': parsed['carbs'] ?? 20,
        'fat': parsed['fat'] ?? 8
      };
    }

    // Fallback if JSON parsing fails
    throw Exception('Could not parse nutrition data');
  } catch (error) {
    print('Using enhanced fallback food analysis due to AI service unavailability');

    // Use enhanced default nutrition database instead of mock responses
    final defaultNutrition = getDefaultNutrition(foodName, quantity);

    return {
      'foodName': foodName,
      'calories': defaultNutrition['calories'],
      'protein': defaultNutrition['protein'],
      'carbs': defaultNutrition['carbs'],
      'fat': defaultNutrition['fat'],
    };
  }
}

Map<String, dynamic> getDefaultNutrition(String foodName, String quantity) {
  final food = foodName.toLowerCase();

  // Enhanced nutrition database for common foods (per 100g) - Including Cultural Foods
  final nutritionDatabase = {
    // Fruits
    'apple': {'calories': 52, 'protein': 0.3, 'carbs': 14, 'fat': 0.2},
    'banana': {'calories': 89, 'protein': 1.1, 'carbs': 23, 'fat': 0.3},
    'orange': {'calories': 47, 'protein': 0.9, 'carbs': 12, 'fat': 0.1},
    'mango': {'calories': 60, 'protein': 0.8, 'carbs': 15, 'fat': 0.4},

    // Vegetables
    'potato': {'calories': 77, 'protein': 2.0, 'carbs': 17, 'fat': 0.1},
    'aloo': {'calories': 77, 'protein': 2.0, 'carbs': 17, 'fat': 0.1}, // Hindi for potato
    'tomato': {'calories': 18, 'protein': 0.9, 'carbs': 3.9, 'fat': 0.2},
    'tamatar': {'calories': 18, 'protein': 0.9, 'carbs': 3.9, 'fat': 0.2}, // Hindi for tomato
    'onion': {'calories': 40, 'protein': 1.1, 'carbs': 9.3, 'fat': 0.1},
    'pyaz': {'calories': 40, 'protein': 1.1, 'carbs': 9.3, 'fat': 0.1}, // Hindi for onion
    'carrot': {'calories': 41, 'protein': 0.9, 'carbs': 10, 'fat': 0.2},
    'gajar': {'calories': 41, 'protein': 0.9, 'carbs': 10, 'fat': 0.2}, // Hindi for carrot
    'broccoli': {'calories': 34, 'protein': 2.8, 'carbs': 7, 'fat': 0.4},
    'spinach': {'calories': 23, 'protein': 2.9, 'carbs': 3.6, 'fat': 0.4},
    'palak': {'calories': 23, 'protein': 2.9, 'carbs': 3.6, 'fat': 0.4}, // Hindi for spinach

    // Indian Vegetables
    'bhindi': {'calories': 33, 'protein': 1.9, 'carbs': 7.5, 'fat': 0.2}, // Okra
    'okra': {'calories': 33, 'protein': 1.9, 'carbs': 7.5, 'fat': 0.2},
    'karela': {'calories': 17, 'protein': 1.0, 'carbs': 3.7, 'fat': 0.2}, // Bitter gourd
    'bitter gourd': {'calories': 17, 'protein': 1.0, 'carbs': 3.7, 'fat': 0.2},
    'lauki': {'calories': 14, 'protein': 0.6, 'carbs': 3.4, 'fat': 0.0}, // Bottle gourd
    'bottle gourd': {'calories': 14, 'protein': 0.6, 'carbs': 3.4, 'fat': 0.0},
    'baingan': {'calories': 25, 'protein': 1.0, 'carbs': 6.0, 'fat': 0.2}, // Eggplant
    'eggplant': {'calories': 25, 'protein': 1.0, 'carbs': 6.0, 'fat': 0.2},
    'gobi': {'calories': 25, 'protein': 1.9, 'carbs': 5.0, 'fat': 0.3}, // Cauliflower
    'cauliflower': {'calories': 25, 'protein': 1.9, 'carbs': 5.0, 'fat': 0.3},

    // Proteins
    'chicken': {'calories': 239, 'protein': 27, 'carbs': 0, 'fat': 14},
    'fish': {'calories': 206, 'protein': 22, 'carbs': 0, 'fat': 12},
    'beef': {'calories': 250, 'protein': 26, 'carbs': 0, 'fat': 15},
    'egg': {'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11},
    'tofu': {'calories': 76, 'protein': 8, 'carbs': 1.9, 'fat': 4.8},
    'paneer': {'calories': 265, 'protein': 18, 'carbs': 1.2, 'fat': 21}, // Indian cottage cheese

    // Grains & Carbs
    'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3},
    'chawal': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3}, // Hindi for rice
    'basmati rice': {'calories': 121, 'protein': 2.5, 'carbs': 25, 'fat': 0.4},
    'jeera rice': {'calories': 142, 'protein': 2.8, 'carbs': 28, 'fat': 1.2}, // Cumin rice
    'bread': {'calories': 265, 'protein': 9, 'carbs': 49, 'fat': 3.2},
    'pasta': {'calories': 220, 'protein': 8, 'carbs': 44, 'fat': 1.1},
    'oats': {'calories': 389, 'protein': 17, 'carbs': 66, 'fat': 6.9},
    'quinoa': {'calories': 120, 'protein': 4.4, 'carbs': 22, 'fat': 1.9},

    // Indian Breads
    'roti': {'calories': 297, 'protein': 11, 'carbs': 61, 'fat': 1.2},
    'chapati': {'calories': 297, 'protein': 11, 'carbs': 61, 'fat': 1.2},
    'naan': {'calories': 310, 'protein': 9, 'carbs': 56, 'fat': 6},
    'paratha': {'calories': 320, 'protein': 8, 'carbs': 45, 'fat': 12},
    'puri': {'calories': 501, 'protein': 10, 'carbs': 55, 'fat': 27},

    // Dairy
    'milk': {'calories': 42, 'protein': 3.4, 'carbs': 5, 'fat': 1},
    'yogurt': {'calories': 59, 'protein': 10, 'carbs': 3.6, 'fat': 0.4},
    'dahi': {'calories': 59, 'protein': 10, 'carbs': 3.6, 'fat': 0.4}, // Hindi for yogurt
    'cheese': {'calories': 113, 'protein': 7, 'carbs': 1, 'fat': 9},
    'ghee': {'calories': 900, 'protein': 0, 'carbs': 0, 'fat': 100}, // Clarified butter

    // Indian Lentils and Legumes
    'dal': {'calories': 116, 'protein': 9, 'carbs': 20, 'fat': 0.4}, // General lentil
    'daal': {'calories': 116, 'protein': 9, 'carbs': 20, 'fat': 0.4},
    'moong dal': {'calories': 347, 'protein': 24, 'carbs': 59, 'fat': 1.2}, // Mung beans
    'toor dal': {'calories': 335, 'protein': 22, 'carbs': 62, 'fat': 1.5}, // Pigeon peas
    'chana dal': {'calories': 335, 'protein': 20, 'carbs': 61, 'fat': 1.5}, // Split chickpeas
    'rajma': {'calories': 333, 'protein': 23, 'carbs': 60, 'fat': 0.8}, // Kidney beans
    'kidney beans': {'calories': 333, 'protein': 23, 'carbs': 60, 'fat': 0.8},
    'chole': {'calories': 164, 'protein': 8.9, 'carbs': 27, 'fat': 2.6}, // Chickpeas
    'chickpeas': {'calories': 164, 'protein': 8.9, 'carbs': 27, 'fat': 2.6},
    'chana': {'calories': 164, 'protein': 8.9, 'carbs': 27, 'fat': 2.6},

    // Processed Foods
    'maggie': {'calories': 420, 'protein': 11, 'carbs': 60, 'fat': 15},
    'noodle': {'calories': 138, 'protein': 4.5, 'carbs': 25, 'fat': 2.2},
    'pizza': {'calories': 266, 'protein': 11, 'carbs': 33, 'fat': 10},
    'burger': {'calories': 295, 'protein': 17, 'carbs': 24, 'fat': 15},

    // Nuts & Seeds
    'almond': {'calories': 579, 'protein': 21, 'carbs': 22, 'fat': 50},
    'peanut': {'calories': 567, 'protein': 26, 'carbs': 16, 'fat': 49},
    'walnut': {'calories': 654, 'protein': 15, 'carbs': 14, 'fat': 65},

    // Indian Dishes and Combinations
    'dal chawal': {'calories': 245, 'protein': 11.7, 'carbs': 48, 'fat': 0.7}, // Lentil rice
    'dal rice': {'calories': 245, 'protein': 11.7, 'carbs': 48, 'fat': 0.7},
    'rajma chawal': {'calories': 463, 'protein': 25.7, 'carbs': 88, 'fat': 1.1}, // Kidney beans rice
    'chole chawal': {'calories': 294, 'protein': 11.6, 'carbs': 55, 'fat': 2.9}, // Chickpeas rice
    'biryani': {'calories': 290, 'protein': 8, 'carbs': 45, 'fat': 8}, // Mixed rice dish
    'pulao': {'calories': 250, 'protein': 6, 'carbs': 42, 'fat': 6}, // Flavored rice
    'khichdi': {'calories': 120, 'protein': 4.5, 'carbs': 22, 'fat': 1.5}, // Rice lentil mix

    // South Indian Foods
    'dosa': {'calories': 168, 'protein': 4, 'carbs': 28, 'fat': 4}, // Fermented crepe
    'masala dosa': {'calories': 200, 'protein': 5, 'carbs': 32, 'fat': 6}, // Stuffed dosa
    'plain dosa': {'calories': 168, 'protein': 4, 'carbs': 28, 'fat': 4},
    'idli': {'calories': 58, 'protein': 2, 'carbs': 12, 'fat': 0.3}, // Steamed cake
    'vada': {'calories': 185, 'protein': 4, 'carbs': 18, 'fat': 11}, // Fried lentil donut
    'medu vada': {'calories': 185, 'protein': 4, 'carbs': 18, 'fat': 11},
    'uttapam': {'calories': 147, 'protein': 4, 'carbs': 24, 'fat': 4}, // Thick pancake
    'upma': {'calories': 150, 'protein': 4, 'carbs': 28, 'fat': 2.5}, // Semolina dish
    'sambar': {'calories': 85, 'protein': 4, 'carbs': 15, 'fat': 1.5}, // Lentil soup
    'rasam': {'calories': 45, 'protein': 2, 'carbs': 8, 'fat': 1}, // Tamarind soup

    // North Indian Curries
    'butter chicken': {'calories': 438, 'protein': 30, 'carbs': 5, 'fat': 32},
    'dal makhani': {'calories': 150, 'protein': 8, 'carbs': 18, 'fat': 6}, // Creamy lentils
    'paneer makhani': {'calories': 325, 'protein': 15, 'carbs': 8, 'fat': 26}, // Paneer curry
    'palak paneer': {'calories': 270, 'protein': 14, 'carbs': 6, 'fat': 22}, // Spinach paneer
    'aloo gobi': {'calories': 105, 'protein': 3, 'carbs': 18, 'fat': 3}, // Potato cauliflower
    'bhindi masala': {'calories': 95, 'protein': 3, 'carbs': 12, 'fat': 4}, // Okra curry

    // Indian Snacks
    'samosa': {'calories': 308, 'protein': 5, 'carbs': 25, 'fat': 21}, // Fried pastry
    'pakora': {'calories': 250, 'protein': 6, 'carbs': 20, 'fat': 16}, // Fritters
    'vada pav': {'calories': 286, 'protein': 7, 'carbs': 35, 'fat': 13}, // Mumbai burger
    'pav bhaji': {'calories': 400, 'protein': 8, 'carbs': 45, 'fat': 20}, // Bread vegetable curry
    'aloo tikki': {'calories': 180, 'protein': 4, 'carbs': 25, 'fat': 7}, // Potato patty
    'poha': {'calories': 180, 'protein': 3, 'carbs': 35, 'fat': 3}, // Flattened rice

    // Indian Sweets
    'gulab jamun': {'calories': 387, 'protein': 4, 'carbs': 52, 'fat': 18}, // Milk balls in syrup
    'rasgulla': {'calories': 186, 'protein': 4, 'carbs': 32, 'fat': 4}, // Spongy cheese balls
    'laddu': {'calories': 420, 'protein': 8, 'carbs': 55, 'fat': 18}, // Sweet balls
    'halwa': {'calories': 350, 'protein': 6, 'carbs': 45, 'fat': 16}, // Sweet pudding
    'kheer': {'calories': 120, 'protein': 4, 'carbs': 20, 'fat': 3}, // Rice pudding
    'jalebi': {'calories': 150, 'protein': 1, 'carbs': 30, 'fat': 3}, // Spiral sweet

    // Indian Beverages
    'chai': {'calories': 40, 'protein': 1.5, 'carbs': 6, 'fat': 1.5}, // Spiced tea
    'masala chai': {'calories': 40, 'protein': 1.5, 'carbs': 6, 'fat': 1.5},
    'lassi': {'calories': 110, 'protein': 4, 'carbs': 15, 'fat': 4}, // Yogurt drink
    'buttermilk': {'calories': 40, 'protein': 3.3, 'carbs': 5, 'fat': 0.9},
    'chaas': {'calories': 40, 'protein': 3.3, 'carbs': 5, 'fat': 0.9}, // Spiced buttermilk

    // Spices (small quantities, per 1 tsp)
    'turmeric': {'calories': 8, 'protein': 0.3, 'carbs': 1.4, 'fat': 0.2},
    'haldi': {'calories': 8, 'protein': 0.3, 'carbs': 1.4, 'fat': 0.2},
    'cumin': {'calories': 8, 'protein': 0.4, 'carbs': 0.9, 'fat': 0.5},
    'jeera': {'calories': 8, 'protein': 0.4, 'carbs': 0.9, 'fat': 0.5},
    'coriander': {'calories': 5, 'protein': 0.2, 'carbs': 1, 'fat': 0.1},
    'dhania': {'calories': 5, 'protein': 0.2, 'carbs': 1, 'fat': 0.1},
    'garam masala': {'calories': 6, 'protein': 0.3, 'carbs': 1.2, 'fat': 0.2},

    // Jharkhand Cuisine
    'dhuska': {'calories': 250, 'protein': 6, 'carbs': 35, 'fat': 10}, // Fried lentil pancake
    'dhushka': {'calories': 250, 'protein': 6, 'carbs': 35, 'fat': 10}, // Alternative spelling
    'pittha': {'calories': 180, 'protein': 4, 'carbs': 38, 'fat': 2}, // Rice cake
    'arsa': {'calories': 320, 'protein': 3, 'carbs': 65, 'fat': 6}, // Sweet rice cake
    'rugra': {'calories': 45, 'protein': 3, 'carbs': 8, 'fat': 1}, // Wild mushroom
    'bamboo shoot curry': {'calories': 85, 'protein': 4, 'carbs': 12, 'fat': 3},
    'bamboo shoot': {'calories': 27, 'protein': 2.6, 'carbs': 5.2, 'fat': 0.3},

    // Bihar Cuisine
    'litti chokha': {'calories': 320, 'protein': 12, 'carbs': 55, 'fat': 8}, // Stuffed wheat balls with mashed vegetables
    'litti': {'calories': 280, 'protein': 10, 'carbs': 50, 'fat': 6}, // Stuffed wheat ball
    'chokha': {'calories': 85, 'protein': 2, 'carbs': 12, 'fat': 3}, // Mashed vegetables
    'sattu paratha': {'calories': 350, 'protein': 15, 'carbs': 58, 'fat': 8}, // Roasted gram flour stuffed bread
    'sattu': {'calories': 413, 'protein': 20, 'carbs': 65, 'fat': 5}, // Roasted gram flour
    'khaja': {'calories': 450, 'protein': 6, 'carbs': 60, 'fat': 20}, // Layered sweet
    'tilkut': {'calories': 480, 'protein': 12, 'carbs': 45, 'fat': 28}, // Sesame sweet
    'chana ghugni': {'calories': 180, 'protein': 8, 'carbs': 28, 'fat': 4}, // Spiced chickpeas
    'ghugni': {'calories': 180, 'protein': 8, 'carbs': 28, 'fat': 4},
    'thekua': {'calories': 420, 'protein': 8, 'carbs': 65, 'fat': 15}, // Sweet snack

    // Tamil Nadu Cuisine
    'paniyaram': {'calories': 120, 'protein': 3, 'carbs': 20, 'fat': 3}, // Fermented rice balls
    'kuska': {'calories': 280, 'protein': 8, 'carbs': 50, 'fat': 6}, // Spiced rice
    'kothu parotta': {'calories': 380, 'protein': 12, 'carbs': 55, 'fat': 12}, // Shredded bread curry
    'kothu': {'calories': 380, 'protein': 12, 'carbs': 55, 'fat': 12},
    'parotta': {'calories': 300, 'protein': 8, 'carbs': 45, 'fat': 10}, // Layered bread
    'parotha': {'calories': 300, 'protein': 8, 'carbs': 45, 'fat': 10},
    'chettinad chicken': {'calories': 280, 'protein': 25, 'carbs': 8, 'fat': 18}, // Spicy chicken curry
    'chettinad': {'calories': 280, 'protein': 25, 'carbs': 8, 'fat': 18},
    'kuzhambu': {'calories': 95, 'protein': 3, 'carbs': 15, 'fat': 3}, // Tamil curry
    'kootu': {'calories': 110, 'protein': 5, 'carbs': 18, 'fat': 2}, // Lentil vegetable curry
    'poriyal': {'calories': 85, 'protein': 3, 'carbs': 12, 'fat': 3}, // Stir-fried vegetables
    'vadai': {'calories': 185, 'protein': 4, 'carbs': 18, 'fat': 11}, // Fried lentil donut
    'murukku': {'calories': 520, 'protein': 12, 'carbs': 55, 'fat': 28}, // Spiral snack
    'adhirasam': {'calories': 380, 'protein': 4, 'carbs': 65, 'fat': 12}, // Sweet rice cake

    // Bengali Cuisine
    'machher bhat': {'calories': 220, 'protein': 18, 'carbs': 28, 'fat': 4}, // Fish rice
    'fish rice': {'calories': 220, 'protein': 18, 'carbs': 28, 'fat': 4},
    'shorshe ilish': {'calories': 280, 'protein': 22, 'carbs': 3, 'fat': 20}, // Mustard hilsa fish
    'ilish': {'calories': 310, 'protein': 20, 'carbs': 0, 'fat': 25}, // Hilsa fish
    'hilsa': {'calories': 310, 'protein': 20, 'carbs': 0, 'fat': 25},
    'kosha mangsho': {'calories': 320, 'protein': 28, 'carbs': 5, 'fat': 20}, // Slow-cooked mutton
    'mangsho': {'calories': 320, 'protein': 28, 'carbs': 5, 'fat': 20}, // Mutton
    'mishti doi': {'calories': 120, 'protein': 4, 'carbs': 18, 'fat': 4}, // Sweet yogurt
    'aloo posto': {'calories': 180, 'protein': 4, 'carbs': 25, 'fat': 7}, // Potato poppy seed
    'posto': {'calories': 525, 'protein': 18, 'carbs': 28, 'fat': 42}, // Poppy seed
    'chingri malai curry': {'calories': 220, 'protein': 18, 'carbs': 8, 'fat': 14}, // Prawn coconut curry
    'bhapa ilish': {'calories': 290, 'protein': 22, 'carbs': 2, 'fat': 22}, // Steamed hilsa
    'sandesh': {'calories': 180, 'protein': 4, 'carbs': 32, 'fat': 4}, // Milk sweet
    'chomchom': {'calories': 200, 'protein': 4, 'carbs': 35, 'fat': 5}, // Spongy sweet
    'langcha': {'calories': 190, 'protein': 3, 'carbs': 38, 'fat': 4}, // Fried sweet

    // Assamese Cuisine
    'pitha': {'calories': 220, 'protein': 4, 'carbs': 45, 'fat': 3}, // Rice cake
    'til pitha': {'calories': 280, 'protein': 6, 'carbs': 48, 'fat': 8}, // Sesame rice cake
    'narikol pitha': {'calories': 250, 'protein': 5, 'carbs': 42, 'fat': 7}, // Coconut rice cake
    'sunga saul': {'calories': 140, 'protein': 3, 'carbs': 30, 'fat': 1}, // Bamboo rice
    'khar': {'calories': 65, 'protein': 2, 'carbs': 12, 'fat': 1}, // Alkaline curry
    'tenga': {'calories': 85, 'protein': 3, 'carbs': 15, 'fat': 2}, // Sour curry
    'ou tenga': {'calories': 75, 'protein': 2, 'carbs': 16, 'fat': 1}, // Elephant apple curry

    // Northeastern Cuisine
    'momos': {'calories': 180, 'protein': 8, 'carbs': 25, 'fat': 5}, // Steamed dumplings
    'momo': {'calories': 180, 'protein': 8, 'carbs': 25, 'fat': 5},
    'thukpa': {'calories': 220, 'protein': 12, 'carbs': 35, 'fat': 4}, // Noodle soup
    'gundruk': {'calories': 45, 'protein': 3, 'carbs': 8, 'fat': 0.5}, // Fermented leafy greens
    'kinema': {'calories': 192, 'protein': 19, 'carbs': 13, 'fat': 7}, // Fermented soybean
    'churpi': {'calories': 380, 'protein': 60, 'carbs': 5, 'fat': 12}, // Dried yak cheese
    'tingmo': {'calories': 180, 'protein': 5, 'carbs': 35, 'fat': 2}, // Steamed bread
    'sel roti': {'calories': 320, 'protein': 6, 'carbs': 55, 'fat': 8}, // Ring-shaped bread

    // Additional Regional Dishes
    'dal dhokli': {'calories': 180, 'protein': 8, 'carbs': 32, 'fat': 3}, // Gujarati lentil pasta
    'dhokli': {'calories': 120, 'protein': 3, 'carbs': 24, 'fat': 1}, // Wheat pasta
    'bisi bele bath': {'calories': 250, 'protein': 8, 'carbs': 45, 'fat': 5}, // Karnataka rice dish
    'ragi mudde': {'calories': 180, 'protein': 6, 'carbs': 35, 'fat': 2}, // Finger millet balls
    'pesarattu': {'calories': 150, 'protein': 8, 'carbs': 25, 'fat': 2}, // Green gram dosa
    'punugulu': {'calories': 160, 'protein': 4, 'carbs': 22, 'fat': 6}, // Fried rice balls
    'gongura': {'calories': 35, 'protein': 2, 'carbs': 6, 'fat': 0.5}, // Sorrel leaves
    'ker sangri': {'calories': 95, 'protein': 3, 'carbs': 18, 'fat': 2}, // Desert beans
    'laal maas': {'calories': 350, 'protein': 30, 'carbs': 5, 'fat': 23}, // Spicy red meat curry
    'rogan josh': {'calories': 320, 'protein': 28, 'carbs': 6, 'fat': 20}, // Kashmiri lamb curry
    'yakhni': {'calories': 280, 'protein': 25, 'carbs': 4, 'fat': 18}, // Yogurt-based curry
    'tabak maaz': {'calories': 380, 'protein': 32, 'carbs': 2, 'fat': 26}, // Fried ribs
    'gustaba': {'calories': 320, 'protein': 28, 'carbs': 3, 'fat': 22}, // Minced meat balls
    'fish molee': {'calories': 240, 'protein': 20, 'carbs': 8, 'fat': 15}, // Kerala fish curry
    'olan': {'calories': 120, 'protein': 3, 'carbs': 15, 'fat': 6}, // Ash gourd coconut curry
    'avial': {'calories': 110, 'protein': 3, 'carbs': 18, 'fat': 3}, // Mixed vegetable curry
    'thoran': {'calories': 85, 'protein': 3, 'carbs': 12, 'fat': 3}, // Stir-fried vegetables with coconut
  };

  // Try exact match first
  if (nutritionDatabase.containsKey(food)) {
    return nutritionDatabase[food]!;
  }

  // Try partial matches
  for (final key in nutritionDatabase.keys) {
    if (food.contains(key) || key.contains(food)) {
      return nutritionDatabase[key]!;
    }
  }

  // Enhanced category-based fallbacks including cultural foods
  if (food.contains('fruit')) {
    return {'calories': 60, 'protein': 0.8, 'carbs': 15, 'fat': 0.3};
  } else if (food.contains('vegetable') || food.contains('sabzi') || food.contains('salad')) {
    return {'calories': 35, 'protein': 2, 'carbs': 7, 'fat': 0.3};
  } else if (food.contains('meat') || food.contains('protein') || food.contains('chicken') || food.contains('mutton')) {
    return {'calories': 250, 'protein': 25, 'carbs': 0, 'fat': 14};
  } else if (food.contains('grain') || food.contains('cereal') || food.contains('chawal') || food.contains('rice')) {
    return {'calories': 200, 'protein': 6, 'carbs': 40, 'fat': 2};
  } else if (food.contains('dal') || food.contains('lentil') || food.contains('beans')) {
    return {'calories': 116, 'protein': 9, 'carbs': 20, 'fat': 0.4};
  } else if (food.contains('roti') || food.contains('chapati') || food.contains('naan') || food.contains('bread')) {
    return {'calories': 297, 'protein': 11, 'carbs': 61, 'fat': 1.2};
  } else if (food.contains('curry') || food.contains('masala') || food.contains('gravy')) {
    return {'calories': 180, 'protein': 8, 'carbs': 15, 'fat': 10};
  } else if (food.contains('dosa') || food.contains('idli') || food.contains('south indian')) {
    return {'calories': 168, 'protein': 4, 'carbs': 28, 'fat': 4};
  } else if (food.contains('biryani') || food.contains('pulao') || food.contains('fried rice')) {
    return {'calories': 290, 'protein': 8, 'carbs': 45, 'fat': 8};
  } else if (food.contains('paneer') || food.contains('cottage cheese')) {
    return {'calories': 265, 'protein': 18, 'carbs': 1.2, 'fat': 21};
  } else if (food.contains('sweet') || food.contains('dessert') || food.contains('mithai')) {
    return {'calories': 350, 'protein': 6, 'carbs': 45, 'fat': 16};
  } else if (food.contains('snack') || food.contains('namkeen') || food.contains('chaat')) {
    return {'calories': 250, 'protein': 6, 'carbs': 30, 'fat': 12};
  } else if (food.contains('tea') || food.contains('chai') || food.contains('coffee')) {
    return {'calories': 40, 'protein': 1.5, 'carbs': 6, 'fat': 1.5};
  } else if (food.contains('juice') || food.contains('drink') || food.contains('beverage')) {
    return {'calories': 45, 'protein': 0.5, 'carbs': 11, 'fat': 0.1};
  }

  // Default for unknown foods (more generous for cultural foods)
  return {'calories': 150, 'protein': 8, 'carbs': 20, 'fat': 5};
}

Future<String> getPersonalizedGreeting(UserProfile profile, String currentMood) async {
  final messages = [
    CoreMessage(
      role: 'system',
      content: '''You are IRA, a caring AI wellness companion. Generate ONLY a personalized greeting message.

STRICT REQUIREMENTS:
- Address user by name: ${profile.name ?? 'there'}
- Mention their specific goal: ${profile.goal.replaceAll('_', ' ')}
- Reference mood: $currentMood
- Keep under 50 words
- Use 1-2 emojis maximum
- NO explanations, NO questions, ONLY the greeting

EXAMPLE FORMAT: "Hello [Name]! 😊 Ready to continue your [goal] journey today? You seem [mood] - let's make it count! 💪"'''
    ),
    CoreMessage(
      role: 'user',
      content: '''Create a greeting for ${profile.name ?? 'there'} who wants to ${profile.goal.replaceAll('_', ' ')} and is feeling $currentMood today.'''
    )
  ];

  try {
    final result = await chatWithAI(messages, userProfile: profile);
    print('✅ AI greeting generated: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');

    // Clean and validate response is appropriate (more lenient to allow AI responses)
    final cleanedResult = _cleanAIResponse(result);
    if (cleanedResult.length > 300 ||
        cleanedResult.toLowerCase().contains('as an ai assistant') ||
        cleanedResult.toLowerCase().contains('i cannot') ||
        cleanedResult.toLowerCase().contains('i\'m sorry') ||
        !cleanedResult.toLowerCase().contains(profile.name?.toLowerCase() ?? 'user')) {
    print('⚠️ AI response not personalized enough, using structured response');
      return _generateStructuredGreeting(profile, currentMood);
    }

    return cleanedResult;
  } catch (error) {
    print('❌ AI greeting failed: $error');
    return _generateStructuredGreeting(profile, currentMood);
  }
}

String _generateStructuredGreeting(UserProfile profile, String currentMood) {
  final name = profile.name ?? 'there';
  final goal = profile.goal.replaceAll('_', ' ');

  final greetings = [
    'Hello $name! 😊 Ready to continue your $goal journey today? You seem $currentMood - let\'s make it count! 💪',
    'Hey $name! 🌟 Feeling $currentMood? Perfect energy for your $goal goals today! Let\'s do this! 💪',
    'Hi $name! 😊 Your $currentMood mood is perfect for working on your $goal goal today! Ready to shine? ✨',
  ];

  return greetings[DateTime.now().millisecond % greetings.length];
}

Future<String> getMotivationalMessage(UserProfile profile, String context) async {
  final messages = [
    CoreMessage(
      role: 'system',
      content: '''You are IRA, an encouraging AI wellness companion. Generate ONLY a motivational message.

STRICT REQUIREMENTS:
- Address user: ${profile.name ?? 'you'}
- Focus on their goal: ${profile.goal.replaceAll('_', ' ')}
- Context: $context
- Keep under 40 words
- Be specific and actionable
- Use 1 emoji maximum
- NO generic advice, NO explanations

EXAMPLE: "You're crushing your [goal] journey! Every healthy choice today brings you closer to success. Keep that momentum going! 💪"'''
    ),
    CoreMessage(
      role: 'user',
      content: '''Create motivation for ${profile.name ?? 'you'} who is working on ${profile.goal.replaceAll('_', ' ')} in the context of $context.'''
    )
  ];

  try {
    final result = await chatWithAI(messages, userProfile: profile);
    print('✅ AI motivation generated: ${result.substring(0, result.length > 80 ? 80 : result.length)}...');

    // Clean and validate response (more lenient)
    final cleanedResult = _cleanAIResponse(result);
    if (cleanedResult.length > 200 ||
        cleanedResult.toLowerCase().contains('as an ai assistant') ||
        cleanedResult.toLowerCase().contains('i cannot') ||
        !cleanedResult.toLowerCase().contains(profile.goal.replaceAll('_', ' '))) {
    print('⚠️ AI motivation not goal-specific enough, using structured response');
      return _generateStructuredMotivation(profile, context);
    }

    return cleanedResult;
  } catch (error) {
    print('❌ AI motivation failed: $error');
    return _generateStructuredMotivation(profile, context);
  }
}

String _generateStructuredMotivation(UserProfile profile, String context) {
  final name = profile.name ?? 'you';
  final goal = profile.goal.replaceAll('_', ' ');

  final motivations = [
    'You\'re crushing your $goal journey, $name! Every healthy choice today brings you closer to success. Keep going! 💪',
    'Amazing progress on your $goal goal, $name! Your consistency is paying off. Stay strong! 🌟',
    'You\'ve got this, $name! Your $goal journey is all about small wins that add up to big results! ✨',
  ];

  return motivations[DateTime.now().millisecond % motivations.length];
}

/// Analyze food nutrition using AI with validation
Future<Map<String, dynamic>> analyzeFoodNutrition(String foodName, String quantity) async {
  print('🔍 Analyzing food nutrition for: "$foodName" ($quantity)');

  try {
    // First, validate that the input is actually a food item
    final validation = await FoodValidationService.validateFoodText(foodName);
    print('🔍 Food validation result: $validation');

    if (!validation.isValid) {
      print('❌ Food validation failed: ${validation.errorMessage}');
      throw FoodValidationException(validation.errorMessage ?? 'Invalid food input');
    }

    // If validation passes with low confidence, add a warning but continue
    if (validation.confidence < 0.7) {
      print('⚠️ Low confidence food validation (${validation.confidence}), proceeding with caution');
    }

    final messages = [
      CoreMessage(
        role: 'system',
        content: '''You are a nutrition expert with comprehensive knowledge of global cuisines, including Indian, Asian, African, Middle Eastern, and other cultural foods. Analyze the given food and provide accurate nutritional information.

        IMPORTANT: Recognize and analyze foods from ALL cultures and cuisines, including:
        - Indian foods: dal, roti, chapati, naan, biryani, dosa, idli, sambar, rasam, curry, sabzi
        - Regional dishes: rajma chawal, chole, masala dosa, dal chawal, paneer dishes
        - Spices and ingredients: turmeric (haldi), cumin (jeera), coriander (dhania), garam masala
        - Traditional preparations: thali combinations, regional specialties, cultural cooking methods

        If the input is NOT a food item (furniture, electronics, etc.), respond with:
        {"error": "not_food", "message": "Invalid input, please enter food items only"}

        For valid food items from ANY culture, return ONLY a JSON object with these exact keys: calories, protein, carbs, fat.
        All values should be numbers (not strings). Base the analysis on the specified quantity.
        Be inclusive - when analyzing cultural foods, provide your best nutritional estimate based on typical preparations.

        Examples:
        - "apple" → {"calories": 52, "protein": 0.3, "carbs": 14, "fat": 0.2}
        - "dal chawal" → {"calories": 320, "protein": 12, "carbs": 58, "fat": 4}
        - "masala dosa" → {"calories": 168, "protein": 4, "carbs": 28, "fat": 4}
        - "wooden chair" → {"error": "not_food", "message": "Invalid input, please enter food items only"}'''
      ),
      CoreMessage(
        role: 'user',
        content: '''Analyze the nutrition for: $quantity of $foodName

        Provide the nutritional values in JSON format with keys: calories, protein, carbs, fat
        OR if this is not a food item, return the error format specified above.'''
      )
    ];

    final response = await chatWithAI(messages);

    // Try to parse JSON from the response
    try {
      // Extract JSON from response if it contains other text
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final Map<String, dynamic> parsed = jsonDecode(jsonString);

        // Check if AI detected non-food item
        if (parsed.containsKey('error') && parsed['error'] == 'not_food') {
          final errorMessage = parsed['message'] ?? 'Invalid input, please enter food items only';
          print('❌ AI detected non-food item: $errorMessage');
          throw FoodValidationException(errorMessage);
        }

        return {
          'calories': (parsed['calories'] ?? 0).toDouble(),
          'protein': (parsed['protein'] ?? 0).toDouble(),
          'carbs': (parsed['carbs'] ?? 0).toDouble(),
          'fat': (parsed['fat'] ?? 0).toDouble(),
        };
      }
    } catch (e) {
      if (e is FoodValidationException) {
        rethrow; // Re-throw validation exceptions
      }
      print('Failed to parse AI nutrition response: $e');
    }

    // Fallback to enhanced nutrition database (only for validated food items)
    print('⚠️ Using fallback nutrition database for validated food item');
    return getDefaultNutrition(foodName, quantity);

  } catch (error) {
    if (error is FoodValidationException) {
      rethrow; // Re-throw validation exceptions to caller
    }

    print('❌ Food nutrition analysis error: $error');
    // For other errors, try fallback but with additional validation
    final fallbackValidation = await FoodValidationService.validateFoodText(foodName);
    if (!fallbackValidation.isValid) {
      throw FoodValidationException(fallbackValidation.errorMessage ?? 'Invalid food input');
    }

    print('Using enhanced fallback food analysis for validated item');
    return getDefaultNutrition(foodName, quantity);
  }
}

/// Exception thrown when food validation fails
class FoodValidationException implements Exception {
  final String message;
  FoodValidationException(this.message);

  @override
  String toString() => 'FoodValidationException: $message';
}

/// Call Gemini API with proper formatting
Future<String> _callGemini(List<CoreMessage> messages) async {
    print('🤖 Calling Gemini API...');

  // Properly format messages for Gemini API
  String combinedContent = '';

  // Separate system and user messages
  final systemMessages = messages.where((m) => m.role == 'system').toList();
  final userMessages = messages.where((m) => m.role == 'user').toList();

  // Create a comprehensive prompt for Gemini
  if (systemMessages.isNotEmpty && userMessages.isNotEmpty) {
    // Combine system instructions with user query in a clear format
    combinedContent = '''${systemMessages.map((m) => m.content.toString()).join('\n\n')}

USER REQUEST: ${userMessages.map((m) => m.content.toString()).join('\n\n')}

IMPORTANT: Follow the system instructions exactly. Provide only the requested response format without any meta-commentary or explanations about being an AI.''';
  } else if (systemMessages.isNotEmpty) {
    combinedContent = systemMessages.map((m) => m.content.toString()).join('\n\n');
  } else if (userMessages.isNotEmpty) {
    combinedContent = userMessages.map((m) => m.content.toString()).join('\n\n');
  } else {
    combinedContent = messages.map((m) => m.content.toString()).join('\n\n');
  }

  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': combinedContent}
        ]
      }
    ],
    'generationConfig': {
      'temperature': AIConfig.gemini['temperature'] ?? 0.7,
      'maxOutputTokens': AIConfig.gemini['maxTokens'] ?? 2048,
      'topP': 0.8,
      'topK': 10
    }
  };

  try {
    print('📤 Sending to Gemini: ${combinedContent.substring(0, combinedContent.length > 200 ? 200 : combinedContent.length)}...');
    print('📋 Request body keys: ${requestBody.keys.toList()}');
    print('📄 Full request body: ${jsonEncode(requestBody)}');

    final url = '${AIConfig.gemini['baseUrl']}/${AIConfig.gemini['model']}:generateContent?key=${AIConfig.gemini['apiKey']}';
    print('🌐 Full API URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    print('🔍 Gemini API Response Status: ${response.statusCode}');
    print('📄 Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
    print('📊 Response structure: ${data.keys.toList()}');

      // Extract content from Gemini response format
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
    print('✅ Found ${candidates.length} candidates');
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
    print('✅ Gemini AI response generated successfully (${text.length} chars)');
            return text.trim();
          }
        }
      }

    print('⚠️ Gemini response format unexpected: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      throw Exception('Unexpected response format from Gemini');
    } else {
      final errorText = response.body;
    print('❌ Gemini API Error ${response.statusCode}: ${response.reasonPhrase}');
    print('📄 Error Details: $errorText');

      if (response.statusCode == 401) {
    print('🔑 Gemini Authentication Failed - Check API key');
      } else if (response.statusCode == 429) {
    print('⏰ Gemini Rate Limit Exceeded - Try again later');
      } else if (response.statusCode == 400) {
    print('📝 Bad Request - Check request format');
      }

      throw Exception('Gemini API failed with status ${response.statusCode}: $errorText');
    }
  } catch (error) {
    print('💥 Gemini API call failed: $error');
    print('🔍 Error details: ${error.toString()}');
    rethrow;
  }
}

/// Call OpenRouter API with proper formatting
Future<String> _callOpenRouter(List<CoreMessage> messages) async {
    print('🤖 Calling OpenRouter API...');

  try {
    // Format messages for OpenRouter (OpenAI-compatible format)
    final formattedMessages = messages.map((m) => {
      'role': m.role,
      'content': m.content.toString(),
    }).toList();

    final requestBody = {
      'model': AIConfig.openrouter['model'],
      'messages': formattedMessages,
      'max_tokens': AIConfig.openrouter['maxTokens'] ?? 2048,
      'temperature': AIConfig.openrouter['temperature'] ?? 0.7,
    };

    print('📤 Sending to OpenRouter: ${formattedMessages.length} messages');
    print('🤖 Model: ${AIConfig.openrouter['model']}');
    print('📄 Request body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse(AIConfig.openrouter['url']),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.openrouter['apiKey']}',
        'HTTP-Referer': AIConfig.openrouter['siteUrl'],
        'X-Title': AIConfig.openrouter['siteName'],
      },
      body: jsonEncode(requestBody),
    );

    print('🔍 OpenRouter API Response Status: ${response.statusCode}');
    print('📄 Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
    print('📊 Response structure: ${data.keys.toList()}');

      // Extract content from OpenRouter response format (OpenAI-compatible)
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
    print('✅ Found ${choices.length} choices');
        final message = choices[0]['message'];
        final content = message['content'] as String?;
        if (content != null && content.isNotEmpty) {
    print('✅ OpenRouter AI response generated successfully (${content.length} chars)');
          return content.trim();
        }
      }

    print('⚠️ OpenRouter response format unexpected: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      throw Exception('Unexpected response format from OpenRouter');
    } else {
      final errorText = response.body;
    print('❌ OpenRouter API Error ${response.statusCode}: ${response.reasonPhrase}');
    print('📄 Error Details: $errorText');

      if (response.statusCode == 401) {
    print('🔑 OpenRouter Authentication Failed - Check API key');
      } else if (response.statusCode == 429) {
    print('⏰ OpenRouter Rate Limit Exceeded - Try again later');
      } else if (response.statusCode == 400) {
    print('📝 Bad Request - Check request format');
      }

      throw Exception('OpenRouter API failed with status ${response.statusCode}: $errorText');
    }
  } catch (error) {
    print('💥 OpenRouter API call failed: $error');
    print('🔍 Error details: ${error.toString()}');
    rethrow;
  }
}

/// Check if a query is nutrition-related (enhanced version)
bool _isNutritionQueryEnhanced(String query) {
  final lowerQuery = query.toLowerCase();
  final nutritionKeywords = [
    'calories', 'nutrition', 'protein', 'carbs', 'fat', 'fiber',
    'nutrients', 'vitamins', 'minerals', 'macros', 'nutritional',
    'how many calories', 'nutritional value', 'nutritional info',
    'nutritional content', 'food value', 'dietary', 'diet'
  ];

  return nutritionKeywords.any((keyword) => lowerQuery.contains(keyword));
}

/// Validate nutrition queries for non-food inputs
Future<Map<String, dynamic>> _validateNutritionQuery(String query) async {
  try {
    // Extract potential food items from the query
    final foodMentions = _extractFoodMentions(query);

    if (foodMentions.isEmpty) {
      // No specific food items mentioned, let AI handle general nutrition questions
      return {'isValid': true};
    }

    // Validate each mentioned item
    for (final foodItem in foodMentions) {
      final validation = await FoodValidationService.validateFoodText(foodItem);
      if (!validation.isValid && validation.confidence > 0.7) {
        return {
          'isValid': false,
          'reason': 'Non-food item detected: $foodItem',
          'response': 'I can only provide nutritional information for food items. "$foodItem" is not a food item. Please ask about actual foods, beverages, or ingredients.'
        };
      }
    }

    return {'isValid': true};

  } catch (e) {
    print('❌ Nutrition query validation error: $e');
    // On error, allow the query to proceed
    return {'isValid': true};
  }
}

/// Extract potential food mentions from a query
List<String> _extractFoodMentions(String query) {
  final lowerQuery = query.toLowerCase();

  // Look for patterns like "calories in X", "nutrition of X", etc.
  final patterns = [
    RegExp(r'calories in (.+?)(?:\?|$|\.)', caseSensitive: false),
    RegExp(r'nutrition of (.+?)(?:\?|$|\.)', caseSensitive: false),
    RegExp(r'nutritional value of (.+?)(?:\?|$|\.)', caseSensitive: false),
    RegExp(r'how many calories in (.+?)(?:\?|$|\.)', caseSensitive: false),
    RegExp(r'protein in (.+?)(?:\?|$|\.)', caseSensitive: false),
    RegExp(r'carbs in (.+?)(?:\?|$|\.)', caseSensitive: false),
  ];

  final mentions = <String>[];

  for (final pattern in patterns) {
    final matches = pattern.allMatches(query);
    for (final match in matches) {
      if (match.group(1) != null) {
        final mention = match.group(1)!.trim();
        if (mention.isNotEmpty && mention.length < 50) { // Reasonable length limit
          mentions.add(mention);
        }
      }
    }
  }

  return mentions;
}
