// Stub implementation for web platform
// This file is used when compiling for web to avoid firebase_messaging_web compatibility issues

import 'package:flutter/foundation.dart';

/// Stub FCM Service for web platform
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  Future<void> initialize() async {
    debugPrint('[FCMService] FCM not supported on web');
  }

  Future<void> unregisterDevice() async {
    debugPrint('[FCMService] FCM not supported on web');
  }

  void setNotificationTapCallback(Function(Map<String, dynamic>) callback) {
    // No-op on web
  }

  void setForegroundMessageCallback(
    Function(String title, String body, Map<String, dynamic> data) callback,
  ) {
    // No-op on web
  }

  Map<String, dynamic>? getPendingNavigationData() {
    return null;
  }

  String? get currentToken => null;
  bool get isInitialized => false;
}

/// Stub background message handler for web
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  debugPrint('[FCMService] Background messages not supported on web');
}

