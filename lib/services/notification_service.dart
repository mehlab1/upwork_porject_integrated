import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/pal_push_notification.dart';

/// Service for managing in-app notifications
/// Fetches notifications from notifications_history table
class NotificationService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Fetch notifications for current user
  /// 
  /// Parameters:
  /// - limit: Maximum number of notifications to fetch (default: 50)
  /// - offset: Number of notifications to skip (default: 0)
  /// - unreadOnly: If true, only fetch unread notifications (default: false)
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('[NotificationService] No user logged in');
        return [];
      }

      // Build query chain without reassigning to avoid type mismatch
      final baseQuery = _supabaseClient
          .from('notifications_history')
          .select()
          .eq('user_id', userId);

      final filteredQuery = unreadOnly 
          ? baseQuery.eq('is_read', false)
          : baseQuery;

      final response = await filteredQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      final notifications = (response as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList() ?? [];

      debugPrint('[NotificationService] Fetched ${notifications.length} notifications');
      if (notifications.isNotEmpty) {
        debugPrint('[NotificationService] First notification type: ${notifications.first['notification_type']}');
        debugPrint('[NotificationService] First notification ID: ${notifications.first['id']}');
        debugPrint('[NotificationService] First notification is_read: ${notifications.first['is_read']}');
      }
      
      return notifications;
    } catch (e) {
      debugPrint('[NotificationService] Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        return 0;
      }

      // Fetch all unread notification IDs and count them
      final response = await _supabaseClient
          .from('notifications_history')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      // Response is a List, so just return its length
      if (response is List) {
        return response.length;
      }
      
      return 0;
    } catch (e) {
      debugPrint('[NotificationService] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        return false;
      }

      await _supabaseClient
          .from('notifications_history')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', userId);

      debugPrint('[NotificationService] Marked notification $notificationId as read');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        return false;
      }

      await _supabaseClient
          .from('notifications_history')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      debugPrint('[NotificationService] Marked all notifications as read');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Mark notification as clicked
  Future<bool> markAsClicked(String notificationId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        return false;
      }

      await _supabaseClient
          .from('notifications_history')
          .update({
            'clicked': true,
            'clicked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', userId);

      debugPrint('[NotificationService] Marked notification $notificationId as clicked');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as clicked: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        return false;
      }

      await _supabaseClient
          .from('notifications_history')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);

      debugPrint('[NotificationService] Deleted notification $notificationId');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error deleting notification: $e');
      return false;
    }
  }

  /// Show unread notifications as in-app banners
  /// Fetches 3-5 most recent unread notifications and displays them one by one
  /// with delays between each notification
  Future<void> showUnreadNotificationsInApp(BuildContext context) async {
    try {
      // Check if user is logged in
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[NotificationService] No user logged in, skipping in-app notifications');
        return;
      }

      // Fetch 3-5 most recent unread notifications
      final unreadNotifications = await getNotifications(
        limit: 5,
        offset: 0,
        unreadOnly: true,
      );

      if (unreadNotifications.isEmpty) {
        debugPrint('[NotificationService] No unread notifications to show');
        return;
      }

      debugPrint('[NotificationService] Found ${unreadNotifications.length} unread notifications to show');

      // Show notifications one by one with delays
      for (int i = 0; i < unreadNotifications.length; i++) {
        final notification = unreadNotifications[i];
        
        // Extract title and body from notification
        final title = notification['title']?.toString() ?? 'New notification';
        final body = notification['body']?.toString() ?? '';
        
        // Add delay before showing (except for first one)
        if (i > 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }

        // Check if context is still mounted before showing
        if (!context.mounted) {
          debugPrint('[NotificationService] Context no longer mounted, stopping notification display');
          break;
        }

        // Show in-app notification banner
        try {
          PalPushNotification.show(
            context,
            title: title,
            message: body,
          );
          debugPrint('[NotificationService] Shown in-app notification: $title');
        } catch (e) {
          debugPrint('[NotificationService] Error showing notification: $e');
          // Continue with next notification even if one fails
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error showing unread notifications in-app: $e');
      // Don't throw - this is a non-critical feature
    }
  }

  // Internal helper to call Supabase Edge Functions
  Future<Map<String, dynamic>> _callFunction(
    String functionName, {
    Map<String, dynamic>? body,
    String method = 'POST',
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/$functionName');
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      print('=== NOTIFICATION SERVICE - REQUEST TO EDGE FUNCTION ($functionName) ===');
      print('URL: $uri');
      print('Method: $method');
      print('Has session token: ${sessionToken != null}');
      if (body != null) {
        print('Request body: ${jsonEncode(body)}');
      }

      late http.Response resp;
      final encoded = body == null ? null : jsonEncode(body);
      if (method.toUpperCase() == 'GET') {
        resp = await http.get(uri, headers: headers);
      } else {
        resp = await http.post(uri, headers: headers, body: encoded);
      }

      print('=== NOTIFICATION SERVICE - RESPONSE FROM EDGE FUNCTION ($functionName) ===');
      print('Status Code: ${resp.statusCode}');
      print('Response headers: ${resp.headers}');
      print('Response body: ${resp.body}');
      print('===================================================================');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        debugPrint('ERROR: Function $functionName returned ${resp.statusCode}: $errorMessage');
        print('ERROR _callFunction ($functionName): Full response body: $parsed');
        throw Exception(errorMessage);
      }

      print('SUCCESS _callFunction ($functionName): Response parsed - $parsed');
      return parsed;
    } catch (e) {
      debugPrint('ERROR: Exception while calling function $functionName - ${e.toString()}');
      print('ERROR _callFunction ($functionName): Exception - $e');
      rethrow;
    }
  }

  /// Get user mentions using the get-mentions edge function
  /// 
  /// The edge function fetches mentions for the authenticated user from the mentions table
  /// 
  /// Parameters:
  /// - unreadOnly: If true, only fetch unread mentions (default: false)
  /// - limit: Maximum number of mentions to fetch (default: 50)
  /// - offset: Number of mentions to skip (default: 0)
  /// - includeStats: If true, include mention statistics (default: false)
  /// 
  /// Returns: Map with success (bool), mentions (List), count (int), stats (Map?), and pagination (Map)
  Future<Map<String, dynamic>> getMentions({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
    bool includeStats = false,
  }) async {
    final body = <String, dynamic>{
      'unread_only': unreadOnly,
      'limit': limit,
      'offset': offset,
      'include_stats': includeStats,
    };
    
    debugPrint('[NotificationService] Fetching mentions - unreadOnly: $unreadOnly, limit: $limit, offset: $offset');
    
    try {
      final response = await _callFunction('get-mentions', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? true;
      
      if (!success) {
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to fetch mentions';
        throw Exception(errorMessage);
      }
      
      final mentions = response['mentions'] as List<dynamic>? ?? [];
      final count = response['count'] as int? ?? mentions.length;
      
      debugPrint('[NotificationService] Retrieved $count mentions');
      
      if (response['stats'] != null) {
        debugPrint('[NotificationService] Stats included: ${response['stats']}');
      }
      
      return response;
    } catch (e) {
      // Handle errors with better messages
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        throw Exception('You must be logged in to fetch mentions');
      } else if (errorStr.contains('500') || errorStr.contains('Failed to fetch mentions')) {
        throw Exception('Failed to load mentions. Please try again.');
      }
      
      // Re-throw if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch mentions: $errorStr');
    }
  }
}

