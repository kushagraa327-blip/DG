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
import '../../extensions/colors.dart';

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

bool isFirstTimeGraph = false;

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
      debugPrint('Starting initialization...');
      
      // Initialize nutrition store first (critical for UI)
      try {
        await nutritionStore.initializeStore();
        debugPrint('Nutrition store initialized successfully');
      } catch (e) {
        debugPrint('Error initializing nutrition store: $e');
      }
      
      // Then load user details
      await getUserDetailsApiCall();
      
      // Finally load graph data
      if (isFirstTimeGraph == false) {
        await graphGet();
      }
      
      debugPrint('Home screen initialization complete');
    } catch (e) {
      debugPrint('Error during home screen initialization: $e');
      // Force UI refresh even if some initialization fails
      if (mounted) {
        setState(() {});
      }
    }
  }

  getUserDetailsApiCall() async {
    try {
      debugPrint('Starting getUserDetailsApiCall...');
      await getUSerDetail(context, userStore.userId).then((_) {
        debugPrint('User details API call successful');
        // Clear image cache for profile image
        if (userStore.profileImage.isNotEmpty && userStore.profileImage.startsWith('http')) {
          try {
            CachedNetworkImage.evictFromCache(userStore.profileImage);
          } catch (e) {
            debugPrint('Error clearing image cache: $e');
          }
        }

        // Force UI refresh
        if (mounted) {
          debugPrint('Refreshing UI after user details');
          setState(() {});
        }
      }).catchError((error) {
        debugPrint('Error in getUserDetailsApiCall: $error');
      });
    } catch (e) {
      debugPrint('Exception in getUserDetailsApiCall: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  init() async {
    double weightInPounds = userStore.weight.toDouble();
    double weightInKilograms = poundsToKilograms(weightInPounds);
    var saveWeightGraph = userStore.weightStoreGraph.replaceAll('user', '').trim();

    //visible(getStringAsync(TERMS_SERVICE).isNotEmpty)
  }

  Future<void> graphSave() async {
    appStore.setLoading(true);
    Map? req;
    double weightInPounds = userStore.weight.toDouble();
    double weightInKilograms = poundsToKilograms(weightInPounds);
    if (userStore.weightUnit == 'lbs') {
      if (userStore.weightId.isNotEmpty) {
        req = {"id": userStore.weightId, "value": '${weightInKilograms.toStringAsFixed(2)} user', "type": 'weight', "unit": 'kg', "date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
      } else {
        req = {"value": '${weightInKilograms.toStringAsFixed(2)} user', "type": 'weight', "unit": 'kg', "date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
      }
    } else {
      if (userStore.weightId.isNotEmpty) {
        req = {"id": userStore.weightId, "value": '${userStore.weight} user', "type": 'weight', "unit": 'kg', "date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
      } else {
        req = {"value": '${userStore.weight} user', "type": 'weight', "unit": 'kg', "date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
      }
    }
    await setProgressApi(req).then((value) async {
      await graphGet();
    }).catchError((e, s) {
      appStore.setLoading(false);
    });
  }

  Future<void> graphGet() async {
    getProgressApi(METRICS_WEIGHT).then((value) {
      double weightInKilograms = poundsToKilograms(userStore.weight.toDouble());

      value.data?.forEach((data) {
        if (data.value!.contains('user')) {
          userStore.setWeightId(data.id.toString());
          userStore.setWeightGraph(data.value ?? '');
        }
      });

      if (value.data!.isEmpty) {
        graphSave();
      } else {
        value.data?.forEach((data) {
          if (data.value!.contains('user')) {
            if (userStore.weightUnit == 'lbs') {
              if (userStore.weightStoreGraph.replaceAll('user', '').trim() != weightInKilograms.toStringAsFixed(2)) {
                graphSave();
              }
            } else {
              if (userStore.weightStoreGraph.replaceAll('user', '').trim() != userStore.weight) {
                graphSave();
              }
            }
                    } else {
            appStore.setLoading(false);
          }
          userStore.setWeightId(data.id.toString());
          userStore.setWeightGraph(data.value ?? '');
          isFirstTimeGraph = true;

          appStore.setLoading(false);
        });
      }
    }).catchError((e, s) {
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mHeading(String? title, {bool? isSeeAll = false, Function? onCall}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
        vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title ?? '',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(
              Feather.chevron_right,
              color: primaryColor,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            onPressed: () {
              onCall!.call();
            },
            constraints: BoxConstraints(
              minWidth: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 40,
                tablet: 44,
                desktop: 48,
              ),
              minHeight: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 40,
                tablet: 44,
                desktop: 48,
              ),
            ),
            padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
        backgroundColor: context.scaffoldBackgroundColor,
        onRefresh: () async {
          debugPrint('Refreshing home screen...');
          try {
            await nutritionStore.initializeStore();
            await getUserDetailsApiCall();
            if (isFirstTimeGraph == false) {
              await graphGet();
            }
            if (mounted) {
              setState(() {});
            }
          } catch (e) {
            debugPrint('Error during refresh: $e');
          }
          return Future.value();
        },
        child: HomeScreenResponsiveWrapper(
          enableConstraints: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: appStore.isDarkMode ? Colors.white : textPrimaryColor),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add top spacing for better visual separation
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 32)),
                
                // Profile completion warning with responsive design
                if (userStore.weight.isEmptyOrNull)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        EditProfileScreen().launch(context);
                      },
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
                        child: const Center(
                          child: Text(
                            'Enter your height, weight, gender and age to access advanced features.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Greeting Section with Avatar
                _buildGreetingSection(context),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                
                // Stats Cards Row
                _buildStatsCards(context),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                
                // Keep it up section
                _buildMotivationSection(context),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                
                // Today's Nutrition Section
                _buildTodaysNutritionSection(context),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                
                // Today's Meals Section
                _buildTodaysMealsSection(context),

                // Bottom padding for safe area
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 32)),
              ],
            ),
          ),
          ),
        ),
        ),
      ),
    );
  }

  // Helper methods for the new design
  Widget _buildGreetingSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${userStore.fName.validate().capitalizeFirstLetter()} 👋',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: appStore.isDarkMode ? Colors.white : textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          Container(
            width: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 80,
              tablet: 90,
              desktop: 100,
            ),
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 80,
              tablet: 90,
              desktop: 100,
            ),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Text(
                '😃',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      child: Observer(builder: (context) {
        // Calculate calorie goal percentage
        double calorieGoalPercentage = 0;
        if (nutritionStore.nutritionGoals != null) {
          calorieGoalPercentage = (nutritionStore.todayNutrition.totalCalories / 
              nutritionStore.nutritionGoals!.dailyCalories * 100).clamp(0, 100);
        }

        return Row(
          children: [
            // Day Streak Card
            Expanded(
              child: _buildStatCard(
                context,
                '${nutritionStore.streakCount}',
                'Day\nStreak',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
            
            // Calorie Goal Card
            Expanded(
              child: _buildStatCard(
                context,
                '${calorieGoalPercentage.toInt()}%',
                'Calorie\nGoal',
                Icons.track_changes,
                Colors.green,
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
            
            // Meals Logged Card
            Expanded(
              child: _buildStatCard(
                context,
                '${nutritionStore.todayMeals.length}',
                'Meals\nLogged',
                Icons.restaurant,
                Colors.blue,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context, mobile: 16),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5), // Adaptive card color
        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        border: Border.all(
          color: appStore.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context, 20),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: appStore.isDarkMode ? Colors.white : Colors.black87,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              color: appStore.isDarkMode ? Colors.white70 : Colors.black54,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      child: Observer(builder: (context) {
        bool isOnTrack = nutritionStore.streakCount > 0;
        
        return Container(
          padding: ResponsiveUtils.getResponsivePadding(context, mobile: 20),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: context.cardColor,
            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep it up! 🎉',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                    Text(
                      isOnTrack 
                          ? 'You\'re on track to reach your daily goals'
                          : 'Start logging meals to build your streak',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                        color: appStore.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
                        vertical: ResponsiveUtils.getResponsiveSpacing(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                          ),
                          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                          Text(
                            '${nutritionStore.streakCount} Day Streak!',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
              Container(
                width: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 100,
                  tablet: 120,
                  desktop: 140,
                ),
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 100,
                  tablet: 120,
                  desktop: 140,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                ),
                child: ClipRRect(
                  borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                  child: Image.asset(
                    'assets/welcomeAvatar.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                        ),
                        child: Icon(
                          Icons.psychology,
                          size: ResponsiveUtils.getResponsiveIconSize(context, 40),
                          color: primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTodaysNutritionSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      child: Observer(builder: (context) {
        return Container(
          padding: ResponsiveUtils.getResponsivePadding(context, mobile: 20),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: context.cardColor,
            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Nutrition',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                      color: primaryColor,
                      fontFamily: 'Inter',
                    ),
                  ).onTap(() {
                    _showAllMeals();
                  }),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
              
              // Nutrition Progress Indicators
              if (nutritionStore.nutritionGoals != null)
                _buildNutritionGrid(context)
              else
                _buildEmptyNutritionState(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNutritionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      children: [
        _buildNutritionCard(
          context,
          'Protein',
          '${nutritionStore.todayNutrition.totalProtein.toInt()}/${nutritionStore.nutritionGoals!.dailyProtein.toInt()} g',
          (nutritionStore.todayNutrition.totalProtein / nutritionStore.nutritionGoals!.dailyProtein).clamp(0.0, 1.0),
          Colors.green,
        ),
        _buildNutritionCard(
          context,
          'Calories',
          '${nutritionStore.todayNutrition.totalCalories.toInt()}/${nutritionStore.nutritionGoals!.dailyCalories.toInt()} cal',
          (nutritionStore.todayNutrition.totalCalories / nutritionStore.nutritionGoals!.dailyCalories).clamp(0.0, 1.0),
          Colors.green,
        ),
        _buildNutritionCard(
          context,
          'Carbs',
          '${nutritionStore.todayNutrition.totalCarbs.toInt()}/${nutritionStore.nutritionGoals!.dailyCarbs.toInt()} g',
          (nutritionStore.todayNutrition.totalCarbs / nutritionStore.nutritionGoals!.dailyCarbs).clamp(0.0, 1.0),
          Colors.green,
        ),
        _buildNutritionCard(
          context,
          'Fat',
          '${nutritionStore.todayNutrition.totalFat.toInt()}/${nutritionStore.nutritionGoals!.dailyFat.toInt()} g',
          (nutritionStore.todayNutrition.totalFat / nutritionStore.nutritionGoals!.dailyFat).clamp(0.0, 1.0),
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildNutritionCard(BuildContext context, String label, String value, double progress, Color color) {
    // Ensure progress is a valid number between 0 and 1
    double validProgress = progress.isNaN || progress.isInfinite ? 0.0 : progress.clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8), // Reduced bottom padding
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with label/value and circular indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Label and value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: appStore.isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                        color: appStore.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8), // Reduced spacing
              
              // Right side - Circular percentage indicator
              SizedBox(
                width: 45,
                height: 45,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: validProgress,
                      strokeWidth: 3,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '${(validProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6), // Further reduced spacing
          
          // Progress bar at the bottom - more prominent
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: validProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNutritionState(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context, mobile: 24),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: ResponsiveUtils.getResponsiveIconSize(context, 48),
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          Text(
            'Start tracking your nutrition',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          Text(
            'Log your first meal to see nutrition progress',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          ElevatedButton(
            onPressed: () => _showLogMealDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
            child: Text(
              'Log Meal',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMealsSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      child: Observer(builder: (context) {
        return Container(
          padding: ResponsiveUtils.getResponsivePadding(context, mobile: 20),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: context.cardColor,
            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Meals',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (nutritionStore.todayMeals.isNotEmpty)
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                        color: primaryColor,
                        fontFamily: 'Inter',
                      ),
                    ).onTap(() {
                      _showAllMeals();
                    }),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
              
              // Meals List
              if (nutritionStore.todayMeals.isNotEmpty)
                ...nutritionStore.todayMeals.take(3).map((meal) => 
                  Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                    child: MealCardComponent(
                      meal: meal,
                      onTap: () {
                        // TODO: Navigate to meal detail or edit
                      },
                      onDelete: () {
                        _deleteMeal(meal.id);
                      },
                    ),
                  ),
                )
              else
                _buildEmptyMealsState(context),
                
              // Show more button if there are more than 3 meals
              if (nutritionStore.todayMeals.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () => _showAllMeals(),
                    child: Text(
                      'View ${nutritionStore.todayMeals.length - 3} more meals',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyMealsState(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context, mobile: 24),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: ResponsiveUtils.getResponsiveIconSize(context, 48),
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          Text(
            'Start tracking your meals to see them here',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: Colors.grey[600],
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          ElevatedButton(
            onPressed: () => _showLogMealDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
            child: const Text(
              'Log Your First Meal',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _showLogMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: LogMealFormComponent(
          onSubmit: (meal) async {
            await nutritionStore.addMealEntry(meal);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meal logged successfully! 🍽️'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showAllMeals() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Today\'s Meals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: nutritionStore.todayMeals.length,
                itemBuilder: (context, index) {
                  final meal = nutritionStore.todayMeals[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: MealCardComponent(
                      meal: meal,
                      onDelete: () => _deleteMeal(meal.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMeal(String mealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await nutritionStore.deleteMealEntry(mealId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meal deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
