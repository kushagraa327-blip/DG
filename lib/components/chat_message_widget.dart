import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/loader_widget.dart';
import '../extensions/decorations.dart';
import '../extensions/text_styles.dart';
import '../extensions/responsive_utils.dart';
import '../main.dart';
import '../models/question_answer_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';

class ChatMessageWidget extends StatefulWidget {
  final String answer;
  final QuestionAnswerModel data;
  final bool isLoading;

  const ChatMessageWidget({super.key, 
    required this.answer,
    required this.data,
    required this.isLoading,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  FlutterTts flutterTts = FlutterTts();

  bool isSpeak = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }


  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: ResponsiveUtils.getResponsivePadding(context, mobile: 12),
                margin: EdgeInsets.only(
                  top: ResponsiveUtils.getResponsiveSpacing(context, 3),
                  bottom: ResponsiveUtils.getResponsiveSpacing(context, 3),
                  left: context.isMobile ? ResponsiveUtils.getResponsiveSpacing(context, 60) : ResponsiveUtils.getResponsiveSpacing(context, 120),
                  right: 8,
                ),
                constraints: BoxConstraints(
                  maxWidth: context.width() * (context.isMobile ? 0.8 : 0.7),
                ),
                decoration: boxDecorationDefault(
                  color: const Color(0xFF81C784), // Lighter green
                  boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
                  borderRadius: radiusOnly(bottomLeft: 16, topLeft: 16, topRight: 16),
                ),
                child: SelectableText(
                  widget.data.smartCompose.validate().isNotEmpty ? ': ${widget.data.question.splitAfter('of ')}' : ' ${widget.data.question}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, right: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  "Me",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.answer.isEmpty && widget.isLoading) Center(child: Loader()),
        if (widget.answer.isNotEmpty && !widget.isLoading)
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: ResponsiveUtils.getResponsivePadding(context, mobile: 12),
                  margin: EdgeInsets.only(
                    top: ResponsiveUtils.getResponsiveSpacing(context, 2),
                    bottom: ResponsiveUtils.getResponsiveSpacing(context, 4),
                    left: 0,
                    right: context.isMobile ? ResponsiveUtils.getResponsiveSpacing(context, 40) : ResponsiveUtils.getResponsiveSpacing(context, 70),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: context.width() * (context.isMobile ? 0.85 : 0.75),
                  ),
                  decoration: boxDecorationDefault(
                    color: const Color(0xFF81C784), // Lighter green
                    boxShadow: defaultBoxShadow(blurRadius: 0, shadowColor: Colors.transparent),
                    borderRadius: radiusOnly(topLeft: 16, bottomRight: 16, topRight: 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _cleanAIResponse(widget.answer),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                      ResponsiveText(
                        "${widget.answer.calculateReadTime().toStringAsFixed(1).toDouble().ceil()} min read",
                        baseFontSize: 12,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 25,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: boxDecorationWithRoundedCorners(),
                      child: Icon(Icons.copy, size: 16, color: appStore.isDarkMode ? Colors.white : primaryColor),
                    ).onTap(() {
                      widget.answer.copyToClipboard();
                      toast(languages.lblCopiedToClipboard);
                    }),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Clean AI response text for better display
  String _cleanAIResponse(String content) {
    if (content.isEmpty) return content;

    var result = content;

    // Remove markdown formatting using replaceAllMapped for proper backreference handling
    result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1)!); // Bold
    result = result.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1)!); // Italic
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1)!); // Code

    // Remove headers
    result = result.replaceAll(RegExp(r'#{1,6}\s*'), '');

    // Clean up special characters and formatting
    result = result.replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces
    result = result.replaceAll(RegExp(r'\n\s*\n'), '\n\n'); // Multiple newlines

    // Remove common AI prefixes
    result = result.replaceAll(RegExp(r"Here's[^:]*:\s*"), '');
    result = result.replaceAll(RegExp(r"Here are[^:]*:\s*"), '');
    result = result.replaceAll(RegExp(r"Based on[^:]*:\s*"), '');
    result = result.replaceAll(RegExp(r'As an AI[^,]*,\s*'), '');

    return result.trim();
  }
}
