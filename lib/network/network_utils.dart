import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../extensions/shared_pref.dart';
import '../screens/sign_in_screen.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/system_utils.dart';
import '../main.dart';
import '../utils/app_config.dart';
import '../utils/app_constants.dart';

// Create HTTP client that accepts all certificates
http.Client _createHttpClient() {
  HttpClient httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(httpClient);
}

Map<String, String> buildHeaderTokens() {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.acceptHeader: 'application/json; charset=utf-8',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Origin': '*',
  };

  // Add proper timezone header
  String timezone = _getProperTimezoneForHeaders();
  header['X-Timezone'] = timezone;

  if (userStore.isLoggedIn || getBoolAsync(IS_SOCIAL)) {
    header.putIfAbsent(HttpHeaders.authorizationHeader, () => 'Bearer ${userStore.token}');
  }
  log(jsonEncode(header));
  return header;
}

// Helper function to get proper timezone identifier for headers
String _getProperTimezoneForHeaders() {
  String timezone = DateTime.now().timeZoneName;
  Duration offset = DateTime.now().timeZoneOffset;

  log('DEBUG: Original timezone name for headers: $timezone');
  log('DEBUG: Timezone offset for headers: $offset');

  // Handle timezone offset format (e.g., "+05:00", "-08:00", "05:00")
  if (timezone.contains(':') && (timezone.startsWith('+') || timezone.startsWith('-') || RegExp(r'^\d{2}:\d{2}$').hasMatch(timezone))) {
    // Convert timezone offset to proper timezone identifier
    int hours;

    // If timezone is just "05:00" without sign, parse it directly
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timezone)) {
      List<String> parts = timezone.split(':');
      hours = int.parse(parts[0]);
      log('DEBUG: Parsed timezone offset from string "$timezone" for headers, hours: $hours');
    } else {
      hours = offset.inHours;
      log('DEBUG: Detected timezone offset format for headers, hours: $hours');
    }

    // Map common timezone offsets to proper identifiers
    String result;
    switch (hours) {
      case 5:
      case 6: // IST can be +05:30 or +06:00 depending on DST
        result = 'Asia/Kolkata';
        break;
      case -8:
        result = 'America/Los_Angeles';
        break;
      case -5:
        result = 'America/New_York';
        break;
      case 0:
        result = 'Europe/London';
        break;
      case 9:
        result = 'Asia/Tokyo';
        break;
      case -6:
        result = 'America/Chicago';
        break;
      default:
        result = 'UTC';
    }

    log('DEBUG: Converted timezone offset for headers to: $result');
    return result;
  }

  // Map common timezone names to proper identifiers
  String result;
  switch (timezone) {
    case 'IST':
      result = 'Asia/Kolkata';
      break;
    case 'PST':
      result = 'America/Los_Angeles';
      break;
    case 'EST':
      result = 'America/New_York';
      break;
    case 'GMT':
      result = 'Europe/London';
      break;
    case 'JST':
      result = 'Asia/Tokyo';
      break;
    case 'CST':
      result = 'America/Chicago';
      break;
    default:
      // If it's already a proper timezone identifier, return as is
      if (timezone.contains('/')) {
        result = timezone;
      } else {
        // Fallback to UTC if unknown
        result = 'UTC';
      }
  }

  log('DEBUG: Final timezone result for headers: $result');
  return result;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('$mBaseUrl$endPoint');

  log('URL: ${url.toString()}');

  return url;
}

