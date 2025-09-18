import 'package:flutter/material.dart';
import 'package:mighty_fitness/widget/weight_widget.dart';
import 'dart:async';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../main.dart';
import '../extensions/text_styles.dart';
import 'signup_step_indicator.dart';
import '../utils/app_colors.dart';

class SignUpStep4Component extends StatefulWidget {
  const SignUpStep4Component({super.key});

  @override
  _SignUpStep4ComponentState createState() => _SignUpStep4ComponentState();
}

class _SignUpStep4ComponentState extends State<SignUpStep4Component> with TickerProviderStateMixin {
  int mSelectedWeight = 70; // Default weight in kg
  late ScrollController _scrollController;
  final double itemWidth = 30.0; // Width for weight ruler items
  final int minWeight = 30;
  final int maxWeight = 200;
  Timer? _scrollTimer;
  WeightType weightType = WeightType.kg;
  String weightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    init();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollListener);
  }

  void _onScrollListener() {
    // Cancel previous timer
    _scrollTimer?.cancel();
    
    // Start new timer to detect when scrolling stops
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _updateSelectedWeight();
      }
    });
  }

  init() async {
    if (!userStore.weight.isEmptyOrNull) {
      mSelectedWeight = int.parse(userStore.weight.validate().split(' ')[0]);
    }
    if (!userStore.weightUnit.isEmptyOrNull) {
      weightUnit = userStore.weightUnit.validate();
      weightType = weightUnit == 'kg' ? WeightType.kg : WeightType.lb;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize scroll position after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToWeight(mSelectedWeight);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.removeListener(_onScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToWeight(int weightValue) {
    if (_scrollController.hasClients && mounted) {
      double screenWidth = MediaQuery.of(context).size.width;
      double leftPadding = screenWidth / 2 - itemWidth / 2;
      
      // Calculate the target offset to center the selected weight
      double targetOffset = (weightValue - minWeight) * itemWidth;
      
      // Clamp to valid scroll range
      double maxOffset = _scrollController.position.maxScrollExtent;
      targetOffset = targetOffset.clamp(0.0, maxOffset);
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _updateSelectedWeight() {
    if (_scrollController.hasClients && mounted) {
      double offset = _scrollController.offset;
      double screenWidth = MediaQuery.of(context).size.width;
      
      // Calculate which weight is at the center pointer
      // The center of the screen relative to the scrollable content
      double centerPositionInContent = offset + (screenWidth / 2);
      
      // Account for the left padding
      double leftPadding = screenWidth / 2 - itemWidth / 2;
      double adjustedPosition = centerPositionInContent - leftPadding;
      
      // Calculate the weight index
      int newSelectedWeight = minWeight + (adjustedPosition / itemWidth).round();
      
      // Clamp to valid range
      newSelectedWeight = newSelectedWeight.clamp(minWeight, maxWeight);
      
      if (newSelectedWeight != mSelectedWeight && mounted) {
        setState(() {
          mSelectedWeight = newSelectedWeight;
        });
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // color: Color(0xFFEEF0F4), // Updated background color
      child: Column(
        children: [
          // Main content - scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SignUpStepIndicator(currentStep: 5),
                  ),
                  20.height,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("What's Your Weight?", style: boldTextStyle(size: 30).copyWith(fontFamily: 'Inter')),
                  ),
                  40.height,
                  
                  // Weight display
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: mSelectedWeight.toString(),
                                style: boldTextStyle(size: 48, color: primaryColor).copyWith(fontFamily: 'Inter'),
                              ),
                              TextSpan(
                                text: weightType == WeightType.kg ? " kg" : " lbs",
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        8.height,
                        // Weight unit toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    weightType = WeightType.kg;
                                    weightUnit = 'kg';
                                    if (mSelectedWeight > 200) mSelectedWeight = 200;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: weightType == WeightType.kg ? Colors.black : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'kg',
                                    style: TextStyle(
                                      color: weightType == WeightType.kg ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    weightType = WeightType.lb;
                                    weightUnit = 'lbs';
                                    if (mSelectedWeight > 400) mSelectedWeight = 400;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: weightType == WeightType.lb ? Colors.black : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'lbs',
                                    style: TextStyle(
                                      color: weightType == WeightType.lb ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  40.height,
                  
                  // Horizontal Weight Ruler - Fixed Ruler Design
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    height: 100,
                    child: Stack(
                      children: [
                        // Scrollable ruler
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (notification is ScrollUpdateNotification || notification is ScrollEndNotification) {
                              _updateSelectedWeight();
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              height: 60,
                              child: Row(
                                children: [
                                  // Left padding to center the first item
                                  SizedBox(width: MediaQuery.of(context).size.width / 2 - itemWidth / 2),
                                  
                                  // Generate ruler with numbers and tick marks
                                  ...List.generate(maxWeight - minWeight + 1, (index) {
                                    int weight = minWeight + index;
                                    bool isSelected = weight == mSelectedWeight;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          mSelectedWeight = weight;
                                        });
                                        _scrollToWeight(weight);
                                      },
                                      child: SizedBox(
                                        width: itemWidth,
                                        height: 60,
                                        child: Column(
                                          children: [
                                            // Weight number
                                            SizedBox(
                                              height: 20,
                                              child: Text(
                                                weight.toString(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[600],
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 4),
                                            
                                            // Tick mark/ruler line
                                            Container(
                                              width: 1.5,
                                              height: weight % 10 == 0 ? 30 : 20, // Longer lines for multiples of 10
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? const Color(0xFF6B46C1)
                                                    : Colors.grey[400],
                                                borderRadius: BorderRadius.circular(0.75),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  
                                  // Right padding to center the last item
                                  SizedBox(width: MediaQuery.of(context).size.width / 2 - itemWidth / 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Fixed center pointer/indicator line
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 1,
                          top: 24,
                          child: Container(
                            width: 2,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B46C1), // Purple color matching the theme
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        
                        // Purple triangle pointer at top
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 4,
                          top: 20,
                          child: CustomPaint(
                            size: const Size(8, 6),
                            painter: TrianglePainter(color: const Color(0xFF6B46C1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  40.height,
                ],
              ),
            ),
          ),
          
          // Great Start section with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFE8D5FF).withOpacity(0.0),
                  const Color(0xFFE8D5FF).withOpacity(0.3),
                  const Color(0xFFE8D5FF).withOpacity(0.6),
                ],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Almost There!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                ),
                12.height,
                const Text(
                  "Your weight helps us calculate\nyour daily nutritional needs and\noptimal meal portions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          
          // Next button fixed at bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: context.width(),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        userStore.setWeight(mSelectedWeight.toString());
                        userStore.setWeightUnit(weightUnit);
                        appStore.signUpIndex = 5;
                        setState(() {});
                      },
                      child: const Center(
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                12.height,
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  
  TrianglePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, 0) // Top center
      ..lineTo(0, size.height) // Bottom left
      ..lineTo(size.width, size.height) // Bottom right
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
