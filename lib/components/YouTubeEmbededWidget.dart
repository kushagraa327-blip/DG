import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'package:flutter_html/flutter_html.dart';

import 'package:mighty_fitness/extensions/extension_util/bool_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';

import '../utils/app_common.dart';

class YouTubeEmbedWidget extends StatelessWidget {
  final String videoId;
  final bool? fullIFrame;

  const YouTubeEmbedWidget(this.videoId, {super.key, this.fullIFrame});

  @override
  Widget build(BuildContext context) {
    String path = fullIFrame.validate() ? videoId : 'https://www.youtube.com/embed/$videoId';
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: Center(
        child: Text('YouTube Video: $videoId', style: const TextStyle(color: Colors.black)),
      ),
    ).onTap(() {
      launchUrls(path, forceWebView: true);
    });
  }
}
