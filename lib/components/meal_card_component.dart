import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/decorations.dart';
import '../extensions/responsive_utils.dart';
import '../main.dart';
import '../models/meal_entry_model.dart';
import '../utils/app_colors.dart';

class MealCardComponent extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MealCardComponent({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with meal type and time
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
                            vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
                          ),
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: _getMealTypeColor().withOpacity(0.1),
                            borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 6),
                          ),
                          child: ResponsiveText(
                            _getMealTypeDisplayName(),
                            baseFontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getMealTypeColor(),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                        Flexible(
                          child: ResponsiveText(
                            DateFormat('HH:mm').format(meal.timestamp),
                            baseFontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.7),
                        size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 4)),
                      constraints: BoxConstraints(
                        minWidth: ResponsiveUtils.getResponsiveSpacing(context, 32),
                        minHeight: ResponsiveUtils.getResponsiveSpacing(context, 32),
                      ),
                    ),
                ],
              ),
              
              12.height,
              
              // Food items
              ...meal.foods.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: Text(
                        '${food.name} (${food.quantity}${food.unit})',
                        style: primaryTextStyle(size: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    4.width,
                    Text(
                      '${food.calories.toInt()} cal',
                      style: secondaryTextStyle(size: 12),
                    ),
                  ],
                ),
              )),
              
              if (meal.notes?.isNotEmpty == true) ...[
                8.height,
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: primaryColor.withOpacity(0.7),
                      ),
                      8.width,
                      Expanded(
                        child: Text(
                          meal.notes!,
                          style: secondaryTextStyle(size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              12.height,
              
              // Nutrition summary
              Container(
                width: double.infinity,
                padding: ResponsiveUtils.getResponsivePadding(context, mobile: 12),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: appStore.isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[100]!,
                  borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 8),
                ),
                child: context.isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildNutritionItem(context, 'Calories', '${meal.totalCalories.toInt()}', 'cal', primaryColor)),
                            Expanded(child: _buildNutritionItem(context, 'Protein', '${meal.totalProtein.toInt()}', 'g', Colors.blue)),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                        Row(
                          children: [
                            Expanded(child: _buildNutritionItem(context, 'Carbs', '${meal.totalCarbs.toInt()}', 'g', Colors.orange)),
                            Expanded(child: _buildNutritionItem(context, 'Fat', '${meal.totalFat.toInt()}', 'g', Colors.green)),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildNutritionItem(context, 'Calories', '${meal.totalCalories.toInt()}', 'cal', primaryColor)),
                        Expanded(child: _buildNutritionItem(context, 'Protein', '${meal.totalProtein.toInt()}', 'g', Colors.blue)),
                        Expanded(child: _buildNutritionItem(context, 'Carbs', '${meal.totalCarbs.toInt()}', 'g', Colors.orange)),
                        Expanded(child: _buildNutritionItem(context, 'Fat', '${meal.totalFat.toInt()}', 'g', Colors.green)),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionItem(BuildContext context, String label, String value, String unit, Color color) {
    return Column(
      children: [
        ResponsiveText(
          value,
          baseFontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 2)),
        ResponsiveText(
          unit,
          baseFontSize: 10,
          color: Colors.grey[600],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 2)),
        ResponsiveText(
          label,
          baseFontSize: 11,
          color: Colors.grey[600],
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getMealTypeDisplayName() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return 'Meal';
    }
  }

  Color _getMealTypeColor() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return primaryColor;
    }
  }
}

class MealSummaryCard extends StatelessWidget {
  final DailyNutrition dailyNutrition;
  final NutritionGoals? goals;

