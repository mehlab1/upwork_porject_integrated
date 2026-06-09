import 'package:flutter/material.dart';

import '../screens/onboarding/tracking_permissions_screen.dart';
import '../services/tracking_consent_service.dart';

/// Shows the tracking consent screen once, then runs [onContinue].
Future<void> runWithTrackingConsentCheck(
  BuildContext context,
  Future<void> Function() onContinue,
) async {
  final service = TrackingConsentService.instance;
  if (await service.shouldShowConsentScreen()) {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TrackingPermissionsScreen(),
      ),
    );
  }
  if (!context.mounted) return;
  await onContinue();
}

/// Pushes [destination] after consent; completes when [destination] is popped.
Future<void> navigateWithTrackingConsentCheck(
  BuildContext context, {
  required Widget destination,
  bool replace = false,
}) async {
  await runWithTrackingConsentCheck(context, () async {
    if (!context.mounted) return;
    final route = MaterialPageRoute(builder: (_) => destination);
    if (replace) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
    }
  });
}
