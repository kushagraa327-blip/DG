import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/text_styles.dart';
import '../extensions/app_button.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import 'signup_step_indicator.dart';

class SignUpStep3Component extends StatefulWidget {
  final bool? isNewTask;

  const SignUpStep3Component({super.key, this.isNewTask = false});

  @override
  _SignUpStep3ComponentState createState() => _SignUpStep3ComponentState();
}

class _SignUpStep3ComponentState extends State<SignUpStep3Component> {
  int mSelectedIndex = 25; // Default age
  late ScrollController _scrollController;
  final double itemWidth = 30.0; // Reduced width for more compact layout
  final int minAge = 15;
  final int maxAge = 100;
  Timer? _scrollTimer;

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
        _updateSelectedAge();
      }
    });
  }

  init() async {
    if (!userStore.age.isEmptyOrNull) {
      mSelectedIndex = int.parse(userStore.age.validate());
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize scroll position after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToAge(mSelectedIndex);
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

  void _scrollToAge(int age) {
    if (_scrollController.hasClients && mounted) {
      double screenWidth = MediaQuery.of(context).size.width;
      double leftPadding = screenWidth / 2 - itemWidth / 2;
      
      // Calculate the target offset to center the selected age
      double targetOffset = (age - minAge) * itemWidth;
      
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
  
  void _updateSelectedAge() {
    if (_scrollController.hasClients && mounted) {
      double offset = _scrollController.offset;
      double screenWidth = MediaQuery.of(context).size.width;
      
      // Calculate which age is at the center pointer
      // The center of the screen relative to the scrollable content
      double centerPositionInContent = offset + (screenWidth / 2);
      
      // Account for the left padding
      double leftPadding = screenWidth / 2 - itemWidth / 2;
      double adjustedPosition = centerPositionInContent - leftPadding;
      
      // Calculate the age index
      int newSelectedIndex = minAge + (adjustedPosition / itemWidth).round();
      
      // Clamp to valid range
      newSelectedIndex = newSelectedIndex.clamp(minAge, maxAge);
      
      if (newSelectedIndex != mSelectedIndex && mounted) {
        setState(() {
          mSelectedIndex = newSelectedIndex;
        });
      }
    }
  }
  
  void _snapToNearestAge() {
    _scrollToAge(mSelectedIndex);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFE8F6), // Updated background color
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
                    child: SignUpStepIndicator(currentStep: 3),
                  ),
                  20.height,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(languages.lblHowOld, style: boldTextStyle(size: 30).copyWith(fontFamily: 'Inter')),
                  ),
                  40.height,
                  
                  // Age display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          mSelectedIndex.toString(),
                          style: boldTextStyle(size: 48, color: primaryColor).copyWith(fontFamily: 'Inter'),
                        ),
                        8.height,
                        
                      ],
                    ),
                  ),
                  
                  40.height,
                  
                  // Horizontal Age Ruler - Fixed Ruler Design
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
                              _updateSelectedAge();
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
                                  ...List.generate(maxAge - minAge + 1, (index) {
                                    int age = minAge + index;
                                    bool isSelected = age == mSelectedIndex;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          mSelectedIndex = age;
                                        });
                                        _scrollToAge(age);
                                      },
                                      child: SizedBox(
                                        width: itemWidth,
                                        height: 60,
                                        child: Column(
                                          children: [
                                            // Age number
                                            SizedBox(
                                              height: 20,
                                              child: Text(
                                                age.toString(),
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
                                              height: age % 5 == 0 ? 30 : 20, // Longer lines for multiples of 5
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
                  "Great Start!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                ),
                12.height,
                const Text(
                  "Your age helps us personalize\nyour dietary recommendations for\noptimal health.",
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
                        userStore.setAge(mSelectedIndex.toString());
                        appStore.signUpIndex = 3;
                        setState(() {});
                      },
                      child: const Center(
                        child: Text(
                          "Get My Plan",
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
