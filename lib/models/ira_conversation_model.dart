
/// Represents a single message in IRA conversation
class IRAMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Additional context like images, user mood, etc.
  final List<String>? contextSources; // Sources used for RAG (conversation history, knowledge base)

  IRAMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.contextSources,
  });

  factory IRAMessage.fromJson(Map<String, dynamic> json) {
    return IRAMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      contextSources: (json['contextSources'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'contextSources': contextSources,
    };
  }

  /// Create a copy with updated fields
  IRAMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<String>? contextSources,
  }) {
    return IRAMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      contextSources: contextSources ?? this.contextSources,
    );
  }
}

/// Represents a conversation session with IRA
class IRAConversation {
  final String id;
  final DateTime startTime;
  final DateTime lastUpdated;
  final List<IRAMessage> messages;
  final Map<String, dynamic>? sessionContext; // User state at conversation start
  final String? summary; // AI-generated summary for long conversations

  IRAConversation({
    required this.id,
    required this.startTime,
    required this.lastUpdated,
    required this.messages,
    this.sessionContext,
    this.summary,
  });

  factory IRAConversation.fromJson(Map<String, dynamic> json) {
    return IRAConversation(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => IRAMessage.fromJson(msg as Map<String, dynamic>))
          .toList() ?? [],
      sessionContext: json['sessionContext'] as Map<String, dynamic>?,
      summary: json['summary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'sessionContext': sessionContext,
      'summary': summary,
    };
  }

  /// Add a new message to the conversation
  IRAConversation addMessage(IRAMessage message) {
    final updatedMessages = List<IRAMessage>.from(messages)..add(message);
    return IRAConversation(
      id: id,
      startTime: startTime,
      lastUpdated: DateTime.now(),
      messages: updatedMessages,
      sessionContext: sessionContext,
      summary: summary,
    );
  }

  /// Get recent messages for context (default last 10)
  List<IRAMessage> getRecentMessages({int count = 10}) {
    if (messages.length <= count) return messages;
    return messages.sublist(messages.length - count);
  }

  /// Get messages from a specific time range
  List<IRAMessage> getMessagesByTimeRange(DateTime start, DateTime end) {
    return messages.where((msg) => 
      msg.timestamp.isAfter(start) && msg.timestamp.isBefore(end)
    ).toList();
  }

  /// Calculate conversation duration
  Duration get duration => lastUpdated.difference(startTime);

  /// Check if conversation is recent (within last 24 hours)
  bool get isRecent => DateTime.now().difference(lastUpdated).inHours < 24;
}

/// User preferences for IRA interactions
class IRAUserPreferences {
  final String userId;
  final String preferredResponseStyle; // casual, professional, motivational, etc.
  final List<String> interests; // fitness topics user is most interested in
  final Map<String, dynamic> personalitySettings; // response tone, length, etc.
  final DateTime lastUpdated;

  IRAUserPreferences({
    required this.userId,
    this.preferredResponseStyle = 'motivational',
    this.interests = const [],
    this.personalitySettings = const {},
    required this.lastUpdated,
  });

  factory IRAUserPreferences.fromJson(Map<String, dynamic> json) {
    return IRAUserPreferences(
      userId: json['userId']?.toString() ?? '',
      preferredResponseStyle: json['preferredResponseStyle']?.toString() ?? 'motivational',
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      personalitySettings: json['personalitySettings'] as Map<String, dynamic>? ?? {},
      lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'preferredResponseStyle': preferredResponseStyle,
      'interests': interests,
      'personalitySettings': personalitySettings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Context item for RAG retrieval
class RAGContext {
  final String id;
  final String type; // 'conversation', 'knowledge', 'user_data', 'meal_history'
  final String content;
  final double relevanceScore;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  RAGContext({
    required this.id,
    required this.type,
    required this.content,
    required this.relevanceScore,
    this.metadata,
    required this.timestamp,
  });

  factory RAGContext.fromJson(Map<String, dynamic> json) {
    return RAGContext(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'knowledge',
      content: json['content']?.toString() ?? '',
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'relevanceScore': relevanceScore,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
