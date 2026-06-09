import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notification_display_service.dart';
import 'push_notification_group_store.dart';

/// FCM Service for handling push notifications
/// 
/// This service:
/// - Initializes Firebase Cloud Messaging
/// - Manages FCM tokens and syncs them with Supabase
/// - Sets up notification channels (Android)
/// - Handles foreground, background, and terminated state notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _currentToken;
  String? _pendingTokenSync;
  bool _isInitialized = false;

  /// Initialize FCM service
  /// Should be called after user login
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[FCMService] Already initialized');
      return;
    }

    try {
      // Request notification permissions
      await _requestPermissions();

      // Set up notification channels (Android)
      await _setupNotificationChannels();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getToken();

      // Retry token sync if registration failed earlier
      await _retryPendingTokenSync();

      // Set up message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('========================================');
        print('[FCMService] FCM Token Refreshed:');
        print('New Token: $newToken');
        print('========================================');
        debugPrint('[FCMService] Token refreshed: $newToken');
        _currentToken = newToken;
        final synced = await _saveTokenToSupabase(newToken);
        if (!synced) {
          _pendingTokenSync = newToken;
        }
      });

      _isInitialized = true;
      print('[FCMService] FCM Service initialized successfully');
      if (_currentToken != null) {
        print('[FCMService] Current FCM Token: $_currentToken');
      }
      debugPrint('[FCMService] Initialized successfully');
    } catch (e) {
      debugPrint('[FCMService] Initialization error: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCMService] iOS Permission status: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      // Android 13+ requires runtime permission
      final androidInfo = await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidInfo != null) {
        final granted = await androidInfo.requestNotificationsPermission();
        debugPrint('[FCMService] Android notification permission: $granted');
      }
    }
  }

  /// Set up notification channels for Android
  Future<void> _setupNotificationChannels() async {
    if (!Platform.isAndroid) return;
    await PushNotificationDisplayService.ensureAndroidNotificationChannel(
      _localNotifications,
    );
    debugPrint('[FCMService] Notification channel created: high_importance_channel');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await PushNotificationDisplayService.ensureInitialized(_localNotifications);

    debugPrint('[FCMService] Local notifications initialized');
  }

  /// Handle notification tap (from local/system notification shown for foreground FCM)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCMService] Notification tapped: ${response.payload}');

    Map<String, dynamic>? data = _lastForegroundMessageData;
    if ((data == null || data.isEmpty) &&
        response.payload != null &&
        response.payload!.isNotEmpty) {
      try {
        data = jsonDecode(response.payload!) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('[FCMService] Could not parse notification payload');
      }
    }

    if (data != null && data.isNotEmpty) {
      _pendingNavigationData = data;
      if (_onNotificationTapCallback != null) {
        _onNotificationTapCallback!(data);
      }
      _lastForegroundMessageData = null;
    }
  }

  /// Get notification navigation data from RemoteMessage
  static Map<String, dynamic>? getNavigationData(RemoteMessage message) {
    return message.data;
  }

  /// Callback for notification tap navigation (background/terminated + local tap)
  Function(Map<String, dynamic>)? _onNotificationTapCallback;
  Map<String, dynamic>? _pendingNavigationData;

  /// Callback for foreground messages — used to show in-app banner (PalPushNotification)
  Function(String title, String body, Map<String, dynamic> data)? _onForegroundMessageCallback;

  /// Last foreground message data — used when the local notification is tapped
  Map<String, dynamic>? _lastForegroundMessageData;

  /// Set callback for notification tap handling (background/terminated)
  void setNotificationTapCallback(Function(Map<String, dynamic>) callback) {
    _onNotificationTapCallback = callback;
  }

  /// Set callback for foreground messages — show an in-app banner (PalPushNotification)
  void setForegroundMessageCallback(
    Function(String title, String body, Map<String, dynamic> data) callback,
  ) {
    _onForegroundMessageCallback = callback;
  }

  /// Get pending navigation data and clear it
  Map<String, dynamic>? getPendingNavigationData() {
    final data = _pendingNavigationData;
    _pendingNavigationData = null;
    return data;
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    debugPrint('[FCMService] Handling notification tap with data: $data');
    
    // Store notification data for navigation
    _pendingNavigationData = data;
    
    // Trigger navigation callback if set
    if (_onNotificationTapCallback != null) {
      _onNotificationTapCallback!(data);
    }
  }

  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      
      // Log token in both debug and release modes
      print('========================================');
      print('[FCMService] FCM Token Retrieved:');
      print('Token: $_currentToken');
      print('========================================');
      debugPrint('[FCMService] FCM Token: $_currentToken');
      
      if (_currentToken != null) {
        final synced = await _saveTokenToSupabase(_currentToken!);
        if (!synced) {
          _pendingTokenSync = _currentToken;
        }
      }
      
      return _currentToken;
    } catch (e) {
      print('[FCMService] Error getting token: $e');
      debugPrint('[FCMService] Error getting token: $e');
      return null;
    }
  }

  /// Register device token with Supabase via Edge Function
  /// 
  /// Calls the register-device Edge Function to register the FCM token
  Future<bool> _saveTokenToSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('[FCMService] No user logged in, skipping token registration');
        return false;
      }

      // Get session token and anon key
      final sessionToken = supabase.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      
      // Determine device type and name
      final deviceType = Platform.isAndroid ? 'android' : 'ios';
      final deviceName = '${Platform.operatingSystem} Device';

      // Call register-device Edge Function
      final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/register-device');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      
      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final body = jsonEncode({
        'device_token': token,
        'device_type': deviceType,
        'device_name': deviceName,
      });

      print('========================================');
      print('[FCMService] Registering Device Token with Supabase...');
      print('User ID: $userId');
      print('Device Type: $deviceType');
      print('Device Name: $deviceName');
      print('FCM Token: $token');
      print('========================================');
      debugPrint('[FCMService] Registering device token with Supabase...');
      debugPrint('[FCMService] Device type: $deviceType, Device name: $deviceName');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      // Log response details for debugging
      print('========================================');
      print('[FCMService] Register-Device Edge Function Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================================');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse response to get device details
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final deviceData = responseData['device'] as Map<String, dynamic>?;
          final deviceId = deviceData?['id']?.toString() ?? 'N/A';
          
          print('========================================');
          print('[FCMService] ✅ Device Token Registered Successfully');
          print('User ID: $userId');
          print('Device ID: $deviceId');
          print('Device Type: $deviceType');
          print('Device Name: $deviceName');
          print('FCM Token: $token');
          print('Backend Message: ${responseData['message'] ?? 'N/A'}');
          print('========================================');
        } catch (e) {
          print('[FCMService] ✅ Device Token Registered Successfully');
          print('User ID: $userId');
          print('Device Type: $deviceType');
          print('FCM Token: $token');
        }
        _pendingTokenSync = null;
        debugPrint('[FCMService] Device token registered successfully');
        return true;
      } else {
        print('========================================');
        print('[FCMService] ❌ Failed to Register Device Token');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('========================================');
        debugPrint('[FCMService] Failed to register device token. Status: ${response.statusCode}');
        debugPrint('[FCMService] Response: ${response.body}');
        _pendingTokenSync = token;
        // Don't throw - token registration failure shouldn't break the app
        return false;
      }
    } catch (e) {
      debugPrint('[FCMService] Error registering device token: $e');
      _pendingTokenSync = token;
      // Don't throw - token registration failure shouldn't break the app
      return false;
    }
  }

  Future<void> _retryPendingTokenSync() async {
    final tokenToRetry = _pendingTokenSync;
    if (tokenToRetry == null || tokenToRetry.isEmpty) {
      return;
    }

    debugPrint('[FCMService] Retrying pending token sync...');
    final synced = await _saveTokenToSupabase(tokenToRetry);
    if (synced) {
      debugPrint('[FCMService] Pending token sync succeeded');
    } else {
      debugPrint('[FCMService] Pending token sync failed; will retry later');
    }
  }

  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCMService] Foreground message received: ${message.messageId}');
      debugPrint('[FCMService] Message data: ${message.data}');
      
      // Check if notification is already read before showing
      final isRead = await _isNotificationRead(message);
      if (isRead) {
        debugPrint('[FCMService] Notification is already read, skipping display');
        return;
      }
      
      final titleFromData = message.data['title']?.toString();
      final bodyFromData =
          message.data['body']?.toString() ?? message.data['message']?.toString();

      final title = message.notification?.title ?? titleFromData ?? 'New notification';
      final body = message.notification?.body ?? bodyFromData ?? '';

      if (title.isEmpty && body.isEmpty) {
        debugPrint('[FCMService] Foreground message has no visible content, skipping display');
        return;
      }

      // Store message data so it's available if the local notification is tapped
      _lastForegroundMessageData = message.data;
      if (_onForegroundMessageCallback != null) {
        _onForegroundMessageCallback!(title, body, message.data);
      } else {
        await PushNotificationDisplayService.showFromRemoteMessage(
          message,
          plugin: _localNotifications,
        );
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCMService] Notification opened app: ${message.messageId}');
      debugPrint('[FCMService] Message data: ${message.data}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('[FCMService] App opened from terminated state: ${message.messageId}');
        debugPrint('[FCMService] Message data: ${message.data}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Check if notification is already read in database
  Future<bool> _isNotificationRead(RemoteMessage message) async {
    try {
      final notificationId = message.data['notification_id']?.toString() ?? 
                             message.data['id']?.toString();
      
      if (notificationId == null || notificationId.isEmpty) {
        // If no notification ID, assume it's a new notification and should be shown
        return false;
      }

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        // No user logged in, don't show notification
        return true;
      }

      // Check if notification exists and is read
      final response = await supabase
          .from('notifications_history')
          .select('is_read')
          .eq('id', notificationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Notification doesn't exist yet (might be a new one), show it
        return false;
      }

      final isRead = response['is_read'] == true;
      debugPrint('[FCMService] Notification $notificationId is_read: $isRead');
      return isRead;
    } catch (e) {
      debugPrint('[FCMService] Error checking notification read status: $e');
      // On error, show the notification to be safe
      return false;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final titleFromData = message.data['title']?.toString();
    final bodyFromData =
        message.data['body']?.toString() ?? message.data['message']?.toString();
    final title = message.notification?.title ?? titleFromData;
    final body = message.notification?.body ?? bodyFromData;

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _showLocalNotificationFromContent(
      title: title ?? 'New notification',
      body: body ?? '',
      payload: message.data.toString(),
    );
  }

  Future<void> _showLocalNotificationFromContent({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    if (data != null && data.isNotEmpty) {
      await PushNotificationDisplayService.showFromData(
        data: data,
        fallbackTitle: title,
        fallbackBody: body,
        payload: payload,
        plugin: _localNotifications,
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Unregister device (call on logout)
  Future<void> unregisterDevice() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('[FCMService] No user logged in, skipping unregister');
        return;
      }

      // Mark device as inactive instead of deleting
      if (_currentToken != null) {
        await supabase
            .from('push_notification_devices')
            .update({'is_active': false})
            .eq('device_token', _currentToken!)
            .eq('user_id', userId);
      }

      // Delete local token
      await _firebaseMessaging.deleteToken();
      _currentToken = null;
      _isInitialized = false;
      await PushNotificationGroupStore.clear();

      debugPrint('[FCMService] Device unregistered');
    } catch (e) {
      debugPrint('[FCMService] Error unregistering device: $e');
      // Don't throw - unregister failure shouldn't break logout
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Top-level function for handling background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (!Platform.isAndroid && !Platform.isIOS) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    InitializationSettings(
      android: Platform.isAndroid
          ? const AndroidInitializationSettings('@mipmap/ic_launcher')
          : null,
      iOS: Platform.isIOS
          ? const DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            )
          : null,
    ),
  );
  await PushNotificationDisplayService.ensureInitialized(plugin);
  await PushNotificationDisplayService.ensureAndroidNotificationChannel(plugin);

  try {
    if (message.notification == null) {
      await PushNotificationDisplayService.showFromRemoteMessage(
        message,
        plugin: plugin,
        generateAvatars: false,
      );
    }
  } catch (e, stack) {
    debugPrint('[FCMService] Background styled notification failed: $e');
    debugPrint('$stack');
  }

  debugPrint('[FCMService] Background message received: ${message.messageId}');
}

