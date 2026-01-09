import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:chat_gpt_flutter/chat_gpt_flutter.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/components/chat_message_Image_widget.dart';
import 'package:mighty_fitness/components/typing_indicator.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/models/question_answer_model.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/screens/chatbot_empty_screen.dart';
import 'package:mighty_fitness/services/food_recognition_service.dart';
import 'package:mighty_fitness/components/log_meal_form_component.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/models/meal_entry_model.dart';
import 'package:mighty_fitness/screens/main_goal_screen.dart';
import 'package:mighty_fitness/utils/_storeFirstTimeOpen.dart';
import '../extensions/extension_util/bool_extensions.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/list_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../utils/app_images.dart';
import 'package:share_plus/share_plus.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/confirmation_dialog.dart';
import '../extensions/decorations.dart';
import '../extensions/system_utils.dart';
import '../extensions/widgets.dart';
import '../extensions/shared_pref.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import '../services/ai_service.dart';

int? selectedImageIndex = -1;
bool? isLoading = false;
List<QuestionImageAnswerModel> questionAnswers = [];

class ChattingImageScreen extends StatefulWidget {
  static String tag = '/chatgpt';

  final bool isDirect;

  const ChattingImageScreen({super.key, this.isDirect = false});

  @override
  _ChattingImageScreenState createState() => _ChattingImageScreenState();
}

class _ChattingImageScreenState extends State<ChattingImageScreen> {
  // ChatGpt chatGpt = ChatGpt(apiKey: userStore.chatGptApiKey);

  ScrollController scrollController = ScrollController();

  TextEditingController msgController = TextEditingController();

  StreamSubscription<StreamCompletionResponse>? streamSubscription;

  int adCount = 0;
  int selectedIndex = -1;

  String lastError = "";
  String imageSelected = "";
  String lastStatus = "";
  String selectedText = '';
  String firstQuestion = '';
  String question = '';

  bool isBannerLoad = false;
  bool isShowOption = false;
  bool isSelectedIndex = false;
  bool isScroll = false;
  bool showResponse = false;
  bool isAnalyzingFood = false;
  List<String> foundWords = [];
  File? selectedMealImage;

  late OpenAI openAI;
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();

    Future.value().then((_) {
      voiceMSG();
      openAI = OpenAI.instance.build(
          token: userStore.chatGptApiKey,
          baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20), connectTimeout: const Duration(seconds: 20)),
          enableLog: true);

      print("-----------------82>>>>$isFirstTime");
      if (isFirstTime == false || isFirstTime == null) {
        firstQuestion =
            "my gender is ${userStore.gender.validate()}, my age is ${userStore.age.validate()}, my weight is${userStore.weight.validate()}${userStore.weightUnit.validate()}, my height is ${userStore.height.validate()}${userStore.heightUnit.validate()}, $selectMainGoal, $selectExperienced,$selectEquipments,$selectWeekWorkout please schedule my workout?";
        sendAutoFirstMsg(firstQuestion);
      }

