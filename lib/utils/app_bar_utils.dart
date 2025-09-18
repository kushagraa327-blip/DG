import 'package:flutter/material.dart';
import '../extensions/responsive_utils.dart';
import '../extensions/extension_util/context_extensions.dart';

/// Utility class for consistent AppBar spacing across all screens
class AppBarUtils {
  
  /// Get enhanced top padding for screens with status bar consideration
  static double getEnhancedTopPadding(BuildContext context) {
    return context.statusBarHeight + ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 32.0,   // Increased from typical 16 for better spacing
      tablet: 40.0,   // More space for tablets
      desktop: 48.0,  // Maximum space for desktop
    );
  }

  /// Get enhanced AppBar height for PreferredSize
  static double getEnhancedAppBarHeight(BuildContext context, {bool isArabic = false}) {
    final baseHeight = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 110.0,   // Increased from typical 80-90
      tablet: 120.0,   // More height for tablets
      desktop: 130.0,  // Maximum height for desktop
    );
    
    // Add extra height for Arabic layout if needed
    return isArabic ? baseHeight + 10 : baseHeight;
  }

  /// Create a standardized AppBar with proper spacing
  static PreferredSizeWidget createEnhancedAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isArabic = false,
    VoidCallback? onLeadingPressed,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(getEnhancedAppBarHeight(context, isArabic: isArabic)),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            top: ResponsiveUtils.getResponsiveSpacing(context, 8),
            bottom: ResponsiveUtils.getResponsiveSpacing(context, 4),
          ),
          child: AppBar(
            backgroundColor: backgroundColor ?? Colors.transparent,
            foregroundColor: foregroundColor,
            elevation: 0,
            centerTitle: centerTitle,
            title: Text(title),
            leading: leading ?? (onLeadingPressed != null 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: onLeadingPressed,
                )
              : null),
            actions: actions,
          ),
        ),
      ),
    );
  }

  /// Get enhanced padding for custom header layouts (like profile screens)
  static EdgeInsets getCustomHeaderPadding(BuildContext context) {
    return EdgeInsets.only(
      top: getEnhancedTopPadding(context),
      left: ResponsiveUtils.getResponsiveSpacing(context, 16),
      right: ResponsiveUtils.getResponsiveSpacing(context, 16),
    );
  }

  /// Get enhanced spacing for screens without AppBar
  static double getScreenTopSpacing(BuildContext context) {
    return context.statusBarHeight + ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );
  }
}

/// Mixin for easy integration of enhanced spacing in screens
mixin EnhancedAppBarMixin {
  
  /// Get consistent top padding for any screen
  double getTopPadding(BuildContext context) => AppBarUtils.getEnhancedTopPadding(context);
  
  /// Get consistent AppBar height
  double getAppBarHeight(BuildContext context, {bool isArabic = false}) => 
    AppBarUtils.getEnhancedAppBarHeight(context, isArabic: isArabic);
  
  /// Create standardized AppBar
  PreferredSizeWidget createAppBar(
    BuildContext context, 
    String title, {
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isArabic = false,
    VoidCallback? onLeadingPressed,
  }) => AppBarUtils.createEnhancedAppBar(
    context: context,
    title: title,
    actions: actions,
    leading: leading,
    centerTitle: centerTitle,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    isArabic: isArabic,
    onLeadingPressed: onLeadingPressed,
  );
}

/// Extension for easy access to enhanced spacing
extension EnhancedSpacingExtension on BuildContext {
  
  /// Get enhanced top padding
  double get enhancedTopPadding => AppBarUtils.getEnhancedTopPadding(this);
  
  /// Get enhanced AppBar height
  double get enhancedAppBarHeight => AppBarUtils.getEnhancedAppBarHeight(this);
  
  /// Get enhanced screen top spacing
  double get enhancedScreenTopSpacing => AppBarUtils.getScreenTopSpacing(this);
  
  /// Get custom header padding
  EdgeInsets get customHeaderPadding => AppBarUtils.getCustomHeaderPadding(this);
}
