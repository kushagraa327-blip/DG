import 'dart:convert';
import 'dart:developer';
import '../extensions/shared_pref.dart';
import '../models/ira_conversation_model.dart';
import '../utils/app_constants.dart';

/// Knowledge base entry for fitness and nutrition information
class KnowledgeEntry {
  final String id;
  final String title;
  final String content;
  final List<String> keywords;
  final String category; // fitness, nutrition, health, motivation, etc.
  final double priority; // Higher priority entries are preferred
  final Map<String, dynamic>? metadata;

  KnowledgeEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.keywords,
    required this.category,
    this.priority = 1.0,
    this.metadata,
  });

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) {
    return KnowledgeEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category']?.toString() ?? 'general',
      priority: (json['priority'] as num?)?.toDouble() ?? 1.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'keywords': keywords,
      'category': category,
      'priority': priority,
      'metadata': metadata,
    };
  }
}

/// IRA Knowledge Base Service for fitness and nutrition information
class IRAKnowledgeBase {
  static final IRAKnowledgeBase _instance = IRAKnowledgeBase._internal();
  factory IRAKnowledgeBase() => _instance;
  IRAKnowledgeBase._internal();

  List<KnowledgeEntry> _knowledgeBase = [];
  bool _isInitialized = false;

  /// Initialize the knowledge base with default fitness and nutrition data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadKnowledgeBase();
    
    // If no knowledge base exists, create default one
    if (_knowledgeBase.isEmpty) {
      await _createDefaultKnowledgeBase();
    }
    
