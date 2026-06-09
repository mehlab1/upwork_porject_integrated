import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../utils/push_notification_avatar_generator.dart';
import '../utils/push_notification_builder.dart';
import 'push_notification_group_store.dart';

class PushNotificationDisplayService {
  PushNotificationDisplayService._();

  static final PushNotificationDisplayService instance =
      PushNotificationDisplayService._();

  static FlutterLocalNotificationsPlugin? _plugin;
  static bool _initialized = false;

  static Future<void> ensureInitialized(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (_initialized) return;
    _plugin = plugin;
    _initialized = true;
  }

  static Future<void> showFromRemoteMessage(
    RemoteMessage message, {
    FlutterLocalNotificationsPlugin? plugin,
    bool generateAvatars = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final activePlugin = plugin ?? _plugin;
    if (activePlugin == null) return;

    final data = Map<String, dynamic>.from(message.data);
    _mergeNotificationFieldsIntoData(data, message);

    final titleFromData = data['title']?.toString();
    final bodyFromData =
        data['body']?.toString() ?? data['message']?.toString();
    final title = message.notification?.title ?? titleFromData;
    final body = message.notification?.body ?? bodyFromData;

    if (!_hasDisplayablePayload(data, title: title, body: body)) {
      return;
    }

    await showFromData(
      data: data,
      fallbackTitle: title,
      fallbackBody: body,
      payload: jsonEncode(data),
      plugin: activePlugin,
      generateAvatars: generateAvatars,
    );
  }

  static void _mergeNotificationFieldsIntoData(
    Map<String, dynamic> data,
    RemoteMessage message,
  ) {
    final notificationTitle = message.notification?.title;
    final notificationBody = message.notification?.body;

    if (notificationTitle != null &&
        notificationTitle.isNotEmpty &&
        (data['title'] == null || data['title'].toString().isEmpty)) {
      data['title'] = notificationTitle;
    }

    if (notificationBody != null &&
        notificationBody.isNotEmpty &&
        (data['body'] == null || data['body'].toString().isEmpty) &&
        (data['message'] == null || data['message'].toString().isEmpty)) {
      data['body'] = notificationBody;
    }
  }

  static bool _hasDisplayablePayload(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    if (title != null && title.isNotEmpty) return true;
    if (body != null && body.isNotEmpty) return true;

    final type = data['type']?.toString() ??
        data['notification_type']?.toString() ??
        '';
    return type.isNotEmpty;
  }

  static Future<void> showFromData({
    required Map<String, dynamic> data,
    String? fallbackTitle,
    String? fallbackBody,
    String? payload,
    FlutterLocalNotificationsPlugin? plugin,
    bool generateAvatars = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final activePlugin = plugin ?? _plugin;
    if (activePlugin == null) return;

    try {
      await PushNotificationGroupStore.add(data);

      final model = PushNotificationBuilder.fromRemoteData(
        data,
        fallbackTitle: fallbackTitle,
        fallbackBody: fallbackBody,
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final encodedPayload = payload ?? jsonEncode(data);

      if (Platform.isAndroid) {
        await _showAndroidNotification(
          plugin: activePlugin,
          model: model,
          data: data,
          notificationId: notificationId,
          fallbackTitle: fallbackTitle,
          fallbackBody: fallbackBody,
          payload: encodedPayload,
          generateAvatars: generateAvatars,
        );
      } else if (Platform.isIOS) {
        await _showIosNotification(
          plugin: activePlugin,
          model: model,
          notificationId: notificationId,
          fallbackBody: fallbackBody,
          payload: encodedPayload,
        );
      }

      await _refreshGroupSummary(activePlugin);
    } catch (e, stack) {
      debugPrint('[PushNotificationDisplayService] Styled notification failed: $e');
      debugPrint('$stack');
      await _showSimpleFallbackNotification(
        plugin: activePlugin,
        data: data,
        fallbackTitle: fallbackTitle,
        fallbackBody: fallbackBody,
        payload: payload,
      );
    }
  }

  static Future<void> _showSimpleFallbackNotification({
    required FlutterLocalNotificationsPlugin plugin,
    required Map<String, dynamic> data,
    String? fallbackTitle,
    String? fallbackBody,
    String? payload,
  }) async {
    final model = PushNotificationBuilder.fromRemoteData(
      data,
      fallbackTitle: fallbackTitle,
      fallbackBody: fallbackBody,
    );
    final title = fallbackTitle ??
        (model.androidTitle.isNotEmpty ? model.androidTitle : 'kobiPal');
    final body = fallbackBody ?? model.androidBody ?? model.actionText;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF155DFC),
      icon: '@drawable/ic_notification',
    );

    await plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload ?? jsonEncode(data),
    );
  }

  static Future<void> ensureAndroidNotificationChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (!Platform.isAndroid) return;

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _showAndroidNotification({
    required FlutterLocalNotificationsPlugin plugin,
    required PushNotificationDisplayModel model,
    required Map<String, dynamic> data,
    required int notificationId,
    String? fallbackTitle,
    String? fallbackBody,
    required String payload,
    bool generateAvatars = true,
  }) async {
    ByteArrayAndroidBitmap? largeIcon;
    ByteArrayAndroidBitmap? bigPicture;
    ByteArrayAndroidIcon? personIcon;

    if (generateAvatars && model.variant == PushNotificationVariant.postUpvote) {
      try {
        if (model.hasProfileImage) {
          final bytes = await _downloadBytes(model.profilePictureUrl!);
          if (bytes != null) {
            final typedBytes = Uint8List.fromList(bytes);
            largeIcon = ByteArrayAndroidBitmap(typedBytes);
            bigPicture = ByteArrayAndroidBitmap(typedBytes);
          }
        }

        if (largeIcon == null) {
          final initialsBytes =
              await PushNotificationAvatarGenerator.generateSquareInitials(
            model.resolvedInitials,
          );
          if (initialsBytes != null) {
            largeIcon = ByteArrayAndroidBitmap(initialsBytes);
            bigPicture = ByteArrayAndroidBitmap(initialsBytes);
          }
        }
      } catch (e) {
        debugPrint(
          '[PushNotificationDisplayService] Upvote avatar failed: $e',
        );
      }
    } else if (generateAvatars) {
      try {
        if (model.hasProfileImage) {
          final bytes = await _downloadBytes(model.profilePictureUrl!);
          if (bytes != null) {
            final typedBytes = Uint8List.fromList(bytes);
            largeIcon = ByteArrayAndroidBitmap(typedBytes);
            personIcon = ByteArrayAndroidIcon(typedBytes);
          }
        }

        if (largeIcon == null &&
            (model.variant == PushNotificationVariant.commentSocial ||
                model.variant == PushNotificationVariant.postComment)) {
          final initialsBytes =
              await PushNotificationAvatarGenerator.generateSquareInitials(
            model.resolvedInitials,
          );
          if (initialsBytes != null) {
            largeIcon = ByteArrayAndroidBitmap(initialsBytes);
            personIcon = ByteArrayAndroidIcon(initialsBytes);
          }
        }
      } catch (e) {
        debugPrint(
          '[PushNotificationDisplayService] Avatar download failed: $e',
        );
      }
    }

    final androidDetails = PushNotificationBuilder.buildAndroidDetails(
      model: model,
      largeIcon: largeIcon,
      bigPicture: bigPicture,
      personIcon: personIcon,
      isGroupSummary: false,
    );

    await plugin.show(
      notificationId,
      model.variant == PushNotificationVariant.generic
          ? (fallbackTitle ?? 'kobiPal')
          : model.androidTitle,
      model.androidBody ?? fallbackBody ?? '',
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> _showIosNotification({
    required FlutterLocalNotificationsPlugin plugin,
    required PushNotificationDisplayModel model,
    required int notificationId,
    String? fallbackBody,
    required String payload,
  }) async {
    List<DarwinNotificationAttachment>? attachments;

    try {
      String? imageUrl = model.iosAttachmentUrl;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final bytes = await _downloadBytes(imageUrl);
        if (bytes != null) {
          final file = await _writeAttachmentFile(
            bytes,
            suffix: model.variant == PushNotificationVariant.postUpvote
                ? 'post'
                : 'avatar',
          );
          if (file != null) {
            attachments = [
              DarwinNotificationAttachment(
                file.path,
                hideThumbnail: false,
              ),
            ];
          }
        }
      }
    } catch (e) {
      debugPrint('[PushNotificationDisplayService] iOS attachment failed: $e');
    }

    final iosDetails = PushNotificationBuilder.buildIosDetails(
      model: model,
      attachments: attachments,
    );

    await plugin.show(
      notificationId,
      model.iosTitle,
      model.iosBody ?? fallbackBody ?? '',
      NotificationDetails(iOS: iosDetails),
      payload: payload,
    );
  }

  static Future<void> _refreshGroupSummary(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final recentData = await PushNotificationGroupStore.getRecentData();
    if (recentData.length < 2) {
      await plugin.cancel(PushNotificationGroupStore.summaryNotificationId);
      return;
    }

    final models = recentData
        .map(PushNotificationBuilder.fromRemoteData)
        .toList();
    final inboxLines = models.map((model) => model.inboxLine).toList();
    final summaryText = recentData.length == 1
        ? '1 new message'
        : '${recentData.length} new messages';

    if (Platform.isAndroid) {
      final summaryDetails =
          PushNotificationBuilder.buildGroupSummaryAndroidDetails(
        messageCount: recentData.length,
        inboxLines: inboxLines,
      );

      await plugin.show(
        PushNotificationGroupStore.summaryNotificationId,
        'kobiPal',
        summaryText,
        NotificationDetails(android: summaryDetails),
        payload: jsonEncode({'type': 'group_summary'}),
      );
    } else if (Platform.isIOS) {
      final summaryDetails =
          PushNotificationBuilder.buildIosGroupSummaryDetails(
        messageCount: recentData.length,
      );

      await plugin.show(
        PushNotificationGroupStore.summaryNotificationId,
        'kobiPal',
        summaryText,
        NotificationDetails(iOS: summaryDetails),
        payload: jsonEncode({'type': 'group_summary'}),
      );
    }
  }

  static Future<File?> _writeAttachmentFile(
    List<int> bytes, {
    required String suffix,
  }) async {
    final file = File(
      '${Directory.systemTemp.path}/kobi_pal_${suffix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<List<int>?> _downloadBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    return response.bodyBytes;
  }
}
