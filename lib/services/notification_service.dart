import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
}