  const MealSummaryCard({
    super.key,
    required this.dailyNutrition,
    this.goals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: primaryColor,
                  size: 24,
                ),
                12.width,
                Text(
                  'Today\'s Nutrition',
                  style: boldTextStyle(size: 18),
                ),
              ],
            ),
            
            16.height,
            
            // Dial representation with calories at top
            if (goals != null) ...[
              // Calories dial at the top
              Center(
                child: _buildCaloriesDial(
                  context,
                  dailyNutrition.totalCalories,
                  goals!.dailyCalories,
                ),
              ),
              
              24.height,
              
              // Protein, Carbs, Fat in a single row below calories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildMacroDial(
                      context,
                      'Protein',
                      dailyNutrition.totalProtein,
                      goals!.dailyProtein,
                      Colors.blue,
                      'g',
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: _buildMacroDial(
                      context,
                      'Carbs',
                      dailyNutrition.totalCarbs,
                      goals!.dailyCarbs,
                      Colors.orange,
                      'g',
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: _buildMacroDial(
                      context,
                      'Fat',
                      dailyNutrition.totalFat,
                      goals!.dailyFat,
                      Colors.green,
                      'g',
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Simple display without goals using dials
              Center(
                child: _buildSimpleCaloriesDial(
                  context,
                  dailyNutrition.totalCalories,
                ),
              ),
              
              24.height,
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildSimpleMacroDial(
                      context,
                      'Protein',
                      dailyNutrition.totalProtein,
                      Colors.blue,
                      'g',
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: _buildSimpleMacroDial(
                      context,
                      'Carbs',
                      dailyNutrition.totalCarbs,
                      Colors.orange,
                      'g',
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: _buildSimpleMacroDial(
                      context,
                      'Fat',
                      dailyNutrition.totalFat,
                      Colors.green,
                      'g',
                    ),
                  ),
                ],
              ),
            ],
            
            16.height,
            
            // Meal count
            Container(
              padding: const EdgeInsets.all(12),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant,
                    color: primaryColor,
                    size: 20,
                  ),
                  8.width,
                  Text(
                    '${dailyNutrition.mealCount} meals logged today',
                    style: boldTextStyle(color: primaryColor, size: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calories dial (larger, main display)
  Widget _buildCaloriesDial(BuildContext context, double current, double target) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 8,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${current.toInt()}',
                    style: boldTextStyle(size: 24, color: primaryColor),
                  ),
                  Text(
                    'cal',
                    style: secondaryTextStyle(size: 12),
                  ),
                  Text(
                    '$percentage%',
                    style: boldTextStyle(size: 14, color: primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        8.height,
        Text(
          'Calories',
          style: boldTextStyle(size: 16),
        ),
        4.height,
        Text(
          '${target.toInt()} goal',
          style: secondaryTextStyle(size: 12),
        ),
      ],
    );
  }

  // Macro dials (smaller, for protein, carbs, fat)
  Widget _buildMacroDial(BuildContext context, String label, double current, double target, Color color, String unit) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 6,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${current.toInt()}',
                    style: boldTextStyle(size: 16, color: color),
                  ),
                  Text(
                    unit,
                    style: secondaryTextStyle(size: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        8.height,
        Text(
          label,
          style: boldTextStyle(size: 12),
        ),
        2.height,
        Text(
          '$percentage%',
          style: secondaryTextStyle(size: 10, color: color),
        ),
      ],
    );
  }

  // Simple calories dial (without goals)
  Widget _buildSimpleCaloriesDial(BuildContext context, double current) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 8,
                  ),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${current.toInt()}',
                    style: boldTextStyle(size: 24, color: primaryColor),
                  ),
                  Text(
                    'cal',
                    style: secondaryTextStyle(size: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        8.height,
        Text(
          'Calories',
          style: boldTextStyle(size: 16),
        ),
      ],
    );
  }

  // Simple macro dial (without goals)
  Widget _buildSimpleMacroDial(BuildContext context, String label, double current, Color color, String unit) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 6,
                  ),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${current.toInt()}',
                    style: boldTextStyle(size: 16, color: color),
                  ),
                  Text(
                    unit,
                    style: secondaryTextStyle(size: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        8.height,
        Text(
          label,
          style: boldTextStyle(size: 12),
        ),
      ],
    );
  }
}
