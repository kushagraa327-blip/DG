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
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A90E2),  // Soft blue
                    Color(0xFF50C878),  // Emerald green
                  ],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: mFormKey,
                  child: Column(
                    children: [
                      30.height,
                      // Logo with subtle shadow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/dietary-Logo.png',
                          height: mq.height * 0.18,
                          fit: BoxFit.contain,
                        ),
                      ),
                      40.height,
                      // Welcome Text
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      8.height,
                      Text(
                        'Sign in to continue your journey',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      40.height,
                      // Card Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email Field
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                letterSpacing: 0.5,
                              ),
                            ),
                            12.height,
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: TextFormField(
                                controller: mEmailCont,
                                focusNode: mEmailFocus,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  hintText: 'Enter your email',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF4A90E2),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            24.height,
                            // Password Field
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                letterSpacing: 0.5,
                              ),
                            ),
                            12.height,
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: TextFormField(
                                controller: mPassCont,
                                focusNode: mPassFocus,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF4A90E2),
                                      size: 22,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword 
                                        ? Icons.visibility_off_outlined 
                                        : Icons.visibility_outlined,
                                      color: Colors.grey[500],
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
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
                            20.height,
                            // Remember Me & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        gradient: getBoolAsync(IS_REMEMBER)
                                          ? const LinearGradient(
                                              colors: [Color(0xFF4A90E2), Color(0xFF50C878)],
                                            )
                                          : null,
                                        color: getBoolAsync(IS_REMEMBER) 
                                          ? null 
                                          : Colors.transparent,
                                        border: Border.all(
                                          color: getBoolAsync(IS_REMEMBER) 
                                            ? Colors.transparent 
                                            : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: getBoolAsync(IS_REMEMBER)
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                    ).onTap(() async {
                                      await setValue(IS_REMEMBER, !getBoolAsync(IS_REMEMBER));
                                      setState(() {});
                                    }),
                                    10.width,
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ForgotPwdScreen().launch(context);
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4A90E2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            32.height,
                            // Login Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF50C878)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    save();
                                  },
                                  child: const Center(
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      32.height,
                      // Register Now
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New User? ',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              SignUpScreen().launch(context);
                            },
                            child: const Text(
                              'Register Now',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      20.height,
                    ],
                  ),
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
