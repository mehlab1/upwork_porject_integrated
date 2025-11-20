// Real implementation for mobile
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service_impl.dart';

void setupFCMBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

