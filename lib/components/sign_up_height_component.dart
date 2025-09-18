import 'package:flutter/material.dart';
import 'dart:async';
import '../../extensions/loader_widget.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../main.dart';
import '../extensions/text_styles.dart';
import 'signup_step_indicator.dart';
import '../utils/app_colors.dart';

class SignUpHeightComponent extends StatefulWidget {
  const SignUpHeightComponent({super.key});

  @override
  _SignUpHeightComponentState createState() => _SignUpHeightComponentState();
}

class _SignUpHeightComponentState extends State<SignUpHeightComponent> with TickerProviderStateMixin {
  int mSelectedHeight = 170; // Default height in cm
  late ScrollController _scrollController;
  final double itemWidth = 30.0; // Width for height ruler items
  final int minHeight = 120;
  final int maxHeight = 220;
  Timer? _scrollTimer;
  String heightUnit = 'cm';
  bool isCM = true;

  // For feet representation
  final int minHeightFt = 48; // 4'0" in inches
  final int maxHeightFt = 120; // 10'0" in inches
  int mSelectedHeightInches = 68; // Default 5'8" in inches

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
        _updateSelectedHeight();
      }
    });
  }

  init() async {
    if (!userStore.height.isEmptyOrNull) {
      int storedHeight = int.parse(userStore.height.validate().split(' ')[0]);
      mSelectedHeight = storedHeight;
      // Convert cm to inches for ft mode
      mSelectedHeightInches = (storedHeight * 0.393701).round();
    }
    if (!userStore.heightUnit.isEmptyOrNull) {
      heightUnit = userStore.heightUnit.validate();
      isCM = heightUnit == 'cm';
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize scroll position after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToHeight(mSelectedHeight);
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

  void _scrollToHeight(int height) {
    if (_scrollController.hasClients && mounted) {
      double screenWidth = MediaQuery.of(context).size.width;
      double leftPadding = screenWidth / 2 - itemWidth / 2;
      
      double targetOffset;
      
      if (isCM) {
        // Calculate the target offset to center the selected height (CM mode)
        targetOffset = (height - minHeight) * itemWidth;
      } else {
        // Calculate the target offset to center the selected height (FT mode)
        // Convert cm height to inches first
        int heightInInches = (height * 0.393701).round();
        targetOffset = (heightInInches - minHeightFt) * itemWidth;
      }
      
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
  
  void _updateSelectedHeight() {
    if (_scrollController.hasClients && mounted) {
      double offset = _scrollController.offset;
      double screenWidth = MediaQuery.of(context).size.width;
      
      // Calculate which height is at the center pointer
      // The center of the screen relative to the scrollable content
      double centerPositionInContent = offset + (screenWidth / 2);
      
      // Account for the left padding
      double leftPadding = screenWidth / 2 - itemWidth / 2;
      double adjustedPosition = centerPositionInContent - leftPadding;
      
      if (isCM) {
        // Calculate the height index for CM mode
        int newSelectedHeight = minHeight + (adjustedPosition / itemWidth).round();
        
        // Clamp to valid range
        newSelectedHeight = newSelectedHeight.clamp(minHeight, maxHeight);
        
        if (newSelectedHeight != mSelectedHeight && mounted) {
          setState(() {
            mSelectedHeight = newSelectedHeight;
            // Update inches equivalent
            mSelectedHeightInches = (newSelectedHeight * 0.393701).round();
          });
        }
      } else {
        // Calculate the height index for FT mode
        int newSelectedHeightInches = minHeightFt + (adjustedPosition / itemWidth).round();
        
        // Clamp to valid range
        newSelectedHeightInches = newSelectedHeightInches.clamp(minHeightFt, maxHeightFt);
        
        if (newSelectedHeightInches != mSelectedHeightInches && mounted) {
          setState(() {
            mSelectedHeightInches = newSelectedHeightInches;
            // Update cm equivalent
            mSelectedHeight = (newSelectedHeightInches * 2.54).round();
          });
        }
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String _getDisplayHeight() {
    if (isCM) {
      return mSelectedHeight.toString();
    } else {
      // Use the mSelectedHeightInches for accurate display
      int feet = mSelectedHeightInches ~/ 12;
      int inches = mSelectedHeightInches % 12;
      return "$feet'$inches\"";
    }
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
                    child: SignUpStepIndicator(currentStep: 4),
                  ),
                  20.height,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("What's Your Height?", style: boldTextStyle(size: 30).copyWith(fontFamily: 'Inter')),
                  ),
                  40.height,
                  
                  // Description text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Share your height to receive accurate and relevant dietary tips.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  
                  20.height,
                  
                  // Height display
                  Center(
                    child: Column(
                      children: [
                        // Height unit toggle (moved above the value)
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
                                    isCM = true;
                                    heightUnit = 'cm';
                                    // Sync values when switching to CM
                                    mSelectedHeight = (mSelectedHeightInches * 2.54).round();
                                  });
                                  // Scroll to the new position
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _scrollToHeight(mSelectedHeight);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCM ? Colors.black : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'cm',
                                    style: TextStyle(
                                      color: isCM ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isCM = false;
                                    heightUnit = 'ft';
                                    // Sync values when switching to FT
                                    mSelectedHeightInches = (mSelectedHeight * 0.393701).round();
                                  });
                                  // Scroll to the new position
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _scrollToHeight(mSelectedHeight);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isCM ? Colors.black : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'ft',
                                    style: TextStyle(
                                      color: !isCM ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        20.height,
                        
                        // Height value with unit in green
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: isCM ? mSelectedHeight.toString() : "${mSelectedHeightInches ~/ 12}'${mSelectedHeightInches % 12}\"",
                                style: boldTextStyle(size: 48, color: Colors.green).copyWith(fontFamily: 'Inter'),
                              ),
                              TextSpan(
                                text: isCM ? " cm" : "ft",
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  40.height,
                  
                  // Horizontal Height Ruler - Fixed Ruler Design
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
                              _updateSelectedHeight();
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
                                  ...List.generate(isCM ? (maxHeight - minHeight + 1) : (maxHeightFt - minHeightFt + 1), (index) {
                                    if (isCM) {
                                      // CM mode: show cm values
                                      int height = minHeight + index;
                                      bool isSelected = height == mSelectedHeight;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            mSelectedHeight = height;
                                          });
                                          _scrollToHeight(height);
                                        },
                                        child: SizedBox(
                                          width: itemWidth,
                                          height: 60,
                                          child: Column(
                                            children: [
                                              // Height number (show every 5cm)
                                              SizedBox(
                                                height: 20,
                                                child: height % 5 == 0 ? Text(
                                                  height.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                    color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[600],
                                                    fontFamily: 'Inter',
                                                  ),
                                                ) : const SizedBox(),
                                              ),
                                              
                                              const SizedBox(height: 4),
                                              
                                              // Tick mark/ruler line
                                              Container(
                                                width: 1.5,
                                                height: height % 10 == 0 ? 30 : (height % 5 == 0 ? 25 : 15), // Different heights for different intervals
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
                                    } else {
                                      // FT mode: show feet and inches
                                      int totalInches = minHeightFt + index;
                                      int feet = totalInches ~/ 12;
                                      int inches = totalInches % 12;
                                      bool isSelected = totalInches == mSelectedHeightInches;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            mSelectedHeightInches = totalInches;
                                            // Convert to cm for storage
                                            mSelectedHeight = (totalInches * 2.54).round();
                                          });
                                          _scrollToHeight(mSelectedHeight);
                                        },
                                        child: SizedBox(
                                          width: itemWidth,
                                          height: 60,
                                          child: Column(
                                            children: [
                                              // Height number (show at feet and half-feet)
                                              SizedBox(
                                                height: 20,
                                                child: inches == 0 ? Text(
                                                  "$feet'",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                    color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[600],
                                                    fontFamily: 'Inter',
                                                  ),
                                                ) : (inches == 6 ? Text(
                                                  "$feet'6\"",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w400,
                                                    color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[500],
                                                    fontFamily: 'Inter',
                                                  ),
                                                ) : const SizedBox()),
                                              ),
                                              
                                              const SizedBox(height: 4),
                                              
                                              // Tick mark/ruler line
                                              Container(
                                                width: 1.5,
                                                height: inches == 0 ? 30 : (inches == 6 ? 25 : 15), // Different heights for feet, half-feet, and inches
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
                                    }
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
            child: const Column(
              children: [
              ],
            ),
          ),
          
          // Continue button fixed at bottom
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
                      onTap: () async {
                        userStore.setHeight(mSelectedHeight.toString());
                        userStore.setHeightUnit(heightUnit);
                        appStore.signUpIndex = 4;
                        setState(() {});
                      },
                      child: const Center(
                        child: Text(
                          "Ge my plan",
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
