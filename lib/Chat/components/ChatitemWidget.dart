import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/utils/app_colors.dart';

import '../../../../main.dart';
import '../../../extensions/colors.dart';
import '../../../extensions/common.dart';
import '../../../extensions/constants.dart';
import '../../../extensions/decorations.dart';
import '../../../extensions/loader_widget.dart';
import '../../../extensions/text_styles.dart';
import '../../../extensions/widgets.dart';
import '../../../utils/app_constants.dart';
import '../model/chat_message_model.dart';

class ChatItemWidget extends StatefulWidget {
  final ChatMessageModel? data;

  const ChatItemWidget({super.key, this.data});

  @override
  _ChatItemWidgetState createState() => _ChatItemWidgetState();
}

class _ChatItemWidgetState extends State<ChatItemWidget> {
  String? images;

  @override
  Widget build(BuildContext context) {
    String time;

    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(widget.data!.createdAt!);
    if (dateTime.day == DateTime.now().day) {
      time = DateFormat('hh:mm a').format(dateTime);
    } else {
      time = DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    }


    Widget chatItem(String? messageTypes) {
      switch (messageTypes) {
        case TEXT:
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: widget.data!.isMe!
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              SelectableText(
                _cleanAIResponse(widget.data!.message!),
                style: primaryTextStyle(
                    color: widget.data!.isMe!
                        ? Colors.white
                        : textPrimaryColorGlobal),
              ),
              1.height,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: primaryTextStyle(
                        color: !(widget.data?.isMe??false)
                            ? Colors.blueGrey.withOpacity(0.6)
                            : whiteColor.withOpacity(0.6),
                        size: 10),
                  ),
                  2.width,
                  widget.data!.isMe!
                      ? !widget.data!.isMessageRead!
                          ? const Icon(Icons.done, size: 12, color: Colors.white60)
                          : const Icon(Icons.done_all,
                              size: 12, color: Colors.white60)
                      : const Offstage()
                ],
              ),
            ],
          );
        case IMAGE:
          if (widget.data?.photoUrl?.isNotEmpty??false ||
              widget.data!.photoUrl != null) {
            return Stack(
              children: [
                CachedNetworkImage(
                        imageUrl: widget.data?.photoUrl??'',
                        fit: BoxFit.cover,
                        width: 250,
                        height: 200)
                    .cornerRadiusWithClipRRect(10),
                Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(time,
                            style: primaryTextStyle(
                                color: !(widget.data?.isMe??false)
                                    ? Colors.blueGrey.withOpacity(0.6)
                                    : whiteColor.withOpacity(0.6),
                                size: 10)),
                        2.width,
                        widget.data!.isMe!
                            ? !widget.data!.isMessageRead!
                                ? const Icon(Icons.done,
                                    size: 12, color: Colors.white60)
                                : const Icon(Icons.done_all,
                                    size: 12, color: Colors.white60)
                            : const Offstage()
                      ],
                    ))
              ],
            );
          } else {
            return SizedBox(height: 250, width: 250, child: Loader());
          }
        default:
          return Container();
      }
    }

    EdgeInsetsGeometry customPadding(String? messageTypes) {
      switch (messageTypes) {
        case TEXT:
          return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        case IMAGE:
          return const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
        default:
          return const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
      }
    }

    return GestureDetector(
      onLongPress: !widget.data!.isMe!
          ? null
          : () async {
              bool? res = await showConfirmDialog(context, "Delete Message",
                  positiveText: "Yes",
                  negativeText: "No",
                  buttonColor: primaryColor);
              if (res ?? false) {
                hideKeyboard(context);
                chatMessageService
                    .deleteSingleMessage(
                        senderId: widget.data!.senderId,
                        receiverId: widget.data!.receiverId!,
                        documentId: widget.data!.id)
                    .then((value) {
                  //
                }).catchError(
                  (e) {
                    log(e.toString());
                  },
                );
              }
            },
      child: Container(
        margin: const EdgeInsets.only(top: 2, bottom: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.data?.isMe??false
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisAlignment: widget.data!.isMe!
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            widget.data?.isMe??false
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          margin: EdgeInsets.only(
                              top: 0.0,
                              bottom: 0.0,
                              left: context.width() * 0.25,
                              right: 8),
                          padding: customPadding(widget.data!.messageType),
                          decoration: BoxDecoration(
                            boxShadow: defaultBoxShadow(),
                            color: Color(0xFF81C784), // Lighter green
                            borderRadius: radiusOnly(
                                bottomLeft: 12,
                                topLeft: 12,
                                bottomRight: 0,
                                topRight: 12),
                          ),
                          child: chatItem(widget.data!.messageType),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        margin: EdgeInsets.only(left: 8, right: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
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
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IRA Avatar for AI messages
                      Container(
                        width: 32,
                        height: 32,
                        margin: EdgeInsets.only(left: 8, right: 8, top: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/2-removebg-preview.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // AI message bubble
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              top: 2.0,
                              bottom: 2.0,
                              left: 0,
                              right: context.width() * 0.25),
                          padding: customPadding(widget.data!.messageType),
                          decoration: BoxDecoration(
                            boxShadow: defaultBoxShadow(),
                            color: context.cardColor,
                            borderRadius: radiusOnly(
                                bottomLeft: 0,
                                topLeft: 12,
                                bottomRight: 12,
                                topRight: 12),
                          ),
                          child: chatItem(widget.data!.messageType),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
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
