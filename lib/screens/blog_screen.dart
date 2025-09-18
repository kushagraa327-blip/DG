import 'package:flutter/material.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../utils/app_colors.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  _BlogScreenState createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(languages.lblBlog, context: context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: primaryColor.withOpacity(0.6),
            ),
            24.height,
            Text(
              'Coming Soon',
              style: boldTextStyle(size: 28, color: primaryColor),
            ),
            16.height,
            Text(
              'We\'re working on bringing you\namazing fitness blogs and articles.',
              style: secondaryTextStyle(size: 16),
              textAlign: TextAlign.center,
            ),
            8.height,
            Text(
              'Stay tuned for updates!',
              style: secondaryTextStyle(size: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
