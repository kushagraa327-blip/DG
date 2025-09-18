import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/decorations.dart';
import '../main.dart';
import '../models/meal_entry_model.dart';
import '../services/ai_service.dart';
import '../utils/app_colors.dart';

class AIRecommendationsComponent extends StatefulWidget {
  final UserProfile profile;
  final double todayCalories;
  final double todayProtein;
  final double todayCarbs;
  final double todayFat;
  final double recommendedCalories;

  const AIRecommendationsComponent({
    super.key,
    required this.profile,
    required this.todayCalories,
    required this.todayProtein,
    required this.todayCarbs,
    required this.todayFat,
    required this.recommendedCalories,
  });

  @override
  _AIRecommendationsComponentState createState() => _AIRecommendationsComponentState();
}

class _AIRecommendationsComponentState extends State<AIRecommendationsComponent> {
  String? healthInsights;
  String? mealSuggestion;
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Load all AI recommendations concurrently
      final futures = await Future.wait([
        getHealthInsights(widget.profile),
        _getMealSuggestion(),
      ]);

      if (mounted) {
        setState(() {
          healthInsights = futures[0];
          mealSuggestion = futures[1];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading AI recommendations: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
          // Fallback content
          healthInsights = _getFallbackHealthInsights();
          mealSuggestion = _getFallbackMealSuggestion();
        });
      }
    }
  }

  Future<String> _getMealSuggestion() async {
    final caloriesRemaining = widget.recommendedCalories - widget.todayCalories;
    final proteinNeeded = (widget.recommendedCalories * 0.25 / 4) - widget.todayProtein;
    
    final messages = [
      CoreMessage(
        role: 'system',
        content: '''You are a nutrition expert. Provide a specific meal suggestion based on the user's current intake and remaining nutritional needs. Be concise and practical.'''
      ),
      CoreMessage(
        role: 'user',
        content: '''User profile:
        - Goal: ${widget.profile.goal}
        - Today's intake: ${widget.todayCalories.toInt()} calories, ${widget.todayProtein.toInt()}g protein
        - Recommended daily: ${widget.recommendedCalories.toInt()} calories
        - Remaining: ${caloriesRemaining.toInt()} calories, ${proteinNeeded.toInt()}g protein
        
        Suggest a specific meal or snack to help reach their goals. Keep it under 50 words.'''
      )
    ];

    return await chatWithAI(messages);
  }

  String _getFallbackHealthInsights() {
    final calorieProgress = (widget.todayCalories / widget.recommendedCalories * 100).toInt();
    
    if (calorieProgress < 70) {
      return "You're below your calorie target today. Consider adding a nutritious snack or meal to fuel your body properly! 🍎";
    } else if (calorieProgress > 120) {
      return "You've exceeded your calorie goal today. Focus on lighter, nutrient-dense foods for the rest of the day. 🥗";
    } else {
      return "Great job staying on track with your nutrition today! Keep up the balanced approach to eating. 💪";
    }
  }

  String _getFallbackMealSuggestion() {
    final caloriesRemaining = widget.recommendedCalories - widget.todayCalories;
    
    if (caloriesRemaining > 300) {
      return "Try a balanced meal with lean protein, whole grains, and vegetables to reach your calorie goal! 🍽️";
    } else if (caloriesRemaining > 100) {
      return "A protein-rich snack like Greek yogurt with berries would be perfect right now! 🥛";
    } else {
      return "You're close to your calorie goal! Stay hydrated and listen to your body's hunger cues. 💧";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/2-removebg-preview.png',
                    color: Colors.white,
                    width: 30,
                    height: 30,
                  ),
                ),
                16.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Nutrition Insights',
                        style: boldTextStyle(size: 18, color: primaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      4.height,
                      Text(
                        'Personalized recommendations for you',
                        style: secondaryTextStyle(size: 12, color: primaryColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _loadRecommendations,
                      icon: const Icon(Icons.refresh_rounded, color: primaryColor, size: 22),
                      tooltip: 'Refresh recommendations',
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  _buildLoadingCard(),
                ] else ...[
                  // Health Insights
                  if (healthInsights != null) ...[
                    _buildInsightCard(
                      'Health Insights',
                      healthInsights!,
                      Icons.health_and_safety_outlined,
                      Colors.green,
                    ),
                    16.height,
                  ],

                  // Meal Suggestion
                  if (mealSuggestion != null) ...[
                    _buildInsightCard(
                      'Meal Suggestion',
                      mealSuggestion!,
                      Icons.restaurant_menu_outlined,
                      Colors.orange,
                    ),
                  ],

                  if (hasError) ...[
                    20.height,
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          ),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline Mode',
                                  style: boldTextStyle(size: 14, color: Colors.orange),
                                ),
                                4.height,
                                Text(
                                  'AI recommendations are using offline mode. Connect to internet for personalized insights.',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generating insights...',
                  style: boldTextStyle(size: 14, color: primaryColor),
                ),
                4.height,
                Text(
                  'Please wait while we analyze your nutrition data',
                  style: secondaryTextStyle(size: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String content, IconData icon, Color color) {
    // Clean and format the content
    final cleanContent = _cleanAIResponse(content);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              12.width,
              Expanded(
                child: Text(
                  title,
                  style: boldTextStyle(size: 15, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Add expand button for long content with proper constraints
              if (cleanContent.length > 150)
                Container(
                  constraints: const BoxConstraints(maxWidth: 70),
                  margin: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _showFullContent(title, cleanContent, icon, color),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'More',
                            style: primaryTextStyle(size: 10, color: color),
                          ),
                          2.width,
                          Icon(
                            Icons.expand_more,
                            size: 12,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          12.height,
          SizedBox(
            width: double.infinity,
            child: SelectableText(
              cleanContent,
              style: primaryTextStyle(size: 13).copyWith(height: 1.4),
              maxLines: cleanContent.length > 150 ? 4 : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Clean AI response text for better display
  String _cleanAIResponse(String content) {
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

    // Remove common AI prefixes
    result = result.replaceAll(RegExp(r"Here's[^:]*:\s*"), '');
    result = result.replaceAll(RegExp(r"Here are[^:]*:\s*"), '');
    result = result.replaceAll(RegExp(r"Based on[^:]*:\s*"), '');
    result = result.replaceAll(RegExp(r'As an AI[^,]*,\s*'), '');

    return result.trim();
  }

  /// Show full content in a dialog
  void _showFullContent(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color, size: 20),
              8.width,
              Text(title, style: boldTextStyle(size: 16, color: color)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: primaryTextStyle(size: 14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: primaryTextStyle(color: color)),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content copied to clipboard')),
                );
              },
              child: Text('Copy', style: primaryTextStyle(color: color)),
            ),
          ],
        );
      },
    );
  }
}

class QuickNutritionStats extends StatelessWidget {
  final double todayCalories;
  final double recommendedCalories;
  final double todayProtein;
  final double todayCarbs;
  final double todayFat;

  const QuickNutritionStats({
    super.key,
    required this.todayCalories,
    required this.recommendedCalories,
    required this.todayProtein,
    required this.todayCarbs,
    required this.todayFat,
  });

  @override
  Widget build(BuildContext context) {
    final calorieProgress = (todayCalories / recommendedCalories * 100).clamp(0, 100);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: primaryColor, size: 20),
              8.width,
              Text('Nutrition Overview', style: boldTextStyle(size: 16)),
            ],
          ),
          
          16.height,
          
          // Calorie Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calories', style: boldTextStyle(size: 14)),
                  Text(
                    '${todayCalories.toInt()}/${recommendedCalories.toInt()} (${calorieProgress.toInt()}%)',
                    style: secondaryTextStyle(size: 12),
                  ),
                ],
              ),
              8.height,
              Container(
                height: 8,
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (calorieProgress / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: _getProgressColor(calorieProgress.toDouble()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          16.height,
          
          // Macros Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem('Protein', '${todayProtein.toInt()}g', Colors.blue),
              _buildMacroItem('Carbs', '${todayCarbs.toInt()}g', Colors.orange),
              _buildMacroItem('Fat', '${todayFat.toInt()}g', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: boldTextStyle(size: 16, color: color),
        ),
        4.height,
        Text(
          label,
          style: secondaryTextStyle(size: 12),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 70) return Colors.red;
    if (progress > 110) return Colors.orange;
    return primaryColor;
  }
}
