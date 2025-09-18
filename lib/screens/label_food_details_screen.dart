import 'package:flutter/material.dart';
import 'dart:io';
import '../models/meal_entry_model.dart';
import '../services/food_recognition_service.dart';

class LabelFoodDetailsScreen extends StatefulWidget {
  final FoodItem foodItem;
  final String imagePath;

  const LabelFoodDetailsScreen({
    super.key,
    required this.foodItem,
    required this.imagePath,
  });

  @override
  _LabelFoodDetailsScreenState createState() => _LabelFoodDetailsScreenState();
}

class _LabelFoodDetailsScreenState extends State<LabelFoodDetailsScreen> {
  late FoodItem _foodItem;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _foodItem = widget.foodItem;
    _analyzeLabel();
  }

  Future<void> _analyzeLabel() async {
    try {
      final analyzedFoods = await FoodRecognitionService.analyzeLabelImage(File(widget.imagePath));
      if (analyzedFoods.isNotEmpty) {
        setState(() {
          _foodItem = analyzedFoods.first;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getHealthAssessment(int score) {
    if (score >= 80) return 'Excellent Choice';
    if (score >= 60) return 'Good Choice';
    if (score >= 40) return 'Moderate Choice';
    return 'Not Recommended';
  }

  Widget _nutrientCard(String label, num? value, String unit, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value != null ? '${value.toStringAsFixed(1)}$unit' : 'N/A',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top image (show captured image)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                image: DecorationImage(
                  image: widget.imagePath.isNotEmpty ? FileImage(File(widget.imagePath)) : const AssetImage('assets/placeholder.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Analysis status
                    if (_isAnalyzing)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Analyzing nutrition label...',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Nutrition title
                    const Text(
                      'Nutrition Facts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Food name (if available)
                    if (_foodItem.name.isNotEmpty)
                      Text(
                        _foodItem.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                    const SizedBox(height: 16),
                    // Health score bar with assessment
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, 
                                color: _getHealthScoreColor(_foodItem.healthScore ?? 0),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Health Score',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (_foodItem.healthScore ?? 0) / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getHealthScoreColor(_foodItem.healthScore ?? 0),
                              ),
                              minHeight: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _getHealthAssessment(_foodItem.healthScore ?? 0),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _getHealthScoreColor(_foodItem.healthScore ?? 0),
                                  ),
                                ),
                              ),
                              Text(
                                '${_foodItem.healthScore ?? 0}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nutrient cards in rows
                    Row(
                      children: [
                        _nutrientCard('Calories', _foodItem.calories, ' kcal', Colors.green[100]!, Colors.green[900]!),
                        const SizedBox(width: 8),
                        _nutrientCard('Protein', _foodItem.protein, 'g', Colors.blue[100]!, Colors.blue[900]!),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _nutrientCard('Carbs', _foodItem.carbs, 'g', Colors.yellow[100]!, Colors.orange[900]!),
                        const SizedBox(width: 8),
                        _nutrientCard('Fat', _foodItem.fat, 'g', Colors.red[100]!, Colors.red[900]!),
                      ],
                    ),
                    ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _nutrientCard('Fiber', _foodItem.fiber, 'g', Colors.purple[100]!, Colors.purple[900]!),
                        Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                    const SizedBox(height: 16),
                    // AI Analysis Section
                    FutureBuilder<String>(
                      future: FoodRecognitionService.generateNutritionAnalysis({
                        'calories': _foodItem.calories,
                        'protein': _foodItem.protein,
                        'carbs': _foodItem.carbs,
                        'fat': _foodItem.fat,
                        'fiber': _foodItem.fiber ?? 0,
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Generating insights...',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "IRA's Insight",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.data ?? 'Analyzing nutritional content...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
