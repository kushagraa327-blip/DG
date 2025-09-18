import 'dart:convert';
import 'dart:developer';
import '../extensions/shared_pref.dart';
import '../models/ira_conversation_model.dart';
import '../models/meal_entry_model.dart';
import '../services/ai_service.dart';
import '../main.dart';

/// Enhanced conversation memory and context analysis service
class IRAConversationMemory {
  static final IRAConversationMemory _instance = IRAConversationMemory._internal();
  factory IRAConversationMemory() => _instance;
  IRAConversationMemory._internal();

  // Cache for conversation patterns and insights
  final Map<String, dynamic> _conversationPatterns = {};
  final Map<String, dynamic> _userInsights = {};
  final List<String> _userPreferences = [];
  final Map<String, int> _topicFrequency = {};

  /// Analyze conversation history to extract patterns and insights
  Future<Map<String, dynamic>> analyzeConversationHistory(String currentQuery) async {
    try {
      // Get all conversation history
      final conversationHistory = await _getConversationHistory();
      
      // Extract conversation patterns
      final patterns = _extractConversationPatterns(conversationHistory);
      
      // Analyze user preferences and habits
      final preferences = _analyzeUserPreferences(conversationHistory);
      
      // Find relevant past conversations
      final relevantConversations = _findRelevantConversations(currentQuery, conversationHistory);
      
      // Get conversation context summary
      final contextSummary = await _generateContextSummary(relevantConversations, currentQuery);

      return {
        'patterns': patterns,
        'preferences': preferences,
        'relevantConversations': relevantConversations,
        'contextSummary': contextSummary,
        'userInsights': _userInsights,
        'topicFrequency': _topicFrequency,
      };
    } catch (e) {
      log('❌ Error analyzing conversation history: $e');
      return {};
    }
  }

  /// Extract conversation patterns from history
  Map<String, dynamic> _extractConversationPatterns(List<Map<String, dynamic>> history) {
    final patterns = <String, dynamic>{};
    
    // Analyze question types and frequency
    final questionTypes = <String, int>{};
    final commonTopics = <String, int>{};
    final timePatterns = <String, int>{};
    
    for (final conversation in history) {
      final question = conversation['question']?.toString().toLowerCase() ?? '';
      final timestamp = DateTime.tryParse(conversation['timestamp'] ?? '') ?? DateTime.now();
      
      // Categorize question types
      final questionType = _categorizeQuestion(question);
      questionTypes[questionType] = (questionTypes[questionType] ?? 0) + 1;
      
      // Extract topics
      final topics = _extractTopics(question);
      for (final topic in topics) {
        commonTopics[topic] = (commonTopics[topic] ?? 0) + 1;
      }
      
      // Analyze time patterns
      final hour = timestamp.hour;
      final timeSlot = _getTimeSlot(hour);
      timePatterns[timeSlot] = (timePatterns[timeSlot] ?? 0) + 1;
    }
    
    patterns['questionTypes'] = questionTypes;
    patterns['commonTopics'] = commonTopics;
    patterns['timePatterns'] = timePatterns;
    patterns['totalConversations'] = history.length;
    
    return patterns;
  }

  /// Analyze user preferences from conversation history
  Map<String, dynamic> _analyzeUserPreferences(List<Map<String, dynamic>> history) {
    final preferences = <String, dynamic>{};
    
    // Extract food preferences
    final likedFoods = <String>[];
    final dislikedFoods = <String>[];
    final dietaryRestrictions = <String>[];
    
    // Extract workout preferences
    final preferredWorkouts = <String>[];
    final workoutTimes = <String>[];
    
    // Extract goal-related patterns
    final goalMentions = <String, int>{};
    
    for (final conversation in history) {
      final question = conversation['question']?.toString().toLowerCase() ?? '';
      final answer = conversation['answer']?.toString().toLowerCase() ?? '';
      final fullText = '$question $answer';
      
      // Analyze food preferences
      _extractFoodPreferences(fullText, likedFoods, dislikedFoods, dietaryRestrictions);
      
      // Analyze workout preferences
      _extractWorkoutPreferences(fullText, preferredWorkouts, workoutTimes);
      
      // Analyze goal mentions
      _extractGoalMentions(fullText, goalMentions);
    }
    
    preferences['likedFoods'] = likedFoods;
    preferences['dislikedFoods'] = dislikedFoods;
    preferences['dietaryRestrictions'] = dietaryRestrictions;
    preferences['preferredWorkouts'] = preferredWorkouts;
    preferences['workoutTimes'] = workoutTimes;
    preferences['goalMentions'] = goalMentions;
    
    return preferences;
  }

