import 'package:flutter/material.dart';
// import 'package:flutter_html/flutter_html.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';

import '../utils/app_common.dart';

class VimeoEmbedWidget extends StatelessWidget {
  final String videoId;

  const VimeoEmbedWidget(this.videoId, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: 640,
      color: Colors.grey[300],
      child: Center(
        child: Text('Vimeo Video: $videoId', style: const TextStyle(color: Colors.black)),
      ),
    ).onTap(() {
      launchUrls('https://player.vimeo.com/video/$videoId', forceWebView: true);
    });
  }
}
