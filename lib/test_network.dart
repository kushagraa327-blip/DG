import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkTest {
  static Future<void> testConnectivity() async {
    print('=== NETWORK CONNECTIVITY TEST ===');
    
    // Test 1: Basic internet connectivity
    try {
      final response = await http.get(Uri.parse('http://google.com'))
          .timeout(const Duration(seconds: 10));
      print('✅ Basic Internet: Working (Status: ${response.statusCode})');
    } catch (e) {
      print('❌ Basic Internet: Failed - $e');
    }
    
    // Test 2: Our backend server connectivity (original domain)
    try {
      final response = await http.get(Uri.parse('https://app.dietaryguide.in'))
          .timeout(const Duration(seconds: 10));
      print('✅ Backend Server (HTTPS): Working (Status: ${response.statusCode})');
    } catch (e) {
      print('❌ Backend Server (HTTPS): Failed - $e');
    }
    
    // Test 3: Backend server HTTP fallback
    try {
      final response = await http.get(Uri.parse('http://app.dietaryguide.in'))
          .timeout(const Duration(seconds: 10));
      print('✅ Backend Server (HTTP): Working (Status: ${response.statusCode})');
    } catch (e) {
      print('❌ Backend Server (HTTP): Failed - $e');
    }
    
    // Test 4: Old IP address (for comparison)
    try {
      final response = await http.get(Uri.parse('http://100.87.43.63:8000'))
          .timeout(const Duration(seconds: 10));
      print('✅ Old Backend IP: Working (Status: ${response.statusCode})');
    } catch (e) {
      print('❌ Old Backend IP: Failed - $e');
    }
    
    print('=== NETWORK TEST COMPLETE ===');
  }
  
  static Future<void> testDNS() async {
    print('=== DNS LOOKUP TEST ===');
    
    // Test DNS lookup for the old domain
    try {
      final addresses = await InternetAddress.lookup('app.dietaryguide.in');
      print('✅ DNS app.dietaryguide.in: ${addresses.first.address}');
    } catch (e) {
      print('❌ DNS app.dietaryguide.in: Failed - $e');
    }
    
    // Test DNS lookup for google.com
    try {
      final addresses = await InternetAddress.lookup('google.com');
      print('✅ DNS google.com: ${addresses.first.address}');
    } catch (e) {
      print('❌ DNS google.com: Failed - $e');
    }
    
    print('=== DNS TEST COMPLETE ===');
  }
}
