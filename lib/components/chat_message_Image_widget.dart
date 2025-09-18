import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/decorations.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/question_answer_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';

class ChatMessageImageWidget extends StatefulWidget {
  final String answer;
  final QuestionImageAnswerModel data;
  final bool isLoading;
  final String firstQuestion;

  const ChatMessageImageWidget({super.key, 
    required this.answer,
    required this.data,
    required this.isLoading,
    required this.firstQuestion,
  });

  @override
  State<ChatMessageImageWidget> createState() => _ChatMessageImageWidgetState();
}

class _ChatMessageImageWidgetState extends State<ChatMessageImageWidget> {
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

//widget.data.imageUri.isEmptyOrNull?SizedBox.shrink():cachedImage(widget.data.imageUri, height: 80, fit: BoxFit.fill, width: 100).cornerRadiusWithClipRRect(15),
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Add 10dp bottom padding as requested
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.data.question == widget.firstQuestion || widget.data.question.isEmptyOrNull) ...[
            const SizedBox.shrink()
          ] else ...[
            // Enhanced user message bubble
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    margin: const EdgeInsets.only(top: 8.0, bottom: 12.0, left: 60, right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF81C784), // Lighter green
                          const Color(0xFF81C784).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF81C784).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SelectableText(
                      widget.data.smartCompose.validate().isNotEmpty
                          ? widget.data.question.splitAfter('of ')
                          : '${widget.data.question}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        height: 1.4,
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
          ],
        /* if (widget.answer.isEmpty && widget.isLoading)
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:  CrossAxisAlignment.center,
              children: [
                Lottie.asset('assets/loading.json', width: 70, height: 70),
                SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: primaryTextStyle(size: 14),
                )
              ],
            )),*/
          if (widget.answer.isNotEmpty && !widget.isLoading)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IRA Avatar
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/2-removebg-preview.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Enhanced AI response bubble
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(top: 2, bottom: 16.0, right: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: primaryColor.withOpacity(0.05),
                          blurRadius: 40,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Answer text
                        SelectableText(
                          widget.answer.toString() ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[800],
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Read time and actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${(widget.answer.toString() ?? '').calculateReadTime().toStringAsFixed(1).toDouble().ceil()} min read",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Copy button
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ).onTap(() {
                              (widget.answer.toString() ?? '').copyToClipboard();
                              toast(languages.lblCopiedToClipboard);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
