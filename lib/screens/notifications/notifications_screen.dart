import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';
import 'package:pal/services/notification_service.dart';
import 'package:pal/utils/notification_mapper.dart';
import 'package:pal/models/notification_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isPageLoading = true;
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _notificationItems = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllNotificationsAsRead();
    });
    _loadNotifications();
    _setupRealtimeListener();
  }

  /// Mark all notifications as read when notifications tab is opened
  Future<void> _markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      // Reload to update unread count
      if (mounted) {
        final unreadCount = await _notificationService.getUnreadCount();
        setState(() {
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint(
        '[NotificationsScreen] Error marking all notifications as read: $e',
      );
    }
  }

  /// Set up real-time listener for new notifications
  void _setupRealtimeListener() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    // Listen for new notifications
    supabase
        .from('notifications_history')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((data) {
          // Reload notifications when new one arrives
          if (mounted) {
            _loadNotifications();
          }
        });
  }

  @override
  void dispose() {
    // Cleanup is handled automatically by Supabase stream
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isPageLoading = true;
    });

    try {
      // Fetch notifications from database
      final notifications = await _notificationService.getNotifications(
        limit: 50,
      );

      // Convert to UI format
      final items = notifications
          .map((n) => NotificationMapper.mapToNotificationItem(n))
          .whereType<NotificationItem>()
          .toList();

      // Get unread count
      final unreadCount = await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _notificationItems = items;
        _unreadCount = unreadCount;
        _isPageLoading = false;
      });
    } catch (e) {
      debugPrint('[NotificationsScreen] Error loading notifications: $e');
      if (!mounted) return;
      setState(() {
        _isPageLoading = false;
      });
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
    if (notificationId != null) {
      // Mark as read and clicked
      await _notificationService.markAsRead(notificationId);
      await _notificationService.markAsClicked(notificationId);
    }

    // Extract navigation data
    final notificationType =
        notificationData['notification_type']?.toString() ?? '';
    final data = notificationData['data'] as Map<String, dynamic>? ?? {};
    final postId =
        data['post_id']?.toString() ?? notificationData['post_id']?.toString();
    final commentId =
        data['comment_id']?.toString() ??
        notificationData['comment_id']?.toString();

    // Navigate based on notification type
    // Handle both new and legacy notification types
    switch (notificationType) {
      case 'new_comment':
      case 'post_reply': // Legacy support
      case 'reply_to_comment':
      case 'comment_reply': // Legacy support
      case 'post_upvote':
      case 'post_hot':
      case 'post_top':
      case 'post_trending':
        if (postId != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => route.isFirst,
            arguments: {'highlight_post_id': postId},
          );
        }
        break;
      case 'comment_upvote':
      case 'mention_in_comment':
      case 'mention_in_post':
      case 'mention': // Legacy support
        if (postId != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => route.isFirst,
            arguments: {
              'highlight_post_id': postId,
              'highlight_comment_id': commentId,
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
        Navigator.of(context).pushNamed('/settings');
        break;
    }

    // Refresh to update unread status
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading overlay immediately while loading
    if (_isPageLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: PalLoadingOverlay(),
      );
    }

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
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
                      width: 28.0669,
                      height: 23.98981,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7000B),
                        borderRadius: BorderRadius.circular(25378200),
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
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
            PalBottomNavigationBar(
              active: PalNavDestination.notifications,
              onHomeTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('/home');
              },
              onNotificationsTap: () {},
              onSettingsTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
    return scaffold;
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
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
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFE7000B),
                shape: BoxShape.circle,
              ),
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
    const double size = 46.99876;
    if (item.avatarImageAsset != null) {
      final image = Image.asset(
        item.avatarImageAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );

      if (!item.hasAvatarBorder) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: image,
        );
      }

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: const Color(0xFF0F172B), width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      );
    }

    final BoxDecoration decoration = BoxDecoration(
      color: item.avatarGradient == null
          ? item.avatarBackground ?? const Color(0xFFF1F5F9)
          : null,
      gradient: item.avatarGradient,
      borderRadius: BorderRadius.circular(size / 2),
      border: item.hasAvatarBorder
          ? Border.all(color: const Color(0xFF0F172B), width: 3)
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
