import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mighty_fitness/screens/home_screen.dart';
import 'package:mighty_fitness/screens/workout_history_screen.dart';
import '../screens/reminder_screen.dart';
import '../extensions/common.dart';
import '../screens/subscription_detail_screen.dart';
import '../../extensions/constants.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/system_utils.dart';
import '../../screens/assign_screen.dart';
import '../../screens/blog_screen.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/setting_screen.dart';
import '../../screens/sign_in_screen.dart';
import '../extensions/colors.dart';
import '../extensions/confirmation_dialog.dart';
import '../extensions/decorations.dart';
import '../extensions/text_styles.dart';
import '../extensions/responsive_utils.dart';
import '../main.dart';
import '../service/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';
import 'about_app_screen.dart';
import 'favourite_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mOtherInfo(String title, String value, String heading) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(borderRadius: radius(12), backgroundColor: primaryOpacity),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(text: value, style: boldTextStyle(size: 18, color: primaryColor)),
                const WidgetSpan(child: Padding(padding: EdgeInsets.only(right: 4))),
                TextSpan(text: heading, style: boldTextStyle(size: 14, color: primaryColor)),
              ],
            ),
          ),
          6.height,
          Text(title, style: secondaryTextStyle(size: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        bool? res = await EditProfileScreen().launch(context);
        if (res == true) {
          setState(() {});
        }
      },
      child: Observer(builder: (context) {
        final profileImageUrl = userStore.profileImage.validate();
        final hasValidProfileImage = profileImageUrl.isNotEmpty && 
                                   profileImageUrl.startsWith('http') && 
                                   profileImageUrl.length > 10; // Basic validation
        
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 3, color: Colors.grey[200]!),
            color: Colors.grey[100],
          ),
          child: ClipOval(
            child: hasValidProfileImage
                ? CachedNetworkImage(
                    imageUrl: profileImageUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[600],
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              userStore.weight.isEmptyOrNull ? "80" : userStore.weight.validate(),
              userStore.weight.isEmptyOrNull ? "kg" : userStore.weightUnit.validate(),
              'Weight',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              userStore.height.isEmptyOrNull ? "5.6" : userStore.height.validate(),
              userStore.height.isEmptyOrNull ? "feet" : userStore.heightUnit.validate(),
              'Height',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              userStore.age.isEmptyOrNull ? "18" : userStore.age.validate(),
              userStore.age.isEmptyOrNull ? "year" : 'year',
              'Age',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String unit, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Dark grey color matching the image
        borderRadius: BorderRadius.circular(20), // More rounded corners
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Small icon at the top
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[500]!, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Value and unit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700, // Bold for values
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400, // Regular for units
                      color: Colors.grey[400],
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400, // Regular for labels
              color: Colors.grey[400],
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Same dark color as stats cards
        borderRadius: BorderRadius.circular(20), // More rounded to match
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), // Green color for the icon background
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Every day is a new opportunity for growth and positive change.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400, // Regular for body text
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuOption(
            icon: Icons.book_outlined,
            title: 'Blogs',
            onTap: () {
              BlogScreen().launch(context);
            },
          ),
          _buildDivider(),
          _buildMenuOption(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () async {
              bool? res = await EditProfileScreen().launch(context);
              if (res == true) {
                setState(() {});
              }
            },
          ),
          _buildDivider(),
          _buildMenuOption(
            icon: Icons.settings_outlined,
            title: 'App Settings',
            onTap: () {
              SettingScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
            },
          ),
          _buildDivider(),
          _buildMenuOption(
            icon: Icons.info_outline,
            title: 'About App',
            onTap: () {
              AboutAppScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
            },
          ),
          _buildDivider(),
          _buildMenuOption(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              showConfirmDialogCustom(context,
                  dialogType: DialogType.DELETE,
                  title: languages.lblLogoutMsg,
                  primaryColor: primaryColor,
                  positiveText: languages.lblLogout,
                  image: ic_logout, onAccept: (buildContext) {
                logout(context, onLogout: () {
                  isFirstTimeGraph = false;
                  SignInScreen().launch(context, isNewTask: true);
                });
                finish(context);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400, // Regular for body text
                  color: Colors.black87,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[100],
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Observer(
          builder: (context) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top spacing
                    const SizedBox(height: 40),
                    
                    // Profile Photo
                    _buildProfilePhoto(context),
                    
                    const SizedBox(height: 16),
                    
                    // User Name
                    Text(
                      '${userStore.fName.validate().capitalizeFirstLetter()} ${userStore.lName.capitalizeFirstLetter()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600, // Semi-bold for user name
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Stats Cards
                    _buildStatsCards(context),
                    
                    const SizedBox(height: 24),
                    
                    // Motivational Quote Section
                    _buildMotivationalSection(context),
                    
                    const SizedBox(height: 32),
                    
                    // Menu Options
                    _buildMenuOptions(context),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
