import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Official KOBI PAL legal pages (opened in the device browser).
abstract final class PalLegalUrls {
  static final Uri termsOfService =
      Uri.parse('https://kobipal.com/terms-of-service/');
  static final Uri privacyPolicy =
      Uri.parse('https://kobipal.com/privacy-policy/');
}

/// Opens [uri] in the external browser (not an in-app WebView).
Future<bool> launchExternalUrl(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[launchExternalUrl] failed for $uri: $e');
    return false;
  }
}

Future<bool> launchTermsOfService() => launchExternalUrl(PalLegalUrls.termsOfService);

Future<bool> launchPrivacyPolicy() => launchExternalUrl(PalLegalUrls.privacyPolicy);
