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

  // ── Edge-function base URL ────────────────────────────────────────────────
  static const String _edgeFunctionBase =
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-notifications';

  // ── Single-call fetch: notifications + counts ──────────────────────────────
  /// Calls the `get-notifications` edge function once and returns:
  ///   - `notifications`: List<Map<String, dynamic>>
  ///   - `unread_count`:  int
  ///   - `total_count`:   int
  Future<Map<String, dynamic>> fetchNotificationsPage({
    int limit = 50,
    int offset = 0,
  }) async {
    final empty = <String, dynamic>{
      'notifications': <Map<String, dynamic>>[],
      'unread_count': 0,
      'total_count': 0,
    };
    try {
      final token = _supabaseClient.auth.currentSession?.accessToken;
      if (token == null) {
        debugPrint('[NotificationService] No session – skipping fetchNotificationsPage');
        return empty;
      }

      final uri = Uri.parse(_edgeFunctionBase).replace(queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      debugPrint('[NotificationService] GET $uri');
      final resp = await http.get(uri, headers: _authHeaders(token));
      debugPrint('[NotificationService] fetchNotificationsPage status: ${resp.statusCode}');

      if (resp.statusCode >= 400) {
        final err = (jsonDecode(resp.body) as Map<String, dynamic>)['error'] ?? 'Error';
        debugPrint('[NotificationService] fetchNotificationsPage error: $err');
        return empty;
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return {
        'notifications': (body['notifications'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        'unread_count': body['unread_count'] as int? ?? 0,
        'total_count': body['total_count'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('[NotificationService] Error in fetchNotificationsPage: $e');
      return empty;
    }
  }

  /// Fetch notifications for current user.
  /// Uses the `get-notifications` edge function.
  /// [unreadOnly] is filtered client-side from the edge function response.
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final page = await fetchNotificationsPage(limit: limit, offset: offset);
    final all = page['notifications'] as List<Map<String, dynamic>>;
    if (unreadOnly) {
      return all.where((n) => n['is_read'] == false).toList();
    }
    return all;
  }

  /// Get unread notification count from the edge function.
  /// Uses limit=1 so the DB work is minimal — only the count RPC runs.
  Future<int> getUnreadCount() async {
    try {
      final token = _supabaseClient.auth.currentSession?.accessToken;
      if (token == null) return 0;

      final uri = Uri.parse(_edgeFunctionBase).replace(queryParameters: {
        'limit': '1',
        'offset': '0',
      });

      final resp = await http.get(uri, headers: _authHeaders(token));
      if (resp.statusCode >= 400) return 0;

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['unread_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('[NotificationService] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark a single notification as read via the edge function.
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = _supabaseClient.auth.currentSession?.accessToken;
      if (token == null) return false;

      final uri = Uri.parse(_edgeFunctionBase)
          .replace(queryParameters: {'action': 'mark_read'});

      final resp = await http.post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode({'notification_id': notificationId}),
      );

      final ok = resp.statusCode < 400;
      debugPrint('[NotificationService] markAsRead $notificationId → ${resp.statusCode}');
      return ok;
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read via the edge function.
  Future<bool> markAllAsRead() async {
    try {
      final token = _supabaseClient.auth.currentSession?.accessToken;
      if (token == null) return false;

      final uri = Uri.parse(_edgeFunctionBase)
          .replace(queryParameters: {'action': 'mark_all_read'});

      final resp = await http.post(uri, headers: _authHeaders(token));

      final ok = resp.statusCode < 400;
      debugPrint('[NotificationService] markAllAsRead → ${resp.statusCode}');
      return ok;
    } catch (e) {
      debugPrint('[NotificationService] Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Build common auth headers for edge function requests.
  Map<String, String> _authHeaders(String accessToken) => {
    'Content-Type': 'application/json',
    'apikey':
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY',
    'Authorization': 'Bearer $accessToken',
  };

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
    Map<String, String>? queryParams,
  }) async {
    final baseUri = Uri.parse(
        'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/$functionName');
    final uri = queryParams != null
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final headers = _authHeaders(sessionToken ?? '');

      debugPrint('[NotificationService] $method $uri');
      if (body != null) debugPrint('[NotificationService] body: ${jsonEncode(body)}');

      late http.Response resp;
      final encoded = body == null ? null : jsonEncode(body);
      if (method.toUpperCase() == 'GET') {
        resp = await http.get(uri, headers: headers);
      } else {
        resp = await http.post(uri, headers: headers, body: encoded);
      }

      debugPrint('[NotificationService] $functionName → ${resp.statusCode}');

      final parsed = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      debugPrint('[NotificationService] Error calling $functionName: $e');
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