  /// Find conversations relevant to current query
  List<Map<String, dynamic>> _findRelevantConversations(String currentQuery, List<Map<String, dynamic>> history) {
    final relevant = <Map<String, dynamic>>[];
    final queryLower = currentQuery.toLowerCase();
    final queryKeywords = _extractKeywords(queryLower);
    
    for (final conversation in history) {
      final question = conversation['question']?.toString().toLowerCase() ?? '';
      final answer = conversation['answer']?.toString().toLowerCase() ?? '';
      
      // Calculate relevance score
      double relevanceScore = 0.0;
      
      // Direct keyword matches
      for (final keyword in queryKeywords) {
        if (question.contains(keyword)) relevanceScore += 2.0;
        if (answer.contains(keyword)) relevanceScore += 1.0;
      }
      
      // Semantic similarity (basic)
      if (_hasSemanticSimilarity(queryLower, question)) {
        relevanceScore += 1.5;
      }
      
      // Topic similarity
      final questionTopics = _extractTopics(question);
      final queryTopics = _extractTopics(queryLower);
      final commonTopics = questionTopics.where((topic) => queryTopics.contains(topic)).length;
      relevanceScore += commonTopics * 0.5;
      
      if (relevanceScore > 1.0) {
        conversation['relevanceScore'] = relevanceScore;
        relevant.add(conversation);
      }
    }
    
    // Sort by relevance and return top 5
    relevant.sort((a, b) => (b['relevanceScore'] as double).compareTo(a['relevanceScore'] as double));
    return relevant.take(5).toList();
  }

  /// Generate context summary from relevant conversations
  Future<String> _generateContextSummary(List<Map<String, dynamic>> relevantConversations, String currentQuery) async {
    if (relevantConversations.isEmpty) {
      return 'No relevant conversation history found.';
    }
    
    final summaryBuffer = StringBuffer();
    summaryBuffer.writeln('CONVERSATION HISTORY CONTEXT:');
    
    for (int i = 0; i < relevantConversations.length && i < 3; i++) {
      final conv = relevantConversations[i];
      final question = conv['question']?.toString() ?? '';
      final answer = conv['answer']?.toString() ?? '';
      final score = conv['relevanceScore'] as double;
      
      summaryBuffer.writeln('Previous Context ${i + 1} (relevance: ${score.toStringAsFixed(1)}):');
      summaryBuffer.writeln('Q: ${question.length > 100 ? '${question.substring(0, 100)}...' : question}');
      summaryBuffer.writeln('A: ${answer.length > 150 ? '${answer.substring(0, 150)}...' : answer}');
      summaryBuffer.writeln('');
    }
    
    return summaryBuffer.toString();
  }

  /// Get enhanced prompt with conversation memory
  Future<String> getEnhancedPromptWithMemory({
    required String userQuery,
    required UserProfile userProfile,
    List<MealEntry>? recentMeals,
  }) async {
    final memoryAnalysis = await analyzeConversationHistory(userQuery);
    final buffer = StringBuffer();
    
    // Enhanced system prompt with memory
    buffer.writeln('You are IRA, ${userProfile.name ?? "User"}\'s personal AI fitness companion with memory of past conversations.');
    buffer.writeln('You remember previous discussions and can build upon them to provide personalized, contextual responses.');
    buffer.writeln('');
    
    // User profile
    buffer.writeln('USER PROFILE:');
    buffer.writeln('- Name: ${userProfile.name ?? "User"}');
    buffer.writeln('- Goal: ${userProfile.goal.replaceAll('_', ' ')}');
    if (userProfile.age != null) buffer.writeln('- Age: ${userProfile.age}');
    if (userProfile.weight != null) buffer.writeln('- Weight: ${userProfile.weight} kg');
    if (userProfile.height != null) buffer.writeln('- Height: ${userProfile.height} cm');
    buffer.writeln('');
    
    // Recent meals
    if (recentMeals?.isNotEmpty == true) {
      buffer.writeln('RECENT MEALS:');
      for (final meal in recentMeals!.take(3)) {
        buffer.writeln('${meal.mealType}: ${meal.foods.map((f) => f.name).join(', ')}');
      }
      buffer.writeln('');
    }
    
    // Conversation patterns and preferences
    final patterns = memoryAnalysis['patterns'] as Map<String, dynamic>? ?? {};
    final preferences = memoryAnalysis['preferences'] as Map<String, dynamic>? ?? {};
    
    if (patterns.isNotEmpty) {
      buffer.writeln('CONVERSATION PATTERNS:');
      final commonTopics = patterns['commonTopics'] as Map<String, int>? ?? {};
      if (commonTopics.isNotEmpty) {
        final topTopics = commonTopics.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        buffer.writeln('Common topics: ${topTopics.take(3).map((e) => e.key).join(', ')}');
      }
      buffer.writeln('Total conversations: ${patterns['totalConversations'] ?? 0}');
      buffer.writeln('');
    }
    
    if (preferences.isNotEmpty) {
      buffer.writeln('USER PREFERENCES (from conversation history):');
      final likedFoods = preferences['likedFoods'] as List<String>? ?? [];
      final preferredWorkouts = preferences['preferredWorkouts'] as List<String>? ?? [];
      
      if (likedFoods.isNotEmpty) {
        buffer.writeln('Liked foods: ${likedFoods.take(3).join(', ')}');
      }
      if (preferredWorkouts.isNotEmpty) {
        buffer.writeln('Preferred workouts: ${preferredWorkouts.take(3).join(', ')}');
      }
      buffer.writeln('');
    }
    
    // Relevant conversation context
    final contextSummary = memoryAnalysis['contextSummary'] as String? ?? '';
    if (contextSummary.isNotEmpty && contextSummary != 'No relevant conversation history found.') {
      buffer.writeln(contextSummary);
    }
    
    // Instructions for contextual responses
    buffer.writeln('RESPONSE GUIDELINES:');
    buffer.writeln('- Reference relevant past conversations when appropriate');
    buffer.writeln('- Build upon previous discussions and recommendations');
    buffer.writeln('- Acknowledge user preferences and patterns from history');
    buffer.writeln('- Provide personalized advice based on conversation memory');
    buffer.writeln('- Be consistent with previous guidance while allowing for growth');
    buffer.writeln('');
    
    return buffer.toString();
  }

