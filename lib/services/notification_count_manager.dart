import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Centralized manager for unread notification count
/// Provides real-time updates across the entire app
class NotificationCountManager {
  static NotificationCountManager? _instance;
  static NotificationCountManager get instance {
    _instance ??= NotificationCountManager._();
    return _instance!;
  }

  NotificationCountManager._();

  final ValueNotifier<int> _unreadCount = ValueNotifier<int>(0);
  final NotificationService _notificationService = NotificationService();
  RealtimeChannel? _realtimeChannel;
  bool _isListening = false;
  bool _isDisposed = false;

  /// Current unread count (read-only)
  int get unreadCount => _unreadCount.value;

  /// ValueNotifier for listening to count changes
  ValueNotifier<int> get notifier => _unreadCount;

  /// Initialize and start listening for updates
  /// Call this when user logs in
  Future<void> initialize() async {
    if (_isDisposed) return;
    
    // Fetch initial count
    await refreshCount();
    
    // Start real-time listener
    _setupRealtimeListener();
  }

  /// Directly set the unread count without a DB call
  /// Use this when you already know the correct count (e.g., after marking all as read)
  void setCount(int count) {
    if (_isDisposed) return;
    _unreadCount.value = count;
  }

  /// Refresh count from database
  /// Call this when you need to manually refresh (e.g., after marking as read)
  Future<void> refreshCount() async {
    if (_isDisposed) return;
    
    try {
      final count = await _notificationService.getUnreadCount();
      if (!_isDisposed) {
        _unreadCount.value = count;
        debugPrint('[NotificationCountManager] Refreshed count: $count');
      }
    } catch (e) {
      debugPrint('[NotificationCountManager] Error refreshing count: $e');
      // On error, set to 0 (hide badge) - user is likely offline
      if (!_isDisposed) {
        _unreadCount.value = 0;
      }
    }
  }

  /// Set up real-time listener for notification changes
  void _setupRealtimeListener() {
    if (_isListening || _isDisposed) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint('[NotificationCountManager] No user logged in, skipping real-time listener');
      return;
    }

    try {
      // Remove existing channel if any
      if (_realtimeChannel != null) {
        supabase.removeChannel(_realtimeChannel!);
      }

      // Create new channel for notifications
      _realtimeChannel = supabase
          .channel('notification_count_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications_history',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              // Refresh count when any notification changes
              debugPrint('[NotificationCountManager] Notification changed, refreshing count');
              refreshCount();
            },
          )
          .subscribe();

      _isListening = true;
      debugPrint('[NotificationCountManager] Real-time listener started');
    } catch (e) {
      debugPrint('[NotificationCountManager] Error setting up real-time listener: $e');
      _isListening = false;
    }
  }

  /// Stop listening and clear count
  /// Call this when user logs out
  void clear() {
    if (_isDisposed) return;
    
    _stopRealtimeListener();
    _unreadCount.value = 0;
    debugPrint('[NotificationCountManager] Cleared count and stopped listener');
  }

  /// Stop real-time listener
  void _stopRealtimeListener() {
    if (!_isListening) return;

    try {
      if (_realtimeChannel != null) {
        final supabase = Supabase.instance.client;
        supabase.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
      _isListening = false;
      debugPrint('[NotificationCountManager] Real-time listener stopped');
    } catch (e) {
      debugPrint('[NotificationCountManager] Error stopping real-time listener: $e');
    }
  }

  /// Dispose resources
  /// Call this when app closes
  void dispose() {
    if (_isDisposed) return;
    
    _stopRealtimeListener();
    _unreadCount.dispose();
    _isDisposed = true;
    _instance = null;
    debugPrint('[NotificationCountManager] Disposed');
  }
}
