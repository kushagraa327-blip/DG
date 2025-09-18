import 'dart:convert';
import 'dart:developer';
import '../extensions/shared_pref.dart';
import '../models/ira_conversation_model.dart';
import '../utils/app_constants.dart';

/// Service for managing IRA conversation history and context
class IRAConversationService {
  static final IRAConversationService _instance = IRAConversationService._internal();
  factory IRAConversationService() => _instance;
  IRAConversationService._internal();

  // Current active conversation
  IRAConversation? _currentConversation;
  
  // Cache for recent conversations
  List<IRAConversation> _conversationCache = [];
  
  // User preferences
  IRAUserPreferences? _userPreferences;

  /// Initialize the service and load existing data
  Future<void> initialize() async {
    await _loadConversationHistory();
    await _loadUserPreferences();
    log('🤖 IRA Conversation Service initialized');
  }

  /// Start a new conversation session
  Future<IRAConversation> startNewConversation({
    Map<String, dynamic>? sessionContext,
  }) async {
    final conversationId = 'ira_${DateTime.now().millisecondsSinceEpoch}';
    
    _currentConversation = IRAConversation(
      id: conversationId,
      startTime: DateTime.now(),
      lastUpdated: DateTime.now(),
      messages: [],
      sessionContext: sessionContext,
    );

    log('🆕 Started new IRA conversation: $conversationId');
    return _currentConversation!;
  }

  /// Add a message to the current conversation
  Future<void> addMessage({
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
    List<String>? contextSources,
  }) async {
    if (_currentConversation == null) {
      await startNewConversation();
    }

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final message = IRAMessage(
      id: messageId,
      role: role,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
      contextSources: contextSources,
    );

    _currentConversation = _currentConversation!.addMessage(message);
    
    // Save to persistent storage
    await _saveCurrentConversation();
    
    log('💬 Added $role message to conversation: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
  }

  /// Get the current active conversation
  IRAConversation? getCurrentConversation() {
    return _currentConversation;
  }

  /// Get recent conversation history for context
  List<IRAMessage> getRecentContext({int messageCount = 10}) {
    if (_currentConversation == null) return [];
    return _currentConversation!.getRecentMessages(count: messageCount);
  }

  /// Search conversation history for relevant context
  List<RAGContext> searchConversationHistory(String query, {int maxResults = 5}) {
    final results = <RAGContext>[];
    final queryLower = query.toLowerCase();

    // Search current conversation
    if (_currentConversation != null) {
      for (final message in _currentConversation!.messages) {
        if (message.content.toLowerCase().contains(queryLower)) {
          results.add(RAGContext(
            id: message.id,
            type: 'conversation',
            content: message.content,
            relevanceScore: _calculateRelevanceScore(message.content, query),
            metadata: {
              'role': message.role,
              'timestamp': message.timestamp.toIso8601String(),
              'conversationId': _currentConversation!.id,
            },
            timestamp: message.timestamp,
          ));
        }
      }
    }

    // Search cached conversations
    for (final conversation in _conversationCache) {
      for (final message in conversation.messages) {
        if (message.content.toLowerCase().contains(queryLower)) {
          results.add(RAGContext(
            id: message.id,
            type: 'conversation',
            content: message.content,
            relevanceScore: _calculateRelevanceScore(message.content, query),
            metadata: {
              'role': message.role,
              'timestamp': message.timestamp.toIso8601String(),
              'conversationId': conversation.id,
            },
            timestamp: message.timestamp,
          ));
        }
      }
    }

    // Sort by relevance score and return top results
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(maxResults).toList();
  }

  /// End current conversation and archive it
  Future<void> endCurrentConversation() async {
    if (_currentConversation == null) return;

    // Add to conversation cache
    _conversationCache.add(_currentConversation!);
    
    // Keep only recent conversations in cache (last 10)
    if (_conversationCache.length > 10) {
      _conversationCache = _conversationCache.sublist(_conversationCache.length - 10);
    }

    // Save to persistent storage
    await _saveConversationHistory();
    
    log('🏁 Ended conversation: ${_currentConversation!.id}');
    _currentConversation = null;
  }

  /// Get user preferences for IRA interactions
  IRAUserPreferences? getUserPreferences() {
    return _userPreferences;
  }

  /// Update user preferences
  Future<void> updateUserPreferences(IRAUserPreferences preferences) async {
    _userPreferences = preferences;
    await _saveUserPreferences();
    log('⚙️ Updated IRA user preferences');
  }

  /// Load conversation history from storage
  Future<void> _loadConversationHistory() async {
    try {
      final historyJson = getStringAsync(IRA_CONVERSATION_HISTORY_KEY);
      if (historyJson.isNotEmpty) {
        final historyData = jsonDecode(historyJson) as Map<String, dynamic>;
        
        // Load current conversation
        if (historyData['currentConversation'] != null) {
          _currentConversation = IRAConversation.fromJson(
            historyData['currentConversation'] as Map<String, dynamic>
          );
        }
        
        // Load conversation cache
        if (historyData['conversationCache'] != null) {
          final cacheList = historyData['conversationCache'] as List<dynamic>;
          _conversationCache = cacheList
              .map((conv) => IRAConversation.fromJson(conv as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      log('Error loading conversation history: $e');
      _conversationCache = [];
      _currentConversation = null;
    }
  }

  /// Save conversation history to storage
  Future<void> _saveConversationHistory() async {
    try {
      final historyData = {
        'currentConversation': _currentConversation?.toJson(),
        'conversationCache': _conversationCache.map((conv) => conv.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await setValue(IRA_CONVERSATION_HISTORY_KEY, jsonEncode(historyData));
    } catch (e) {
      log('Error saving conversation history: $e');
    }
  }

  /// Save current conversation immediately
  Future<void> _saveCurrentConversation() async {
    await _saveConversationHistory();
  }

  /// Load user preferences from storage
  Future<void> _loadUserPreferences() async {
    try {
      final prefsJson = getStringAsync(IRA_USER_PREFERENCES_KEY);
      if (prefsJson.isNotEmpty) {
        final prefsData = jsonDecode(prefsJson) as Map<String, dynamic>;
        _userPreferences = IRAUserPreferences.fromJson(prefsData);
      }
    } catch (e) {
      log('Error loading user preferences: $e');
      _userPreferences = null;
    }
  }

  /// Save user preferences to storage
  Future<void> _saveUserPreferences() async {
    try {
      if (_userPreferences != null) {
        await setValue(IRA_USER_PREFERENCES_KEY, jsonEncode(_userPreferences!.toJson()));
      }
    } catch (e) {
      log('Error saving user preferences: $e');
    }
  }

  /// Calculate relevance score for search results
  double _calculateRelevanceScore(String content, String query) {
    final contentLower = content.toLowerCase();
    final queryLower = query.toLowerCase();
    
    // Simple scoring based on keyword matches
    final queryWords = queryLower.split(' ');
    int matches = 0;
    
    for (final word in queryWords) {
      if (contentLower.contains(word)) {
        matches++;
      }
    }
    
    return matches / queryWords.length;
  }

  /// Clear all conversation history (for testing or reset)
  Future<void> clearAllHistory() async {
    _currentConversation = null;
    _conversationCache.clear();
    await setValue(IRA_CONVERSATION_HISTORY_KEY, '');
    log('🗑️ Cleared all IRA conversation history');
  }
}
