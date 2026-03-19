import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';

/// Utility to convert database notification data to UI format
class NotificationMapper {
  /// Convert database notification to NotificationItem
  static NotificationItem? mapToNotificationItem(Map<String, dynamic> notification) {
    try {
      // Support both edge-function shape (type, from_username, message, read_at)
      // and legacy DB shape (notification_type, data{}, body, is_read).
      final notificationType = notification['notification_type']?.toString()
          ?? notification['type']?.toString() ?? '';
      final title = notification['title']?.toString() ?? '';
      final body = notification['body']?.toString()
          ?? notification['message']?.toString() ?? '';
      final data = notification['data'] as Map<String, dynamic>? ?? {};

      // Edge function marks read via read_at timestamp; fallback to is_read bool.
      final rawIsRead = notification['is_read'];
      final readAt = notification['read_at'];
      final isRead = rawIsRead == true
          || rawIsRead?.toString() == 'true'
          || (readAt != null && readAt.toString().isNotEmpty);

      // from_username and profile picture are top-level in edge function response.
      final fromUsername = notification['from_username']?.toString();
      final fromProfilePictureUrl = notification['from_profile_picture_url']?.toString();
      // from_initials provided by edge function; derive from username as fallback.
      final fromInitials = (() {
        final raw = notification['from_initials']?.toString();
        if (raw != null && raw.isNotEmpty) return raw.toUpperCase();
        if (fromUsername == null || fromUsername.isEmpty) return null;
        final clean = fromUsername.replaceAll('@', '').trim();
        final parts = clean.split(RegExp(r'[\s_]+'));
        if (parts.length >= 2) {
          return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
        }
        return clean.length >= 2
            ? clean.substring(0, 2).toUpperCase()
            : clean[0].toUpperCase();
      })();

      // post_id / comment_id may be top-level or inside data{}.
      final topPostId = notification['post_id']?.toString();
      final topCommentId = notification['comment_id']?.toString();

      final createdAt = notification['created_at']?.toString();
      final id = notification['id']?.toString();
      
      // Store original notification data for navigation
      final notificationData = Map<String, dynamic>.from(notification);

      // Parse timestamp
      String timestamp = 'Just now';
      if (createdAt != null) {
        try {
          final dateTime = DateTime.parse(createdAt);
          timestamp = _formatTimestamp(dateTime);
        } catch (e) {
          timestamp = 'Recently';
        }
      }

      // Determine if unread (show highlight)
      final tileBackgroundColor = isRead 
          ? null 
          : const Color.fromRGBO(254, 242, 242, 0.4);

      // Map notification type to UI format
      // Handle edge-function types (comment, reply, upvote, mention)
      // AND legacy DB types (new_comment, post_reply, reply_to_comment, etc.)
      NotificationItem? item;
      switch (notificationType) {
        case 'comment':        // edge function
        case 'new_comment':
        case 'post_reply':
          item = _mapNewComment(data, title, body, timestamp, isRead, tileBackgroundColor, fromUsername);
          break;

        case 'reply':          // edge function
        case 'reply_to_comment':
        case 'comment_reply':
          item = _mapReplyToComment(data, title, body, timestamp, isRead, tileBackgroundColor, fromUsername);
          break;

        case 'upvote':         // edge function (post upvote)
        case 'post_upvote':
          item = _mapPostUpvote(data, title, body, timestamp, isRead, tileBackgroundColor, fromUsername);
          break;

        case 'comment_upvote':
          item = _mapCommentUpvote(data, title, body, timestamp, isRead, tileBackgroundColor, fromUsername);
          break;

        case 'mention':        // edge function / legacy
        case 'mention_in_comment':
        case 'mention_in_post':
          item = _mapMention(data, title, body, timestamp, isRead, tileBackgroundColor, notificationType, fromUsername);
          break;

        case 'post_hot':
          item = _mapPostHot(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;

        case 'post_top':
          item = _mapPostTop(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;

        case 'post_trending':
          item = _mapPostTrending(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;

        case 'report_under_review':
        case 'report_resolved':
          item = _mapReportStatus(data, title, body, timestamp, isRead, tileBackgroundColor, notificationType);
          break;

        case 'account_suspended':
        case 'account_warning':
        case 'account_reactivated':
          item = _mapAccountStatus(data, title, body, timestamp, isRead, tileBackgroundColor, notificationType);
          break;

        default:
          item = _mapGenericNotification(title, body, timestamp, isRead, tileBackgroundColor);
      }

      // Merge top-level post_id / comment_id into notificationData for navigation.
      if (topPostId != null) notificationData['post_id'] = topPostId;
      if (topCommentId != null) notificationData['comment_id'] = topCommentId;
      
      // Attach original notification data for navigation
      // Create a new item with notificationData and profile picture.
      // When a network profile picture is available it takes priority;
      // suppress the static asset placeholder so only the real photo shows.
      final bool hasNetworkPic = fromProfilePictureUrl != null && fromProfilePictureUrl.isNotEmpty;
      final mappedItem = NotificationItem(
        headlineParts: item.headlineParts,
        subtitle: item.subtitle,
        body: item.body,
        bodyAsQuote: item.bodyAsQuote,
        timestamp: item.timestamp,
        avatarNetworkUrl: hasNetworkPic ? fromProfilePictureUrl : null,
        avatarInitials: hasNetworkPic ? null : fromInitials,
        avatarImageAsset: hasNetworkPic ? null : (fromInitials != null ? null : item.avatarImageAsset),
        avatarIcon: item.avatarIcon,
        avatarSvgAsset: item.avatarSvgAsset,
        avatarBackground: item.avatarBackground,
        avatarGradient: item.avatarGradient,
        avatarIconColor: item.avatarIconColor,
        ctaLabel: item.ctaLabel,
        unread: item.unread,
        hasAvatarBorder: item.hasAvatarBorder,
        tileBackgroundColor: item.tileBackgroundColor,
        notificationData: notificationData,
      );
      
      debugPrint('[NotificationMapper] Successfully mapped notification: $notificationType (id: $id)');
      return mappedItem;
    } catch (e) {
      debugPrint('[NotificationMapper] Error mapping notification: $e');
      return null;
    }
  }

  static NotificationItem _mapNewComment(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String? fromUsername,
  ) {
    final raw = fromUsername
        ?? data['commenter_username']?.toString()
        ?? data['username']?.toString()
        ?? 'Someone';
    final formattedUsername = (raw == 'Someone' || raw.isEmpty)
        ? 'Someone'
        : (raw.startsWith('@') ? raw : '@$raw');
    final postContent = data['post_content']?.toString() ?? '';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(formattedUsername, isEmphasized: true),
        const HeadlinePart(' commented on one of your posts'),
      ],
      subtitle: postContent.isNotEmpty && postContent.length <= 100
          ? postContent
          : (postContent.length > 100 ? '${postContent.substring(0, 100)}...' : null),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarImageAsset: 'assets/feedPage/profile.png',
      hasAvatarBorder: true,
    );
  }

  static NotificationItem _mapReplyToComment(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String? fromUsername,
  ) {
    final raw = fromUsername
        ?? data['replier_username']?.toString()
        ?? data['username']?.toString()
        ?? 'Someone';
    final formattedUsername = (raw == 'Someone' || raw.isEmpty)
        ? 'Someone'
        : (raw.startsWith('@') ? raw : '@$raw');

    return NotificationItem(
      headlineParts: [
        HeadlinePart(formattedUsername, isEmphasized: true),
        const HeadlinePart(' replied to your comment'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarImageAsset: 'assets/feedPage/profile.png',
      hasAvatarBorder: true,
    );
  }

  static NotificationItem _mapPostUpvote(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String? fromUsername,
  ) {
    final raw = fromUsername
        ?? data['voter_username']?.toString()
        ?? data['username']?.toString()
        ?? 'Someone';
    final formattedUsername = (raw == 'Someone' || raw.isEmpty)
        ? 'Someone'
        : (raw.startsWith('@') ? raw : '@$raw');

    return NotificationItem(
      headlineParts: [
        HeadlinePart(formattedUsername, isEmphasized: true),
        const HeadlinePart(' upvoted your post'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarImageAsset: 'assets/feedPage/profile.png',
      hasAvatarBorder: true,
    );
  }

  static NotificationItem _mapCommentUpvote(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String? fromUsername,
  ) {
    final raw = fromUsername
        ?? data['voter_username']?.toString()
        ?? data['username']?.toString()
        ?? 'Someone';
    final formattedUsername = (raw == 'Someone' || raw.isEmpty)
        ? 'Someone'
        : (raw.startsWith('@') ? raw : '@$raw');

    return NotificationItem(
      headlineParts: [
        HeadlinePart(formattedUsername, isEmphasized: true),
        const HeadlinePart(' upvoted your comment'),
      ],
      body: data['comment_content']?.toString() ?? data['content']?.toString(),
      bodyAsQuote: true,
      subtitle: data['post_content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarImageAsset: 'assets/feedPage/profile.png',
      hasAvatarBorder: true,
    );
  }

  static NotificationItem _mapMention(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String notificationType,
    String? fromUsername,
  ) {
    final raw = fromUsername
        ?? data['mentioner_username']?.toString()
        ?? data['username']?.toString()
        ?? 'Someone';
    final formattedUsername = (raw == 'Someone' || raw.isEmpty)
        ? 'Someone'
        : (raw.startsWith('@') ? raw : '@$raw');
    final isInPost = notificationType == 'mention_in_post';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(formattedUsername, isEmphasized: true),
        HeadlinePart(isInPost ? ' mentioned you in a post' : ' mentioned you in a comment'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarBackground: const Color(0xFFEBF5FF),
      avatarIcon: Icons.alternate_email_rounded,
      avatarIconColor: const Color(0xFF2563EB),
      hasAvatarBorder: true,
    );
  }

  static NotificationItem _mapPostHot(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
  ) {
    return NotificationItem(
      headlineParts: [
        const HeadlinePart('Your post is getting hot!'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarSvgAsset: 'assets/images/hotIcon.svg',
      avatarGradient: const LinearGradient(
        colors: [Color(0xFFFF6900), Color(0xFFE7000B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      avatarIconColor: Colors.white,
      notificationData: null,
    );
  }

  static NotificationItem _mapPostTop(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
  ) {
    return NotificationItem(
      headlineParts: [
        const HeadlinePart('Your post reached Top Posts this week!'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarBackground: const Color(0xFF9810FA),
      avatarSvgAsset: 'assets/notifications/topPost.svg',
      avatarIconColor: Colors.white,
      notificationData: null,
    );
  }

  static NotificationItem _mapPostTrending(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
  ) {
    final locationName = data['location_name']?.toString() ?? 'your location';
    return NotificationItem(
      headlineParts: [
        HeadlinePart('Your post is trending in $locationName'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarBackground: const Color(0xFF9810FA),
      avatarSvgAsset: 'assets/notifications/topPost.svg',
      avatarIconColor: Colors.white,
      notificationData: null,
    );
  }

  static NotificationItem _mapReportStatus(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String notificationType,
  ) {
    return NotificationItem(
      headlineParts: [
        HeadlinePart(notificationType == 'report_resolved' 
            ? 'Your report has been resolved'
            : 'Your report is under review'),
      ],
      subtitle: data['post_content']?.toString() ?? 
               data['comment_content']?.toString() ?? 
               data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarBackground: const Color(0xFF314158),
      avatarSvgAsset: 'assets/notifications/underReview.svg',
      avatarIconColor: Colors.white,
      notificationData: null,
    );
  }

  static NotificationItem _mapAccountStatus(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
    String notificationType,
  ) {
    return NotificationItem(
      headlineParts: [
        HeadlinePart(notificationType == 'account_suspended'
            ? 'Your account has been temporarily suspended for violating community guidelines. Please review our policies.'
            : 'You have received a warning. Please review our community guidelines.'),
      ],
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarBackground: const Color(0xFFC10007),
      avatarSvgAsset: 'assets/notifications/accountSuspended.svg',
      avatarIconColor: Colors.white,
      notificationData: null,
    );
  }

  static NotificationItem _mapGenericNotification(
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
  ) {
    return NotificationItem(
      headlineParts: [
        HeadlinePart(title),
      ],
      body: body.isNotEmpty ? body : null,
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarBackground: const Color(0xFFF1F5F9),
      avatarIcon: Icons.notifications_outlined,
      avatarIconColor: const Color(0xFF475467),
      notificationData: null,
    );
  }

  /// Format timestamp to relative time (e.g., "2m ago", "1h ago")
  static String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

