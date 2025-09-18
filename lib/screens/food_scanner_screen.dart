import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../components/log_meal_form_component.dart';
import '../models/meal_entry_model.dart';
import '../services/food_recognition_service.dart';
import '../main.dart';
import 'label_food_details_screen.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  _FoodScannerScreenState createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  XFile? _image;
  String analysisResult = '';
  bool _isAnalyzing = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _cameraController = CameraController(
        cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureFood() async {
    if (_isCameraInitialized && _cameraController != null) {
      try {
        final XFile image = await _cameraController!.takePicture();
        setState(() {
          _image = image;
          _isAnalyzing = true;
          _capturedImage = image;
        });

        final bytes = await File(image.path).readAsBytes();
        final original = img.decodeImage(bytes);
        if (original == null) return;

        final boxWidth = (original.width * 0.8).toInt();
        final boxHeight = (original.height * 0.4).toInt();
        final boxLeft = ((original.width - boxWidth) ~/ 2).toInt();
        final boxTop = ((original.height - boxHeight) ~/ 2).toInt();

        final cropped = img.copyCrop(
          original,
          x: boxLeft,
          y: boxTop,
          width: boxWidth,
          height: boxHeight,
        );
        final croppedPath = image.path.replaceFirst('.jpg', '_cropped.jpg');
        await File(croppedPath).writeAsBytes(img.encodeJpg(cropped));

        // Perform analysis without showing dialog
        try {
          final foods = await FoodRecognitionService.analyzeFoodImage(File(croppedPath));
          
          setState(() {
            _isAnalyzing = false;
            _capturedImage = null;
          });
          
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            builder: (context) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: LogMealFormComponent(
                  onSubmit: (mealEntry) async {
                    final combinedName = mealEntry.foods.isNotEmpty ? mealEntry.foods.first.name : 'Scanned Dish';
                    final now = DateTime.now();
                    final localDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                    final combinedMeal = MealEntry(
                      id: now.millisecondsSinceEpoch.toString(),
                      date: localDate,
                      mealType: mealEntry.mealType,
                      foods: mealEntry.foods,
                      timestamp: now,
                      notes: 'Combined dish: $combinedName',
                    );
                    await nutritionStore.addMealEntry(combinedMeal);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meal logged successfully! 🍽️'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  initialFoods: foods.isNotEmpty
                      ? foods.map((food) => FoodItem(
                          id: food.id,
                          name: food.name,
                          quantity: food.quantity,
                          calories: food.calories,
                          protein: food.protein,
                          carbs: food.carbs,
                          fat: food.fat,
                          imagePath: croppedPath,
                        )).toList()
                      : [
                          FoodItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: '',
                            quantity: '1',
                            calories: 0,
                            protein: 0,
                            carbs: 0,
                            fat: 0,
                            imagePath: croppedPath,
                          ),
                        ],
                ),
              );
            },
          ).then((_) {
            // Reset analyzing state when modal is dismissed
            setState(() {
              _isAnalyzing = false;
              _capturedImage = null;
            });
          });
        } catch (e) {
          setState(() {
            _isAnalyzing = false;
            _capturedImage = null;
          });
          
          // Show error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Analysis Error'),
              content: const Text('Could not analyze food image. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isAnalyzing = false;
          _capturedImage = null;
        });
        // Handle error
      }
    }
  }

  Future<void> _scanLabel() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _image = image;
        });

        // Create a basic food item to pass to the details screen
        // The actual analysis will happen in the details screen
        final FoodItem foodItem = FoodItem(
          id: DateTime.now().toString(),
          name: 'Analyzing...',
          quantity: '1 serving',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: 0,
          healthScore: 50,
          imagePath: image.path,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LabelFoodDetailsScreen(
              foodItem: foodItem,
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing label: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _manualInput() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: LogMealFormComponent(
            onSubmit: (mealEntry) async {
              final combinedName = mealEntry.foods.isNotEmpty ? mealEntry.foods.first.name : 'Manual Dish';
              final now = DateTime.now();
              final localDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
              final combinedMeal = MealEntry(
                id: now.millisecondsSinceEpoch.toString(),
                date: localDate,
                mealType: mealEntry.mealType,
                foods: mealEntry.foods,
                timestamp: now,
                notes: 'Manual dish: $combinedName',
              );
              await nutritionStore.addMealEntry(combinedMeal);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meal logged successfully! 🍽️'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _pickFromLibrary() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return FutureBuilder<List<FoodItem>>(
            future: FoodRecognitionService.analyzeFoodImage(File(image.path)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('Analysis Error'),
                  content: const Text('Could not analyze food image. Please try again.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              } else {
                final foods = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    builder: (context) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: LogMealFormComponent(
                          onSubmit: (mealEntry) async {
                            final combinedName = mealEntry.foods.isNotEmpty ? mealEntry.foods.first.name : 'Gallery Dish';
                            final now = DateTime.now();
                            final localDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                            final combinedMeal = MealEntry(
                              id: now.millisecondsSinceEpoch.toString(),
                              date: localDate,
                              mealType: mealEntry.mealType,
                              foods: mealEntry.foods,
                              timestamp: now,
                              notes: 'Gallery dish: $combinedName',
                            );
                            await nutritionStore.addMealEntry(combinedMeal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Meal logged successfully! 🍽️'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          initialFoods: foods.isNotEmpty
                              ? foods.map((food) => FoodItem(
                                  id: food.id,
                                  name: food.name,
                                  quantity: food.quantity,
                                  calories: food.calories,
                                  protein: food.protein,
                                  carbs: food.carbs,
                                  fat: food.fat,
                                  imagePath: image.path,
                                )).toList()
                              : [
                                  FoodItem(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: '',
                                    quantity: '1',
                                    calories: 0,
                                    protein: 0,
                                    carbs: 0,
                                    fat: 0,
                                    imagePath: image.path,
                                  ),
                                ],
                        ),
                      );
                    },
                  );
                });
                return const SizedBox.shrink();
              }
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isAnalyzing && _capturedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.file(
                        File(_capturedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                  : _isCameraInitialized && _cameraController != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: CameraPreview(_cameraController!),
                        )
                      : Container(
                          color: Colors.black,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
            ),
            Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
            const Positioned(
              top: 32,
              left: 32,
              child: Text(
                'Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                ),
              ),
            ),
            Positioned(
              top: 32,
              right: 32,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildScannerButton(Icons.apple, 'Scan food', _isAnalyzing ? () {} : _captureFood, true),
                  _buildScannerButton(Icons.qr_code, 'Scan Label', _isAnalyzing ? () {} : _scanLabel, false),
                  _buildScannerButton(Icons.add, 'Manual', _isAnalyzing ? () {} : _manualInput, false),
                  _buildScannerButton(Icons.photo_library, 'Library', _isAnalyzing ? () {} : _pickFromLibrary, false),
                ],
              ),
            ),
            if (_isAnalyzing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7C6A)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Analyzing food...',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),       
              ),
            if (analysisResult.isNotEmpty)
              Positioned(
                top: 360,
                left: 32,
                right: 32,
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(analysisResult, style: const TextStyle(color: Colors.black)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerButton(IconData icon, String label, VoidCallback onTap, bool isActive) {
    final isDisabled = _isAnalyzing;
    return Column(
      children: [
        InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDisabled ? const Color(0xFFE0E0E0) : const Color(0xFFD6F3E6),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon, 
              color: isDisabled ? const Color(0xFF9E9E9E) : const Color(0xFF3A7C6A), 
              size: 32
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDisabled ? const Color(0xFF9E9E9E) : const Color(0xFF3A7C6A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 