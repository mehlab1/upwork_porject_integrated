# 🔥 Firebase Cloud Messaging (FCM) Setup Guide
## Complete Guide for Android & iOS Push Notifications

---

## 📋 Prerequisites

- Firebase Account (free)
- Flutter project
- Supabase project
- Android Studio (for Android)
- Xcode (for iOS, macOS only)

---

## 🎯 Part 1: Firebase Project Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `k2mvp` (or your app name)
4. Disable Google Analytics (optional)
5. Click **"Create project"**

### Step 2: Download Service Account Key

1. In Firebase Console → Click gear icon ⚙️ → **Project settings**
2. Go to **"Service accounts"** tab
3. Click **"Generate new private key"**
4. Click **"Generate key"** → Save the JSON file
5. **Keep this file secure!** You'll need it for Supabase

---

## 📱 Part 2: Android Setup

### Step 1: Add Android App to Firebase

1. In Firebase Console → Click Android icon (robot)
2. **Android package name**: `com.yourcompany.k2mvp` (get from `android/app/build.gradle`)
3. **App nickname**: K2MVP Android
4. **Debug signing certificate SHA-1**: (optional for now)
5. Click **"Register app"**
6. Download `google-services.json`

### Step 2: Configure Android Project

1. **Place google-services.json**
   ```
   k2mvp/
   └── android/
       └── app/
           └── google-services.json  ← Place here
   ```

2. **Edit `android/build.gradle`**:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.android.tools.build:gradle:8.1.0'
           classpath 'com.google.gms:google-services:4.4.0'  // ← Add this
       }
   }
   ```

3. **Edit `android/app/build.gradle`**:
   
   Add at the TOP (after `plugins` block):
   ```gradle
   plugins {
       id "com.android.application"
       id "kotlin-android"
       id "dev.flutter.flutter-gradle-plugin"
   }
   
   apply plugin: 'com.google.gms.google-services'  // ← Add this line
   ```

   Add in `dependencies` section:
   ```gradle
   dependencies {
       implementation platform('com.google.firebase:firebase-bom:32.7.0')
       implementation 'com.google.firebase:firebase-messaging'
   }
   ```

4. **Edit `android/app/src/main/AndroidManifest.xml`**:
   
   Add inside `<application>` tag:
   ```xml
   <application>
       <!-- ... existing code ... -->
       
       <!-- FCM Service -->
       <service
           android:name="com.google.firebase.messaging.FirebaseMessagingService"
           android:exported="false">
           <intent-filter>
               <action android:name="com.google.firebase.MESSAGING_EVENT" />
           </intent-filter>
       </service>
       
       <!-- Default notification channel -->
       <meta-data
           android:name="com.google.firebase.messaging.default_notification_channel_id"
           android:value="high_importance_channel" />
   </application>
   ```

---

## 🍎 Part 3: iOS Setup

### Step 1: Add iOS App to Firebase

1. In Firebase Console → Click iOS icon (apple)
2. **iOS bundle ID**: `com.yourcompany.k2mvp` (get from Xcode)
3. **App nickname**: K2MVP iOS
4. **App Store ID**: (leave blank for now)
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`

### Step 2: Configure iOS Project

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add GoogleService-Info.plist**:
   - Drag `GoogleService-Info.plist` into `Runner` folder in Xcode
   - ✅ Check "Copy items if needed"
   - ✅ Check "Runner" target
   - Click "Finish"

3. **Enable Push Notifications Capability**:
   - In Xcode, select **Runner** project
   - Select **Runner** target
   - Go to **"Signing & Capabilities"** tab
   - Click **"+ Capability"**
   - Add **"Push Notifications"**
   - Add **"Background Modes"** → Check ✅ **"Remote notifications"**

### Step 3: Configure Apple Push Notification Service (APNs)

1. **Create APNs Authentication Key**:
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
   - Click **"+"** to create new key
   - Name: `K2MVP APNs Key`
   - Check ✅ **"Apple Push Notifications service (APNs)"**
   - Click **"Continue"** → **"Register"**
   - Download `.p8` file (⚠️ you can only download once!)
   - Note the **Key ID** and **Team ID**

2. **Upload APNs Key to Firebase**:
   - Firebase Console → Project Settings → Cloud Messaging tab
   - Under **"Apple app configuration"**
   - Click **"Upload"** next to APNs Authentication Key
   - Upload your `.p8` file
   - Enter **Key ID** and **Team ID**
   - Click **"Upload"**

