import 'package:flutter/material.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/widgets.dart';
import '../extensions/text_styles.dart';
import '../utils/app_colors.dart';
import '../utils/app_config.dart';

class AboutAppScreen extends StatefulWidget {
  static String tag = '/AboutAppScreen';

  const AboutAppScreen({super.key});

  @override
  AboutAppScreenState createState() => AboutAppScreenState();
}

class AboutAppScreenState extends State<AboutAppScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('About App', context: context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Header Section
                _buildAppHeader(),
                24.height,

                // App Description Section
                _buildAppDescription(),
                24.height,

                // Key Features Section
                _buildKeyFeatures(),
                24.height,

                // AI Features Section
                _buildAIFeatures(),
                24.height,

                // Technical Information Section
                // _buildTechnicalInfo(),
                // 24.height,

                // Links Section
                _buildLinksSection(),
                24.height,

                // Disclaimer Section
                _buildDisclaimer(),
                20.height,
              ],
            ),
          ),
        );
  }

  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, primaryLightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 48,
              color: primaryColor,
            ),
          ),
          16.height,
          Text(
            APP_NAME,
            style: boldTextStyle(size: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          8.height,
          Text(
            'Your AI-Powered Wellness Companion',
            style: secondaryTextStyle(color: Colors.white.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          12.height,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version 1.0.0+12',
              style: secondaryTextStyle(color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: primaryColor, size: 24),
              12.width,
              Text(
                'About MightyFitness',
                style: boldTextStyle(size: 18, color: primaryColor),
              ),
            ],
          ),
          16.height,
          Text(
            'MightyFitness is a comprehensive wellness application designed to help you achieve your health and fitness goals through intelligent nutrition tracking, personalized meal planning, and AI-powered health insights.',
            style: primaryTextStyle(),
          ),
          16.height,
          Text(
            'Whether you want to lose weight, gain muscle, maintain a healthy lifestyle, or build strength, our app provides personalized guidance tailored to your unique profile and preferences.',
            style: secondaryTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_outline, color: primaryColor, size: 24),
              12.width,
              Text(
                'Key Features',
                style: boldTextStyle(size: 18, color: primaryColor),
              ),
            ],
          ),
          20.height,
          _buildFeatureItem(
            Icons.camera_alt,
            'Smart Food Recognition',
            'Upload photos of your meals and get instant nutritional analysis with AI-powered food detection.',
          ),
          16.height,
          _buildFeatureItem(
            Icons.restaurant_menu,
            'Meal Logging & Tracking',
            'Easily log your meals with detailed nutritional information including calories, protein, carbs, and fats.',
          ),
          16.height,
          _buildFeatureItem(
            Icons.trending_up,
            'Progress Monitoring',
            'Track your weight, measurements, and fitness progress with detailed charts and analytics.',
          ),
          16.height,
          _buildFeatureItem(
            Icons.fitness_center,
            'Personalized Workouts',
            'Get customized workout plans based on your fitness level, goals, and available equipment.',
          ),
          16.height,
          _buildFeatureItem(
            Icons.schedule,
            'Goal-Based Planning',
            'Choose from weight loss, muscle gain, healthy lifestyle, or strength building goals.',
          ),
          16.height,
          _buildFeatureItem(
            Icons.notifications_active,
            'Smart Reminders',
            'Stay on track with intelligent reminders for meals, workouts, and health check-ins.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        12.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: boldTextStyle(size: 14)),
              4.height,
              Text(description, style: secondaryTextStyle(size: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.1), primaryLightColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              12.width,
              Text(
                'IRA - Your AI Assistant',
                style: boldTextStyle(size: 18, color: primaryColor),
              ),
            ],
          ),
          16.height,
          Text(
            'Meet IRA, your intelligent wellness companion powered by advanced AI technology:',
            style: primaryTextStyle(size: 14),
          ),
          16.height,
          _buildAIFeatureItem('🧠', 'Personalized Nutrition Advice', 'Get tailored meal recommendations based on your goals, dietary preferences, and health profile.'),
          12.height,
          _buildAIFeatureItem('📊', 'Smart Health Insights', 'Receive intelligent analysis of your progress with BMI calculations and health recommendations.'),
          12.height,
          _buildAIFeatureItem('🍽️', 'AI Meal Planning', 'Generate custom meal plans that align with your fitness goals and dietary restrictions.'),
          12.height,
          _buildAIFeatureItem('💬', 'Interactive Chat Support', 'Ask questions about nutrition, fitness, and health - IRA provides instant, personalized responses.'),
          12.height,
          _buildAIFeatureItem('🔍', 'Food Recognition', 'Advanced image analysis to identify foods and provide accurate nutritional information.'),
          16.height,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: primaryColor, size: 16),
                8.width,
                Expanded(
                  child: Text(
                    'Powered by OpenRouter AI with Gemini 2.5 Flash for the most accurate and helpful responses.',
                    style: secondaryTextStyle(size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeatureItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        8.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: boldTextStyle(size: 13)),
              2.height,
              Text(description, style: secondaryTextStyle(size: 11)),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildTechnicalInfo() {
  //   return Container(
  //     padding: EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).cardColor,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: primaryColor.withOpacity(0.2)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.settings, color: primaryColor, size: 24),
  //             12.width,
  //             Text(
  //               'Technical Information',
  //               style: boldTextStyle(size: 18, color: primaryColor),
  //             ),
  //           ],
  //         ),
  //         16.height,
  //         _buildInfoRow('App Version', '1.0.0+12'),
  //         8.height,
  //         _buildInfoRow('Platform', 'Flutter (Cross-platform)'),
  //         8.height,
  //         _buildInfoRow('AI Technology', 'OpenRouter with Gemini 2.5 Flash'),
  //         8.height,
  //         _buildInfoRow('Package Name', 'com.mighty.fitness'),
  //         8.height,
  //         _buildInfoRow('Developer', 'Mighty Fitness Team'),
  //         8.height,
  //         _buildInfoRow('Last Updated', '2025'),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildInfoRow(String label, String value) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(label, style: secondaryTextStyle()),
  //       Text(value, style: primaryTextStyle(size: 14)),
  //     ],
  //   );
  // }

  Widget _buildLinksSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: primaryColor, size: 24),
              12.width,
              Text(
                'More Information',
                style: boldTextStyle(size: 18, color: primaryColor),
              ),
            ],
          ),
          16.height,
          _buildLinkItem(Icons.privacy_tip, 'Privacy Policy', () {
            // PrivacyPolicyScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          }),
          8.height,
          _buildLinkItem(Icons.description, 'Terms of Service', () {
            // TermsAndConditionScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          }),
          8.height,
          _buildLinkItem(Icons.info, 'About Us', () {
            // AboutUsScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          }),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 24),
              12.width,
              Text(
                'Important Disclaimer',
                style: boldTextStyle(size: 16, color: Colors.orange),
              ),
            ],
          ),
          12.height,
          Text(
            'This app is designed to support your wellness journey and provide general health and fitness information. It is not intended to replace professional medical advice, diagnosis, or treatment.',
            style: secondaryTextStyle(size: 12),
          ),
          8.height,
          Text(
            'Always consult with qualified healthcare professionals before making significant changes to your diet, exercise routine, or health regimen, especially if you have pre-existing medical conditions.',
            style: secondaryTextStyle(size: 12),
          ),
          12.height,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: primaryColor, size: 16),
                8.width,
                Expanded(
                  child: Text(
                    'Your health and safety are our top priority. Use this app as a supportive tool alongside professional guidance.',
                    style: secondaryTextStyle(size: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            16.width,
            Expanded(
              child: Text(title, style: primaryTextStyle()),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
