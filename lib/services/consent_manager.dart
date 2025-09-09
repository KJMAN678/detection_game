import 'package:shared_preferences/shared_preferences.dart';

class ConsentManager {
  static const String _privacyConsentKey = 'privacy_consent_given';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _consentVersionKey = 'consent_version';
  // データ送信（Vision API 送信）に関する同意
  static const String _dataTxConsentKey = 'data_tx_consent_given';
  static const String _dataTxConsentVersionKey = 'data_tx_consent_version';
  
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

  // --------- データ送信同意（ゲーム開始前に一度だけ確認） ---------
  static Future<bool> hasGivenDataTransmissionConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final given = prefs.getBool(_dataTxConsentKey) ?? false;
    final ver = prefs.getString(_dataTxConsentVersionKey) ?? '';
    return given && ver == currentConsentVersion;
  }

  static Future<void> giveDataTransmissionConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataTxConsentKey, true);
    await prefs.setString(_dataTxConsentVersionKey, currentConsentVersion);
  }

  static Future<void> withdrawDataTransmissionConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataTxConsentKey, false);
    await prefs.remove(_dataTxConsentVersionKey);
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
    await prefs.remove(_dataTxConsentKey);
    await prefs.remove(_dataTxConsentVersionKey);
  }
}
