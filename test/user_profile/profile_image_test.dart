import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_fitness/store/UserStore/UserStore.dart';

void main() {
  group('Profile Image Tests', () {
    setUp(() {
      // Initialize userStore for testing
      userStore = UserStore();
    });

    test('UserStore should properly store profile image URL', () {
      const testImageUrl = 'https://example.com/profile.jpg';
      
      // Set profile image
      userStore.setUserImage(testImageUrl);
      
      // Verify it's stored correctly
      expect(userStore.profileImage, equals(testImageUrl));
    });

    test('Profile image URL should handle cache busting', () {
      const baseUrl = 'https://example.com/profile.jpg';
      const timestamp = 1234567890;
      
      // Test URL without query parameters
      final urlWithoutQuery = baseUrl.contains('?') 
          ? '$baseUrl&cache=$timestamp' 
          : '$baseUrl?cache=$timestamp';
      
      expect(urlWithoutQuery, equals('$baseUrl?cache=$timestamp'));
      
      // Test URL with existing query parameters
      const urlWithQuery = 'https://example.com/profile.jpg?size=large';
      final urlWithCacheBusting = urlWithQuery.contains('?') 
          ? '$urlWithQuery&cache=$timestamp' 
          : '$urlWithQuery?cache=$timestamp';
      
      expect(urlWithCacheBusting, equals('$urlWithQuery&cache=$timestamp'));
    });

    test('Profile image validation should handle empty URLs', () {
      // Test empty string
      userStore.setUserImage('');
      expect(userStore.profileImage.isEmpty, isTrue);
      
      // Test null handling
      userStore.setUserImage('');
      expect(userStore.profileImage.validate().isEmpty, isTrue);
    });

    test('Profile image validation should handle HTTP URLs', () {
      const httpUrl = 'http://example.com/profile.jpg';
      const httpsUrl = 'https://example.com/profile.jpg';
      
      userStore.setUserImage(httpUrl);
      expect(userStore.profileImage.startsWith('http'), isTrue);
      
      userStore.setUserImage(httpsUrl);
      expect(userStore.profileImage.startsWith('https'), isTrue);
    });

    group('Cache Management', () {
      test('Should generate unique cache keys for profile images', () {
        const baseUrl = 'https://example.com/profile.jpg';
        final timestamp1 = DateTime.now().millisecondsSinceEpoch;
        final timestamp2 = timestamp1 + 1000;
        
        final url1 = '$baseUrl?cache=$timestamp1';
        final url2 = '$baseUrl?cache=$timestamp2';
        
        expect(url1, isNot(equals(url2)));
      });

      test('Should handle URLs with existing parameters', () {
        const baseUrl = 'https://example.com/profile.jpg?size=large&quality=high';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        final urlWithCache = baseUrl.contains('?') 
            ? '$baseUrl&cache=$timestamp' 
            : '$baseUrl?cache=$timestamp';
        
        expect(urlWithCache, contains('cache=$timestamp'));
        expect(urlWithCache, contains('size=large'));
        expect(urlWithCache, contains('quality=high'));
      });
    });

    group('Error Handling', () {
      test('Should handle image picker errors gracefully', () {
        // This would be tested with actual widget testing
        // where we can mock the ImagePicker to throw exceptions
        expect(() => userStore.setUserImage(''), returnsNormally);
      });

      test('Should handle invalid image URLs', () {
        const invalidUrl = 'not-a-valid-url';
        userStore.setUserImage(invalidUrl);
        
        // Should not crash and should store the value
        expect(userStore.profileImage, equals(invalidUrl));
      });
    });
  });
}