Future<Response> buildHttpResponse(String endPoint, {HttpMethod method = HttpMethod.GET, Map? request}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl(endPoint);

    Response response;

    // Add timeout configuration
    const Duration timeoutDuration = Duration(seconds: 30);
    final client = _createHttpClient();

    try {
      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await client.post(url, body: jsonEncode(request), headers: headers).timeout(timeoutDuration);
      } else if (method == HttpMethod.DELETE) {
        response = await client.delete(url, headers: headers).timeout(timeoutDuration);
      } else if (method == HttpMethod.PUT) {
        response = await client.put(url, body: jsonEncode(request), headers: headers).timeout(timeoutDuration);
      } else {
        response = await client.get(url, headers: headers).timeout(timeoutDuration);
      }

      log('Response ($method): ${response.statusCode} ${response.body}');

      return response;
    } catch (e) {
      log('Network Error: $e');
      if (e.toString().contains('TimeoutException')) {
        throw 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException')) {
        throw 'No internet connection. Please check your network settings.';
      } else {
        throw 'Network error: ${e.toString()}';
      }
    } finally {
      client.close();
    }
  } else {
    throw errorInternetNotAvailable;
  }
}

@deprecated
Future<Response> getRequest(String endPoint) async => buildHttpResponse(endPoint);

@deprecated
Future<Response> postRequest(String endPoint, Map request) async => buildHttpResponse(endPoint, request: request, method: HttpMethod.POST);

Future handleResponse(Response response) async {
  print("DEBUG: handleResponse called with status: ${response.statusCode}");
  print("DEBUG: Response body: ${response.body}");

  if (!await isNetworkAvailable()) {
    print("DEBUG: Network not available");
    throw errorInternetNotAvailable;
  }

  if (response.statusCode.isSuccessful()) {
    print("DEBUG: Successful response, parsing JSON");
    try {
      var result = jsonDecode(response.body);
      print("DEBUG: JSON parsed successfully: $result");
      return result;
    } catch (e) {
      print("DEBUG: JSON parsing failed: $e");
      throw "Failed to parse response: $e";
    }
  } else {
    print("DEBUG: Error response with status: ${response.statusCode}");
    var string = await (isJsonValid(response.body));
    print("jsonDecode(response.body)$string");
    if (string!.isNotEmpty) {
      if (string.toString().contains("Unauthenticated")) {
        await removeKey(IS_LOGIN);
        await removeKey(USER_ID);
        await removeKey(FIRSTNAME);
        await removeKey(LASTNAME);
        await removeKey(USER_PROFILE_IMG);
        await removeKey(DISPLAY_NAME);
        await removeKey(PHONE_NUMBER);
        await removeKey(GENDER);
        await removeKey(AGE);
        await removeKey(HEIGHT);
        await removeKey(HEIGHT_UNIT);
        await removeKey(IS_OTP);
        await removeKey(IS_SOCIAL);
        await removeKey(WEIGHT);
        await removeKey(WEIGHT_UNIT);
        userStore.clearUserData();
        if (getBoolAsync(IS_SOCIAL) || !getBoolAsync(IS_REMEMBER)) {
          await removeKey(PASSWORD);
          await removeKey(EMAIL);
        }
        userStore.setLogin(false);
        push(SignInScreen(), isNewTask: true);
      } else {
        throw string;
      }
    } else {
      throw 'Please try again later.';
    }
  }
}

//region Common
enum HttpMethod { GET, POST, DELETE, PUT }

class TokenException implements Exception {
  final String message;

  const TokenException([this.message = ""]);

  @override
  String toString() => "FormatException: $message";
}
//endregion

Future<String?> isJsonValid(json) async {
  try {
    var f = jsonDecode(json) as Map<String, dynamic>;
    return f['message'];
  } catch (e) {
    log(e.toString());
    return "";
  }
}

Future<MultipartRequest> getMultiPartRequest(String endPoint, {String? baseUrl}) async {
  String url = baseUrl ?? buildBaseUrl(endPoint).toString();
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future<void> sendMultiPartRequest(MultipartRequest multiPartRequest, {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  http.Response response = await http.Response.fromStream(await multiPartRequest.send());
  print("Result: ${response.body}");

  if (response.statusCode.isSuccessful()) {
    onSuccess?.call(response.body);
  } else {
    onError?.call(errorSomethingWentWrong);
  }
}
