//region App Name
import 'package:mighty_fitness/utils/app_images.dart';

import '../main.dart';

const APP_NAME = "Dietary Guide"; 
//endregion
var initialSteps = 0;

//region baseurl
/// Note: /Add your domain is www.abc.com
const bool enableFirebaseAnalytics = true;
const bool enableFirebaseCrashlytics = true;
const bool allowBackgroundRefreash = true;

const mBackendURL = "https://app.dietaryguide.in";

class AppConfig {
  static const String DEBUG_MODE = "DEBUG_MODE";

  static const int WALK_THROUGH_COUNT = 3;

  static const String DEFAULT_LANGUAGE = "en";

  static const int DATE_SELECTION_MIN_AGE = 18;

  static const int DATE_SELECTION_MAX_AGE = 90;

  static const String PRIVACY_POLICY_URL = "";

  static const String TERMS_CONDITIONS_URL = "";
}
//const mBackendURL = "https://app.dietaryguide.in";
// Alternative URLs for testing (uncomment if needed)
// const mBackendURL = "https://your-domain.com"; // HTTPS version
// const mBackendURL = "http://localhost:8000"; // Local development



//endregion
//region Default Language Code
const DEFAULT_LANGUAGE = 'en';
//endregion

//region Change Walk Through Text
String WALK1_TITLE = languages.lblWalkTitle1;
String WALK2_TITLE = languages.lblWalkTitle2;
String WALK3_TITLE = languages.lblWalkTitle3;
//endregion

//region onesignal
const mOneSignalID = 'beb048d2-4bdf-421b-8767-b1a45528efeb';
//endregion

//region country

String? countryCode = "+91";
String? countryDail = "+91";
//endregion

//region logins
const ENABLE_SOCIAL_LOGIN = true;
const ENABLE_GOOGLE_SIGN_IN = true;
const ENABLE_OTP = true;
const ENABLE_APPLE_SIGN_IN = true;
//endregion

//region perPage value
const EQUIPMENT_PER_PAGE = 10;
const LEVEL_PER_PAGE = 10;
const WORKOUT_TYPE_PAGE = 10;
//endregion

//region payment description and identifier
const mRazorDescription = 'YOUR_PAYMENT_DESCRIPTION';
const mStripeIdentifier = 'YOUR_PAYMENT_IDENTIFIER';
//endregion

//region urls
const mBaseUrl = '$mBackendURL/api/';
//endregion

//region Manage Ads
// const showAdOnDietDetail = false;
// const showAdOnBlogDetail = false;
// const showAdOnExerciseDetail = false;
// const showAdOnProductDetail = false;
// const showAdOnWorkoutDetail = false;
// const showAdOnProgressDetail = false;

// const showBannerAdOnDiet = false;
// const showBannerOnProduct = false;
// const showBannerOnBodyPart = false;
// const showBannerOnEquipment = false;
// const showBannerOnLevel = false;
// const showBannerOnWorkouts = false;
//endregion



const List<String> firstTitles = ['Build muscle', 'Keep Fit', 'Lose weight'];
const List<String> firstDescriptions = [
  'Lower weight with higher reps and work on medium and small muscles',
  'Start with basic muscle workout plans and keep your muscles fit and toned',
  'Lower weight with higher reps and shorter rest times with cardio exercises',
];
final List<String> firstIcons = [
  ic_build,
  ic_keep,
  ic_lose,
];


const List<String> secondTitles = ['Totally newbie', 'beginner', 'Intermediate', 'Advanced'];
const List<String> secondDescriptions = [
  'I never workedout before',
  'I worked out before but not seriously',
  'I worked out before',
  'I have been working out for years',
];
final List<String> secondIcons = [
  empty_graph,
  one_graph,
  two_graph,
  full_graph,

];



const List<String> thirdTitles = ['No Equipment', 'Dumbbells', 'Garage Gym', 'Full Gym', 'Custom'];
const List<String> thirdDescriptions = [
  'Home workouts with body weight exercises',
  'Only exercises with dumbbell and body weight',
  'Exercises with barbell,dumbbell and body weight',
  'All exercises with machines,barbell and all',
  'Choose the equipments you have or wish to use',
];
final List<String> thirdIcons = [
  ic_noequpment,
  ic_dumbbell,
  garage_gym,
  full_gym,
  custom,
];



const mOneSignalAppId = 'beb048d2-4bdf-421b-8767-b1a45528efeb';
const mOneSignalRestKey = 'os_v2_app_x2yerusl35bbxb3hwgsfkkhp5mdaacqjd3melavhisic4cuwmlhqfqivxsswiug4av2i4o7sk3yfkp6wrwqrhgtmtu2jnjzz56jz76q';
const mOneSignalChannelId = 'daacqjd3melavhisic4cuwmlh';

//firebase keys
const FIREBASE_KEY = "AIzaSyB_rqIrBUi266frtvf-VZets3dHvTmCcjg";
const FIREBASE_APP_ID = "1:794121483501:android:54e220bf941852e43788e4";
const FIREBASE_MESSAGE_SENDER_ID = "794121483501";
const FIREBASE_PROJECT_ID = "dietary-guide-c6c4a";
const FIREBASE_STORAGE_BUCKET_ID = "dietary-guide-c6c4a.firebasestorage.app";

