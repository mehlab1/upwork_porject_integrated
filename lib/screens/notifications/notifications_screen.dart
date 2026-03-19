import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';
import 'package:pal/widgets/profile_avatar_widget.dart';
import 'package:pal/services/notification_service.dart';
import 'package:pal/services/notification_count_manager.dart';
import 'package:pal/utils/notification_mapper.dart';
import 'package:pal/models/notification_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  // ── Static cache shared across all instances of this screen ──────────────
  // Persists while the app is alive, so navigating back shows data instantly.
  static List<NotificationItem> _cachedItems = [];
  static int _cachedUnreadCount = 0;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(seconds: 60);
  // ─────────────────────────────────────────────────────────────────────────

  List<NotificationItem> _notificationItems = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  /// IDs of notifications whose tap handler is currently in flight.
  /// Extra taps while an ID is here are ignored (no duplicate API calls).
  final Set<String> _processingIds = {};
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();

    // Instantly show cached data so there's no blank-screen flash.
    if (_cachedItems.isNotEmpty) {
      _notificationItems = _cachedItems;
      _unreadCount = _cachedUnreadCount;
    }

    final bool cacheStale = _cacheTimestamp == null ||
        DateTime.now().difference(_cacheTimestamp!) > _cacheTtl;

    if (cacheStale) {
      // Cache is empty or old — load immediately (shows spinner only on first
      // ever visit; subsequent visits see stale data while refreshing).
      _setupRealtimeListener();
    } else {
      // Cache is fresh — set up realtime for live updates only, no forced load.
      _setupRealtimeListener(skipInitialLoad: true);
    }

    // Mark all notifications as read after the first load completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllNotificationsAsRead();
    });
  }

  /// Mark all notifications as read when notifications tab is opened
  Future<void> _markAllNotificationsAsRead() async {
    if (_unreadCount == 0) return; // Nothing to mark — skip DB call
    try {
      await _notificationService.markAllAsRead();
      // Update local state directly — no extra API calls needed.
      if (mounted) {
        final readItems = _notificationItems
            .map((item) => item.copyWith(unread: false))
            .toList();
        setState(() {
          _unreadCount = 0;
          _notificationItems = readItems;
        });
        // Keep static cache in sync so next visit shows correct read state.
        _cachedItems = readItems;
        _cachedUnreadCount = 0;
        // Update the badge count without hitting the DB.
        NotificationCountManager.instance.setCount(0);
      }
    } catch (e) {
      debugPrint(
        '[NotificationsScreen] Error marking all notifications as read: $e',
      );
    }
  }

  /// Set up real-time listener for new notifications
  void _setupRealtimeListener({bool skipInitialLoad = false}) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      // No user — do a one-time load instead.
      _loadNotifications();
      return;
    }

    // The stream emits immediately with current data.
    // When skipInitialLoad is true we ignore the first emission so we don't
    // replace fresh-enough cache with a redundant network call.
    bool firstEmission = true;
    _realtimeSubscription = supabase
        .from('notifications_history')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((data) {
          if (!mounted) return;
          if (firstEmission && skipInitialLoad) {
            firstEmission = false;
            return; // skip — cache is fresh enough
          }
          firstEmission = false;
          _loadNotifications();
        });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // Guard against concurrent loads triggered by the realtime stream.
    if (_isLoading) return;
    _isLoading = true;
    try {
      // Single edge-function call returns both the list and counts.
      final page = await _notificationService.fetchNotificationsPage(limit: 50);

      final notifications =
          page['notifications'] as List<Map<String, dynamic>>;
      final unreadCount = page['unread_count'] as int;

      // Convert to UI format
      final items = notifications
          .map((n) => NotificationMapper.mapToNotificationItem(n))
          .whereType<NotificationItem>()
          .toList();

      // Update the badge count directly — no extra DB round-trip.
      NotificationCountManager.instance.setCount(unreadCount);

      // Write through to static cache.
      _cachedItems = items;
      _cachedUnreadCount = unreadCount;
      _cacheTimestamp = DateTime.now();

      if (!mounted) return;

      setState(() {
        _notificationItems = items;
        _unreadCount = unreadCount;
      });
    } catch (e) {
      debugPrint('[NotificationsScreen] Error loading notifications: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  /// Handle notification tap and navigate
  Future<void> _handleNotificationTap(
    NotificationItem item,
    Map<String, dynamic>? notificationData,
  ) async {
    if (notificationData == null) return;

    final notificationId = notificationData['id']?.toString();
    // Deduplicate: if this notification is already being processed, ignore extra taps.
    final lockKey = notificationId ?? 'unknown';
    if (_processingIds.contains(lockKey)) return;
    _processingIds.add(lockKey);

    try {
      if (notificationId != null) {
        // Support both is_read (bool) and read_at (timestamp) to detect unread.
        final rawIsRead = notificationData['is_read'];
        final readAt = notificationData['read_at'];
        final wasUnread = !(rawIsRead == true
            || rawIsRead?.toString() == 'true'
            || (readAt != null && readAt.toString().isNotEmpty));
        // Mark as read and clicked
        await _notificationService.markAsRead(notificationId);
        await _notificationService.markAsClicked(notificationId);
        // Decrement badge locally — no extra DB round-trip.
        if (wasUnread && mounted) {
          final newCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          setState(() => _unreadCount = newCount);
          NotificationCountManager.instance.setCount(newCount);
        }
      }

    // Extract navigation data — support both edge function and legacy shapes.
    final notificationType = notificationData['notification_type']?.toString()
        ?? notificationData['type']?.toString() ?? '';
    final data = notificationData['data'] as Map<String, dynamic>? ?? {};
    final postId =
        notificationData['post_id']?.toString() ?? data['post_id']?.toString();
    final commentId =
        notificationData['comment_id']?.toString() ?? data['comment_id']?.toString();

    // Navigate based on notification type (edge function + legacy types).
    switch (notificationType) {
      case 'comment':        // edge function
      case 'new_comment':
      case 'post_reply':
      case 'reply':          // edge function
      case 'reply_to_comment':
      case 'comment_reply':
      case 'upvote':         // edge function
      case 'post_upvote':
      case 'post_hot':
      case 'post_top':
      case 'post_trending':
        if (postId != null && mounted) {
          Navigator.of(context).pushNamed(
            '/post-detail',
            arguments: {'postId': postId},
          );
        }
        break;
      case 'comment_upvote':
      case 'mention':        // edge function / legacy
      case 'mention_in_comment':
      case 'mention_in_post':
        if (postId != null && mounted) {
          Navigator.of(context).pushNamed(
            '/post-detail',
            arguments: {
              'postId': postId,
              'commentId': commentId,
            },
          );
        }
        break;
      case 'report_under_review':
      case 'report_resolved':
        // Already on notifications screen
        break;
      case 'account_suspended':
      case 'account_warning':
      case 'account_reactivated':
        if (mounted) Navigator.of(context).pushNamed('/settings');
        break;
      default:
        // Unknown type — navigate to post detail if we have a postId,
        // otherwise stay on the notifications screen.
        if (postId != null && mounted) {
          Navigator.of(context).pushNamed(
            '/post-detail',
            arguments: {
              'postId': postId,
              if (commentId != null) 'commentId': commentId,
            },
          );
        }
    }

    // Refresh to update unread status
    if (mounted) _loadNotifications();
    } finally {
      _processingIds.remove(lockKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: PalBottomNavigationBar(
        active: PalNavDestination.notifications,
        onHomeTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        onNotificationsTap: () {},
        onSettingsTap: () => Navigator.pushNamed(context, '/settings'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Heading with notification count badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (_unreadCount > 0)
                    Container(
                      width: 28.0669002532959,
                      height: 23.98981475830078,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7000B),
                        borderRadius: BorderRadius.circular(25378200),
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount.toString(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16 / 12, // line-height: 16px / font-size: 12px
                            letterSpacing: 0,
                            color: Color(0xFFFFFFFF), // #FFFFFF
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PalRefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _notificationItems.length + 1,
                  separatorBuilder: (_, index) {
                    if (index == 0) {
                      return const SizedBox(height: 0);
                    }
                    return const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const _WelcomeNotificationCard();
                    }
                    final item = _notificationItems[index - 1];
                    // Get original notification data for navigation
                    final notificationData = item.notificationData;
                    return GestureDetector(
                      onTap: () =>
                          _handleNotificationTap(item, notificationData),
                      child: _NotificationTile(item: item),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeNotificationCard extends StatelessWidget {
  const _WelcomeNotificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(254, 242, 242, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000), // Light shadow with 10% opacity
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🎉', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172A),
                        ),
                        children: [
                          TextSpan(text: 'Welcome to '),
                          TextSpan(
                            text: 'Pal',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                '! Join the conversation, explore what’s new, and make your mark.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '2m ago',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: item.tileBackgroundColor),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationAvatar(item: item),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _NotificationHeadline(item: item)),
                    if (item.unread)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3358),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
                if (item.body != null) ...[
                  const SizedBox(height: 6),
                  if (item.bodyAsQuote)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0xFFCBD5E1), width: 3),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                      child: Text(
                        item.body!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF475467),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Text(
                        item.body!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ),
                ],
                if (item.ctaLabel != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/notifications/sharelink.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: Text(
                      item.ctaLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      backgroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.timestamp,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationHeadline extends StatelessWidget {
  const _NotificationHeadline({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    for (final part in item.headlineParts) {
      spans.add(
        TextSpan(
          text: part.text,
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: part.isEmphasized ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF0F172A),
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    const double size = 47;

    // User avatar: network image OR initials — use the same styling as
    // the post card's comment avatar (Color(0xFFF1F5F9) bg, Color(0xFF314158) text/border).
    if (item.avatarNetworkUrl != null || item.avatarInitials != null) {
      return ProfileAvatarWidget(
        imageUrl: item.avatarNetworkUrl,
        initials: item.avatarInitials ?? '?',
        size: size,
        borderWidth: 2,
        borderColor: const Color(0xFFE2E8F0),
        backgroundColor: const Color(0xFFF1F5F9),
        textColor: const Color(0xFF314158),
      );
    }

    // System/icon-based notifications (SVG or Material icon inside a circle).
    final BoxDecoration decoration = BoxDecoration(
      color: item.avatarGradient == null
          ? item.avatarBackground ?? const Color(0xFFF1F5F9)
          : null,
      gradient: item.avatarGradient,
      borderRadius: BorderRadius.circular(size / 2),
      border: item.hasAvatarBorder
          ? Border.all(color: const Color(0xFF314158), width: 2)
          : null,
    );

    if (item.avatarSvgAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        alignment: Alignment.center,
        child: SvgPicture.asset(
          item.avatarSvgAsset!,
          width: 24,
          height: 24,
          colorFilter: item.avatarIconColor != null
              ? ColorFilter.mode(item.avatarIconColor!, BlendMode.srcIn)
              : null,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Icon(
        item.avatarIcon ?? Icons.notifications_outlined,
        color: item.avatarIconColor ?? Colors.white,
        size: 24,
      ),
    );
  }
}

// Old mock data removed - now using real data from database via NotificationService
// NotificationItem and HeadlinePart classes are now in lib/models/notification_item.dart
