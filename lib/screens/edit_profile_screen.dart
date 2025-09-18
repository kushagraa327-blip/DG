import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/widget/custome_height_picker.dart';
import 'package:mighty_fitness/widget/weight_widget.dart';
import 'package:tuple/tuple.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/loader_widget.dart';
import '../../extensions/system_utils.dart';
import '../../main.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../extensions/LiveStream.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/colors.dart';
import '../extensions/common.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../models/gender_response.dart';
import '../models/user_response.dart';
import '../network/network_utils.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController mFNameCont = TextEditingController();
  TextEditingController mLNameCont = TextEditingController();
  TextEditingController mEmailCont = TextEditingController();
  TextEditingController mAgeCont = TextEditingController();
  TextEditingController mMobileNumberCont = TextEditingController();
  TextEditingController mWeightCont = TextEditingController();
  TextEditingController mHeightCont = TextEditingController();

  FocusNode mEmailFocus = FocusNode();
  FocusNode mFNameFocus = FocusNode();
  FocusNode mLNameFocus = FocusNode();
  FocusNode mMobileNumberFocus = FocusNode();
  FocusNode mAgeFocus = FocusNode();
  FocusNode mWeightFocus = FocusNode();
  FocusNode mHeightFocus = FocusNode();

  List<String> item = [languages.lblFemale, languages.lblMale];
  List<GenderModel> GenderList = [];

  String mGender = languages.lblFemale;
  String? profileImg = '';
  String? countryCode = '';

  int? mHeight;
  int? mWeight;

  XFile? image;

  double inputValue = 0.0;
  int selectGender = 0;

  bool isKGClicked = false;
  bool isLBSClicked = false;
  bool isFeetClicked = false;
  bool isCMClicked = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    getGender();
    //
    mFNameCont.text = userStore.fName;
    mLNameCont.text = userStore.lName;
    mEmailCont.text = userStore.email;
    mAgeCont.text = userStore.age;
    mMobileNumberCont.text = userStore.phoneNo;
    mWeightCont.text = '${userStore.weight} ${userStore.weightUnit}';
    profileImg = userStore.profileImage;
    if(!userStore.height.isEmptyOrNull){
      mHeightCont.text = '${userStore.height} ${userStore.heightUnit}';
    }
    //userStore.heightUnit == FEET ? mHeight = 0 : mHeight = 1;
    //userStore.weightUnit == LBS ? mWeight = 0 : mWeight = 1;
    mGender = userStore.gender.isEmptyOrNull ? "female" : userStore.gender.capitalizeFirstLetter();
    userStore.displayName = userStore.fName + userStore.lName;
  }

  getGender() {
    GenderList.add(GenderModel(0, languages.lblMale, MALE));
    GenderList.add(GenderModel(1, languages.lblFemale, FEMALE));
    for (var element in GenderList) {
      print('userStore.gender${userStore.gender}');
      if (element.key == userStore.gender) {
        selectGender = element.id.validate();
      }
    }
  }

  Future save() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
    multiPartRequest.fields['id'] = userStore.userId.toString();
    multiPartRequest.fields['first_name'] = mFNameCont.text;
    multiPartRequest.fields['last_name'] = mLNameCont.text;
    multiPartRequest.fields['email'] = mEmailCont.text;
    multiPartRequest.fields['username'] = mEmailCont.text;
    multiPartRequest.fields['phone_number'] = mMobileNumberCont.text;
    multiPartRequest.fields['gender'] = mGender.toLowerCase();
    multiPartRequest.fields['user_profile[age]'] = mAgeCont.text;
    multiPartRequest.fields['user_profile[weight]'] = mWeightCont.text.validate().split(' ')[0];
    multiPartRequest.fields['user_profile[height]'] = mHeightCont.text.validate().split(' ')[0];
    multiPartRequest.fields['user_profile[height_unit]'] = userStore.heightUnit;
    multiPartRequest.fields['user_profile[weight_unit]'] = userStore.weightUnit;

    if (image != null) {
      multiPartRequest.files.add(await MultipartFile.fromPath('profile_image', image!.path.toString()));
      print("🖼️ Profile image file added to request: ${image!.path}");
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());
    print("🚀 Sending profile update request with fields: ${multiPartRequest.fields}");

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        print("✅ Profile update API response received");
        if ((data as String).isJson()) {
          UserResponse res = UserResponse.fromJson(jsonDecode(data));
          print("🖼️ New profile image URL from API: ${res.data!.profileImage}");

          setValue(COUNTRY_CODE, countryCode);
          userStore.weight.isEmpty;
          userStore.weightUnit.isEmpty;
          userStore.height.isEmpty;
          userStore.heightUnit.isEmpty;
          await userStore.setUserEmail(res.data!.email.validate());
          await userStore.setFirstName(res.data!.firstName.validate());
          await userStore.setLastName(res.data!.lastName.validate());
          await userStore.setUsername(res.data!.username.validate());
          await userStore.setGender(res.data!.gender.validate());

          // Clear image cache before updating profile image
          if (res.data!.profileImage.validate().isNotEmpty) {
            await _clearImageCache(res.data!.profileImage.validate());
          }

          await userStore.setUserImage(res.data!.profileImage.validate());
          print("🖼️ Profile image updated in userStore: ${userStore.profileImage}");

          await userStore.setDisplayName(res.data!.displayName.validate());
          await userStore.setPhoneNo(res.data!.phoneNumber.validate());

          if (res.data?.userProfile != null) {
            await userStore.setAge(res.data?.userProfile?.age??'');
            await userStore.setHeight(res.data?.userProfile?.height??'');
            await userStore.setHeightUnit(res.data?.userProfile?.heightUnit??'');
            await userStore.setWeight(res.data?.userProfile?.weight??'');
            await userStore.setWeightUnit(res.data?.userProfile?.weightUnit??'');
          } else {
            await userStore.setAge(mAgeCont.text.validate());
            await userStore.setHeight(mHeightCont.text.validate());
            await userStore.setHeightUnit(mHeight == 0 ? FEET : METRICS_CM);
            await userStore.setWeight(weight.toString());
           await userStore.setWeightUnit(weightType.name);
          }

          double weightInPounds = userStore.weight.toDouble();
          double weightInKilograms = poundsToKilograms(weightInPounds);

          if (userStore.weightUnit == 'LBS' || userStore.weightUnit == 'lbs') {
            if(userStore.weightStoreGraph.replaceAll('user', '').trim()!=weightInKilograms.toStringAsFixed(2)){
              await graphsave();
            }

          }else{
            if(userStore.weightStoreGraph.replaceAll('user', '').trim()!=userStore.weight){
              await graphsave();
            }
          }

          // Clear the local image after successful upload
          image = null;
          profileImg = userStore.profileImage;

          await getUSerDetail(context, userStore.userId).whenComplete(() {
            print("✅ User details refreshed after profile update");
            LiveStream().emit(PROGRESS);
            finish(context, true);
            appStore.setLoading(false);
            if(mounted) setState(() {});
          });

        }
      },
      onError: (error) {
        print("❌ Profile update error: $error");
        log(multiPartRequest.toString());
        toast(error.toString());
        appStore.setLoading(false);
      },
    ).catchError((e) {
      print("❌ Profile update exception: $e");
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  // Helper method to clear image cache
  Future<void> _clearImageCache(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        await CachedNetworkImage.evictFromCache(imageUrl);
        print("🗑️ Cleared cache for image: $imageUrl");
      }
    } catch (e) {
      print("⚠️ Error clearing image cache: $e");
    }
  }


  Future<void> graphsave({String? id}) async {
    Map? req;
    double weightInPounds = userStore.weight.toDouble();
    double weightInKilograms = poundsToKilograms(weightInPounds);
    print("----------221>>>${userStore.weightUnit}");

    if (userStore.weightUnit == 'LBS' || userStore.weightUnit == 'lbs') {
      req = {"id":userStore.weightId,"value": '${weightInKilograms.toStringAsFixed(2)} user', "type": 'weight', "unit": 'kg', "date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
      print("----------224>>>${weightInKilograms.toStringAsFixed(2)}");
    } else {
      req = {"id":userStore.weightId,"value": '${userStore.weight} user', "type": 'weight', "unit": 'kg', "date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
      String weightText = userStore.weight.replaceAll(' lbs', '');

      print("----------230>>>${userStore.weight}");
      print("----------231>>>$weightText");
    }

    await setProgressApi(req).then((value) {
      getProgressApi(METRICS_WEIGHT).then((value) {
        value.data?.forEach((data){
          userStore.setWeightId(data.id.toString());
          print("----------230>>>${data.value}");
          userStore.setWeightGraph(data.value??'');
        });

      });
    }).catchError((e,s) {

    });
  }





  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }


  Widget mHeightOption(String? value, int? index) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(6),
          backgroundColor: mHeight == index
              ? primaryColor
              : appStore.isDarkMode
                  ? context.cardColor
                  : GreyLightColor),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(value.toString(), style: secondaryTextStyle(color: mHeight == index ? Colors.white : textColor)),
    ).onTap(() {
      mHeight = index;
      hideKeyboard(context);
      if (index == 1) {
        if (!isFeetClicked) {
          convertFeetToCm();
          isFeetClicked = true;
          isCMClicked = false;
        }
      } else {
        if (!isCMClicked) {
          convertCMToFeet();
          isCMClicked = true;
          isFeetClicked = false;
        }
      }
      setState(() {});
    });
  }

  WeightType weightType = userStore.weightUnit=='kg'?WeightType.lb:WeightType.kg;

  double weight = 0;

  //Convert Feet to Cm
  void convertFeetToCm() {
    double a = double.parse(mHeightCont.text.isEmptyOrNull ? "0.0" : mHeightCont.text.validate()) * 30.48;
    if (!mHeightCont.text.isEmptyOrNull) {
      mHeightCont.text = a.toStringAsFixed(2).toString();
    }
    mHeightCont.selection = TextSelection.fromPosition(TextPosition(offset: mHeightCont.text.length));
    print(a.toStringAsFixed(2).toString());
  }

  //Convert CM to Feet
  void convertCMToFeet() {
    double a = double.parse(mHeightCont.text.isEmptyOrNull ? "0.0" : mHeightCont.text.validate()) * 0.0328;
    if (!mHeightCont.text.isEmptyOrNull) {
      mHeightCont.text = a.toStringAsFixed(2).toString();
    }
    mHeightCont.selection = TextSelection.fromPosition(TextPosition(offset: mHeightCont.text.length));
    print(a.toStringAsFixed(2).toString());
  }

  Widget mWeightOption(String? value, int? index) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(6),
        backgroundColor: mWeight == index
            ? primaryColor
            : appStore.isDarkMode
                ? Colors.black
                : const Color(0xffD9D9D9),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(value!, style: secondaryTextStyle(color: mWeight == index ? Colors.white : textColor)),
    ).onTap(() {
      mWeight = index;
      hideKeyboard(context);
      if (index == 0) {
        if (!isLBSClicked) {
          convertKgToLbs();
          isLBSClicked = true;
          isKGClicked = false;
        }
      } else {
        if (!isKGClicked) {
          convertLbsToKg();
          isKGClicked = true;
          isLBSClicked = false;
        }
      }
      setState(() {});
    });
  }

  //Convert lbs to kg
  void convertLbsToKg() {
    double a = double.parse(mWeightCont.text.isEmptyOrNull ? "0.0" : mWeightCont.text.validate()) * 0.45359237;
    if (!mWeightCont.text.isEmptyOrNull) {
      mWeightCont.text = a.toStringAsFixed(2).toString();
    }
    mWeightCont.selection = TextSelection.fromPosition(TextPosition(offset: mWeightCont.text.length));
  }

  void convertKgToLbs() {
    double a = double.parse(mWeightCont.text.isEmptyOrNull ? "0.0" : mWeightCont.text.validate()) * 2.2046;
    if (!mWeightCont.text.isEmptyOrNull) {
      mWeightCont.text = a.toStringAsFixed(2).toString();
    }
    mWeightCont.selection = TextSelection.fromPosition(TextPosition(offset: mWeightCont.text.length));
  }

  Future getImage() async {
    try {
      // Show dialog to choose between camera and gallery
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Profile Picture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("❌ Error showing image picker dialog: $e");
      toast("Error showing image options: $e");
    }
  }

  Future _pickImageFromCamera() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedImage != null) {
        print("🖼️ Camera image picked: ${pickedImage.path}");
        setState(() {
          image = pickedImage;
        });
      } else {
        print("⚠️ No camera image selected");
      }
    } catch (e) {
      print("❌ Error picking camera image: $e");
      toast("Error taking photo: $e");
    }
  }

  Future _pickImageFromGallery() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedImage != null) {
        print("🖼️ Gallery image picked: ${pickedImage.path}");
        setState(() {
          image = pickedImage;
        });
      } else {
        print("⚠️ No gallery image selected");
      }
    } catch (e) {
      print("❌ Error picking gallery image: $e");
      toast("Error selecting image: $e");
    }
  }

  Widget profileImage() {
    print("🖼️ Building profile image widget");
    print("🖼️ Local image: ${image?.path}");
    print("🖼️ Profile image URL: $profileImg");

    const double avatarRadius = 45;
    const double containerSize = 90;

    if (image != null) {
      // Show locally selected image
      return Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: primaryColor.withOpacity(0.5))
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(avatarRadius),
          child: Image.file(
            File(image!.path),
            width: containerSize,
            height: containerSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("❌ Error loading local image: $error");
              return _buildDefaultAvatar(avatarRadius);
            },
          ),
        ),
      );
    } else if (!profileImg.isEmptyOrNull && profileImg!.isNotEmpty) {
      // Show profile image from server with cache busting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageUrl = profileImg!.contains('?')
          ? '$profileImg&cache=$timestamp'
          : '$profileImg?cache=$timestamp';

      print("🖼️ Using cached image with URL: $imageUrl");

      return Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: primaryColor.withOpacity(0.5))
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(avatarRadius),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: containerSize,
            height: containerSize,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              print("❌ Error loading network image: $error");
              return _buildDefaultAvatar(avatarRadius);
            },
            cacheKey: "$imageUrl-$timestamp",
          ),
        ),
      );
    } else {
      // Show default image
      return _buildDefaultAvatar(avatarRadius);
    }
  }

  Widget _buildDefaultAvatar(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: primaryColor.withOpacity(0.5)),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Icon(
          Icons.person,
          size: radius,
          color: primaryColor.withOpacity(0.7),
        ),
      ),
    );
  }

  int mSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.light,
        systemNavigationBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
                child: Stack(
              children: [
                Container(height: context.height() * 0.4, color: primaryColor),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(appStore.selectedLanguageCode == 'ar' ? MaterialIcons.arrow_forward_ios : Octicons.chevron_left, color: white, size: 28).onTap(() {
                        Navigator.pop(context);
                      }),
                      16.width,
                      Text(languages.lblEditProfile, style: boldTextStyle(size: 20, color: white)),
                    ],
                  ).paddingOnly(top: context.statusBarHeight + 32, left: 16, right: appStore.selectedLanguageCode == 'ar' ? 16 : 0), // Increased from 16 to 32
                ),
                Container(
                  margin: EdgeInsets.only(top: context.height() * 0.2),
                  height: context.height() * 0.4,
                  decoration:
                      boxDecorationWithRoundedCorners(borderRadius: radiusOnly(topRight: 16, topLeft: 16), backgroundColor: appStore.isDarkMode ? context.scaffoldBackgroundColor : Colors.white),
                ),
                Column(children: [
                  16.height,
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      profileImage(),
                      Container(
                              decoration: boxDecorationWithRoundedCorners(boxShape: BoxShape.circle, backgroundColor: primaryOpacity),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(ic_camera, color: primaryColor, height: 20, width: 20))
                          .onTap(() {
                        getImage();
                      })/*.visible(!getBoolAsync(IS_SOCIAL))*/
                    ],
                  ).paddingOnly(top: context.height() * 0.11).center(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.height,
                      Text(languages.lblFirstName, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mFNameCont,
                        textFieldType: TextFieldType.NAME,
                        isValidationRequired: true,
                        focus: mFNameFocus,
                        nextFocus: mLNameFocus,
                        suffix: mSuffixTextFieldIconWidget(ic_user),
                        decoration: defaultInputDecoration(context, label: languages.lblEnterFirstName),
                      ),
                      16.height,
                      Text(languages.lblLastName, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mLNameCont,
                        textFieldType: TextFieldType.NAME,
                        isValidationRequired: true,
                        focus: mLNameFocus,
                        nextFocus: mMobileNumberFocus,
                        suffix: mSuffixTextFieldIconWidget(ic_user),
                        decoration: defaultInputDecoration(context, label: languages.lblEnterLastName),
                      ),
                      16.height,
                      Text(languages.lblEmail, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mEmailCont,
                        textFieldType: TextFieldType.EMAIL,
                        isValidationRequired: true,
                        focus: mEmailFocus,
                        readOnly: true,
                        nextFocus: mMobileNumberFocus,
                        suffix: mSuffixTextFieldIconWidget(ic_mail),
                        decoration: defaultInputDecoration(context, label: languages.lblEnterEmail),
                      ),
                      16.height,
                      Text(languages.lblPhoneNumber, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mMobileNumberCont,
                        textFieldType: TextFieldType.PHONE,
                        isValidationRequired: true,
                        focus: mMobileNumberFocus,
                        readOnly: true,
                      //  readOnly: getBoolAsync(IS_OTP) != true ? false : true,
                        nextFocus: mAgeFocus,
                        suffix: mSuffixTextFieldIconWidget(ic_call),
                        decoration: defaultInputDecoration(context,
                            label: languages.lblEnterPhoneNumber,
                           /* mPrefix: IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CountryCodePicker(
                                    initialSelection: getStringAsync(COUNTRY_CODE, defaultValue: countryCode!),
                                    showCountryOnly: false,
                                    showFlag: false,
                                    boxDecoration: BoxDecoration(borderRadius: radius(defaultRadius), color: appStore.isDarkMode ? context.cardColor : GreyLightColor),
                                    showFlagDialog: true,
                                    showOnlyCountryWhenClosed: false,
                                    alignLeft: false,
                                    dialogTextStyle: TextStyle(
                                      color: appStore.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    searchStyle: TextStyle(
                                      color: appStore.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    textStyle: primaryTextStyle(),
                                    onInit: (c) {
                                      countryCode = c!.code;
                                    },
                                    onChanged: (c) {
                                      countryCode = c.code;
                                    },
                                  ),
                                  VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                                  16.width,
                                ],
                              ),
                            )*/),
                      ),
                      16.height,
                      Text(languages.lblAge, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        readOnly: true,
                        onTap: () {
                          _openAgePickerBottomSheet(context);
                        },
                        controller: mAgeCont,
                        textFieldType: TextFieldType.NUMBER,
                        isValidationRequired: true,
                        focus: mAgeFocus,
                        nextFocus: mWeightFocus,
                        keyboardType: TextInputType.number,
                        /*  inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[ ]')), // Block space
                          FilteringTextInputFormatter.deny(RegExp(r'[!@#\$%^&*(),.?":{}|<>-]')), // Block special characters
                        ],*/
                        suffix: mSuffixTextFieldIconWidget(ic_user),
                        decoration: defaultInputDecoration(context, label: languages.lblEnterAge),
                      ),
                      16.height,
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(languages.lblWeight, style: secondaryTextStyle()),
                            4.height,
                            AppTextField(
                              readOnly: true,
                              onTap: () {
                                _openWightPickerBottomSheet(context);
                              },
                              controller: mWeightCont,
                              textFieldType: TextFieldType.NUMBER,
                              focus: mWeightFocus,
                              nextFocus: mHeightFocus,
                              decoration: defaultInputDecoration(context, label: languages.lblEnterWeight),
                            ),
                            16.height,
                            Text(languages.lblHeight, style: secondaryTextStyle()),
                            4.height,
                            AppTextField(
                              readOnly: true,
                              onTap: () {
                                CustomeHeightPicker(
                                  heightSelected: (val) {
                                    mHeightCont.text = "$val ${userStore.heightUnit.validate()}";
                                  },
                                ).launch(context);
                              },
                              controller: mHeightCont,
                              textFieldType: TextFieldType.NUMBER,
                             // keyboardType: TextInputType.number,
                              focus: mHeightFocus,
                              decoration: defaultInputDecoration(context, label: languages.lblEnterHeight),
                            ),
                          ],
                        ),
                      ),
                      16.height,
                      Text(languages.lblGender, style: secondaryTextStyle()),
                      4.height,
                      DropdownButtonFormField<GenderModel>(
                        items: GenderList.map((e) {
                          return DropdownMenuItem<GenderModel>(
                            value: e,
                            child: Text(e.name.validate().capitalizeFirstLetter(), style: primaryTextStyle()),
                          );
                        }).toList(),
                        isExpanded: false,
                        value: GenderList.isNotEmpty ? GenderList[selectGender] : null,
                        isDense: true,
                        borderRadius: radius(),
                        decoration: defaultInputDecoration(context),
                        onChanged: (GenderModel? value) {
                          setState(() {
                            mGender = value!.key.toString();
                          });
                        },
                      ),
                      24.height,
                      AppButton(
                          text: languages.lblSave,
                          width: context.width(),
                          color: primaryColor,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              save();
                            }
                          }),
                      24.height,
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ])
              ],
            )),
            Observer(
              builder: (context) {
                return Loader().center().visible(appStore.isLoading);
              },
            )
          ],
        ),
      ),
    );
  }

  void _openWightPickerBottomSheet(BuildContext context) async {
    final res = await showModalBottomSheet<Tuple2<WeightType, double>>(
      context: context,
      isDismissible: false,
      elevation: 0,
      enableDrag: false,
      transitionAnimationController: AnimationController(vsync: this, duration: const Duration(milliseconds: 0)),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: appStore.isDarkMode ? Colors.black : const Color(0xffD9D9D9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            height: 250,
            child: Column(
              children: [
                Header(
                  weightType: weightType,
                  inKg: weight,
                ),
                Switcher(
                  weightType: weightType,
                  onChanged: (type) {
                  /*  Navigator.pop(context);
                    _openWightPickerBottomSheet(context);
                    setState(() => weightType = type);*/
                    weightType = type;
                    if (type.name == languages.lblKg && weight > 200) {
                      weight = 200;
                    } else if (type.name != languages.lblKg && weight > 400) {
                      weight = 400;
                    }
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: DivisionSlider(
                    key: ValueKey(weightType.name),
                    from: weightType.name == languages.lblKg ? 40 : 90,
                    max: weightType.name == "KG" ? 200 : 400,
                    initialValue: userStore.weight.toDouble(),
                    type: weightType,
                    onChanged: (value) {
                      setState(() => weight = value);
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
    if (res != null) {
      setState(() {
        mWeightCont.text = "${res.item2.toString()}  ${res.item1.name.toString().toLowerCase()}";
        userStore.setWeightUnit(res.item1.name.toString().toLowerCase());
        weightType = res.item1;
        weight = res.item2;
        print("-----------768>>>$weightType");
        print("-----------769>>>$weight");
      });
    }
  }

  void _openAgePickerBottomSheet(BuildContext context) async {
    final res = await showModalBottomSheet<Tuple2<WeightType, double>>(
      context: context,
      isDismissible: false,
      elevation: 0,
      transitionAnimationController: AnimationController(vsync: this, duration: const Duration(milliseconds: 500)),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? scaffoldColorDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          height: 300,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: appStore.isDarkMode ? Colors.black : const Color(0xffD9D9D9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        color: appStore.isDarkMode ? const Color(0xffD9D9D9) : Colors.black,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                      Text(languages.lblAge, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: appStore.isDarkMode ? const Color(0xffD9D9D9) : Colors.black)),
                      IconButton(
                        color: appStore.isDarkMode ? const Color(0xffD9D9D9) : Colors.black,
                        onPressed: () {
                          mAgeCont.text = mSelectedIndex.toString();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CupertinoPicker(
                      magnification: 1.4,
                      squeeze: 0.8,
                      useMagnifier: true,
                      selectionOverlay: const SizedBox(),
                      itemExtent: 32.0,
                      scrollController: FixedExtentScrollController(initialItem: userStore.age.validate().toInt() - 17),
                      onSelectedItemChanged: (int selectedItem) {
                        setState(() {
                          mSelectedIndex = selectedItem + 17;
                        });
                      },
                      children: List<Widget>.generate(99 - 17 + 1, (int index) {
                        int actualIndex = index + 17;
                        return Text(actualIndex.toString(), style: boldTextStyle(size: 30)).center();
                      }),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(height: 2, width: 100, color: primaryColor),
                        50.height,
                        Container(height: 2, width: 100, color: primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    /* if (res != null) {
      setState(() {
        mWeightCont.text = "${res.item2.toString()}  ${res.item1.name.toString().toLowerCase()}";
        userStore.setWeightUnit(res.item1.name.toString().toLowerCase());
        weightType = res.item1;
        weight = res.item2;
      });
    }*/
  }
}
