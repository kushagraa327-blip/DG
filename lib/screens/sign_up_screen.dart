import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../extensions/constants.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/system_utils.dart';
import '../../extensions/widgets.dart';
import '../../main.dart';
import '../extensions/colors.dart';
import '../utils/app_colors.dart';
import '../components/sign_up_step1_component.dart';
import '../components/sign_up_step2_component.dart';
import '../components/sign_up_step3_component.dart';
import '../components/sign_up_step4_component.dart';
import '../components/sign_up_height_component.dart';
import '../components/sign_up_step5_component.dart';

class SignUpScreen extends StatefulWidget {
  final String? phoneNumber;

  const SignUpScreen({super.key, this.phoneNumber});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool? isNewTask = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
    appStore.signUpIndex = 0;
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (appStore.signUpIndex == 0) {
          appStore.setLoading(false);
          finish(context);
          return false;
        } else {
          isNewTask = false;
          appStore.signUpIndex--;
          setState(() {});
          return false;
        }
      },
      child: Observer(builder: (context) {
        return Scaffold(
          backgroundColor: (appStore.signUpIndex == 2 || appStore.signUpIndex == 3) ? const Color(0xFFEFE8F6) : null,
          appBar: (appStore.signUpIndex == 2 || appStore.signUpIndex == 3) ? AppBar(
            backgroundColor: const Color(0xFFEFE8F6),
            elevation: 0,
            leading: const Icon(
              Octicons.chevron_left,
              color: Colors.black,
              size: 28,
            ).onTap(() {
              isNewTask = false;
              appStore.signUpIndex--;
              setState(() {});
            }),
            title: const Text(""),
          ) : appBarWidget("",
              backWidget: const Icon(
                Octicons.chevron_left,
                color: Colors.black,
                size: 28,
              ).onTap(() {
                if (appStore.signUpIndex == 0) {
                  finish(context);
                } else {
                  isNewTask = false;
                  appStore.signUpIndex--;
                  setState(() {});
                }
              }),
              color: const Color(0xFFEFE8F6),
              elevation: 0,
              textColor: textPrimaryColorGlobal,
              context: context),
          body: Column(
            children: [
              16.height,
              if (appStore.signUpIndex == 0) SignUpStep1Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 1) SignUpStep2Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 2) SignUpStep3Component(isNewTask: isNewTask).expand(),
              if (appStore.signUpIndex == 3) SignUpHeightComponent().expand(),
              if (appStore.signUpIndex == 4) SignUpStep4Component().expand(),
              if (appStore.signUpIndex == 5) SignUpStep5Component().expand(),
            ],
          ),
        );
      }),
    );
  }
}
