import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';

/// Utility to convert database notification data to UI format
class NotificationMapper {
  /// Convert database notification to NotificationItem
  static NotificationItem? mapToNotificationItem(Map<String, dynamic> notification) {
    try {
      final notificationType = notification['notification_type']?.toString() ?? '';
      final title = notification['title']?.toString() ?? '';
      final body = notification['body']?.toString() ?? '';
      final data = notification['data'] as Map<String, dynamic>? ?? {};
      final isRead = notification['is_read'] == true;
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
      // Handle both old naming (post_reply, comment_reply) and new naming (new_comment, reply_to_comment)
      NotificationItem? item;
      switch (notificationType) {
        case 'new_comment':
        case 'post_reply': // Legacy support
          item = _mapNewComment(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;
        
        case 'reply_to_comment':
        case 'comment_reply': // Legacy support
          item = _mapReplyToComment(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;
        
        case 'post_upvote':
          item = _mapPostUpvote(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;
        
        case 'comment_upvote':
          item = _mapCommentUpvote(data, title, body, timestamp, isRead, tileBackgroundColor);
          break;
        
        case 'mention_in_comment':
        case 'mention_in_post':
        case 'mention': // Legacy support
          item = _mapMention(data, title, body, timestamp, isRead, tileBackgroundColor, notificationType);
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
      
      // Attach original notification data for navigation
      // Create a new item with notificationData
      final mappedItem = NotificationItem(
        headlineParts: item.headlineParts,
        subtitle: item.subtitle,
        body: item.body,
        bodyAsQuote: item.bodyAsQuote,
        timestamp: item.timestamp,
        avatarImageAsset: item.avatarImageAsset,
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
  ) {
    final commenterUsername = data['commenter_username']?.toString() ?? 'Someone';
    final postContent = data['post_content']?.toString() ?? '';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(commenterUsername, isEmphasized: true),
        const HeadlinePart(' commented on your post'),
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
  ) {
    final replierUsername = data['replier_username']?.toString() ?? 
                            data['username']?.toString() ?? 
                            'Someone';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(replierUsername, isEmphasized: true),
        const HeadlinePart(' replied to your comment'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarImageAsset: 'assets/feedPage/profile.png',
      hasAvatarBorder: true,
      notificationData: null,
    );
  }

  static NotificationItem _mapPostUpvote(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
  ) {
    final voterUsername = data['voter_username']?.toString() ?? 
                          data['username']?.toString() ?? 
                          'Someone';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(voterUsername, isEmphasized: true),
        const HeadlinePart(' upvoted your post'),
      ],
      subtitle: data['post_content']?.toString() ?? data['content']?.toString(),
      timestamp: timestamp,
      unread: !isRead,
      tileBackgroundColor: tileBackgroundColor,
      avatarImageAsset: 'assets/feedPage/profile.png',
      hasAvatarBorder: true,
      notificationData: null,
    );
  }

  static NotificationItem _mapCommentUpvote(
    Map<String, dynamic> data,
    String title,
    String body,
    String timestamp,
    bool isRead,
    Color? tileBackgroundColor,
  ) {
    final voterUsername = data['voter_username']?.toString() ?? 
                          data['username']?.toString() ?? 
                          'Someone';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(voterUsername, isEmphasized: true),
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
      notificationData: null,
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
  ) {
    final mentionerUsername = data['mentioner_username']?.toString() ?? 
                              data['username']?.toString() ?? 
                              'Someone';
    final isInPost = notificationType == 'mention_in_post';

    return NotificationItem(
      headlineParts: [
        HeadlinePart(mentionerUsername, isEmphasized: true),
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
      notificationData: null,
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

