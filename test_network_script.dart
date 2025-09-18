import 'lib/test_network.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 Starting Network Diagnostic Tests...\n');
  
  await NetworkTest.testConnectivity();
  print('');
  await NetworkTest.testDNS();
  
  print('\n=== API ENDPOINT TESTING ===');
  
  // Test the specific API endpoints the app will use
  await testLanguageTableAPI();
  await testLoginAPI();
  
  print('\n🏁 All tests completed!');
}

Future<void> testLanguageTableAPI() async {
  try {
    final response = await http.get(
      Uri.parse('http://app.dietaryguide.in/api/language-table-list?version_no=1'),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'accept': 'application/json; charset=utf-8',
      }
    ).timeout(const Duration(seconds: 10));
    print('✅ Language Table API: Working (Status: ${response.statusCode})');
    if (response.statusCode == 200) {
      print('   Response preview: ${response.body.substring(0, 100)}...');
    }
  } catch (e) {
    print('❌ Language Table API: Failed - $e');
  }
}

Future<void> testLoginAPI() async {
  try {
    // Test with a simple GET request first (should return method not allowed or similar)
    final response = await http.get(
      Uri.parse('http://app.dietaryguide.in/api/login'),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'accept': 'application/json; charset=utf-8',
      }
    ).timeout(const Duration(seconds: 10));
    print('✅ Login API (GET): Endpoint reachable (Status: ${response.statusCode})');
  } catch (e) {
    print('❌ Login API (GET): Failed - $e');
  }
}
