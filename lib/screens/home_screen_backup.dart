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

class _HomeScreenState extends State<HomeScreen>{

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

            /*  if(userStore.weightStoreGraph.replaceAll('user', '').trim()!=weightInKilograms.toStringAsFixed(2)){
              graphSave();
            }*/
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

  /* Future<void> deleteUserGraphs(String? id) async {
    Map req = {
      "id": id,
    };
    await deleteProgressApi(req).then((value) {
      toast(value.message);
      setState(() {});
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }*/

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
            child: ResponsiveText(
              title ?? '',
              baseFontSize: 18,
              fontWeight: FontWeight.bold,
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          ResponsiveUtils.getResponsiveValue(
            context,
            mobile: appStore.selectedLanguageCode == 'ar' ? 120 : 105,  // Increased significantly for better spacing
            tablet: appStore.selectedLanguageCode == 'ar' ? 130 : 115, // Increased for tablets
            desktop: appStore.selectedLanguageCode == 'ar' ? 140 : 125, // Increased for desktop
          ),
        ),
        child: SafeArea(
          child: Container(
            padding: context.responsiveHorizontalPadding.copyWith(
              top: ResponsiveUtils.getResponsiveSpacing(context, 24), // Increased from 16 to 24 for more space
              bottom: ResponsiveUtils.getResponsiveSpacing(context, 8), // Slightly increased bottom
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Observer(builder: (context) {
                        // Add cache busting for profile image
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final profileImageUrl = userStore.profileImage.validate();
                        final imageUrl = profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http')
                            ? (profileImageUrl.contains('?')
                                ? '$profileImageUrl&cache=$timestamp'
                                : '$profileImageUrl?cache=$timestamp')
                            : profileImageUrl;

                        final avatarSize = ResponsiveUtils.getResponsiveValue(
                          context,
                          mobile: 42.0,
                          tablet: 48.0,
                          desktop: 54.0,
                        );

                        return Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 1)
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(avatarSize / 2),
                            child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: avatarSize,
                                    height: avatarSize,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint("❌ Error loading profile image: $error");
                                      return Icon(
                                        Icons.person,
                                        size: avatarSize * 0.6,
                                        color: primaryColor.withOpacity(0.7),
                                      );
                                    },
                                    cacheKey: "$imageUrl-$timestamp",
                                  )
                                : Icon(
                                    Icons.person,
                                    size: avatarSize * 0.6,
                                    color: primaryColor.withOpacity(0.7),
                                  ),
                          ),
                        ).onTap(() {
                          EditProfileScreen().launch(context).then((result) {
                            if (result == true) {
                              // Force refresh after profile update
                              setState(() {});
                            }
                          });
                        });
                      }),
                      SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ResponsiveText(
                              "Hey ${userStore.fName.validate().capitalizeFirstLetter()} ${userStore.lName.capitalizeFirstLetter()}👋",
                              baseFontSize: 18,
                              fontWeight: FontWeight.bold,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (appStore.selectedLanguageCode != 'ar')
                              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 2)),
                            ResponsiveText(
                              "Welcome to your fitness journey!",
                              baseFontSize: 14,
                              color: Colors.grey[600],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: context.scaffoldBackgroundColor,
        onRefresh: () async {
          debugPrint('Refreshing home screen...');
          try {
            // Re-initialize nutrition store
            await nutritionStore.initializeStore();
            // Refresh user details
            await getUserDetailsApiCall();
            // Refresh graph data
            if (isFirstTimeGraph == false) {
              await graphGet();
            }
            // Force UI refresh
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add top spacing for better visual separation
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                
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

                // Bottom padding for safe area
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 32)),
              ],
            ),
          ),
        ),
      ),
    );
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

                // Basic spacing when profile is complete
                if (!userStore.weight.isEmptyOrNull) {
                  const SizedBox(height: 16)
                },

                // Nutrition Tracking Section - Simplified
                Observer(builder: (context) {
                  return Column(
                    children: [
                      // Avatar and Streak Section - Simplified
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${userStore.fName.validate().capitalizeFirstLetter()}! 👋',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryColor.withOpacity(0.1),
                                    ),
                                    child: const Icon(
                                      Icons.face,
                                      size: 32,
                                      color: primaryColor,
                                    ),
                                  ).onTap(() {
                                    debugPrint('Avatar tapped');
                                  }),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Streak Counter - Simplified
                            if (nutritionStore.streakCount > 0)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${nutritionStore.streakCount} Day${nutritionStore.streakCount != 1 ? 's' : ''} Streak!',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Today's Nutrition Progress - Simplified
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Builder(
                          builder: (context) {
                            try {
                              // Check if nutrition store is properly initialized
                              try {
                                return MealSummaryCard(
                                  dailyNutrition: nutritionStore.todayNutrition,
                                  goals: nutritionStore.nutritionGoals,
                                );
                              } catch (e) {
                                debugPrint('MealSummaryCard Error: $e');
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Nutrition tracking temporarily unavailable',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Nutrition section error: $e');
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Loading nutrition data...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Today's Meals Section - Simplified
                      Observer(builder: (context) {
                        try {
                          if (nutritionStore.todayMeals.isNotEmpty) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryColor.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.restaurant,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Today\'s Meals',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${nutritionStore.todayMeals.length} meals',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Display meals
                                  ...nutritionStore.todayMeals.take(3).map((meal) =>
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: MealCardComponent(
                                        meal: meal,
                                        onDelete: () => _deleteMeal(meal.id),
                                      ),
                                    ),
                                  ),
                                  if (nutritionStore.todayMeals.length > 3)
                                    Center(
                                      child: TextButton(
                                        onPressed: () => _showAllMeals(),
                                        child: Text(
                                          '+${nutritionStore.todayMeals.length - 3} more meals',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            );
                          } else {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.no_meals_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No meals logged today',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start tracking your nutrition by logging your first meal!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Meals section error: $e');
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Meals section temporarily unavailable',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                      }),
                    ],
                  );
                }),

                // AI Recommendations Section - Simplified
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Observer(builder: (context) {
                    try {
                      // Create user profile for AI recommendations
                      final profile = UserProfile(
                        name: userStore.fName.isNotEmpty ? userStore.fName : 'User',
                        age: int.tryParse(userStore.age.validate()) ?? 25,
                        gender: userStore.gender.isNotEmpty ? userStore.gender : 'male',
                        weight: double.tryParse(userStore.weight.validate()) ?? 70.0,
                        height: double.tryParse(userStore.height.validate()) ?? 170.0,
                        goal: userStore.goal.isNotEmpty ? userStore.goal : 'general_fitness',
                        exerciseDuration: 30,
                        diseases: [],
                        dietaryPreferences: [],
                        isSmoker: false,
                      );

                      final recommendedCalories = nutritionStore.nutritionGoals?.dailyCalories ?? 2000.0;

                      return AIRecommendationsComponent(
                        profile: profile,
                        todayCalories: nutritionStore.todayNutrition.totalCalories,
                        todayProtein: nutritionStore.todayNutrition.totalProtein,
                        todayCarbs: nutritionStore.todayNutrition.totalCarbs,
                        todayFat: nutritionStore.todayNutrition.totalFat,
                        recommendedCalories: recommendedCalories,
                      );
                    } catch (e) {
                      debugPrint('AIRecommendationsComponent Error: $e');
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'AI recommendations temporarily unavailable',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                  }),
                ),

                // Bottom padding for safe area
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    )
  }

  // Dashboard API call with enhanced error handling and fallback
  Future<DashboardResponse> _getDashboardWithFallback() async {
    try {
      debugPrint('Attempting dashboard API call...');
      final response = await getDashboardApi().timeout(
        const Duration(seconds: 8), // Reduced timeout for production
        onTimeout: () {
          debugPrint('Dashboard API timeout - will return fallback data');
          throw TimeoutException('Dashboard API timeout', const Duration(seconds: 8));
        },
      );
      debugPrint('Dashboard API successful');
      return response;
    } catch (e) {
      debugPrint('Dashboard API failed: $e - returning fallback data');
      // Return a response that indicates we should show basic content
      // but not completely empty, so the app can still function
      return DashboardResponse(
        bodypart: [],
        equipment: [],
        workout: [],
        level: [],
      );
    }
  }

  // Enhanced error handling wrapper
  Widget _safeBuilder(Widget Function() builder, {String? errorContext}) {
    try {
      return builder();
    } catch (e) {
      debugPrint('Error in ${errorContext ?? 'widget'}: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'Content temporarily unavailable',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  // Basic fallback content when API fails or returns empty data
  Widget _buildBasicContent(bool isDark, BuildContext context) {
    return HomeScreenResponsiveWrapper(
      enableConstraints: true,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),
            
            // Profile completion warning (if needed)
            ResponsiveContainer(
              padding: ResponsiveUtils.getResponsivePadding(context),
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
                vertical: ResponsiveUtils.getResponsiveSpacing(context, 8),
              ),
              backgroundColor: Colors.red.withOpacity(0.1),
              borderRadius: ResponsiveUtils.getResponsiveSpacing(context, 8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              child: GestureDetector(
                onTap: () {
                  EditProfileScreen().launch(context);
                },
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 50,
                      tablet: 60,
                      desktop: 70,
                    ),
                  ),
                  child: const Center(
                    child: ResponsiveText(
                      'Enter your height, weight, gender and age to access advanced features.',
                      baseFontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ).visible(userStore.weight.isEmptyOrNull),

            // Basic welcome content
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
              ),
              padding: ResponsiveUtils.getResponsivePadding(context, mobile: 20),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 64),
                    color: primaryColor,
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                  const ResponsiveText(
                    'Welcome to Dietary Guide!',
                    baseFontSize: 24,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                  ResponsiveText(
                    'Your personalized fitness content is loading. Please check your internet connection and try again.',
                    baseFontSize: 16,
                    color: Colors.grey[600],
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry loading
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getResponsiveSpacing(context, 16),
                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 32),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                      ),
                    ),
                    child: const ResponsiveText(
                      'Refresh',
                      baseFontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),
            
            // Basic nutrition section with better error handling
            Observer(builder: (context) {
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
                ),
                child: Builder(
                  builder: (context) {
                    try {
                      // Check if nutrition store is properly initialized
                      return MealSummaryCard(
                        dailyNutrition: nutritionStore.todayNutrition,
                        goals: nutritionStore.nutritionGoals,
                      );
                    } catch (e) {
                      debugPrint('Nutrition section error: $e');
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: boxDecorationWithRoundedCorners(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                        ),
                        child: ResponsiveText(
                          'Nutrition tracking temporarily unavailable',
                          baseFontSize: 14,
                          textAlign: TextAlign.center,
                          color: Colors.grey[600],
                        ),
                      );
                    }
                  },
                ),
              );
            }),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 40)),
          ],
        ),
      ),
    );
  }

  // Helper method for calculating recommended calories
  int getRecommendedCalories() {
    try {
      final age = int.tryParse(userStore.age.validate()) ?? 25;
      final weight = double.tryParse(userStore.weight.validate()) ?? 70.0;
      final height = double.tryParse(userStore.height.validate()) ?? 170.0;
      final gender = userStore.gender.toLowerCase();

      // Calculate BMR using Mifflin-St Jeor Equation
      double bmr;
      if (gender == 'male') {
        bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      } else {
        bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      }

      // Apply activity multiplier (assuming moderate activity)
      double tdee = bmr * 1.55;

      // Adjust based on goal
      if (userStore.goal.toLowerCase() == 'weight_loss' || userStore.goal.toLowerCase() == 'lose_weight') {
        tdee -= 500;
      } else if (userStore.goal.toLowerCase() == 'weight_gain' || userStore.goal.toLowerCase() == 'gain_weight') {
        tdee += 500;
      }

      return tdee.round();
    } catch (e) {
      return 2000; // Default fallback
    }
  }







  // Nutrition tracking helper methods
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
            setState(() {}); // Refresh the UI
          },
        ),
      ),
    );
  }

  void _showMealPlanDialog() async {
    try {
      // Create user profile for AI meal planning
      final profile = UserProfile(
        name: userStore.fName.isNotEmpty ? userStore.fName : 'User',
        age: int.tryParse(userStore.age.validate()) ?? 25,
        gender: userStore.gender.isNotEmpty ? userStore.gender : 'male',
        weight: double.tryParse(userStore.weight.validate()) ?? 70.0,
        height: double.tryParse(userStore.height.validate()) ?? 170.0,
        goal: userStore.goal.isNotEmpty ? userStore.goal : 'general_fitness',
        exerciseDuration: 30,
        diseases: [],
        dietaryPreferences: [],
        isSmoker: false,
      );

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating meal plan...'),
            ],
          ),
        ),
      );

      // Generate meal plan using AI
      final mealPlan = await generateMealPlan(profile, nutritionStore.todayMeals);

      // Close loading dialog
      Navigator.pop(context);

      // Show meal plan dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restaurant_menu, color: primaryColor),
              SizedBox(width: 8),
              Text('AI Meal Plan'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(mealPlan),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            /*
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showLogMealDialog();
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: Text('Log Meal', style: TextStyle(color: Colors.white)),
            ),
            */
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not generate meal plan. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
                  content: Text('Meal deleted'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {}); // Refresh the UI
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                  const Icon(Icons.restaurant, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  const Text('Today\'s Meals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: nutritionStore.todayMeals.length,
                itemBuilder: (context, index) {
                  final meal = nutritionStore.todayMeals[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: MealCardComponent(
                      meal: meal,
                      onDelete: () {
                        Navigator.pop(context);
                        _deleteMeal(meal.id);
                      },
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

  // Helper widget for stat items
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: color.withOpacity(0.1),
        borderRadius: radius(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // New helper methods for the updated home screen design
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
                ResponsiveText(
                  'Hello, ${userStore.fName.validate().capitalizeFirstLetter()} 👋',
                  baseFontSize: 24,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                const ResponsiveText(
                  '😃',
                  baseFontSize: 20,
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
          Container(
            width: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 60,
              tablet: 70,
              desktop: 80,
            ),
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 60,
              tablet: 70,
              desktop: 80,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/welcomeAvatar.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 32),
                    color: primaryColor,
                  );
                },
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
        color: const Color(0xFF2D2D2D), // Dark card color to match the design
        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 16),
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
          ResponsiveText(
            value,
            baseFontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
          ResponsiveText(
            label,
            baseFontSize: 12,
            color: Colors.white70,
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
        // Determine if user is on track
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
                    const ResponsiveText(
                      'Keep it up! 🎉',
                      baseFontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                    ResponsiveText(
                      isOnTrack 
                          ? 'You\'re on track to reach your daily goals'
                          : 'Start logging meals to build your streak',
                      baseFontSize: 14,
                      color: Colors.grey[600],
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
                          ResponsiveText(
                            '${nutritionStore.streakCount} Day Streak!',
                            baseFontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
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
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                ),
                child: Icon(
                  Icons.psychology,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 40),
                  color: primaryColor,
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
                  const ResponsiveText(
                    'Today\'s Nutrition',
                    baseFontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const ResponsiveText(
                    'See all',
                    baseFontSize: 14,
                    color: primaryColor,
                  ).onTap(() {
                    // Navigate to detailed nutrition view
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
      childAspectRatio: 1.1,
      mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      children: [
        _buildNutritionCircle(
          context,
          'Protein',
          '${nutritionStore.todayNutrition.totalProtein.toInt()}/${nutritionStore.nutritionGoals!.dailyProtein.toInt()} g',
          nutritionStore.proteinProgress,
          Colors.green,
        ),
        _buildNutritionCircle(
          context,
          'Calories',
          '${nutritionStore.todayNutrition.totalCalories.toInt()}/${nutritionStore.nutritionGoals!.dailyCalories.toInt()}',
          nutritionStore.calorieProgress,
          Colors.orange,
        ),
        _buildNutritionCircle(
          context,
          'Carbs',
          '${nutritionStore.todayNutrition.totalCarbs.toInt()}/${nutritionStore.nutritionGoals!.dailyCarbs.toInt()} g',
          nutritionStore.carbsProgress,
          Colors.blue,
        ),
        _buildNutritionCircle(
          context,
          'Fat',
          '${nutritionStore.todayNutrition.totalFat.toInt()}/${nutritionStore.nutritionGoals!.dailyFat.toInt()} g',
          nutritionStore.fatProgress,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildNutritionCircle(BuildContext context, String label, String value, double progress, Color color) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context, mobile: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 60,
                  tablet: 70,
                  desktop: 80,
                ),
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 60,
                  tablet: 70,
                  desktop: 80,
                ),
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              ResponsiveText(
                '${(progress * 100).toInt()}%',
                baseFontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          ResponsiveText(
            label,
            baseFontSize: 14,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
          ResponsiveText(
            value,
            baseFontSize: 12,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
            maxLines: 2,
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
          const ResponsiveText(
            'Start tracking your nutrition',
            baseFontSize: 18,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
          ResponsiveText(
            'Log your first meal to see nutrition progress',
            baseFontSize: 14,
            color: Colors.grey[600],
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
            child: const ResponsiveText(
              'Log Meal',
              baseFontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