---

## 📦 Part 4: Flutter Setup

### Step 1: Install Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

Run:
```bash
flutter pub get
```

### Step 2: Initialize Firebase

**Edit `lib/main.dart`**:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

// Notification channel for Android
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize local notifications for Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Create high importance notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  
  // Request notification permissions
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  print('Permission status: ${settings.authorizationStatus}');
  
  runApp(MyApp());
}
```

### Step 3: Create FCM Service

Create `lib/services/fcm_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  String? _token;
  
  /// Initialize FCM and register device token
  Future<void> initialize() async {
    // Get FCM token
    _token = await _messaging.getToken();
    print('FCM Token: $_token');
    
    if (_token != null) {
      await _registerDeviceToken(_token!);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _registerDeviceToken(newToken);
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  /// Register device token with Supabase
  Future<void> _registerDeviceToken(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      
      // Check if token already exists
      final existing = await Supabase.instance.client
          .from('push_notification_devices')
          .select()
          .eq('device_token', token)
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (existing == null) {
        // Insert new token
        await Supabase.instance.client
            .from('push_notification_devices')
            .insert({
          'user_id': user.id,
          'device_token': token,
          'device_type': deviceType,
          'is_active': true,
        });
      } else {
        // Update existing token to active
        await Supabase.instance.client
            .from('push_notification_devices')
            .update({
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', existing['id']);
      }
      
      print('Device token registered successfully');
    } catch (e) {
      print('Error registering device token: $e');
    }
  }
  
  /// Handle foreground notifications
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.messageId}');
    
    // Show local notification
    _showLocalNotification(message);
  }
  
  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New notification',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    // Navigate based on notification data
    final data = message.data;
    if (data.containsKey('post_id')) {
      // Navigate to post details
      // navigatorKey.currentState?.pushNamed('/post', arguments: data['post_id']);
    }
  }
  
  /// Unregister device token (call on logout)
  Future<void> unregisterDevice() async {
    try {
      if (_token == null) return;
      
      await Supabase.instance.client
          .from('push_notification_devices')
          .update({'is_active': false})
          .eq('device_token', _token!);
      
      print('Device token unregistered');
    } catch (e) {
      print('Error unregistering device: $e');
    }
  }
}
```

### Step 4: Use FCM Service

In your app initialization (after Supabase.initialize()):

```dart
// After user logs in
await FCMService().initialize();

// On logout
await FCMService().unregisterDevice();
```

---

## 🔐 Part 5: Supabase Configuration

### Step 1: Set Environment Variable

1. Go to Supabase Dashboard → Project Settings → Edge Functions
2. Add environment variable:
   - **Name**: `FCM_SERVICE_ACCOUNT_JSON`
   - **Value**: Paste entire contents of Firebase service account JSON file

### Step 2: Deploy Edge Function

```powershell
supabase functions deploy send-push-notification
```

---

## ✅ Part 6: Testing

### Test on Android

1. Run app: `flutter run`
2. Check console for FCM token
3. Send test notification from Firebase Console:
   - Firebase Console → Cloud Messaging → Send test message
   - Paste FCM token
   - Send

### Test on iOS

1. Run on real device (simulator doesn't support push)
2. Accept notification permission
3. Check console for FCM token
4. Send test notification from Firebase Console

### Test from Supabase

```sql
SELECT send_push_notification(
  'your-user-id',
  'test',
  'Test Notification',
  'This is a test message from Supabase'
);
```

---

## 🐛 Troubleshooting

### Android Issues

1. **"google-services.json not found"**
   - Ensure file is in `android/app/` directory
   - Run `flutter clean && flutter pub get`

2. **Build fails with "Duplicate class"**
   - Check Firebase BOM version matches
   - Remove duplicate dependencies

### iOS Issues

1. **"No APNs certificates"**
   - Upload APNs key in Firebase Console
   - Verify bundle ID matches

2. **Notifications not received**
   - Check device is real (not simulator)
   - Verify APNs key is uploaded
   - Check notification permissions granted

---

## 📚 Additional Resources

- [Firebase FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [APNs Setup Guide](https://firebase.google.com/docs/cloud-messaging/ios/certs)

---

✅ **Setup Complete!** Your app now supports push notifications on both Android and iOS using FCM.
