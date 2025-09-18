import 'dart:developer';
import '../models/ira_conversation_model.dart';
import '../models/meal_entry_model.dart';
import '../services/ai_service.dart';
import 'ira_conversation_service.dart';
import 'ira_knowledge_base.dart';

/// Smart context retrieval service for RAG implementation
class IRARagService {
  static final IRARagService _instance = IRARagService._internal();
  factory IRARagService() => _instance;
  IRARagService._internal();

  final IRAConversationService _conversationService = IRAConversationService();
  final IRAKnowledgeBase _knowledgeBase = IRAKnowledgeBase();
  
  bool _isInitialized = false;

  /// Initialize the RAG service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _conversationService.initialize();
    await _knowledgeBase.initialize();
    
    _isInitialized = true;
    log('🔍 IRA RAG Service initialized');
  }

  /// Retrieve relevant context for a user query
  Future<RAGContextResult> retrieveContext({
    required String query,
    required UserProfile userProfile,
    List<MealEntry>? recentMeals,
    int maxContextItems = 10,
  }) async {
    if (!_isInitialized) await initialize();

    final contextItems = <RAGContext>[];

    // 1. Get user profile context (always include)
    final userContext = _buildUserProfileContext(userProfile, recentMeals);
    contextItems.addAll(userContext);

    // 2. Check if this is a personal data query and boost relevance
    final queryLower = query.toLowerCase();
    final personalDataKeywords = ['height', 'weight', 'age', 'my', 'me', 'i am', 'how tall', 'how much do i weigh'];
    final isPersonalQuery = personalDataKeywords.any((keyword) => queryLower.contains(keyword));

    if (isPersonalQuery) {
      // Boost user stats relevance for personal queries
      for (final item in contextItems) {
        if (item.type == 'user_data') {
          final boostedItem = RAGContext(
            id: item.id,
            type: item.type,
            content: item.content,
            relevanceScore: item.relevanceScore + 2.0, // Boost relevance
            metadata: item.metadata,
            timestamp: item.timestamp,
          );
          contextItems.removeWhere((i) => i.id == item.id);
          contextItems.add(boostedItem);
        }
      }

      log('🎯 Personal data query detected, boosting user profile relevance');
    }

    // 3. Search conversation history
    final conversationContext = _conversationService.searchConversationHistory(
      query,
      maxResults: 3
    );
    contextItems.addAll(conversationContext);

    // 4. Search knowledge base
    final knowledgeContext = _knowledgeBase.searchKnowledge(
      query,
      maxResults: 4
    );
    contextItems.addAll(knowledgeContext);

    // 5. Get recent conversation context
    final recentContext = _getRecentConversationContext();
    contextItems.addAll(recentContext);

    // 6. Sort by relevance and limit results
    contextItems.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    final finalContext = contextItems.take(maxContextItems).toList();

    log('🔍 Retrieved ${finalContext.length} context items for query: ${query.substring(0, query.length > 50 ? 50 : query.length)}...');
    log('📊 Top context: ${finalContext.take(3).map((c) => '${c.type}(${c.relevanceScore.toStringAsFixed(1)})').join(', ')}');

    return RAGContextResult(
      query: query,
      contextItems: finalContext,
      userProfile: userProfile,
      recentMeals: recentMeals,
      timestamp: DateTime.now(),
    );
  }

  /// Build enhanced prompt with retrieved context
  String buildEnhancedPrompt({
    required String userQuery,
    required RAGContextResult contextResult,
  }) {
    final buffer = StringBuffer();
    
    // System prompt with user context
    buffer.writeln('You are IRA, ${contextResult.userProfile.name ?? "User"}\'s personal AI fitness companion.');
    buffer.writeln('');
    
    // User profile information
    buffer.writeln('USER PROFILE:');
    buffer.writeln('- Name: ${contextResult.userProfile.name ?? "User"}');
    buffer.writeln('- Goal: ${contextResult.userProfile.goal.replaceAll('_', ' ')}');
    if (contextResult.userProfile.age != null) {
      buffer.writeln('- Age: ${contextResult.userProfile.age}');
    }
    if (contextResult.userProfile.weight != null) {
      buffer.writeln('- Weight: ${contextResult.userProfile.weight} kg');
    }
    if (contextResult.userProfile.height != null) {
      buffer.writeln('- Height: ${contextResult.userProfile.height} cm');
    }
    buffer.writeln('');
    
    // Recent meals context
    if (contextResult.recentMeals?.isNotEmpty == true) {
      buffer.writeln('RECENT MEALS:');
      final recentMealText = contextResult.recentMeals
          ?.take(3)
          .map((meal) => '${meal.mealType}: ${meal.foods.map((f) => f.name).join(', ')}')
          .join('; ') ?? '';
      buffer.writeln(recentMealText);
      buffer.writeln('');
    }
    
    // Relevant context from RAG
    if (contextResult.contextItems.isNotEmpty) {
      buffer.writeln('RELEVANT CONTEXT:');
      
      // Group context by type
      final knowledgeItems = contextResult.contextItems.where((item) => item.type == 'knowledge').toList();
      final conversationItems = contextResult.contextItems.where((item) => item.type == 'conversation').toList();
      final userDataItems = contextResult.contextItems.where((item) => item.type == 'user_data').toList();
      
      // Add knowledge context
      if (knowledgeItems.isNotEmpty) {
        buffer.writeln('Knowledge Base:');
        for (final item in knowledgeItems.take(3)) {
          buffer.writeln('- ${item.content}');
        }
        buffer.writeln('');
      }
      
      // Add conversation context
      if (conversationItems.isNotEmpty) {
        buffer.writeln('Previous Conversations:');
        for (final item in conversationItems.take(2)) {
          buffer.writeln('- ${item.content}');
        }
        buffer.writeln('');
      }
      
      // Add user data context
      if (userDataItems.isNotEmpty) {
        buffer.writeln('User Data:');
        for (final item in userDataItems.take(2)) {
          buffer.writeln('- ${item.content}');
        }
        buffer.writeln('');
      }
    }
    
    // Instructions for response
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('- ALWAYS use the user\'s personal information from the context above when answering questions about them');
    buffer.writeln('- When asked about height, weight, age, or other personal data, refer to the specific values in the USER PROFILE section');
    buffer.writeln('- If the user asks "what is my height/weight/age", provide the exact value from their profile');
    buffer.writeln('- Provide personalized, helpful advice based on the user\'s profile and context');
    buffer.writeln('- Reference the user\'s specific goals and recent activities when relevant');
    buffer.writeln('- Use the knowledge base information to provide accurate fitness/nutrition advice');
    buffer.writeln('- Keep responses conversational and motivating');
    buffer.writeln('- Address the user by name when appropriate');
    buffer.writeln('- If personal data is missing, ask the user to update their profile');
    buffer.writeln('');
    
    // User's current question
    buffer.writeln('USER QUESTION: $userQuery');
    
    return buffer.toString();
  }

  /// Save user message to conversation history
  Future<void> saveUserMessage(String message, {Map<String, dynamic>? metadata}) async {
    await _conversationService.addMessage(
      role: 'user',
      content: message,
      metadata: metadata,
    );
  }

  /// Save assistant response to conversation history
  Future<void> saveAssistantResponse(String response, {List<String>? contextSources}) async {
    await _conversationService.addMessage(
      role: 'assistant',
      content: response,
      contextSources: contextSources,
    );
  }

  /// Build user profile context
  List<RAGContext> _buildUserProfileContext(UserProfile userProfile, List<MealEntry>? recentMeals) {
    final contextItems = <RAGContext>[];

    // User goal context
    final goalContext = RAGContext(
      id: 'user_goal',
      type: 'user_data',
      content: 'User\'s primary fitness goal is to ${userProfile.goal.replaceAll('_', ' ')}',
      relevanceScore: 2.0,
      metadata: {'type': 'goal', 'goal': userProfile.goal},
      timestamp: DateTime.now(),
    );
    contextItems.add(goalContext);

    // Physical stats context - Always add even if some data is missing
    final statsContent = StringBuffer();
    statsContent.write('User\'s physical information: ');

    if (userProfile.name != null) {
      statsContent.write('Name: ${userProfile.name}, ');
    }

    if (userProfile.age != null) {
      statsContent.write('Age: ${userProfile.age} years old, ');
    }

    if (userProfile.height != null) {
      statsContent.write('Height: ${userProfile.height}cm, ');
    }

    if (userProfile.weight != null) {
      statsContent.write('Weight: ${userProfile.weight}kg, ');
    }

    if (userProfile.gender != null) {
      statsContent.write('Gender: ${userProfile.gender}, ');
    }

    // Calculate BMI if both height and weight are available
    if (userProfile.weight != null && userProfile.height != null) {
      final bmi = userProfile.weight! / ((userProfile.height! / 100) * (userProfile.height! / 100));
      statsContent.write('BMI: ${bmi.toStringAsFixed(1)}');
    }

    final statsContext = RAGContext(
      id: 'user_stats',
      type: 'user_data',
      content: statsContent.toString().replaceAll(', ', '').trim(),
      relevanceScore: 2.5, // Higher relevance for personal data questions
      metadata: {
        'type': 'physical_stats',
        'name': userProfile.name,
        'age': userProfile.age,
        'height': userProfile.height,
        'weight': userProfile.weight,
        'gender': userProfile.gender,
      },
      timestamp: DateTime.now(),
    );
    contextItems.add(statsContext);
    
    // Recent nutrition context
    if (recentMeals?.isNotEmpty == true) {
      final nutritionContext = RAGContext(
        id: 'recent_nutrition',
        type: 'user_data',
        content: 'Recent meals include: ${recentMeals!.take(3).map((m) => m.foods.map((f) => f.name).join(', ')).join('; ')}',
        relevanceScore: 1.8,
        metadata: {'type': 'nutrition', 'meal_count': recentMeals.length},
        timestamp: DateTime.now(),
      );
      contextItems.add(nutritionContext);
    }
    
    return contextItems;
  }

  /// Get recent conversation context
  List<RAGContext> _getRecentConversationContext() {
    final recentMessages = _conversationService.getRecentContext(messageCount: 4);
    return recentMessages.map((message) => RAGContext(
      id: message.id,
      type: 'conversation',
      content: '${message.role}: ${message.content}',
      relevanceScore: 1.0,
      metadata: {
        'role': message.role,
        'timestamp': message.timestamp.toIso8601String(),
      },
      timestamp: message.timestamp,
    )).toList();
  }

  /// Get conversation service for external access
  IRAConversationService get conversationService => _conversationService;
  
  /// Get knowledge base for external access
  IRAKnowledgeBase get knowledgeBase => _knowledgeBase;
}

/// Result of RAG context retrieval
class RAGContextResult {
  final String query;
  final List<RAGContext> contextItems;
  final UserProfile userProfile;
  final List<MealEntry>? recentMeals;
  final DateTime timestamp;

  RAGContextResult({
    required this.query,
    required this.contextItems,
    required this.userProfile,
    this.recentMeals,
    required this.timestamp,
  });

  /// Get context items by type
  List<RAGContext> getContextByType(String type) {
    return contextItems.where((item) => item.type == type).toList();
  }

  /// Get total relevance score
  double get totalRelevanceScore {
    return contextItems.fold(0.0, (sum, item) => sum + item.relevanceScore);
  }

  /// Get context summary
  String get summary {
    final types = contextItems.map((item) => item.type).toSet();
    return 'Retrieved ${contextItems.length} context items (${types.join(', ')}) with total relevance score: ${totalRelevanceScore.toStringAsFixed(2)}';
  }
}
