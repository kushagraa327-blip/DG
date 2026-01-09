import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../components/calories_card.dart';
import '../components/metabolic_rate_card.dart';
import '../extensions/extension_util/list_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/LiveStream.dart';
import '../extensions/shared_pref.dart';
import '../main.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../extensions/decorations.dart';
import '../extensions/text_styles.dart';
import '../extensions/responsive_utils.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../services/ai_service.dart' as ai_service;

class ProgressScreen extends StatefulWidget {
  static String tag = '/ProgressScreen';

  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  int _calculateBMR() {
    final age = int.tryParse(userStore.age) ?? 25;
    final gender = userStore.gender.toLowerCase();
    double weight = double.tryParse(userStore.weight) ?? 70.0;
    double height = double.tryParse(userStore.height) ?? 170.0;
    if (userStore.weightUnit == 'lbs') {
      weight = weight * 0.45359237;
    }
    if (userStore.heightUnit == 'feet') {
      height = height * 30.48;
    }
    if (gender == 'female') {
      return (10 * weight + 6.25 * height - 5 * age - 161).round();
    } else {
      return (10 * weight + 6.25 * height - 5 * age + 5).round();
    }
  }
  bool? isWeight, isHeartRate, isPush;
  String? healthInsights;
  bool isLoadingInsights = false;

  @override
  void initState() {
    super.initState();
    init();
    LiveStream().emit(IdealWeight);
    getDoubleAsync(IdealWeight);
    loadHealthInsights();

    LiveStream().on(PROGRESS_SETTING, (p0) {
      userStore.mProgressList.forEachIndexed((element, index) {
        if (element.id == 1) {
          isWeight = element.isEnable;
        }
        if (element.id == 2) {
          isHeartRate = element.isEnable;
        }
        if (element.id == 3) {
          isPush = element.isEnable;
        }
        setState(() {});
      });
    });
  }

  init() async {
    userStore.mProgressList.forEachIndexed((element, index) {
      if (element.id == 1) {
        isWeight = element.isEnable;
        if (element.isEnable == true) {
          getProgressApi(METRICS_WEIGHT);
        }
      }
      if (element.id == 2) {
        isHeartRate = element.isEnable;
        if (element.isEnable == true) {
          getProgressApi(METRICS_HEART_RATE);
        }
      }
      if (element.id == 3) {
        isPush = element.isEnable;
        if (element.isEnable == true) {
          getProgressApi(PUSH_UP_MIN_UNIT);
        }
      }
    });
    setState(() {});
  }

