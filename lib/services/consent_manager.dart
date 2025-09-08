import 'package:shared_preferences/shared_preferences.dart';

class ConsentManager {
  static const String _privacyConsentKey = 'privacy_consent_given';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _consentVersionKey = 'consent_version';
  
  static const String currentConsentVersion = '1.0.0';
  
  static Future<bool> hasGivenConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final consentGiven = prefs.getBool(_privacyConsentKey) ?? false;
    final consentVersion = prefs.getString(_consentVersionKey) ?? '';
    
    return consentGiven && consentVersion == currentConsentVersion;
  }
  
  static Future<void> giveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyConsentKey, true);
    await prefs.setString(_consentVersionKey, currentConsentVersion);
    await prefs.setInt(_consentTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  static Future<void> withdrawConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyConsentKey, false);
    await prefs.remove(_consentTimestampKey);
  }
  
  static Future<DateTime?> getConsentTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_consentTimestampKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privacyConsentKey);
    await prefs.remove(_consentTimestampKey);
    await prefs.remove(_consentVersionKey);
  }
}