    _isInitialized = true;
    log('🧠 IRA Knowledge Base initialized with ${_knowledgeBase.length} entries');
  }

  /// Search knowledge base for relevant information
  List<RAGContext> searchKnowledge(String query, {int maxResults = 5}) {
    final results = <RAGContext>[];
    final queryLower = query.toLowerCase();
    final queryWords = queryLower.split(' ');

    for (final entry in _knowledgeBase) {
      double relevanceScore = 0.0;
      
      // Check title match (higher weight)
      if (entry.title.toLowerCase().contains(queryLower)) {
        relevanceScore += 2.0;
      }
      
      // Check keyword matches (high weight)
      for (final keyword in entry.keywords) {
        if (queryWords.any((word) => keyword.toLowerCase().contains(word))) {
          relevanceScore += 1.5;
        }
      }
      
      // Check content match (lower weight)
      for (final word in queryWords) {
        if (entry.content.toLowerCase().contains(word)) {
          relevanceScore += 0.5;
        }
      }
      
      // Apply priority multiplier
      relevanceScore *= entry.priority;
      
      if (relevanceScore > 0) {
        results.add(RAGContext(
          id: entry.id,
          type: 'knowledge',
          content: entry.content,
          relevanceScore: relevanceScore,
          metadata: {
            'title': entry.title,
            'category': entry.category,
            'keywords': entry.keywords,
            ...?entry.metadata,
          },
          timestamp: DateTime.now(),
        ));
      }
    }

    // Sort by relevance score and return top results
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(maxResults).toList();
  }

  /// Get knowledge entries by category
  List<KnowledgeEntry> getByCategory(String category) {
    return _knowledgeBase.where((entry) => entry.category == category).toList();
  }

  /// Add new knowledge entry
  Future<void> addKnowledgeEntry(KnowledgeEntry entry) async {
    _knowledgeBase.add(entry);
    await _saveKnowledgeBase();
    log('📚 Added knowledge entry: ${entry.title}');
  }

  /// Load knowledge base from storage
  Future<void> _loadKnowledgeBase() async {
    try {
      final knowledgeJson = getStringAsync(IRA_KNOWLEDGE_BASE_KEY);
      if (knowledgeJson.isNotEmpty) {
        final knowledgeData = jsonDecode(knowledgeJson) as List<dynamic>;
        _knowledgeBase = knowledgeData
            .map((entry) => KnowledgeEntry.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      log('Error loading knowledge base: $e');
      _knowledgeBase = [];
    }
  }

  /// Save knowledge base to storage
  Future<void> _saveKnowledgeBase() async {
    try {
      final knowledgeData = _knowledgeBase.map((entry) => entry.toJson()).toList();
      await setValue(IRA_KNOWLEDGE_BASE_KEY, jsonEncode(knowledgeData));
    } catch (e) {
      log('Error saving knowledge base: $e');
    }
  }

  /// Create default knowledge base with fitness and nutrition information
  Future<void> _createDefaultKnowledgeBase() async {
    final defaultEntries = [
      // Weight Loss Knowledge
      KnowledgeEntry(
        id: 'weight_loss_basics',
        title: 'Weight Loss Fundamentals',
        content: 'Weight loss occurs when you create a caloric deficit - burning more calories than you consume. A safe rate is 1-2 pounds per week. Focus on sustainable habits: balanced nutrition, regular exercise, adequate sleep, and stress management.',
        keywords: ['weight loss', 'caloric deficit', 'fat loss', 'lose weight', 'diet'],
        category: 'weight_loss',
        priority: 2.0,
      ),
      
      KnowledgeEntry(
        id: 'cardio_for_weight_loss',
        title: 'Cardio for Weight Loss',
        content: 'Cardiovascular exercise burns calories and improves heart health. Aim for 150-300 minutes of moderate cardio or 75-150 minutes of vigorous cardio weekly. Mix steady-state cardio with HIIT for best results.',
        keywords: ['cardio', 'cardiovascular', 'running', 'cycling', 'HIIT', 'aerobic'],
        category: 'weight_loss',
        priority: 1.8,
      ),

      // Weight Gain Knowledge
      KnowledgeEntry(
        id: 'weight_gain_basics',
        title: 'Healthy Weight Gain',
        content: 'Healthy weight gain requires a caloric surplus of 300-500 calories daily. Focus on nutrient-dense foods: lean proteins, complex carbs, healthy fats. Combine with strength training to build muscle mass.',
        keywords: ['weight gain', 'muscle gain', 'caloric surplus', 'bulk', 'mass'],
        category: 'weight_gain',
        priority: 2.0,
      ),

      // Muscle Building
      KnowledgeEntry(
        id: 'muscle_building_basics',
        title: 'Muscle Building Fundamentals',
        content: 'Build muscle through progressive overload, adequate protein (0.8-1g per lb bodyweight), and proper recovery. Focus on compound movements: squats, deadlifts, bench press, rows. Train each muscle group 2-3x weekly.',
        keywords: ['muscle building', 'strength training', 'progressive overload', 'protein', 'compound exercises'],
        category: 'muscle_gain',
        priority: 2.0,
      ),

      // Nutrition Knowledge
      KnowledgeEntry(
        id: 'protein_importance',
        title: 'Protein for Fitness Goals',
        content: 'Protein is essential for muscle repair and growth. Aim for 0.8-1.2g per lb bodyweight. Good sources: lean meats, fish, eggs, dairy, legumes, protein powder. Distribute intake throughout the day.',
        keywords: ['protein', 'amino acids', 'muscle recovery', 'protein powder', 'lean meat'],
        category: 'nutrition',
        priority: 1.9,
      ),

      KnowledgeEntry(
        id: 'hydration_importance',
        title: 'Hydration for Performance',
        content: 'Proper hydration is crucial for performance and recovery. Aim for 8-10 glasses daily, more during exercise. Water regulates body temperature, transports nutrients, and removes waste products.',
        keywords: ['hydration', 'water', 'electrolytes', 'performance', 'recovery'],
        category: 'nutrition',
        priority: 1.7,
      ),

      // Exercise Knowledge
      KnowledgeEntry(
        id: 'workout_frequency',
        title: 'Optimal Workout Frequency',
        content: 'For beginners: 3-4 workouts weekly. Intermediate: 4-5 workouts. Advanced: 5-6 workouts. Always include rest days for recovery. Listen to your body and adjust intensity accordingly.',
        keywords: ['workout frequency', 'training schedule', 'rest days', 'recovery', 'exercise routine'],
        category: 'fitness',
        priority: 1.8,
      ),

      // Health & Wellness
      KnowledgeEntry(
        id: 'sleep_importance',
        title: 'Sleep for Fitness',
        content: 'Quality sleep (7-9 hours) is crucial for recovery, hormone regulation, and performance. Poor sleep affects metabolism, increases hunger hormones, and impairs muscle recovery.',
        keywords: ['sleep', 'recovery', 'rest', 'hormone regulation', 'metabolism'],
        category: 'health',
        priority: 1.8,
      ),

      KnowledgeEntry(
        id: 'stress_management',
        title: 'Stress and Fitness',
        content: 'Chronic stress elevates cortisol, which can hinder fat loss and muscle gain. Manage stress through exercise, meditation, adequate sleep, and relaxation techniques.',
        keywords: ['stress', 'cortisol', 'meditation', 'relaxation', 'mental health'],
        category: 'health',
        priority: 1.6,
      ),

      // Motivation & Mindset
      KnowledgeEntry(
        id: 'consistency_importance',
        title: 'Consistency Over Perfection',
        content: 'Consistency beats perfection. Small, sustainable changes compound over time. Focus on building habits rather than seeking quick fixes. Progress isn\'t always linear - trust the process.',
        keywords: ['consistency', 'habits', 'motivation', 'progress', 'mindset'],
        category: 'motivation',
        priority: 1.9,
      ),
    ];

    _knowledgeBase.addAll(defaultEntries);
    await _saveKnowledgeBase();
    log('📚 Created default knowledge base with ${defaultEntries.length} entries');
  }

  /// Get all available categories
  List<String> getCategories() {
    return _knowledgeBase.map((entry) => entry.category).toSet().toList();
  }

  /// Get knowledge base statistics
  Map<String, dynamic> getStats() {
    final categories = getCategories();
    final categoryStats = <String, int>{};
    
    for (final category in categories) {
      categoryStats[category] = _knowledgeBase.where((entry) => entry.category == category).length;
    }
    
    return {
      'totalEntries': _knowledgeBase.length,
      'categories': categoryStats,
      'isInitialized': _isInitialized,
    };
  }
}