      init();
    });
  }


  void voiceMSG() {
    flutterTts = FlutterTts();
    flutterTts.awaitSpeakCompletion(true);
    // Set volume to 0 to completely silence TTS
    flutterTts.setVolume(0.0);
  }

  Future<void> setFitBotDataApiCall(String? question, String? answer) async {
    // TTS disabled per user request - IRA should not speak out loud
    // speakLongText(answer??'');
    appStore.setLoading(true);
    
    // Enhanced conversation data with context
    Map req = {
      "question": question,
      "answer": answer,
      "timestamp": DateTime.now().toIso8601String(),
      "user_id": userStore.userId,
      "session_id": DateTime.now().millisecondsSinceEpoch.toString(),
      "user_profile": {
        "name": userStore.fName,
        "age": userStore.age,
        "weight": userStore.weight,
        "height": userStore.height,
        "goal": userStore.goal,
        "gender": userStore.gender,
      },
      "recent_meals": nutritionStore.todayMeals.take(3).map((meal) => {
        "mealType": meal.mealType,
        "foods": meal.foods.map((food) => food.name).toList(),
        "calories": meal.foods.fold(0.0, (sum, food) => sum + food.calories),
      }).toList(),
    };
    
    await saveFitBotData(req).then((value) async {
      // Also save to local conversation history for memory analysis
      await _saveToLocalConversationHistory(question, answer);
    }).catchError((e) {
      appStore.setLoading(false);
      print(e.toString());
    });
  }

  /// Save conversation to local storage for memory analysis
  Future<void> _saveToLocalConversationHistory(String? question, String? answer) async {
    try {
      final conversationData = {
        "question": question,
        "answer": answer,
        "timestamp": DateTime.now().toIso8601String(),
        "user_profile": {
          "name": userStore.fName,
          "goal": userStore.goal,
          "age": userStore.age,
        },
        "context": {
          "recent_meals_count": nutritionStore.todayMeals.length,
          "time_of_day": _getTimeOfDay(),
        }
      };
      
      // Get existing conversation history
      final existingHistory = getStringAsync('conversation_history', defaultValue: '[]');
      final List<dynamic> historyList = jsonDecode(existingHistory);
      
      // Add new conversation
      historyList.add(conversationData);
      
      // Keep only last 100 conversations to prevent storage bloat
      if (historyList.length > 100) {
        historyList.removeRange(0, historyList.length - 100);
      }
      
      // Save back to storage
      await setValue('conversation_history', jsonEncode(historyList));
      
      print('💾 Saved conversation to local memory for future context analysis');
    } catch (e) {
      print('❌ Error saving conversation to local memory: $e');
    }
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  Future<void> speakLongText(String text) async {
    // Text-to-speech is disabled by manager request.
    // Keep function present but no-op so no audio will be produced.
    return Future.value();
  }

  List<String> _splitTextIntoChunks(String text, int chunkSize) {
    final List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      chunks.add(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
    }
    return chunks;
  }

  Future<void> deleteFitBotDataApiCall() async {
    appStore.setLoading(true);
    await deleteFitBotData().then((value) async {
      questionAnswers.clear();
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      print(e.toString());
    });
  }

  void init() async {
    hideKeyboard(context);
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = status;
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  /// Pick image from camera or gallery for meal logging
  Future<void> _pickMealImage(ImageSource source) async {
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
          selectedMealImage = File(image.path);
          isAnalyzingFood = true;
        });

        // Analyze the food image with AI
        await _analyzeFoodImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Analyze food image and show meal logging form
  Future<void> _analyzeFoodImage() async {
    if (selectedMealImage == null) return;

    try {
      print('🍽️ Analyzing food image...');

      // Show analyzing message in chat
      final analyzingMessage = QuestionImageAnswerModel(
        question: 'Analyzing food image...',
        imageUri: selectedMealImage!.path,
        answer: StringBuffer('🔍 IRA is analyzing your food image...'),
        isLoading: false,
        smartCompose: ''
      );

      setState(() {
        questionAnswers.insert(0, analyzingMessage);
      });

      // Analyze the image with AI
      final recognizedFoods = await FoodRecognitionService.analyzeFoodImage(selectedMealImage!);

      setState(() {
        isAnalyzingFood = false;
      });

      if (recognizedFoods.isNotEmpty) {
        // Calculate total nutrition
        final totalCalories = recognizedFoods.fold(0.0, (sum, food) => sum + food.calories);
        final totalProtein = recognizedFoods.fold(0.0, (sum, food) => sum + food.protein);
        final totalCarbs = recognizedFoods.fold(0.0, (sum, food) => sum + food.carbs);
        final totalFat = recognizedFoods.fold(0.0, (sum, food) => sum + food.fat);

        // Update the analyzing message with detailed results
        final resultText = '''✅ Food Analysis Complete!

I found ${recognizedFoods.length} food item(s) in your image:

${recognizedFoods.map((food) => '🍽️ ${food.name}\n   ${food.quantity} - ${food.calories.toInt()} cal\n   P: ${food.protein.toInt()}g • C: ${food.carbs.toInt()}g • F: ${food.fat.toInt()}g').join('\n\n')}

📊 **Total Nutrition Summary:**
• Total Calories: ${totalCalories.toInt()} cal
• Total Protein: ${totalProtein.toInt()}g
• Total Carbs: ${totalCarbs.toInt()}g
• Total Fat: ${totalFat.toInt()}g

Would you like me to log all these items to your meal?''';

        setState(() {
          questionAnswers[0].answer = StringBuffer(resultText);
        });

        // Show options for handling the recognized foods
        _showFoodAnalysisOptions(recognizedFoods);
      } else {
        // Update message with failure
        setState(() {
          questionAnswers[0].answer = StringBuffer('❌ Sorry, I couldn\'t identify any food items in this image. You can still log your meal manually!');
        });

        // Show empty meal logging form
        _showMealLoggingForm([]);
      }

    } catch (e) {
      print('Error analyzing food image: $e');
      setState(() {
        isAnalyzingFood = false;
        questionAnswers[0].answer = StringBuffer('❌ Error analyzing image: $e\n\nYou can still log your meal manually!');
      });

      // Show empty meal logging form
      _showMealLoggingForm([]);
    }
  }

  /// Show options for handling analyzed food items
  void _showFoodAnalysisOptions(List<FoodItem> recognizedFoods) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Row(
              children: [
                Icon(Icons.restaurant_menu, color: primaryColor),
                SizedBox(width: 12),
                Text(
                  'Food Analysis Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
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
                    'Found ${recognizedFoods.length} food items',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${recognizedFoods.fold(0.0, (sum, food) => sum + food.calories).toInt()} calories',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditFoodsDialog(recognizedFoods);
                    },
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Edit Items'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showMealLoggingForm(recognizedFoods);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Log Meal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Show edit dialog for recognized foods
  void _showEditFoodsDialog(List<FoodItem> recognizedFoods) {
    List<FoodItem> editableFoods = List.from(recognizedFoods);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
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
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
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
                      return _buildEditableFoodCard(editableFoods[index], index, (updatedFood) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showMealLoggingForm(editableFoods);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Edited Items'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build editable food card for chat screen
  Widget _buildEditableFoodCard(FoodItem food, int index, Function(FoodItem) onUpdate) {
    final nameController = TextEditingController(text: food.name);
    final quantityController = TextEditingController(text: food.quantity);
    final caloriesController = TextEditingController(text: food.calories.toString());
    final proteinController = TextEditingController(text: food.protein.toString());
    final carbsController = TextEditingController(text: food.carbs.toString());
    final fatController = TextEditingController(text: food.fat.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (value) {
                    onUpdate(food.copyWith(quantity: value));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final calories = double.tryParse(value) ?? 0.0;
                    onUpdate(food.copyWith(calories: calories));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show meal logging form with optional pre-filled data
  void _showMealLoggingForm(List<FoodItem> recognizedFoods) {
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
          initialFoods: recognizedFoods,
          initialMealType: FoodRecognitionService.suggestMealType(),
          onSubmit: (meal) async {
            await nutritionStore.addMealEntry(meal);

            // Add success message to chat
            final successMessage = QuestionImageAnswerModel(
              question: 'Meal logged successfully!',
              imageUri: '',
              answer: StringBuffer('✅ Great! I\'ve logged your ${meal.mealType} with ${meal.foods.length} food item(s). Total calories: ${meal.foods.fold(0.0, (sum, food) => sum + food.calories).toInt()} cal'),
              isLoading: false,
              smartCompose: ''
            );

            setState(() {
              questionAnswers.insert(0, successMessage);
              selectedMealImage = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meal logged successfully! 🍽️'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Show meal logging form directly (without image requirement)
  void _showDirectMealLoggingForm() {
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

            // Add success message to chat
            final successMessage = QuestionImageAnswerModel(
              question: 'Meal logged successfully!',
              imageUri: '',
              answer: StringBuffer('✅ Great! I\'ve logged your ${meal.mealType} with ${meal.foods.length} food item(s). Total calories: ${meal.foods.fold(0.0, (sum, food) => sum + food.calories).toInt()} cal'),
              isLoading: false,
              smartCompose: ''
            );

            setState(() {
              questionAnswers.insert(0, successMessage);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meal logged successfully! 🍽️'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Log Meal with Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or choose from gallery',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Camera',
                    subtitle: 'Take a photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMealImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library_rounded,
                    title: 'Gallery',
                    subtitle: 'Choose photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMealImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendAutoFirstMsg(String? questions) async {
    isLoading = true;

    hideKeyboard(context);
    showResponse = true;
    questionAnswers.insert(0, QuestionImageAnswerModel(
      question: '',
      imageUri: imageSelected,
      answer: StringBuffer(),
      isLoading: true,
      smartCompose: selectedText
    ));
    setState(() {});

    try {
      // Create user profile from stored data
      final profile = UserProfile(
        name: userStore.fName,
        age: int.tryParse(userStore.age.validate()),
        gender: userStore.gender,
        weight: double.tryParse(userStore.weight.validate()),
        height: double.tryParse(userStore.height.validate()),
        goal: userStore.goal.isNotEmpty ? userStore.goal : 'general_fitness',
        exerciseDuration: 30, // Default 30 minutes
        diseases: [], // Add if you have disease data
        dietaryPreferences: [], // Add if you have dietary preference data
        isSmoker: false, // Add if you have smoking data
      );

      // Get today's meals for context (not just recent meals from any date)
      final recentMeals = nutritionStore.todayMeals;

      // Generate personalized workout plan
      final response = await generateMealPlan(profile, recentMeals);

      // Update the answer
      questionAnswers[0].answer = StringBuffer(response);

    } catch (e) {
      print('AI Service Error in auto message: $e');
      // Fallback response
      questionAnswers[0].answer = StringBuffer(
        '''Welcome to your personalized fitness journey! 🏋️‍♀️

Based on your profile, I'm here to help you with:
• Customized workout plans
• Nutrition and meal planning
• Exercise form and technique
• Progress tracking and motivation

What would you like to start with today?'''
      );
    }

    await setFirstTimeOpen(isFirstTime = true);
    print("------------------>>>>$isFirstTime");
    isFirstTime = await getFirstTimeOpen();
    print("------------------>>>>----$isFirstTime");

    isLoading = false;
    questionAnswers[0].isLoading = false;
    showResponse = false;
    setState(() {});
  }

  void sendMessage() async {
    print('🚀🚀🚀 sendMessage() called');
    showResponse = true;
    isLoading = true;
    hideKeyboard(context);

    if (selectedText.isNotEmpty) {
      question = selectedText + msgController.text;
      setState(() {});
    } else {
      question = msgController.text;
      setState(() {});
    }

    msgController.clear();
    questionAnswers.insert(0, QuestionImageAnswerModel(
      question: question,
      imageUri: imageSelected,
      answer: StringBuffer(),
      isLoading: true,
      smartCompose: selectedText
    ));

    setState(() {});

    try {
      // Create user profile from stored data
      final profile = UserProfile(
        name: userStore.fName,
        age: int.tryParse(userStore.age.validate()),
        gender: userStore.gender,
        weight: double.tryParse(userStore.weight.validate()),
        height: double.tryParse(userStore.height.validate()),
        goal: userStore.goal.isNotEmpty ? userStore.goal : 'general_fitness',
        exerciseDuration: 30, // Default 30 minutes
        diseases: [], // Add if you have disease data
        dietaryPreferences: [], // Add if you have dietary preference data
        isSmoker: false, // Add if you have smoking data
      );

      // Get today's meals for context (not just recent meals from any date)
      final recentMeals = nutritionStore.todayMeals;
      final mealContext = recentMeals.isNotEmpty
          ? '\n\nRecent meals: ${recentMeals.map((m) => '${m.mealType}: ${m.foods.map((f) => f.name).join(', ')}').take(3).join('; ')}'
          : '';

      // Prepare messages for AI
      final messages = [
        CoreMessage(
          role: 'system',
          content: '''You are IRA, a professional fitness and health AI assistant. You specialize in:
- Workout planning and exercise guidance
- Nutrition and diet advice
- Health and wellness recommendations
- Body composition and fitness goals
- Yoga and mindfulness practices
- General health questions

User Profile:
- Name: ${profile.name ?? 'User'}
- Age: ${profile.age ?? 'Unknown'}, Gender: ${profile.gender ?? 'Unknown'}
- Weight: ${profile.weight ?? 'Unknown'}kg, Height: ${profile.height ?? 'Unknown'}cm
- Goal: ${profile.goal.replaceAll('_', ' ')}
- Exercise Duration: ${profile.exerciseDuration} minutes/day$mealContext

Always provide helpful, accurate, and personalized advice based on the user's profile, goals, and recent eating habits. Address the user by name when appropriate and reference their specific goals and recent meals when relevant.'''
        ),
        CoreMessage(
          role: 'user',
          content: imageSelected.isNotEmpty
            ? '$question [Image provided: $imageSelected]'
            : question
        ),
      ];

      // Get AI response using RAG-enhanced service
      print('🚀🚀🚀 About to call chatWithAIRAG with question: "$question"');
      final response = await chatWithAIRAG(question, userProfile: profile, recentMeals: recentMeals);
      print('🚀🚀🚀 chatWithAIRAG returned response: "${response.substring(0, response.length > 100 ? 100 : response.length)}..."');

      // Update the answer
      questionAnswers[0].answer = StringBuffer(response);

      // Save conversation to API
      setFitBotDataApiCall(question, response);

      // Clear image selection
      imageSelected = '';
      selectedImageIndex = -1;

    } catch (e) {
      print('AI Service Error: $e');
      // Fallback response
      questionAnswers[0].answer = StringBuffer(
        'I\'m here to help with your fitness journey! You can ask me about workouts, nutrition, meal plans, or general health advice. What would you like to know?'
      );
    }

    isLoading = false;
    questionAnswers[0].isLoading = false;
    showResponse = false;
    setState(() {});
  }



  void showClearDialog() {
    showConfirmDialogCustom(
      context,
      title: languages.lblChatConfirmMsg,
      positiveText: languages.lblYes,
      positiveTextColor: Colors.white,
      image: ic_logo,
      negativeText: languages.lblNo,
      dialogType: DialogType.CONFIRMATION,
      onAccept: (p0) {
        deleteFitBotDataApiCall();
      },
    );
  }

  void share(BuildContext context, {required List<QuestionImageAnswerModel> questionAnswers, RenderBox? box}) {
    String getFinalString = questionAnswers.map((e) => "Q: ${e.question}\nChatGPT: ${e.answer.toString().trim()}\n\n").join(' ');
    Share.share(getFinalString, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  void dispose() {
    msgController.dispose();
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Changed to false for manual control
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + MediaQuery.of(context).padding.top + 16),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          color: Colors.white,
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: context.isMobile ? 30 : 40,
                  height: context.isMobile ? 30 : 40,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/2-removebg-preview.png',
                      width: context.isMobile ? 18 : 24,
                      height: context.isMobile ? 18 : 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: context.isMobile ? 12 : 16),
                Text(
                  "IRA AI",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: context.isMobile ? 18 : 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: Column(
          children: [
            // Today header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: context.isMobile ? 16 : 20,
                horizontal: context.isMobile ? 16 : 24,
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile ? 16 : 20,
                    vertical: context.isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(context.isMobile ? 20 : 24),
                  ),
                  child: Text(
                    "Today",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: context.isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Chat content
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
            Container(
              height: context.height(),
              width: context.width(),
              margin: EdgeInsets.only(
                bottom: (context.isMobile ? 100 : 120) + keyboardHeight + (isShowOption ? 50 : 0)
              ),
              padding: EdgeInsets.only(
                left: context.isMobile ? 16 : 24,
                right: context.isMobile ? 16 : 24,
              ),
            child: ListView.separated(
              separatorBuilder: (_, i) => const Divider(color: Colors.transparent),
              reverse: true,
              padding: EdgeInsets.only(
                bottom: context.isMobile ? 20 : 24,
                top: context.isMobile ? 16 : 20,
              ),
              controller: scrollController,
              itemCount: questionAnswers.length,
              itemBuilder: (_, index) {
                QuestionImageAnswerModel data = questionAnswers[index];
                return ChatMessageImageWidget(answer: data.answer.toString().trim(), data: data, isLoading: data.isLoading.validate(), firstQuestion: firstQuestion);
              },
            ),
          ),
          // Enterprise typing indicator
          if (isLoading == true)
            Positioned(
              bottom: context.isMobile ? 120 : 140,
              left: context.isMobile ? 16 : 24,
              right: context.isMobile ? 16 : 24,
              child: EnterpriseTypingIndicator(
                isVisible: isLoading == true,
                userName: languages.lblFitBot,
              ),
            ),

       if (questionAnswers.validate().isEmpty)
            ChatBotEmptyScreen(
                isScroll: isScroll,
                onTap: (value) {
                  msgController.text = value;
                  setState(() {});
                }).center(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: keyboardHeight + bottomPadding + (context.isMobile ? 10 : 16),
                top: context.isMobile ? 16 : 20,
                left: context.isMobile ? 16 : 24,
                right: context.isMobile ? 16 : 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.isMobile ? 24 : 32),
                  topRight: Radius.circular(context.isMobile ? 24 : 32),
                ),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.05),
                    blurRadius: 60,
                    offset: const Offset(0, -16),
                  ),
                ],
              ),
              child: showResponse == false
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(context.isMobile ? 25 : 30),
                            ),
                            child: Row(
                              children: [
                                // Text field
                                Expanded(
                                  child: TextField(
                                    controller: msgController,
                                    minLines: 1,
                                    maxLines: 3,
                                    cursorColor: primaryColor,
                                    keyboardType: TextInputType.multiline,
                                    style: TextStyle(
                                      fontSize: context.isMobile ? 16 : 18,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Ask anything here..",
                                      hintStyle: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: context.isMobile ? 16 : 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: context.isMobile ? 16 : 20,
                                        vertical: context.isMobile ? 12 : 16,
                                      ),
                                    ),
                                    onSubmitted: (s) {
                                      sendMessage();
                                    },
                                    onTap: () {
                                      isScroll = true;
                                      setState(() {});
                                      // Auto scroll to bottom when keyboard appears
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (scrollController.hasClients) {
                                          scrollController.animateTo(
                                            scrollController.position.maxScrollExtent,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: context.isMobile ? 12 : 16),
                        // Enhanced floating send button
                        Container(
                          width: context.isMobile ? 48 : 56,
                          height: context.isMobile ? 48 : 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB39DDB),
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(context.isMobile ? 24 : 28),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(context.isMobile ? 24 : 28),
                              onTap: () {
                                if (msgController.text.isNotEmpty) {
                                  sendMessage();
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(context.isMobile ? 24 : 28),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: context.isMobile ? 24 : 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button for Meal Logging
      floatingActionButton: Container(
        margin: EdgeInsets.only(
          bottom: context.isMobile ? 80 : 100,
          right: context.isMobile ? 0 : 16,
        ),
        child: FloatingActionButton.extended(
          onPressed: _showDirectMealLoggingForm,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: Icon(
            Icons.restaurant_menu,
            size: context.isMobile ? 20 : 24,
          ),
          label: Text(
            'Log Meal',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: context.isMobile ? 14 : 16,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.isMobile ? 16 : 20),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ), // AnnotatedRegion
    );
  }
}