  loadHealthInsights() async {
    if (userStore.fName.isEmpty) return;

    try {
      setState(() {
        isLoadingInsights = true;
      });

      // Create a UserProfile from userStore data
      final profile = ai_service.UserProfile(
        name: '${userStore.fName} ${userStore.lName}'.trim(),
        age: int.tryParse(userStore.age) ?? 25,
        gender: userStore.gender.isNotEmpty ? userStore.gender : 'male',
        height: double.tryParse(userStore.height) ?? 170.0,
        weight: double.tryParse(userStore.weight) ?? 70.0,
        goal: userStore.goal.isNotEmpty ? userStore.goal : 'maintain_healthy_lifestyle',
        exerciseDuration: 30, // Default 30 minutes
      );

      final insights = await ai_service.getHealthInsights(profile);
      setState(() {
        healthInsights = insights;
        isLoadingInsights = false;
      });
    } catch (error) {
      print('Error loading health insights: $error');
      setState(() {
        healthInsights = 'Unable to load health insights at this time.';
        isLoadingInsights = false;
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // Helper methods for nutrition calculations
  int getTotalCaloriesConsumed() {
    try {
      return nutritionStore.todayNutrition.totalCalories.toInt();
    } catch (e) {
      print('Error getting total calories consumed: $e');
      return 0;
    }
  }

  int getCalorieGoal() {
    try {
      if (nutritionStore.nutritionGoals != null) {
        return nutritionStore.nutritionGoals!.dailyCalories.toInt();
      }

      // Default calorie goals based on profile
      final baseCalories = userStore.gender == 'female' ? 1800 : 2200;

      if (userStore.goal == 'weight_loss') {
        return baseCalories - 300;
      } else if (userStore.goal == 'weight_gain') {
        return baseCalories + 300;
      }

      return baseCalories;
    } catch (e) {
      print('Error getting calorie goal: $e');
      return 2000; // Default fallback
    }
  }

  int getCompletedMealsCount() {
    try {
      return nutritionStore.todayMeals.length;
    } catch (e) {
      print('Error getting completed meals count: $e');
      return 0;
    }
  }

  int getPlannedMealsCount() {
    // This would come from meal plans if implemented
    return 3; // Default planned meals per day
  }

  double calculateBMI() {
    try {
      if (userStore.height.isNotEmpty && userStore.weight.isNotEmpty &&
          userStore.heightUnit.isNotEmpty && userStore.weightUnit.isNotEmpty) {

        final heightValue = double.tryParse(userStore.height) ?? 0;
        final weightValue = double.tryParse(userStore.weight) ?? 0;

        if (heightValue > 0 && weightValue > 0) {
          // Convert weight to kg if needed
          double weightInKg;
          if (userStore.weightUnit == LBS) {
            weightInKg = weightValue * 0.45359237; // Convert lbs to kg
          } else {
            weightInKg = weightValue; // Already in kg
          }

          // Convert height to cm if needed
          double heightInCm;
          if (userStore.heightUnit == FEET) {
            heightInCm = heightValue * 30.48; // Convert feet to cm
          } else {
            heightInCm = heightValue; // Already in cm
          }

          // Calculate BMI: weight(kg) / (height(m))^2
          double heightInM = heightInCm / 100;
          return weightInKg / (heightInM * heightInM);
        }
      }
      return 0.0;
    } catch (e) {
      print('Error calculating BMI: $e');
      return 0.0;
    }
  }

  String getHealthStatus() {
    final bmi = calculateBMI();
    if (bmi == 0) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget mHeading(String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(value!, style: boldTextStyle()),
        8.width,
        const Icon(Icons.keyboard_arrow_right, color: primaryColor),
      ],
    ).paddingSymmetric(horizontal: 16, vertical: 8);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      // Check if user profile is loaded
      if (userStore.fName.isEmpty) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 80.0,
                tablet: 90.0,
                desktop: 100.0,
              ),
            ),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  top: ResponsiveUtils.getResponsiveSpacing(context, 8),
                  bottom: ResponsiveUtils.getResponsiveSpacing(context, 8),
                  left: ResponsiveUtils.getResponsiveSpacing(context, 16),
                  right: ResponsiveUtils.getResponsiveSpacing(context, 16),
                ),
                color: appStore.isDarkMode ? scaffoldColorDark : Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'Hello, ${userStore.fName}!',
                          style: boldTextStyle(size: 20, color: appStore.isDarkMode ? Colors.white : Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withOpacity(0.1),
                          ),
                          child: const Center(
                            child: Text(
                              '😊',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: primaryColor),
                16.height,
                Text('Loading profile data...', style: secondaryTextStyle()),
              ],
            ),
          ),
        );
      }

      final bmi = calculateBMI();
      final healthStatus = getHealthStatus();
      final caloriesConsumed = getTotalCaloriesConsumed();
      final calorieGoal = getCalorieGoal();

      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 80.0,
              tablet: 90.0,
              desktop: 100.0,
            ),
          ),
          child: SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveSpacing(context, 8),
                bottom: ResponsiveUtils.getResponsiveSpacing(context, 8),
                left: ResponsiveUtils.getResponsiveSpacing(context, 16),
                right: ResponsiveUtils.getResponsiveSpacing(context, 16),
              ),
              color: appStore.isDarkMode ? scaffoldColorDark : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar and greeting
                  Row(
                    children: [
                      Text(
                        'Hello, ${userStore.fName}!',
                        style: boldTextStyle(size: 20, color: appStore.isDarkMode ? Colors.white : Colors.black),
                      ),
                    ],
                  ),
                  // Emoji on the right
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: Image.asset(
                          'assets/Smile_emoji.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_emotions, size: 40, color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),

              // Health Insights Card - moved to top
              _buildHealthInsightsCard(context),

              16.height,

              // Responsive Calories and Metabolic Rate Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CaloriesCard(
                        caloriesConsumed: caloriesConsumed,
                        calorieGoal: calorieGoal,
                        percent: calorieGoal > 0 ? caloriesConsumed / calorieGoal : 0.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MetabolicRateCard(
                        bmr: _calculateBMR(),
                      ),
                    ),
                  ],
                ),
              ),
              16.height,

              // Health Stats Card
              _buildHealthStatsCard(context, bmi, healthStatus),

              16.height,

              // Your Health Profile Card
              _buildHealthProfileCard(context),
              
              // Add some bottom padding
              32.height,
            ],
          ),
        ),
      );
    });
  }

  // Build Health Stats Card
  Widget _buildHealthStatsCard(BuildContext context, double bmi, String healthStatus) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: appStore.isDarkMode
          ? boxDecorationWithRoundedCorners(borderRadius: radius(16), backgroundColor: context.cardColor)
          : boxDecorationRoundedWithShadow(16, backgroundColor: context.cardColor),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety,
                color: primaryColor,
                size: 24,
              ),
              12.width,
              Expanded(
                child: Text(
                  'Health Overview',
                  style: boldTextStyle(size: 18),
                ),
              ),
            ],
          ),
          16.height,
          Row(
            children: [
              Expanded(
                child: _buildHealthStatItem(
                  bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                  'BMI',
                  primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              Expanded(
                child: _buildHealthStatItem(
                  healthStatus.isNotEmpty ? healthStatus : 'Unknown',
                  'Status',
                  _getHealthStatusColor(healthStatus),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Health Insights Card
  Widget _buildHealthInsightsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: appStore.isDarkMode
          ? boxDecorationWithRoundedCorners(borderRadius: radius(16), backgroundColor: context.cardColor)
          : boxDecorationRoundedWithShadow(16, backgroundColor: context.cardColor),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalized greeting with emoji
          Row(
            children: [
              Expanded(
                child: Text(
                  'Metrices',
                  style: boldTextStyle(size: 20, color: appStore.isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
          12.height,
          // Health Insights title
          Text(
            'Health Insights',
            style: boldTextStyle(size: 18, color: appStore.isDarkMode ? Colors.white70 : Colors.grey[700]),
          ),
          16.height,
          if (isLoadingInsights)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                  8.height,
                  Text('Loading insights...', style: secondaryTextStyle()),
                ],
              ),
            )
          else if (healthInsights != null)
            _renderHealthInsights()
          else
            Text('No insights available', style: secondaryTextStyle()),
        ],
      ),
    );
  }

  // Render formatted health insights
  Widget _renderHealthInsights() {
    if (healthInsights == null) return const SizedBox();

    // Remove emojis from the text
    String cleanText = healthInsights!.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '');
    
    // Split the text into paragraphs
    final paragraphs = cleanText.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        final trimmed = paragraph.trim();
        if (trimmed.isEmpty) return const SizedBox();

        // Check if this paragraph looks like a heading (all caps or ends with colon)
        final isHeading = RegExp(r'^[A-Z\s]+$').hasMatch(trimmed) || trimmed.endsWith(':');

        // Check if this paragraph is a bullet point
        final isBulletPoint = trimmed.startsWith('•') ||
                             trimmed.startsWith('-') ||
                             trimmed.startsWith('✅') ||
                             RegExp(r'^\d+\.').hasMatch(trimmed);

        if (isHeading) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              trimmed,
              style: boldTextStyle(size: 16, color: const Color(0xFF818181)).copyWith(fontFamily: 'Inter'),
            ),
          );
        } else if (isBulletPoint) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8),
            child: Text(
              trimmed,
              style: primaryTextStyle(size: 14, color: const Color(0xFF818181)).copyWith(fontFamily: 'Inter'),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              trimmed,
              style: primaryTextStyle(size: 14, color: const Color(0xFF818181)).copyWith(fontFamily: 'Inter'),
            ),
          );
        }
      }).toList(),
    );
  }

  // Build Your Health Profile Card
  Widget _buildHealthProfileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: appStore.isDarkMode
          ? boxDecorationWithRoundedCorners(borderRadius: radius(16), backgroundColor: context.cardColor)
          : boxDecorationRoundedWithShadow(16, backgroundColor: context.cardColor),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: primaryColor, size: 24),
              12.width,
              Text('Your Health Profile', style: boldTextStyle(size: 18)),
            ],
          ),
          20.height,

          // First row: Age and Gender
          Row(
            children: [
              Expanded(
                child: _buildProfileItem(
                  'Age',
                  userStore.age.isNotEmpty ? userStore.age : '--',
                  userStore.age.isNotEmpty ? 'years' : '',
                  Icons.cake_outlined,
                ),
              ),
              16.width,
              Expanded(
                child: _buildProfileItem(
                  'Gender',
                  userStore.gender.isNotEmpty ? userStore.gender.capitalizeFirstLetter() : '--',
                  '',
                  userStore.gender.toLowerCase() == 'male' ? Icons.male :
                  userStore.gender.toLowerCase() == 'female' ? Icons.female : Icons.person,
                ),
              ),
            ],
          ),

          16.height,

          // Second row: Height and Weight
          Row(
            children: [
              Expanded(
                child: _buildProfileItem(
                  'Height',
                  userStore.height.isNotEmpty ? userStore.height : '--',
                  userStore.height.isNotEmpty ? userStore.heightUnit : '',
                  Icons.height,
                ),
              ),
              16.width,
              Expanded(
                child: _buildProfileItem(
                  'Weight',
                  userStore.weight.isNotEmpty ? userStore.weight : '--',
                  userStore.weight.isNotEmpty ? userStore.weightUnit : '',
                  Icons.monitor_weight_outlined,
                ),
              ),
            ],
          ),

          16.height,

          // Goal section (full width)
          _buildProfileItem(
            'Goal',
            userStore.goal.isNotEmpty ? _formatGoal(userStore.goal) : '--',
            '',
            Icons.flag_outlined,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  // Helper method to build individual profile items
  Widget _buildProfileItem(String label, String value, String unit, IconData icon, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: isFullWidth
        ? Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: secondaryTextStyle(size: 12)),
                  4.height,
                  Text(
                    value,
                    style: boldTextStyle(size: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          )
        : Column(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              8.height,
              Text(label, style: secondaryTextStyle(size: 12)),
              4.height,
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: boldTextStyle(size: 16),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: secondaryTextStyle(size: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  // Helper method to build health stat item
  Widget _buildHealthStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: boldTextStyle(size: 24, color: color),
          textAlign: TextAlign.center,
        ),
        4.height,
        Text(
          label,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper method to get health status color
  Color _getHealthStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'normal':
        return Colors.green;
      case 'underweight':
        return Colors.blue;
      case 'overweight':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format goal text
  String _formatGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'weight_loss':
      case 'lose_weight':
        return 'Lose Weight';
      case 'weight_gain':
      case 'gain_weight':
        return 'Gain Weight';
      case 'maintain_healthy_lifestyle':
        return 'Maintain Healthy Lifestyle';
      case 'gain_muscles':
        return 'Gain Muscles';
      case 'general_fitness':
        return 'General Fitness';
      default:
        return goal.replaceAll('_', ' ').split(' ').map((word) =>
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
        ).join(' ');
    }
  }
}