  // Helper methods for analysis
  
  String _categorizeQuestion(String question) {
    if (question.contains('food') || question.contains('eat') || question.contains('meal') || question.contains('nutrition')) {
      return 'nutrition';
    } else if (question.contains('workout') || question.contains('exercise') || question.contains('training')) {
      return 'fitness';
    } else if (question.contains('weight') || question.contains('lose') || question.contains('gain')) {
      return 'weight_management';
    } else if (question.contains('motivation') || question.contains('help') || question.contains('encourage')) {
      return 'motivation';
    } else if (question.contains('plan') || question.contains('schedule') || question.contains('routine')) {
      return 'planning';
    }
    return 'general';
  }
  
  List<String> _extractTopics(String text) {
    final topics = <String>[];
    final words = text.toLowerCase().split(' ');
    
    // Fitness topics
    final fitnessKeywords = ['workout', 'exercise', 'training', 'fitness', 'gym', 'cardio', 'strength'];
    // Nutrition topics
    final nutritionKeywords = ['food', 'eat', 'meal', 'nutrition', 'diet', 'calories', 'protein'];
    // Health topics
    final healthKeywords = ['health', 'weight', 'body', 'muscle', 'fat', 'metabolism'];
    
    for (final word in words) {
      if (fitnessKeywords.contains(word)) topics.add('fitness');
      if (nutritionKeywords.contains(word)) topics.add('nutrition');
      if (healthKeywords.contains(word)) topics.add('health');
    }
    
    return topics.toSet().toList();
  }
  
  String _getTimeSlot(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
  
  List<String> _extractKeywords(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
    final stopWords = ['i', 'me', 'my', 'you', 'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'];
    return words.where((word) => word.length > 2 && !stopWords.contains(word)).toList();
  }
  
  bool _hasSemanticSimilarity(String query, String question) {
    final queryWords = _extractKeywords(query);
    final questionWords = _extractKeywords(question);
    final commonWords = queryWords.where((word) => questionWords.contains(word)).length;
    final totalWords = (queryWords.length + questionWords.length) / 2;
    return commonWords / totalWords > 0.3;
  }
  
  void _extractFoodPreferences(String text, List<String> liked, List<String> disliked, List<String> restrictions) {
    // Look for food preference indicators
    if (text.contains('like') || text.contains('love') || text.contains('enjoy')) {
      // Extract foods mentioned in positive context
    }
    if (text.contains('dislike') || text.contains('hate') || text.contains('avoid')) {
      // Extract foods mentioned in negative context
    }
    if (text.contains('allergic') || text.contains('intolerant') || text.contains('vegetarian') || text.contains('vegan')) {
      // Extract dietary restrictions
    }
  }
  
  void _extractWorkoutPreferences(String text, List<String> workouts, List<String> times) {
    // Extract workout preferences from text
  }
  
  void _extractGoalMentions(String text, Map<String, int> goals) {
    // Extract goal-related mentions
  }
  
  /// Get conversation history from storage
  Future<List<Map<String, dynamic>>> _getConversationHistory() async {
    try {
      final historyJson = getStringAsync('conversation_history', defaultValue: '[]');
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    } catch (e) {
      log('❌ Error loading conversation history: $e');
      return [];
    }
  }
}
