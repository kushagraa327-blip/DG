import 'dart:io' show Platform;

class EnvConfig {
  static String get chatGptApiKey => Platform.environment['CHATGPT_API_KEY'] ?? '';
  static String get stripeSecretKey => Platform.environment['STRIPE_SECRET_KEY'] ?? '';
  static String get stripePublishableKey => Platform.environment['STRIPE_PUBLISHABLE_KEY'] ?? '';
  
  // Add other API keys as needed
  
  static bool get isProduction => Platform.environment['FLUTTER_ENV'] == 'production';
  
  static void validateConfig() {
    assert(chatGptApiKey.isNotEmpty, 'ChatGPT API key not found in environment');
    assert(stripeSecretKey.isNotEmpty, 'Stripe secret key not found in environment');
    assert(stripePublishableKey.isNotEmpty, 'Stripe publishable key not found in environment');
  }
}
