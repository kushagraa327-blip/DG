import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Enhanced responsive wrapper for home screen sections
class HomeScreenResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool enableConstraints;
  final double? maxWidth;
  
  const HomeScreenResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.enableConstraints = true,
    this.maxWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = child;
    
    // Apply responsive constraints
    if (enableConstraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final double constrainedWidth;
      
      if (maxWidth != null) {
        constrainedWidth = maxWidth!;
      } else {
        constrainedWidth = ResponsiveUtils.getResponsiveValue(
          context,
          mobile: screenWidth,
          tablet: screenWidth * 0.9,
          desktop: 1200.0,
        );
      }
      
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constrainedWidth,
        ),
        child: content,
      );
    }
    
    // Apply responsive padding
    if (padding != null || margin != null) {
      content = Container(
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        margin: margin ?? EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
          vertical: ResponsiveUtils.getResponsiveSpacing(context, 8),
        ),
        child: content,
      );
    }
    
    // Center content for larger screens
    if (enableConstraints && MediaQuery.of(context).size.width > 1200) {
      content = Center(child: content);
    }
    
    return content;
  }
}

/// Responsive safe area wrapper that handles different screen sizes
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool maintainBottomViewPadding;
  
  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.maintainBottomViewPadding = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }
}

/// Extension to add responsive utilities to context
extension HomeScreenResponsive on BuildContext {
  /// Get responsive constraints for home screen content
  BoxConstraints get homeScreenConstraints {
    final screenWidth = MediaQuery.of(this).size.width;
    return BoxConstraints(
      maxWidth: ResponsiveUtils.getResponsiveValue(
        this,
        mobile: screenWidth,
        tablet: screenWidth * 0.95,
        desktop: 1400.0,
      ),
    );
  }
  
  /// Get responsive padding for home screen sections
  EdgeInsets get homeScreenPadding => ResponsiveUtils.getResponsivePadding(
    this,
    mobile: 16,
    tablet: 24,
    desktop: 32,
  );
  
  /// Get responsive margin for home screen cards
  EdgeInsets get homeScreenMargin => EdgeInsets.symmetric(
    horizontal: ResponsiveUtils.getResponsiveSpacing(this, 16),
    vertical: ResponsiveUtils.getResponsiveSpacing(this, 8),
  );
  
  /// Check if screen is extra small (less than 360dp)
  bool get isExtraSmall => MediaQuery.of(this).size.width < 360;
  
  /// Check if screen is large (greater than 800dp)
  bool get isLarge => MediaQuery.of(this).size.width > 800;
  
  /// Get appropriate column count for grid layouts
  int get gridColumnCount {
    final width = MediaQuery.of(this).size.width;
    if (width < 360) return 1;
    if (width < 600) return 2;
    if (width < 1200) return 3;
    return 4;
  }
}

/// Responsive grid view for home screen components
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  
  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? context.homeScreenPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumnCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, crossAxisSpacing),
        mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, mainAxisSpacing),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
