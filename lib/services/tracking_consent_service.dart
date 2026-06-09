import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tracking_consent_service_att.dart'
    if (dart.library.html) 'tracking_consent_service_att_stub.dart'
    as att;

/// Persists personalized-experience consent and triggers the iOS ATT system dialog
/// when the user opts in.
class TrackingConsentService {
  TrackingConsentService._();
  static final TrackingConsentService instance = TrackingConsentService._();

  static const String _promptCompletedKey = 'tracking_consent_prompt_completed';
  static const String _personalizedAllowedKey =
      'tracking_personalized_experience_allowed';

  Future<bool> hasCompletedConsentPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_promptCompletedKey) ?? false;
    } catch (e) {
      debugPrint('[TrackingConsentService] read prompt completed: $e');
      return false;
    }
  }

  Future<bool> isPersonalizedExperienceAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_personalizedAllowedKey) ?? false;
    } catch (e) {
      debugPrint('[TrackingConsentService] read personalized allowed: $e');
      return false;
    }
  }

  /// Whether the in-app consent screen should be shown (first launch / never answered).
  Future<bool> shouldShowConsentScreen() async {
    return !(await hasCompletedConsentPrompt());
  }

  /// User accepted personalized experience — save choice, then iOS ATT if applicable.
  Future<void> grantPersonalizedExperience() async {
    await _saveConsent(allowed: true);
    await att.requestAppTrackingAuthorization();
  }

  /// User declined personalized tracking — save choice; do not show iOS ATT.
  Future<void> denyPersonalizedExperience() async {
    await _saveConsent(allowed: false);
  }

  Future<void> _saveConsent({required bool allowed}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_promptCompletedKey, true);
      await prefs.setBool(_personalizedAllowedKey, allowed);
    } catch (e) {
      debugPrint('[TrackingConsentService] save consent: $e');
    }
  }

  /// Clears stored consent (e.g. for testing).
  Future<void> resetForTesting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promptCompletedKey);
      await prefs.remove(_personalizedAllowedKey);
    } catch (e) {
      debugPrint('[TrackingConsentService] reset: $e');
    }
  }
}
