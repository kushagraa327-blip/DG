import 'dart:io';
import 'dart:ui';

import 'package:crisp_chat/crisp_chat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/models/app_setting_response.dart';
import 'package:mighty_fitness/models/question_answer_model.dart';
import 'package:mighty_fitness/screens/Schedule_Screen.dart';
import 'package:mighty_fitness/screens/chatting_image_screen.dart';
import 'package:mighty_fitness/service/VersionServices.dart';

import '../../extensions/extension_util/context_extensions.dart';
import '../components/double_back_to_close_app.dart';
import '../components/permission.dart';
import '../extensions/LiveStream.dart';
import '../extensions/colors.dart';
import '../extensions/constants.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/bottom_bar_item_model.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/app_images.dart';
import '../components/log_meal_form_component.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'food_scanner_screen.dart';


bool? isFirstTime = false;
AppVersion? app_update_check;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int mCurrentIndex = 0;
  int mCounter = 0;
  late CrispConfig configData;

  List<QuestionImageAnswerModel> questionAnswers = [];



  final tab = [
    HomeScreen(),
    ProgressScreen(),
    Container(), // Placeholder for IRA Chat navigation
    ProfileScreen(),
  ];

  List<BottomBarItemModel> bottomItemList = [
    BottomBarItemModel(iconData: ic_home_outline, selectedIconData: ic_home_fill, labelText: languages.lblHome),
    BottomBarItemModel(iconData: ic_report_outline, selectedIconData: ic_report_fill, labelText: languages.lblReport),
    BottomBarItemModel(iconData: ic_bot, selectedIconData: ic_bot, labelText: 'IRA Chat'), // Chatbot replaces schedule
    BottomBarItemModel(iconData: ic_user, selectedIconData: ic_user_fill_icon, labelText: languages.lblProfile),
  ];

  @override
  void initState() {
    super.initState();
    // Start async setup in background, don't block UI
    Future.microtask(() => init());
    LiveStream().on("LANGUAGE", (s) {
      setState(() {});
    });

  }

  init() async {
    // Don't block UI, run async setup in background
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
        appStore.setDarkMode(MediaQuery.of(context).platformBrightness == Brightness.light);
      }
    };
    getSettingList(); // Don't await
    getFitBotListApiCall();
    Permissions.activityPermissionsGranted();
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
  }

  Future<void> getSettingList() async {
    await getSettingApi().then((value) {
      userStore.setCurrencyCodeID(value.currencySetting?.symbol.validate() ?? '');
      userStore.setCurrencyPositionID(value.currencySetting?.position.validate() ?? '');
      userStore.setCurrencyCode(value.currencySetting?.code.validate() ?? '');

      /// Config crispChat

      for (int i = 0; i < value.data!.length; i++) {
        switch (value.data![i].key) {
          case "terms_condition":
            {
              userStore.setTermsCondition(value.data![i].value.validate());
            }
          case "privacy_policy":
            {
              userStore.setPrivacyPolicy(value.data![i].value.validate());
            }
          case "ONESIGNAL_APP_ID":
            {
              userStore.setOneSignalAppID(value.data![i].value.validate());
            }
          case "ONESIGNAL_REST_API_KEY":
            {
              userStore.setOnesignalRestApiKey(value.data![i].value.validate());
            }
          case "ADMOB_BannerId":
            {
              userStore.setAdmobBannerId(value.data![i].value.validate());
            }
          case "ADMOB_InterstitialId":
            {
              userStore.setAdmobInterstitialId(value.data![i].value.validate());
            }
          case "ADMOB_BannerIdIos":
            {
              userStore.setAdmobBannerIdIos(value.data![i].value.validate());
            }
          case "ADMOB_InterstitialIdIos":
            {
              userStore.setAdmobInterstitialIdIos(value.data![i].value.validate());
            }
          case "CHATGPT_API_KEY":
            {
              userStore.setChatGptApiKey(value.data?[i].value.validate() ?? "");
            }
          case "AdsBannerDetail_Show_Ads_On_Diet_Detail":
            {
              userStore.setAdsBannerDetailShowAdsOnDietDetail(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Banner_Ads_OnDiet":
            {
              userStore.setAdsBannerDetailShowBannerAdsOnDiet(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Ads_On_Workout_Detail":
            {
              userStore.setAdsBannerDetailShowAdsOnWorkoutDetail(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Banner_On_Workouts":
            {
              userStore.setAdsBannerDetailShowBannerOnWorkouts(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Ads_On_Exercise_Detail":
            {
              userStore.setAdsBannerDetailShowAdsOnExerciseDetail(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Banner_On_Equipment":
            {
              userStore.setAdsBannerDetailShowBannerOnEquipment(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Ads_On_Product_Detail":
            {
              userStore.setAdsBannerDetailShowAdsOnProductDetail(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Banner_On_Product":
            {
              userStore.setAdsBannerDetailShowBannerOnProduct(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Ads_On_Progress_Detail":
            {
              userStore.setAdsBannerDetailShowAdsOnProgressDetail(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Banner_On_BodyPart":
            {
              userStore.setAdsBannerDetailShowBannerOnBodyPart(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Ads_On_Blog_Detail":
            {
              userStore.setAdsBannerDetailShowAdsOnBlogDetail(value.data![i].value.toInt());
            }
          case "AdsBannerDetail_Show_Banner_On_Level":
            {
              userStore.setAdsBannerDetailShowBannerOnLevel(value.data![i].value.toInt());
            }
          case "subscription_system":
            {
              userStore.setSubscription(value.data![i].value.toString());
            }
        }
      }
      getSettingData().whenComplete(() {
        if (getStringAsync(CRISP_CHAT_WEB_SITE_ID).isNotEmpty) {
          User user = User(email: userStore.email, nickName: userStore.displayName, avatar: userStore.profileImage ?? "");
          configData = CrispConfig(
            user: user,
            tokenId: userStore.userId.toString(),
            enableNotifications: true,
            websiteID: getStringAsync(CRISP_CHAT_WEB_SITE_ID),
          );
        }
        if (app_update_check != null) {
          VersionService().getVersionData(context, app_update_check);
        }
      });
    });
  }

  Future<void> getFitBotListApiCall() async {
    await getFitBotList().then((value) {
      value.data?.reversed.forEach((data) {
        questionAnswers.insert(
            0, QuestionImageAnswerModel(question: data.question, imageUri: "", answer: data.answer != null ? StringBuffer(data.answer ?? '') : null, isLoading: false, smartCompose: ''));
      });
    });
  }

  @override
  void didChangeDependencies() {
    if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) appStore.setDarkMode(MediaQuery.of(context).platformBrightness == Brightness.dark);
    setState(() {});
    super.didChangeDependencies();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _showLogMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: LogMealFormComponent(
          onSubmit: (meal) async {
            await nutritionStore.addMealEntry(meal);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meal logged successfully! 🍽️'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {}); // Refresh the UI
          },
        ),
      ),
    );
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DoubleBackToCloseApp(
            snackBar: SnackBar(
              elevation: 4,
              backgroundColor: appStore.isDarkMode ? cardDarkColor : primaryOpacity,
              content: Text(languages.lblTapBackAgainToLeave, style: primaryTextStyle()),
            ),
            child: AnimatedContainer(
              color: context.cardColor, 
              duration: const Duration(seconds: 1), 
              child: _getTabForIndex(mCurrentIndex)
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isActive: mCurrentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Charts',
                  index: 1,
                  isActive: mCurrentIndex == 1,
                ),
                _buildNavItem(
                  icon: Icons.add,
                  activeIcon: Icons.add,
                  label: 'Add',
                  index: 2,
                  isActive: false,
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chat',
                  index: 3,
                  isActive: false,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  isActive: mCurrentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getTabForIndex(int index) {
    // Map the visual tab indices to actual tab array indices
    switch (index) {
      case 0:
        return tab[0]; // HomeScreen
      case 1:
        return tab[1]; // ProgressScreen
      case 4:
        return tab[3]; // ProfileScreen (moved from index 3 to 4)
      default:
        return tab[0]; // Default to HomeScreen
    }
  }

  String _getIRAImage() {
    // Use different images based on system configuration
    if (appStore.isDarkMode) {
      return ic_ira_dark; // Transparent background for dark mode
    } else {
      return ic_ira_light; // Regular image for light mode
    }
  }

  Widget _buildNavItem({
    required dynamic icon,
    required dynamic activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          // Add button - open FoodScannerScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FoodScannerScreen()),
          );
        } else if (index == 3) {
          // Chat - navigate to chatbot screen
          ChattingImageScreen(isDirect: true).launch(context);
        } else {
          // Regular tab navigation
          if (index == 4) {
            mCurrentIndex = 4; // Profile tab
          } else {
            mCurrentIndex = index;
          }
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Handle both IconData and String icon types
            if (icon is IconData)
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.black : Colors.grey[400],
                size: 26,
              )
            else
              Image.asset(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.black : Colors.grey[400],
                height: 26,
              ),
          ],
        ),
      ),
    );
  }
}

configureCrispChat() async {
  FlutterCrispChat.setSessionString(
    key: userStore.userId.toString(),
    value: userStore.userId.toString(),
  );

  /// Checking session ID After 5 sec
  await Future.delayed(const Duration(seconds: 5), () async {
    String? sessionId = await FlutterCrispChat.getSessionIdentifier();
    if (sessionId != null) {
      // Session ID available
    } else {
      // No session ID
    }
  });
}
