import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

import 'package:mighty_fitness/utils/app_constants.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../main.dart';
import '../../utils/app_colors.dart';

import '../services/ai_service.dart';
import '../models/dashboard_response.dart';
import '../network/rest_api.dart';
import '../screens/edit_profile_screen.dart';
import '../utils/app_common.dart';
import '../components/meal_card_component.dart';
import '../components/log_meal_form_component.dart';
import '../components/ai_recommendations_component.dart';
import '../extensions/responsive_utils.dart';
import '../extensions/home_screen_responsive.dart';

bool? isFirstTimeGraph = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initState called');
    
    // Use a more robust initialization approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeScreen();
    });
  }

  Future<void> _initializeHomeScreen() async {
    try {
      // Initialize stores
      await nutritionStore.initialize();
      if (userStore.user?.userName?.isNotEmpty == true) {
        await userStore.getDashBoard();
      }
    } catch (e) {
      debugPrint('Error initializing home screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    
    return Scaffold(
      body: Observer(
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(responsive.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(responsive),
                SizedBox(height: responsive.spacing),
                _buildStatsCards(responsive),
                SizedBox(height: responsive.spacing),
                _buildMotivationSection(responsive),
                SizedBox(height: responsive.spacing),
                _buildTodaysNutritionSection(responsive),
                SizedBox(height: responsive.spacing * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(ResponsiveUtils responsive) {
    final userName = userStore.user?.userName ?? 'User';
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: EdgeInsets.all(responsive.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Welcome Avatar
          Container(
            width: responsive.iconSize * 1.8,
            height: responsive.iconSize * 1.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/welcomeAvatar.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: responsive.iconSize,
                    color: primaryColor,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: responsive.spacing),
          
          // Greeting Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: responsive.fontSize * 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.fontSize * 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Notification Icon
          IconButton(
            onPressed: () {
              // Handle notification tap
            },
            icon: Icon(
              Icons.notifications_outlined,
              size: responsive.iconSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ResponsiveUtils responsive) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            responsive,
            'Streak',
            '${nutritionStore.streakCount}',
            'Days',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        SizedBox(width: responsive.spacing),
        Expanded(
          child: _buildStatCard(
            responsive,
            'Calories',
            '${(nutritionStore.todayNutrition.calories ?? 0).toInt()}',
            'kcal',
            Icons.local_fire_department_outlined,
            Colors.red,
          ),
        ),
        SizedBox(width: responsive.spacing),
        Expanded(
          child: _buildStatCard(
            responsive,
            'Meals',
            '${nutritionStore.todayMeals.length}',
            'Today',
            Icons.restaurant,
            primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ResponsiveUtils responsive,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.padding * 0.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: responsive.iconSize * 0.8,
              color: color,
            ),
          ),
          SizedBox(height: responsive.spacing * 0.5),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: responsive.fontSize * 1.1,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: responsive.fontSize * 0.8,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: responsive.fontSize * 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationSection(ResponsiveUtils responsive) {
    final motivationalQuotes = [
      "You're doing great! Keep up the healthy habits! 💪",
      "Every meal is a chance to nourish your body! 🥗",
      "Progress, not perfection. You've got this! ⭐",
      "Your body is your temple. Treat it with respect! 🏛️",
      "Healthy choices today, healthier you tomorrow! 🌟",
    ];

    final randomQuote = motivationalQuotes[DateTime.now().day % motivationalQuotes.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.1),
            primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.padding * 0.5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_emotions,
              size: responsive.iconSize * 0.8,
              color: primaryColor,
            ),
          ),
          SizedBox(width: responsive.spacing),
          Expanded(
            child: Text(
              randomQuote,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: responsive.fontSize * 0.9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysNutritionSection(ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Nutrition",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: responsive.fontSize * 1.2,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to detailed nutrition view
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: responsive.fontSize * 0.8,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing),
        _buildNutritionGrid(responsive),
      ],
    );
  }

  Widget _buildNutritionGrid(ResponsiveUtils responsive) {
    final nutrition = nutritionStore.todayNutrition;
    final goals = nutritionStore.nutritionGoals;
    
    // Calculate progress percentages
    final caloriesProgress = goals?.calories != null && goals!.calories! > 0
        ? ((nutrition.calories ?? 0) / goals.calories!).clamp(0.0, 1.0)
        : 0.0;
    
    final proteinProgress = goals?.protein != null && goals!.protein! > 0
        ? ((nutrition.protein ?? 0) / goals.protein!).clamp(0.0, 1.0)
        : 0.0;
    
    final carbsProgress = goals?.carbs != null && goals!.carbs! > 0
        ? ((nutrition.carbs ?? 0) / goals.carbs!).clamp(0.0, 1.0)
        : 0.0;
    
    final fatProgress = goals?.fat != null && goals!.fat! > 0
        ? ((nutrition.fat ?? 0) / goals.fat!).clamp(0.0, 1.0)
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: responsive.spacing,
      crossAxisSpacing: responsive.spacing,
      childAspectRatio: 1.1,
      children: [
        _buildNutritionCard(
          responsive,
          'Calories',
          '${(nutrition.calories ?? 0).toInt()}',
          '${(goals?.calories ?? 0).toInt()}',
          'kcal',
          caloriesProgress,
          Colors.orange,
        ),
        _buildNutritionCard(
          responsive,
          'Protein',
          '${(nutrition.protein ?? 0).toInt()}',
          '${(goals?.protein ?? 0).toInt()}',
          'g',
          proteinProgress,
          Colors.blue,
        ),
        _buildNutritionCard(
          responsive,
          'Carbs',
          '${(nutrition.carbs ?? 0).toInt()}',
          '${(goals?.carbs ?? 0).toInt()}',
          'g',
          carbsProgress,
          Colors.green,
        ),
        _buildNutritionCard(
          responsive,
          'Fat',
          '${(nutrition.fat ?? 0).toInt()}',
          '${(goals?.fat ?? 0).toInt()}',
          'g',
          fatProgress,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildNutritionCard(
    ResponsiveUtils responsive,
    String title,
    String current,
    String goal,
    String unit,
    double progress,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: responsive.iconSize * 1.5,
            height: responsive.iconSize * 1.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.fontSize * 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing * 0.5),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: responsive.fontSize * 0.9,
            ),
          ),
          const SizedBox(height: 2),
          
          // Current / Goal
          Text(
            '$current / $goal $unit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: responsive.fontSize * 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
