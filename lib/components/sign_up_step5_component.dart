import 'package:flutter/material.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import '../../extensions/loader_widget.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../main.dart';
import '../../models/user_response.dart';
import '../../network/rest_api.dart';
import '../../screens/dashboard_screen.dart';
import '../../utils/app_common.dart';
import '../extensions/app_button.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'signup_step_indicator.dart';

class SignUpStep5Component extends StatefulWidget {
  const SignUpStep5Component({super.key});

  @override
  _SignUpStep5ComponentState createState() => _SignUpStep5ComponentState();
}

class _SignUpStep5ComponentState extends State<SignUpStep5Component> {
  int mCurrentValue = 0;
  
  final List<String> goalTitles = [
    'Lose Weight',
    'Gain Weight', 
    'Maintain Healthy Lifestyle',
    'Gain Muscles'
  ];
  
  final List<String> goalDescriptions = [
    'Burn calories and reduce body weight with targeted exercises',
    'Build mass and increase body weight with strength training',
    'Stay fit and maintain current weight with balanced workouts',
    'Build muscle mass and strength with resistance training'
  ];
  
  final List<String> goalValues = [
    'weight_loss',
    'weight_gain',
    'maintenance', 
    'muscle_gain'
  ];

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mGoalOption(String title, String description, int index, Function onTap) {
    bool isSelected = mCurrentValue == index;
    
    return Bounce(
      duration: const Duration(milliseconds: 110),
      onPressed: () {
        onTap.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: isSelected ? Colors.black.withOpacity(0.1) : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? Colors.black : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            16.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: boldTextStyle(
                      size: 16,
                      color: isSelected ? Colors.black : textPrimaryColorGlobal,
                    ),
                  ),
                  4.height,
                  Text(
                    description,
                    style: secondaryTextStyle(
                      size: 14,
                      color: textSecondaryColorGlobal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveData() async {
    Map req = {};
    UserProfile userProfile = UserProfile();

    userProfile.age = userStore.age.validate();
    userProfile.weight = userStore.weight.validate();
    userProfile.height = userStore.height.validate();
    userProfile.weightUnit = userStore.weightUnit.validate();
    userProfile.heightUnit = userStore.heightUnit.validate();
    userProfile.goal = goalValues[mCurrentValue];

    print("-------------194>>>${getStringAsync(PLAYER_ID).validate()}");
    req = {
      'first_name': userStore.fName.validate(),
      'last_name': userStore.lName.validate(),
      'username': getBoolAsync(IS_OTP) != true ? userStore.email.validate() : userStore.phoneNo.validate(),
      'email': userStore.email.validate(),
      'password': userStore.password.validate(),
      'user_type': LoginUser,
      'status': statusActive,
      'phone_number': userStore.phoneNo.validate(),
      'gender': userStore.gender.validate().toLowerCase(),
      'user_profile': userProfile.toJson(),
      'goal': goalValues[mCurrentValue], // Add the selected goal
      "player_id": getStringAsync(PLAYER_ID).validate(),
      if (getBoolAsync(IS_OTP) != false) "login_type": LoginTypeOTP,
    };

    appStore.setLoading(true);

    // Add network connectivity check
    print("🌐 Testing network connectivity...");

    await registerApi(req).then((value) async {
      print("✅ Registration Success: ${value.message}");
      print("👤 User Data: ${value.data?.toJson()}");
      appStore.setLoading(false);
      userStore.setLogin(true);
      userStore.setToken(value.data!.apiToken.validate());

      // Save the selected goal
      userStore.setGoal(goalValues[mCurrentValue]);

      getUSerDetail(context, value.data!.id).then((value) {
        DashboardScreen().launch(context, isNewTask: true);
      }).catchError((e) {
        print("❌ Get User Detail Error: $e");
      });
    }).catchError((e) {
      print("❌ Registration Error: $e");
      appStore.setLoading(false);

      // Provide more specific error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('timeout') || errorMessage.contains('Connection timed out')) {
        toast('Connection timeout. Please check your internet connection and try again.');
      } else if (errorMessage.contains('SocketException') || errorMessage.contains('Network is unreachable')) {
        toast('Network error. Please check your internet connection.');
      } else if (errorMessage.contains('HandshakeException')) {
        toast('SSL/TLS connection error. Please try again.');
      } else {
        toast(errorMessage);
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.height,
              // Step indicator
              const SignUpStepIndicator(currentStep: 6).paddingSymmetric(horizontal: 16),
              32.height,
              Text(
                languages.lblSelectYourGoal ?? "Select Your Goal",
                style: boldTextStyle(size: 24, color: textPrimaryColorGlobal),
              ).paddingSymmetric(horizontal: 16),
              8.height,
              Text(
                "Choose your primary fitness goal to get personalized recommendations",
                style: secondaryTextStyle(size: 16, color: textSecondaryColorGlobal),
              ).paddingSymmetric(horizontal: 16),
              24.height,
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goalTitles.length,
                itemBuilder: (context, index) {
                  return mGoalOption(
                    goalTitles[index],
                    goalDescriptions[index],
                    index,
                    () {
                      setState(() {
                        mCurrentValue = index;
                      });
                    },
                  );
                },
              ).paddingSymmetric(horizontal: 16),
              24.height,
              AppButton(
                text: languages.lblDone,
                width: context.width(),
                color: Colors.black,
                onTap: () async {
                  userStore.setGoal(goalValues[mCurrentValue]);
                  saveData();
                },
              ).paddingSymmetric(horizontal: 16),
              32.height,
            ],
          ),
        ),
        Loader().visible(appStore.isLoading)
      ],
    );
  }
}
