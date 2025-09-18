import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy consent management for GDPR/Data Safety compliance
class PrivacyConsentManager {
  static const String _consentKey = 'privacy_consent_given';
  static const String _analyticsConsentKey = 'analytics_consent';
  static const String _adsConsentKey = 'ads_consent';

  /// Check if user has given basic privacy consent
  static Future<bool> hasGivenConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Set privacy consent status
  static Future<void> setConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, consent);
  }

  /// Check if user has consented to analytics
  static Future<bool> hasAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsConsentKey) ?? false;
  }

  /// Set analytics consent
  static Future<void> setAnalyticsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, consent);
  }

  /// Check if user has consented to personalized ads
  static Future<bool> hasAdsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adsConsentKey) ?? false;
  }

  /// Set ads consent
  static Future<void> setAdsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsConsentKey, consent);
  }

  /// Show privacy consent dialog
  static Future<bool> showConsentDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy & Data Usage'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We value your privacy. This app collects certain data to provide you with the best experience:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text('• Device identifiers for analytics and crash reporting'),
                const Text('• Usage data to improve app performance'),
                const Text('• Advertising ID for relevant ads (optional)'),
                const SizedBox(height: 16),
                Text(
                  'You can change these preferences anytime in Settings.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await setConsent(true);
      await setAnalyticsConsent(true);
      await setAdsConsent(true);
    }

    return result ?? false;
  }

  /// Initialize consent check on app start
  static Future<void> initializeConsent(BuildContext context) async {
    if (!await hasGivenConsent()) {
      await showConsentDialog(context);
    }
  }
}

/// Privacy settings screen widget
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _analyticsConsent = false;
  bool _adsConsent = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final analytics = await PrivacyConsentManager.hasAnalyticsConsent();
    final ads = await PrivacyConsentManager.hasAdsConsent();
    
    setState(() {
      _analyticsConsent = analytics;
      _adsConsent = ads;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Collection Preferences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            SwitchListTile(
              title: const Text('Analytics'),
              subtitle: const Text('Help improve the app with usage analytics'),
              value: _analyticsConsent,
              onChanged: (bool value) async {
                await PrivacyConsentManager.setAnalyticsConsent(value);
                setState(() {
                  _analyticsConsent = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('Personalized Ads'),
              subtitle: const Text('Show ads tailored to your interests'),
              value: _adsConsent,
              onChanged: (bool value) async {
                await PrivacyConsentManager.setAdsConsent(value);
                setState(() {
                  _adsConsent = value;
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Data Collection',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We collect device identifiers and usage data to provide core app functionality, improve performance, and show relevant content. You can control optional features like personalized advertising.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
