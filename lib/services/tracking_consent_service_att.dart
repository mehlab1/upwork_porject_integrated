import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Requests Apple's App Tracking Transparency prompt on iOS 14+.
Future<void> requestAppTrackingAuthorization() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.iOS) return;

  try {
    final status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    debugPrint('[TrackingConsentService] ATT request failed: $e');
  }
}
