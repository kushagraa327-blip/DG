import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/decorations.dart';
import '../extensions/widgets.dart';
import '../extensions/responsive_utils.dart';
import '../main.dart';
import '../models/meal_entry_model.dart';
import '../utils/app_colors.dart';
import '../services/ai_service.dart' show analyzeFoodNutrition, FoodValidationException;
import '../services/food_recognition_service.dart';

class LogMealFormComponent extends StatefulWidget {
  final void Function(MealEntry) onSubmit;
  final MealEntry? initialMeal;
  final List<FoodItem>? initialFoods;
  final String? initialMealType;

  const LogMealFormComponent({
    super.key,
    required this.onSubmit,
    this.initialMeal,
    this.initialFoods,
    this.initialMealType,
  });

  @override
  _LogMealFormComponentState createState() => _LogMealFormComponentState();
}

class _LogMealFormComponentState extends State<LogMealFormComponent> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedMealType = 'breakfast';
  List<FoodItem> _foodItems = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    if (widget.initialMeal != null) {
      _selectedMealType = widget.initialMeal!.mealType;
      _foodItems = List.from(widget.initialMeal!.foods);
      _notesController.text = widget.initialMeal!.notes ?? '';
    } else {
      // Handle pre-filled data from image recognition
      if (widget.initialFoods != null && widget.initialFoods!.isNotEmpty) {
        _foodItems = List.from(widget.initialFoods!);
        _notesController.text = 'Auto-detected from image';
        // If image is present, try to auto-analyze
        final food = widget.initialFoods!.first;
        if (food.imagePath != null) {
          Future.microtask(() async {
            setState(() { _isAnalyzing = true; });
            String detectedName = food.name;
            double detectedCalories = food.calories;
            double detectedProtein = food.protein;
            double detectedCarbs = food.carbs;
            double detectedFat = food.fat;
            // If food name or nutrients are missing, try to get it from image recognition
            if (detectedName.isEmpty || detectedCalories == 0) {
              try {
                List<FoodItem> recognizedFoods = await FoodRecognitionService.analyzeFoodImage(File(food.imagePath!));
                if (recognizedFoods.isNotEmpty) {
                  final recognized = recognizedFoods.first;
                  detectedName = recognized.name;
                  detectedCalories = recognized.calories;
                  detectedProtein = recognized.protein;
                  detectedCarbs = recognized.carbs;
                  detectedFat = recognized.fat;
                  _nameController.text = detectedName;
                  _caloriesController.text = detectedCalories.toString();
                  _proteinController.text = detectedProtein.toString();
                  _carbsController.text = detectedCarbs.toString();
                  _fatController.text = detectedFat.toString();
                }
              } catch (e) {
                // Optionally show error
              }
            } else {
              _nameController.text = detectedName;
              _caloriesController.text = detectedCalories.toString();
              _proteinController.text = detectedProtein.toString();
              _carbsController.text = detectedCarbs.toString();
              _fatController.text = detectedFat.toString();
            }
            setState(() { _isAnalyzing = false; });
          });
        }
      }
      if (widget.initialMealType != null) {
        _selectedMealType = widget.initialMealType!;
      }
    }
  }

  @override
  void dispose() {
  _notesController.dispose();
  _nameController.dispose();
  _caloriesController.dispose();
  _proteinController.dispose();
  _carbsController.dispose();
  _fatController.dispose();
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Column(
        children: [
          // Handle bar for modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: primaryColor,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 28),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                Expanded(
                  child: ResponsiveText(
                    widget.initialMeal != null ? 'Edit Meal' : 'Log New Meal',
                    baseFontSize: 24,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                  ),
                ),
              ],
            ),

            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),

            // Meal Type Selection
            const ResponsiveText('Meal Type', baseFontSize: 16, fontWeight: FontWeight.bold),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
            Container(
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _mealTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getMealTypeIcon(type),
                          color: _getMealTypeColor(type),
                          size: 20,
                        ),
                        12.width,
                        Text(
                          type[0].toUpperCase() + type.substring(1),
                          style: primaryTextStyle(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value!;
                  });
                },
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),

            // Food Items Section
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: ResponsiveText(
                    'Food Items',
                    baseFontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: _addFoodItem,
                    icon: Icon(
                      Icons.add,
                      size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                    ),
                    label: const ResponsiveText(
                      'Add Food',
                      baseFontSize: 12,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: ResponsiveUtils.getResponsiveBorderRadius(context, 8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
                        vertical: ResponsiveUtils.getResponsiveSpacing(context, 6),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
            
            // Auto-detected foods header
            if (widget.initialFoods != null && widget.initialFoods!.isNotEmpty && _foodItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI-Detected Foods',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IRA automatically detected ${_foodItems.length} food item(s) from your image.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                              if (_foodItems.length > 1) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '📊 Total Nutrition Summary:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Calories: ${_foodItems.fold(0.0, (sum, food) => sum + food.calories).toInt()}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Protein: ${_foodItems.fold(0.0, (sum, food) => sum + food.protein).toInt()}g',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Carbs: ${_foodItems.fold(0.0, (sum, food) => sum + food.carbs).toInt()}g',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Fat: ${_foodItems.fold(0.0, (sum, food) => sum + food.fat).toInt()}g',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'You can edit, remove, or add more items below.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Food Items List
            if (_foodItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.no_food_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    12.height,
                    Text(
                      'No food items added yet',
                      style: secondaryTextStyle(),
                    ),
                    8.height,
                    Text(
                      'Tap "Add Food" to start logging your meal',
                      style: secondaryTextStyle(size: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_foodItems.length, (index) {
                final food = _foodItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food image (if available)
                      if (food.imagePath != null && File(food.imagePath!).existsSync()) ...[
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(food.imagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    food.name,
                                    style: boldTextStyle(size: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (food.imagePath != null)
                                  Flexible(
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_rounded,
                                            size: 8,
                                            color: primaryColor,
                                          ),
                                          SizedBox(width: 1),
                                          Text(
                                            'Photo',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            4.height,
                            Text(
                              '${food.quantity}${food.unit} • ${food.calories.toInt()} cal',
                              style: secondaryTextStyle(size: 12, color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            4.height,
                            Text(
                              'P: ${food.protein.toInt()}g • C: ${food.carbs.toInt()}g • F: ${food.fat.toInt()}g',
                              style: secondaryTextStyle(size: 11, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeFoodItem(index),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            
            24.height,
            
            // Notes Section
            Text('Notes (Optional)', style: boldTextStyle(size: 16)),
            12.height,
            Container(
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add any notes about this meal...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            
            32.height,
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: boldTextStyle(color: primaryColor),
                    ),
                  ),
                ),
                16.width,
                Expanded(
                  child: ElevatedButton(
                    onPressed: _foodItems.isNotEmpty && !_isLoading ? _submitMeal : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.initialMeal != null ? 'Update Meal' : 'Log Meal',
                            style: boldTextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),

            // Add some bottom padding for better scrolling experience
            const SizedBox(height: 100), // Extra padding for bottom navigation
          ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addFoodItem() {
    showDialog(
      context: context,
      builder: (context) => AddFoodDialog(
        onAdd: (foodItem) {
          setState(() {
            _foodItems.add(foodItem);
          });
        },
      ),
    );
  }

  void _removeFoodItem(int index) {
    setState(() {
      _foodItems.removeAt(index);
    });
  }

  void _submitMeal() async {
    // Log the meal even if nutrient fields are empty
    if (_formKey.currentState!.validate() && _foodItems.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use local date in yyyy-MM-dd format for consistency
        final now = DateTime.now();
        final localDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final meal = MealEntry(
          id: widget.initialMeal?.id ?? now.millisecondsSinceEpoch.toString(),
          date: localDate,
          mealType: _selectedMealType,
          foods: _foodItems,
          timestamp: now,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        widget.onSubmit(meal);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one food item.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  IconData _getMealTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
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

class AddFoodDialog extends StatefulWidget {
  final void Function(FoodItem) onAdd;

  const AddFoodDialog({super.key, required this.onAdd});

  @override
  _AddFoodDialogState createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedUnit = 'g';
  bool _isAnalyzing = false;
  File? _selectedImage;
  bool _isAnalyzingImage = false;

  final List<String> _units = ['g', 'ml', 'cup', 'piece', 'slice', 'tbsp', 'tsp'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        constraints: BoxConstraints(
          maxHeight: context.height() * 0.85,
          maxWidth: context.isMobile ? context.width() * 0.95 : 500,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Food Item', style: boldTextStyle(size: 20)),
                
                20.height,
                
                // Food Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    hintText: 'e.g., Chicken Breast',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter food name';
                    }

                    // Basic validation for obviously non-food items
                    final input = value!.toLowerCase().trim();
                    final nonFoodKeywords = [
                      'chair', 'table', 'desk', 'computer', 'phone', 'car', 'book',
                      'pen', 'pencil', 'paper', 'wall', 'door', 'window', 'lamp',
                      'television', 'tv', 'remote', 'keyboard', 'mouse', 'screen',
                      'clothes', 'shirt', 'pants', 'shoes', 'furniture', 'sofa',
                      'bed', 'pillow', 'blanket', 'soap', 'shampoo', 'medicine',
                      'pill', 'tool', 'hammer', 'electronic', 'device', 'toy'
                    ];

                    for (final keyword in nonFoodKeywords) {
                      if (input.contains(keyword)) {
                        return 'Invalid input, please enter food items only';
                      }
                    }

                    return null;
                  },
                ),

                20.height,

                // Photo Upload Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            color: primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Food Photo (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImage == null) ...[
                        // Photo upload buttons
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPhotoOption(
                                  icon: Icons.camera_alt_rounded,
                                  title: 'Camera',
                                  onTap: () => _pickImage(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPhotoOption(
                                  icon: Icons.photo_library_rounded,
                                  title: 'Gallery',
                                  onTap: () => _pickImage(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a photo to help with automatic nutritional analysis',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        // Selected image preview
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: _isAnalyzingImage ? null : _analyzeImageNutrition,
                                icon: _isAnalyzingImage
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded, size: 14),
                                label: Text(
                                  _isAnalyzingImage ? 'Analyzing...' : 'Auto-Fill',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.withOpacity(0.7),
                                  size: 18,
                                ),
                                tooltip: 'Remove photo',
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                16.height,
                
                // Quantity and Unit
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          hintText: '100',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          // Allow both numeric values and descriptive quantities
                          final trimmed = value!.trim();
                          if (trimmed.isEmpty) {
                            return 'Required';
                          }
                          // If it starts with a number, validate the numeric part
                          final numericPart = RegExp(r'^\d+(\.\d+)?').firstMatch(trimmed);
                          if (numericPart != null) {
                            final numericValue = double.tryParse(numericPart.group(0)!);
                            if (numericValue == null || numericValue <= 0) {
                              return 'Invalid quantity';
                            }
                          }
                          // Allow descriptive quantities like "1 serving", "Mixed: 1 cup, 2 pieces"
                          return null;
                        },
                      ),
                    ),
                    8.width,
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),
                
                16.height,
                
                // AI Analysis Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeFood,
                    icon: _isAnalyzing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isAnalyzing ? 'Analyzing...' : 'Auto-fill with AI'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                16.height,
                
                // Manual Nutrition Input
                Text('Nutrition Information', style: boldTextStyle(size: 16)),
                12.height,
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Calories',
                          hintText: '165',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: TextFormField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          hintText: '31',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                16.height,
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Carbs (g)',
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: TextFormField(
                        controller: _fatController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fat (g)',
                          hintText: '3.6',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                24.height,
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addFood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Food', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _analyzeFood() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter food name first')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Use AI service to analyze food
      final foodName = _nameController.text.trim();
      final quantity = _quantityController.text.trim();

      // Validate input is not empty
      if (foodName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a food name first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final analysis = await analyzeFoodNutrition(foodName, quantity.isNotEmpty ? quantity : '100');

      // Parse the analysis and fill the fields
      setState(() {
        _caloriesController.text = analysis['calories']?.toString() ?? '0';
        _proteinController.text = analysis['protein']?.toString() ?? '0';
        _carbsController.text = analysis['carbs']?.toString() ?? '0';
        _fatController.text = analysis['fat']?.toString() ?? '0';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrition information filled automatically!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = 'Could not analyze food. Please enter manually.';
      Color errorColor = Colors.orange;

      // Handle food validation errors specifically
      if (e is FoodValidationException) {
        errorMessage = e.message;
        errorColor = Colors.red;
      } else if (e.toString().contains('Invalid input, please enter food items only')) {
        errorMessage = 'Invalid input, please enter food items only';
        errorColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 4), // Show validation errors longer
        ),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  /// Build photo option button
  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Analyze image and auto-fill nutritional data
  Future<void> _analyzeImageNutrition() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzingImage = true;
    });

    try {
      print('🍽️ Analyzing food image for nutrition data...');

      // Use the food recognition service to analyze the image
      final recognizedFoods = await FoodRecognitionService.analyzeFoodImage(_selectedImage!);

      if (recognizedFoods.isNotEmpty) {
        print('🍽️ Found ${recognizedFoods.length} food items in image');

        // Show dialog to let user choose how to handle multiple items
        if (recognizedFoods.length > 1) {
          _showMultipleFoodsDialog(recognizedFoods);
        } else {
          // Single item - show option to auto-fill or edit
          final food = recognizedFoods.first;
          _showSingleFoodDialog(food);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Could not analyze food from image. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error analyzing image: $e');

      String errorMessage = 'Error analyzing image. Please try again or enter manually.';
      Color errorColor = Colors.red;

      // Handle food validation errors specifically
      if (e is FoodValidationException) {
        errorMessage = e.message;
        errorColor = Colors.red;
      } else if (e.toString().contains('No food items detected')) {
        errorMessage = 'No food items detected in image. Please upload an image containing food.';
        errorColor = Colors.red;
      } else if (e.toString().contains('Invalid input, please enter food items only')) {
        errorMessage = 'Invalid input, please enter food items only';
        errorColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 4), // Show validation errors longer
        ),
      );
    } finally {
      setState(() {
        _isAnalyzingImage = false;
      });
    }
  }

  /// Show dialog for single detected food item
  void _showSingleFoodDialog(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: primaryColor),
            SizedBox(width: 8),
            Text('Food Detected'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'I found this food item in your image:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${food.quantity}${food.unit} • ${food.calories.toInt()} calories',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Protein: ${food.protein.toInt()}g',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Carbs: ${food.carbs.toInt()}g',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fat: ${food.fat.toInt()}g',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Fiber: ${food.fiber.toInt()}g',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Would you like to use this data or edit it first?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show edit dialog for single food
              _showEditSingleFoodDialog(food);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 18, color: Colors.orange),
                SizedBox(width: 4),
                Text('Edit First', style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fillFormWithFoodData(food);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Food data auto-filled from image!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 18),
                SizedBox(width: 4),
                Text('Use This Data'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show edit dialog for single food item
  void _showEditSingleFoodDialog(FoodItem food) {
    final nameController = TextEditingController(text: food.name);
    final quantityController = TextEditingController(text: food.quantity);
    final caloriesController = TextEditingController(text: food.calories.toString());
    final proteinController = TextEditingController(text: food.protein.toString());
    final carbsController = TextEditingController(text: food.carbs.toString());
    final fatController = TextEditingController(text: food.fat.toString());
    String selectedUnit = food.unit;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.orange),
            SizedBox(width: 8),
            Text('Edit Food Details'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.straighten),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['g', 'ml', 'cup', 'piece', 'slice', 'tbsp', 'tsp'].map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedUnit = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: caloriesController,
                        decoration: InputDecoration(
                          labelText: 'Calories',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: proteinController,
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: carbsController,
                        decoration: InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: fatController,
                        decoration: InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // Create updated food item with edited values
              final updatedFood = FoodItem(
                id: food.id,
                name: nameController.text,
                quantity: quantityController.text,
                calories: double.tryParse(caloriesController.text) ?? 0.0,
                protein: double.tryParse(proteinController.text) ?? 0.0,
                carbs: double.tryParse(carbsController.text) ?? 0.0,
                fat: double.tryParse(fatController.text) ?? 0.0,
                fiber: food.fiber,
                unit: selectedUnit,
                imagePath: food.imagePath,
              );

              _fillFormWithFoodData(updatedFood);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Edited food data applied to form!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply Changes'),
          ),
        ],
      ),
    );
  }

  /// Fill form with food data
  void _fillFormWithFoodData(FoodItem food) {
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameController.text = food.name;
      }
      if (_quantityController.text.isEmpty) {
        _quantityController.text = food.quantity;
      }
      _caloriesController.text = food.calories.toStringAsFixed(1);
      _proteinController.text = food.protein.toStringAsFixed(1);
      _carbsController.text = food.carbs.toStringAsFixed(1);
      _fatController.text = food.fat.toStringAsFixed(1);
    });
  }

  /// Show dialog for handling multiple detected food items
  void _showMultipleFoodsDialog(List<FoodItem> recognizedFoods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: primaryColor),
            SizedBox(width: 8),
            Text('Multiple Foods Detected'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I found ${recognizedFoods.length} food items in your image:',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: recognizedFoods.length,
                    itemBuilder: (context, index) {
                      final food = recognizedFoods[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${food.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${food.quantity}${food.unit} • ${food.calories.toInt()} cal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'P: ${food.protein.toInt()}g • C: ${food.carbs.toInt()}g • F: ${food.fat.toInt()}g',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How would you like to add these items?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Aggregate all items into one
              final aggregatedFood = FoodRecognitionService.aggregateFoodItems(recognizedFoods);
              _fillFormWithFoodData(aggregatedFood);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Combined ${recognizedFoods.length} items - total nutrition calculated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.merge_type, size: 20),
                SizedBox(height: 4),
                Text('Combine All', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show edit dialog for multiple foods
              _showEditMultipleFoodsDialog(recognizedFoods);
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 20, color: Colors.orange),
                SizedBox(height: 4),
                Text('Edit Items', style: TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add all items individually to the meal
              _addMultipleFoodsToMeal(recognizedFoods);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 20),
                SizedBox(height: 4),
                Text('Add All Separately', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show edit dialog for multiple detected food items
  void _showEditMultipleFoodsDialog(List<FoodItem> recognizedFoods) {
    List<FoodItem> editableFoods = List.from(recognizedFoods);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.orange),
              SizedBox(width: 8),
              Text('Edit Detected Foods'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit the details for each detected food item:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: editableFoods.length,
                    itemBuilder: (context, index) {
                      final food = editableFoods[index];
                      return _buildEditableFoodCard(food, index, (updatedFood) {
                        setState(() {
                          editableFoods[index] = updatedFood;
                        });
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Add all edited items to the meal
                _addMultipleFoodsToMeal(editableFoods);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add All Items'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build an editable food card for the edit dialog
  Widget _buildEditableFoodCard(FoodItem food, int index, Function(FoodItem) onUpdate) {
    final nameController = TextEditingController(text: food.name);
    final quantityController = TextEditingController(text: food.quantity);
    final caloriesController = TextEditingController(text: food.calories.toString());
    final proteinController = TextEditingController(text: food.protein.toString());
    final carbsController = TextEditingController(text: food.carbs.toString());
    final fatController = TextEditingController(text: food.fat.toString());
    String selectedUnit = food.unit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                  // Remove this item from the list
                  // This would need to be handled by the parent widget
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Food Name
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Food Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              onUpdate(food.copyWith(name: value));
            },
          ),
          const SizedBox(height: 8),

          // Quantity and Unit Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    onUpdate(food.copyWith(quantity: value));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: StatefulBuilder(
                  builder: (context, setStateCard) {
                    return DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      items: ['g', 'ml', 'cup', 'piece', 'slice', 'tbsp', 'tsp'].map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateCard(() {
                          selectedUnit = value!;
                        });
                        onUpdate(food.copyWith(unit: selectedUnit));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nutrition Row 1: Calories and Protein
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final calories = double.tryParse(value) ?? 0.0;
                    onUpdate(food.copyWith(calories: calories));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: proteinController,
                  decoration: InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final protein = double.tryParse(value) ?? 0.0;
                    onUpdate(food.copyWith(protein: protein));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nutrition Row 2: Carbs and Fat
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: carbsController,
                  decoration: InputDecoration(
                    labelText: 'Carbs (g)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final carbs = double.tryParse(value) ?? 0.0;
                    onUpdate(food.copyWith(carbs: carbs));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: fatController,
                  decoration: InputDecoration(
                    labelText: 'Fat (g)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final fat = double.tryParse(value) ?? 0.0;
                    onUpdate(food.copyWith(fat: fat));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Add multiple foods directly to the meal (bypassing the form)
  void _addMultipleFoodsToMeal(List<FoodItem> recognizedFoods) {
    final individualFoods = FoodRecognitionService.createIndividualFoodItems(recognizedFoods);

    // Add each food item to the meal
    for (final food in individualFoods) {
      widget.onAdd(food);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added ${recognizedFoods.length} food items to your meal!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Close the add food dialog
  }

  void _addFood() {
    if (_formKey.currentState!.validate()) {
      try {
        final foodItem = FoodItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          quantity: _quantityController.text.trim(),
          calories: double.parse(_caloriesController.text),
          protein: double.parse(_proteinController.text),
          carbs: double.parse(_carbsController.text),
          fat: double.parse(_fatController.text),
          unit: _selectedUnit,
          imagePath: _selectedImage?.path, // Include the image path
        );

        widget.onAdd(foodItem);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error adding food: Please check all numeric values'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
