import 'package:flutter/material.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/decorations.dart';
import '../main.dart';
import '../models/meal_entry_model.dart';
import '../utils/app_colors.dart';

class AvatarEmojiComponent extends StatefulWidget {
  final AvatarMood mood;
  final String size; // small, medium, large, xlarge, xxlarge
  final bool interactive;
  final VoidCallback? onPress;
  final bool showDescription;

  const AvatarEmojiComponent({
    super.key,
    required this.mood,
    this.size = 'medium',
    this.interactive = false,
    this.onPress,
    this.showDescription = false,
  });

  @override
  _AvatarEmojiComponentState createState() => _AvatarEmojiComponentState();
}

class _AvatarEmojiComponentState extends State<AvatarEmojiComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.interactive ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _getAvatarSize(),
                    height: _getAvatarSize(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _getMoodGradient(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getMoodColor().withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.mood.emoji,
                        style: TextStyle(
                          fontSize: _getEmojiSize(),
                        ),
                      ),
                    ),
                  ),
                  
                  if (widget.showDescription) ...[
                    8.height,
                    Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        widget.mood.description,
                        style: secondaryTextStyle(size: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    if (widget.onPress != null) {
      widget.onPress!();
    }
  }

  double _getAvatarSize() {
    switch (widget.size) {
      case 'small':
        return 40.0;
      case 'medium':
        return 60.0;
      case 'large':
        return 80.0;
      case 'xlarge':
        return 100.0;
      case 'xxlarge':
        return 120.0;
      default:
        return 60.0;
    }
  }

  double _getEmojiSize() {
    switch (widget.size) {
      case 'small':
        return 20.0;
      case 'medium':
        return 30.0;
      case 'large':
        return 40.0;
      case 'xlarge':
        return 50.0;
      case 'xxlarge':
        return 60.0;
      default:
        return 30.0;
    }
  }

  Color _getMoodColor() {
    switch (widget.mood) {
      case AvatarMood.joyful:
        return Colors.green;
      case AvatarMood.happy:
        return Colors.lightGreen;
      case AvatarMood.neutral:
        return Colors.blue;
      case AvatarMood.concerned:
        return Colors.orange;
      case AvatarMood.worried:
        return Colors.red;
      case AvatarMood.excited:
        return Colors.purple;
    }
  }

  List<Color> _getMoodGradient() {
    final baseColor = _getMoodColor();
    return [
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
    ];
  }
}

class AvatarMoodIndicator extends StatelessWidget {
  final AvatarMood mood;
  final bool showLabel;

  const AvatarMoodIndicator({
    super.key,
    required this.mood,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: _getMoodColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getMoodColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mood.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          if (showLabel) ...[
            8.width,
            Text(
              _getMoodLabel(),
              style: boldTextStyle(
                size: 12,
                color: _getMoodColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMoodLabel() {
    switch (mood) {
      case AvatarMood.joyful:
        return 'Excellent';
      case AvatarMood.happy:
        return 'Good';
      case AvatarMood.neutral:
        return 'Okay';
      case AvatarMood.concerned:
        return 'Concerned';
      case AvatarMood.worried:
        return 'Needs Attention';
      case AvatarMood.excited:
        return 'Amazing';
    }
  }

  Color _getMoodColor() {
    switch (mood) {
      case AvatarMood.joyful:
        return Colors.green;
      case AvatarMood.happy:
        return Colors.lightGreen;
      case AvatarMood.neutral:
        return Colors.blue;
      case AvatarMood.concerned:
        return Colors.orange;
      case AvatarMood.worried:
        return Colors.red;
      case AvatarMood.excited:
        return Colors.purple;
    }
  }
}

class MoodProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final Color color;

  const MoodProgressIndicator({
    super.key,
    required this.progress,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: boldTextStyle(size: 14),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: boldTextStyle(size: 14, color: color),
            ),
          ],
        ),
        8.height,
        Container(
          height: 8,
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InteractiveAvatar extends StatefulWidget {
  final AvatarMood mood;
  final VoidCallback? onTap;
  final String? message;

  const InteractiveAvatar({
    super.key,
    required this.mood,
    this.onTap,
    this.message,
  });

  @override
  _InteractiveAvatarState createState() => _InteractiveAvatarState();
}

class _InteractiveAvatarState extends State<InteractiveAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _bounceAnimation.value,
            child: Column(
              children: [
                AvatarEmojiComponent(
                  mood: widget.mood,
                  size: 'xxlarge',
                  interactive: false,
                ),
                
                if (widget.message != null) ...[
                  16.height,
                  Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.message!,
                      style: primaryTextStyle(size: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleTap() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }
}
