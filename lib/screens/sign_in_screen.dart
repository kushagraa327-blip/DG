import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/loader_widget.dart';
import '../../main.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/forgot_pwd_screen.dart';
import '../../screens/otp_screen.dart';
import '../../screens/sign_up_screen.dart';
import '../../utils/app_images.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/device_extensions.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../network/rest_api.dart';
import '../service/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_config.dart';
import '../utils/app_constants.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  TextEditingController mEmailCont = TextEditingController();
  TextEditingController mPassCont = TextEditingController();

  FocusNode mEmailFocus = FocusNode();
  FocusNode mPassFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (getBoolAsync(IS_REMEMBER)) {
      mEmailCont.text = getStringAsync(EMAIL);
      mPassCont.text = getStringAsync(PASSWORD);
    }
    getCountryCodeFromLocale();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> save() async {
    hideKeyboard(context);
    Map<String, dynamic> req = {
      'email': mEmailCont.text.trim(),
      'user_type': LoginUser,
      'password': mPassCont.text.trim(),
      'player_id': getStringAsync(PLAYER_ID).validate(),
    };

    if (mFormKey.currentState!.validate()) {
      appStore.setLoading(true);
      await logInApi(req).then((value) async {
        updatePlayerId();
        if (value.data!.status == statusActive) {
          if (getBoolAsync(IS_REMEMBER)) {
            userStore.setUserPassword(mPassCont.text.trim());
          }
          print("------------------81>>>${userStore.email}");
          print("------------------82>>>${mEmailCont.text.trim()}");
          if (userStore.email == mEmailCont.text.trim()) {
            userStore.setIsSTEP('oldUser');

          }else{
            userStore.setIsSTEP('newUser');

          }


          getUSerDetail(context, value.data!.id).then((value) {
            DashboardScreen().launch(context, isNewTask: true);
          }).catchError((e) {
            print("error=>$e");
          });
        } else {
          toast(languages.lblContactAdmin);
        }
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString());
      });
      setState(() {});
    }
  }

  Future<String?> getCountryCodeFromLocale() async {
    try {
      String localeName = Platform.localeName; // e.g., "en_US" or "fr_FR"

      if (localeName.contains('_')) {
        print("---------114>>>${localeName.split('_').last}");
        setValue(COUNTRY_CODE,localeName.split('_').last);
        return localeName.split('_').last; // Returns "US", "FR", etc.
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String? locale = androidInfo.device; // More reliable locale
        if (locale.contains('_')) {
          return locale.split('_').last;
        }
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        String? locale = iosInfo.localizedModel; // e.g., "en_US"
        if (locale.contains('_')) {
          return locale.split('_').last;
        }
      }
    } catch (e) {
      print('Error getting country code: $e');
    }
    return null; // Return null if no country code is found
  }

  googleLogin() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await signInWithGoogle().then((user) async {
      print(user);
      setValue(IS_SOCIAL, true);
      await userStore.setUserEmail(user.email.validate());
      await userStore.setUsername(user.email.validate());
      await userStore.setUserImage(user.photoURL.validate());
      await userStore.setDisplayName(user.displayName.validate());
      await userStore.setPhoneNo(user.phoneNumber.validate());
      updatePlayerId();
      await getUSerDetail(context, userStore.userId).then((value) {
        appStore.setLoading(false);
        setValue(IS_REMEMBER, false);
        DashboardScreen().launch(context, isNewTask: true);
      }).catchError((e) {
        print("error=>$e");
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  appleLogin() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await appleLogIn(context).then((value) {
      setValue(IS_SOCIAL, true);
      appStore.setLoading(false);
      if (userStore.isLoggedIn == true) {
        updatePlayerId();
      }
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Widget mSocialWidget(String icon, Function onCall) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(backgroundColor: socialBackground, boxShape: BoxShape.circle),
      child: Image.asset(icon, height:40, width:40),
    ).onTap(() {
      onCall.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(top: context.statusBarHeight + 32), // Increased from 16 to 32 for better spacing
              child: Form(
                key: mFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dietary Guide Logo centered
                    Center(
                      child: Image.asset(
                        'assets/dietary-Logo.png',
                        height: mq.height * 0.25,
                        width: mq.width * 0.8,
                        fit: BoxFit.contain,
                      ),
                    ),
                    1.height,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        40.height,
                        const Text('Email', style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        )),
                        8.height,
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextFormField(
                            controller: mEmailCont,
                            focusNode: mEmailFocus,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              hintText: 'User@gmail.com',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Colors.black54,
                                size: 20,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                        ),
                        24.height,
                        const Text('Password', style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        )),
                        8.height,
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextFormField(
                            controller: mPassCont,
                            focusNode: mPassFocus,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.black54,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            onFieldSubmitted: (c) {
                              save();
                            },
                          ),
                        ),
                        16.height,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: getBoolAsync(IS_REMEMBER) ? const Color(0xFF00C853) : Colors.transparent,
                                    border: Border.all(
                                      color: getBoolAsync(IS_REMEMBER) ? const Color(0xFF00C853) : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: getBoolAsync(IS_REMEMBER) 
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : null,
                                ).onTap(() async {
                                  await setValue(IS_REMEMBER, !getBoolAsync(IS_REMEMBER));
                                  setState(() {});
                                }),
                                8.width,
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Forget Password',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF00C853),
                                fontWeight: FontWeight.w500,
                              ),
                            ).onTap(() {
                              ForgotPwdScreen().launch(context);
                            }),
                          ],
                        ),
                        40.height,
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                save();
                              },
                              child: const Center(
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        24.height,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(languages.lblNewUser, style: primaryTextStyle()),
                            GestureDetector(
                                child: Text(languages.lblRegisterNow, style: primaryTextStyle(color: primaryColor)).paddingLeft(4),
                                onTap: () {
                                  SignUpScreen().launch(context);
                                })
                          ],
                        ),
                        24.height,
                      ],
                    ).paddingSymmetric(horizontal: mq.height*0.020, vertical: 4),
                  ],
                ),
              ),
            ),
            Observer(builder: (context) {
              return Loader().center().visible(appStore.isLoading);
            })
          ],
        ),
      ),
    );
  }
}
