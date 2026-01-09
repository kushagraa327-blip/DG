import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Professional Dark Mode Color Palette - Enterprise Level
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color darkCardBg = Color(0xFF1A1A1A);
  static const Color darkCardBgAlt = Color(0xFF252525);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkText = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initState called');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeScreen();
    });
  }

  Future<void> _initializeHomeScreen() async {
    try {
      debugPrint('Starting initialization...');
      
      try {
        await nutritionStore.initializeStore();
        debugPrint('Nutrition store initialized successfully');
      } catch (e) {
        debugPrint('Error initializing nutrition store: $e');
      }
      
      await getUserDetailsApiCall();
      
      if (isFirstTimeGraph == false) {
        await graphGet();
      }
      
      debugPrint('Home screen initialization complete');
    } catch (e) {
      debugPrint('Error during home screen initialization: $e');
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
        if (userStore.profileImage.isNotEmpty && userStore.profileImage.startsWith('http')) {
          try {
            CachedNetworkImage.evictFromCache(userStore.profileImage);
          } catch (e) {
            debugPrint('Error clearing image cache: $e');
          }
        }

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

  Color _getCardBackgroundColor() {
    return appStore.isDarkMode ? darkCardBg : const Color(0xFFF5F5F5);
  }

  Color _getCardBorderColor() {
    return appStore.isDarkMode ? darkBorder : Colors.black.withOpacity(0.05);
  }

  Color _getTextColor() {
    return appStore.isDarkMode ? darkText : Colors.black87;
  }

  Color _getSecondaryTextColor() {
    return appStore.isDarkMode ? darkTextSecondary : Colors.black54;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: appStore.isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: appStore.isDarkMode ? darkBg : Colors.white,
        systemNavigationBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: appStore.isDarkMode ? darkBg : Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          backgroundColor: appStore.isDarkMode ? darkCardBg : context.scaffoldBackgroundColor,
          color: primaryColor,
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
                style: TextStyle(color: _getTextColor()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 32)),
                    
                    if (userStore.weight.isEmptyOrNull)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(appStore.isDarkMode ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(appStore.isDarkMode ? 0.4 : 0.3),
                          ),
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
                                  color: Color(0xFFDC2626),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),

                    _buildGreetingSection(context),
                    
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                    
                    _buildStatsCards(context),
                    
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                    
                    _buildMotivationSection(context),
                    
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                    
                    _buildTodaysNutritionSection(context),

                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                    
                    _buildTodaysMealsSection(context),

                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 32)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ), // AnnotatedRegion
    );
  }

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
                    color: _getTextColor(),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appStore.isDarkMode ? darkCardBgAlt : Colors.grey[100],
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
        double calorieGoalPercentage = 0;
        if (nutritionStore.nutritionGoals != null) {
          calorieGoalPercentage = (nutritionStore.todayNutrition.totalCalories / 
              nutritionStore.nutritionGoals!.dailyCalories * 100).clamp(0, 100);
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '${nutritionStore.streakCount}',
                'Day\nStreak',
                Icons.local_fire_department,
                const Color(0xFFF97316),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
            
            Expanded(
              child: _buildStatCard(
                context,
                '${calorieGoalPercentage.toInt()}%',
                'Calorie\nGoal',
                Icons.track_changes,
                const Color(0xFF22C55E),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
            
            Expanded(
              child: _buildStatCard(
                context,
                '${nutritionStore.todayMeals.length}',
                'Meals\nLogged',
                Icons.restaurant,
                const Color(0xFF3B82F6),
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
        color: appStore.isDarkMode 
            ? color.withOpacity(0.1) 
            : color.withOpacity(0.08),
        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        border: Border.all(
          color: appStore.isDarkMode 
              ? color.withOpacity(0.25) 
              : color.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 6)),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              color: _getSecondaryTextColor(),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
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
          decoration: BoxDecoration(
            color: _getCardBackgroundColor(),
            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            border: Border.all(color: _getCardBorderColor(), width: 1),
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
                        color: _getTextColor(),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                    Text(
                      isOnTrack 
                          ? 'You\'re on track to reach your daily goals'
                          : 'Start logging meals to build your streak',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                        color: _getSecondaryTextColor(),
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
                        vertical: ResponsiveUtils.getResponsiveSpacing(context, 8),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(appStore.isDarkMode ? 0.15 : 0.1),
                        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF22C55E),
                            size: 16,
                          ),
                          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 6)),
                          Text(
                            '${nutritionStore.streakCount} Day Streak!',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF22C55E),
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
                  color: appStore.isDarkMode ? darkCardBgAlt : Colors.grey[100],
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
          decoration: BoxDecoration(
            color: _getCardBackgroundColor(),
            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            border: Border.all(color: _getCardBorderColor(), width: 1),
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
                      color: _getTextColor(),
                    ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                      color: primaryColor,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ).onTap(() {
                    _showAllMeals();
                  }),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
              
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
      childAspectRatio: 1.45,
      mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      children: [
        _buildNutritionCard(
          context,
          'Protein',
          '${nutritionStore.todayNutrition.totalProtein.toInt()}/${nutritionStore.nutritionGoals!.dailyProtein.toInt()} g',
          (nutritionStore.todayNutrition.totalProtein / nutritionStore.nutritionGoals!.dailyProtein).clamp(0.0, 1.0),
          const Color(0xFF06B6D4),
        ),
        _buildNutritionCard(
          context,
          'Calories',
          '${nutritionStore.todayNutrition.totalCalories.toInt()}/${nutritionStore.nutritionGoals!.dailyCalories.toInt()} cal',
          (nutritionStore.todayNutrition.totalCalories / nutritionStore.nutritionGoals!.dailyCalories).clamp(0.0, 1.0),
          const Color(0xFFEF4444),
        ),
        _buildNutritionCard(
          context,
          'Carbs',
          '${nutritionStore.todayNutrition.totalCarbs.toInt()}/${nutritionStore.nutritionGoals!.dailyCarbs.toInt()} g',
          (nutritionStore.todayNutrition.totalCarbs / nutritionStore.nutritionGoals!.dailyCarbs).clamp(0.0, 1.0),
          const Color(0xFFFCD34D),
        ),
        _buildNutritionCard(
          context,
          'Fat',
          '${nutritionStore.todayNutrition.totalFat.toInt()}/${nutritionStore.nutritionGoals!.dailyFat.toInt()} g',
          (nutritionStore.todayNutrition.totalFat / nutritionStore.nutritionGoals!.dailyFat).clamp(0.0, 1.0),
          const Color(0xFFA855F7),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(BuildContext context, String label, String value, double progress, Color color) {
    double validProgress = progress.isNaN || progress.isInfinite ? 0.0 : progress.clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appStore.isDarkMode 
            ? color.withOpacity(0.12) 
            : color.withOpacity(0.08),
        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        border: Border.all(
          color: appStore.isDarkMode 
              ? color.withOpacity(0.28) 
              : color.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 13),
                        fontWeight: FontWeight.w700,
                        color: _getTextColor(),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                        color: _getSecondaryTextColor(),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: validProgress,
                      strokeWidth: 2.5,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '${(validProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 9),
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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: validProgress,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
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
            color: _getSecondaryTextColor(),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          Text(
            'Start tracking your nutrition',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          Text(
            'Log your first meal to see nutrition progress',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: _getSecondaryTextColor(),
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
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 24),
                vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
              ),
            ),
            child: Text(
              'Log Meal',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
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
          decoration: BoxDecoration(
            color: _getCardBackgroundColor(),
            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            border: Border.all(color: _getCardBorderColor(), width: 1),
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
                      color: _getTextColor(),
                    ),
                  ),
                  if (nutritionStore.todayMeals.isNotEmpty)
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                        color: primaryColor,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ).onTap(() {
                      _showAllMeals();
                    }),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
              
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
                
              if (nutritionStore.todayMeals.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () => _showAllMeals(),
                    child: Text(
                      'View ${nutritionStore.todayMeals.length - 3} more meals',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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
            color: _getSecondaryTextColor(),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: _getTextColor(),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          Text(
            'Start tracking your meals to see them here',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: _getSecondaryTextColor(),
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
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 24),
                vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
              ),
            ),
            child: Text(
              'Log Your First Meal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: appStore.isDarkMode ? darkBg : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: LogMealFormComponent(
          onSubmit: (meal) async {
            await nutritionStore.addMealEntry(meal);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Meal logged successfully! 🍽️'),
                backgroundColor: const Color(0xFF22C55E),
                behavior: SnackBarBehavior.floating,
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: appStore.isDarkMode ? darkBg : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _getCardBorderColor(),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Today\'s Meals',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: _getTextColor(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: nutritionStore.todayMeals.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemBuilder: (context, index) {
                  final meal = nutritionStore.todayMeals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
        backgroundColor: _getCardBackgroundColor(),
        title: Text(
          'Delete Meal',
          style: TextStyle(
            color: _getTextColor(),
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this meal?',
          style: TextStyle(
            color: _getSecondaryTextColor(),
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _getSecondaryTextColor(),
                fontFamily: 'Inter',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await nutritionStore.deleteMealEntry(mealId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Meal deleted successfully'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}