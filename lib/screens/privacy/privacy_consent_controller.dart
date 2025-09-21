import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/services/consent_manager.dart';

final privacyConsentProvider = FutureProvider<bool>((ref) async {
  return ConsentManager.hasGivenConsent();
});

final dataTransmissionConsentProvider = FutureProvider<bool>((ref) async {
  return ConsentManager.hasGivenDataTransmissionConsent();
});

final givePrivacyConsentProvider = Provider<Future<void> Function()>((ref) {
  return () => ConsentManager.giveConsent();
});

final giveDataTransmissionConsentProvider = Provider<Future<void> Function()>((ref) {
  return () => ConsentManager.giveDataTransmissionConsent();
});
