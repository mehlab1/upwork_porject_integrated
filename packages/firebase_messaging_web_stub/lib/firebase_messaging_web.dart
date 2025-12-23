// Stub implementation to avoid firebase_messaging_web compilation errors on web
// This package provides empty implementations that do nothing

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Stub FirebaseMessagingWeb class
class FirebaseMessagingWeb {
  FirebaseMessagingWeb._();
  
  static FirebaseMessagingWeb get instance => FirebaseMessagingWeb._();
  
  /// Register the plugin with Flutter's web plugin system
  static void registerWith(Registrar registrar) {
    // No-op: This is a stub, so we don't actually register anything
    // The real firebase_messaging_web would register platform channels here
  }
  
  Future<String?> getToken({String? vapidKey}) async => null;
  Future<void> deleteToken() async {}
  Future<bool> isSupported() async => false;
  
  void onMessage(void Function(dynamic) callback) {}
  void onMessageOpenedApp(void Function(dynamic) callback) {}
  Future<dynamic> getInitialMessage() async => null;
}

