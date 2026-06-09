import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum PushNotificationVariant {
  commentSocial,
  postUpvote,
  postComment,
  generic,
}

class PushNotificationDisplayModel {
  const PushNotificationDisplayModel({
    required this.variant,
    required this.username,
    required this.actionText,
    this.contentLine,
    this.postTitle,
    this.profilePictureUrl,
    this.postImageUrl,
    this.avatarInitials,
    this.timestampLabel = 'now',
    this.showCommentQuote = false,
    this.notificationType = '',
  });

  final PushNotificationVariant variant;
  final String username;
  final String actionText;
  final String? contentLine;
  final String? postTitle;
  final String? profilePictureUrl;
  final String? postImageUrl;
  final String? avatarInitials;
  final String timestampLabel;
  final bool showCommentQuote;
  final String notificationType;

  String get displayUsername {
    if (username.isEmpty || username == 'Someone') return 'Someone';
    return username.replaceAll('@', '').trim();
  }

  String get formattedUsername {
    if (username.isEmpty || username == 'Someone') return 'Someone';
    return username.startsWith('@') ? username : '@$username';
  }

  String get androidTitle => '$displayUsername $actionText';

  bool get hasProfileImage =>
      profilePictureUrl != null && profilePictureUrl!.isNotEmpty;

  bool get hasPostImage =>
      postImageUrl != null && postImageUrl!.isNotEmpty;

  /// Profile photo for social notifications, post thumbnail for upvotes.
  String? get iosAttachmentUrl {
    if (variant == PushNotificationVariant.postUpvote) {
      return hasPostImage ? postImageUrl : null;
    }
    if (variant == PushNotificationVariant.generic) {
      return null;
    }
    return hasProfileImage ? profilePictureUrl : null;
  }

  String get resolvedInitials {
    if (avatarInitials != null && avatarInitials!.isNotEmpty) {
      return avatarInitials!.toUpperCase();
    }
    final clean = displayUsername;
    if (clean == 'Someone') return 'SU';
    if (clean.length >= 2) return clean.substring(0, 2).toUpperCase();
    return clean[0].toUpperCase();
  }

  String get iosTitle {
    if (variant == PushNotificationVariant.generic) {
      return 'kobiPal';
    }
    return androidTitle;
  }

  /// Light-blue "Notification" sub-label shown on iOS banners.
  String? get iosSubtitle {
    if (variant == PushNotificationVariant.generic) {
      return null;
    }
    return 'Notification';
  }

  String? get iosBody {
    if (variant == PushNotificationVariant.generic) {
      return contentLine;
    }
    return iosPreviewBody;
  }

  /// Plain preview text for iOS banners (with or without image attachment).
  String? get iosPreviewBody {
    final parts = <String>[];

    if (contentLine != null && contentLine!.isNotEmpty) {
      parts.add(contentLine!);
    }

    if (showCommentQuote &&
        postTitle != null &&
        postTitle!.isNotEmpty &&
        !parts.contains(postTitle)) {
      parts.add(postTitle!);
    } else if (variant == PushNotificationVariant.postComment &&
        postTitle != null &&
        postTitle!.isNotEmpty) {
      parts.add(postTitle!);
    } else if (variant == PushNotificationVariant.postUpvote &&
        postTitle != null &&
        postTitle!.isNotEmpty) {
      parts.add(postTitle!);
    } else if (parts.isEmpty &&
        postTitle != null &&
        postTitle!.isNotEmpty) {
      parts.add(postTitle!);
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join('\n');
  }

  /// Whether the in-app banner should use the plain preview row (no quote bar).
  bool get usesPlainIosPreview =>
      !hasProfileImage &&
      variant == PushNotificationVariant.commentSocial &&
      !showCommentQuote &&
      contentLine != null &&
      contentLine!.isNotEmpty;

  String get inboxLine => androidTitle;

  bool get usesQuoteContent =>
      showCommentQuote ||
      (variant == PushNotificationVariant.commentSocial &&
          contentLine != null &&
          contentLine!.isNotEmpty);

  String? get quotedContentLine {
    if (usesQuoteContent && contentLine != null && contentLine!.isNotEmpty) {
      return contentLine;
    }
    if (variant == PushNotificationVariant.postUpvote &&
        postTitle != null &&
        postTitle!.isNotEmpty) {
      return postTitle;
    }
    if (variant == PushNotificationVariant.postComment &&
        postTitle != null &&
        postTitle!.isNotEmpty) {
      return postTitle;
    }
    return contentLine ?? postTitle;
  }

  String? get androidBody {
    if (variant == PushNotificationVariant.commentSocial ||
        variant == PushNotificationVariant.postComment) {
      if (postTitle != null && postTitle!.isNotEmpty) {
        return postTitle;
      }
      if (contentLine != null && contentLine!.isNotEmpty) {
        return contentLine;
      }
      return null;
    }

    final buffer = StringBuffer();

    if (usesQuoteContent && contentLine != null && contentLine!.isNotEmpty) {
      buffer.writeln(contentLine);
    } else if (contentLine != null && contentLine!.isNotEmpty) {
      buffer.writeln(contentLine);
    }

    if (postTitle != null &&
        postTitle!.isNotEmpty &&
        (showCommentQuote || variant == PushNotificationVariant.postComment)) {
      buffer.writeln(postTitle);
    } else if (variant == PushNotificationVariant.postUpvote &&
        postTitle != null &&
        postTitle!.isNotEmpty &&
        !usesQuoteContent) {
      buffer.writeln(postTitle);
    }

    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  String get androidMessagingText {
    final body = androidBody;
    if (body == null || body.isEmpty) {
      return actionText;
    }
    return body;
  }

  String get inAppPreviewLine {
    return quotedContentLine ?? actionText;
  }
}

class PushNotificationBuilder {
  static const androidGroupKey = 'com.kobi.pal.notifications';
  static const iosThreadIdentifier = 'com.kobi.pal.notifications';
  static const summaryNotificationId = 0;

  static PushNotificationDisplayModel fromRemoteData(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    final type = data['type']?.toString()
        ?? data['notification_type']?.toString()
        ?? '';
    final username = data['from_username']?.toString().trim().isNotEmpty == true
        ? data['from_username'].toString().trim()
        : 'Someone';
    final postTitle = _postTitleFromContent(data);
    final commentContent = data['comment_content']?.toString().trim();
    final timestampLabel = _timestampLabel(data['created_at']?.toString());
    final profilePictureUrl = data['from_profile_picture_url']?.toString();
    final postImageUrl = data['post_image_url']?.toString()
        ?? data['image_url']?.toString();
    final avatarInitials = _initialsFromData(data, username);

    switch (type) {
      case 'mention':
      case 'mention_in_comment':
      case 'mention_in_post':
        return PushNotificationDisplayModel(
          variant: PushNotificationVariant.commentSocial,
          username: username,
          actionText: type == 'mention_in_post'
              ? 'mentioned you in a post'
              : 'mentioned you in a comment',
          contentLine: commentContent,
          postTitle: postTitle,
          profilePictureUrl: profilePictureUrl,
          avatarInitials: avatarInitials,
          timestampLabel: timestampLabel,
          showCommentQuote: false,
          notificationType: type,
        );

      case 'reply':
      case 'reply_to_comment':
      case 'comment_reply':
        return PushNotificationDisplayModel(
          variant: PushNotificationVariant.commentSocial,
          username: username,
          actionText: 'replied to your comment',
          contentLine: commentContent,
          postTitle: postTitle,
          profilePictureUrl: profilePictureUrl,
          avatarInitials: avatarInitials,
          timestampLabel: timestampLabel,
          showCommentQuote: true,
          notificationType: type,
        );

      case 'comment_upvote':
        return PushNotificationDisplayModel(
          variant: PushNotificationVariant.commentSocial,
          username: username,
          actionText: 'upvoted your comment',
          contentLine: commentContent,
          postTitle: postTitle,
          profilePictureUrl: profilePictureUrl,
          avatarInitials: avatarInitials,
          timestampLabel: timestampLabel,
          showCommentQuote: true,
          notificationType: type,
        );

      case 'comment':
      case 'new_comment':
      case 'post_reply':
        return PushNotificationDisplayModel(
          variant: PushNotificationVariant.postComment,
          username: username,
          actionText: 'commented on one of your posts',
          postTitle: postTitle,
          profilePictureUrl: profilePictureUrl,
          avatarInitials: avatarInitials,
          timestampLabel: timestampLabel,
          notificationType: type,
        );

      case 'upvote':
      case 'post_upvote':
        return PushNotificationDisplayModel(
          variant: PushNotificationVariant.postUpvote,
          username: username,
          actionText: 'upvoted your post',
          postTitle: postTitle,
          profilePictureUrl: profilePictureUrl,
          postImageUrl: postImageUrl,
          avatarInitials: avatarInitials,
          timestampLabel: timestampLabel,
          notificationType: type,
        );

      default:
        return PushNotificationDisplayModel(
          variant: PushNotificationVariant.generic,
          username: username,
          actionText: '',
          contentLine: fallbackBody ?? data['message']?.toString() ?? data['body']?.toString(),
          profilePictureUrl: profilePictureUrl,
          avatarInitials: avatarInitials,
          timestampLabel: timestampLabel,
          notificationType: type,
        );
    }
  }

  static AndroidNotificationDetails buildAndroidDetails({
    required PushNotificationDisplayModel model,
    ByteArrayAndroidBitmap? largeIcon,
    ByteArrayAndroidBitmap? bigPicture,
    ByteArrayAndroidIcon? personIcon,
    required bool isGroupSummary,
  }) {
    if (isGroupSummary) {
      throw ArgumentError('Use buildGroupSummaryAndroidDetails for summaries');
    }

    StyleInformation? styleInformation;
    final body = model.androidBody;

    if (model.variant == PushNotificationVariant.postUpvote && bigPicture != null) {
      styleInformation = BigPictureStyleInformation(
        bigPicture,
        contentTitle: model.androidTitle,
        summaryText: body,
        hideExpandedLargeIcon: true,
      );
    } else if (body != null && body.isNotEmpty) {
      styleInformation = BigTextStyleInformation(
        body,
        contentTitle: model.androidTitle,
        summaryText: _androidSubText(model),
      );
    }

    return AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: const Color(0xFF155DFC),
      icon: '@drawable/ic_notification',
      largeIcon: largeIcon,
      styleInformation: styleInformation,
      groupKey: androidGroupKey,
      setAsGroupSummary: false,
      groupAlertBehavior: GroupAlertBehavior.summary,
      subText: _androidSubText(model),
      ticker: model.androidTitle,
    );
  }

  static String _androidSubText(PushNotificationDisplayModel model) {
    if (model.variant == PushNotificationVariant.commentSocial ||
        model.variant == PushNotificationVariant.postComment) {
      return model.timestampLabel;
    }
    return 'kobiPal • ${model.timestampLabel}';
  }

  static AndroidNotificationDetails buildGroupSummaryAndroidDetails({
    required int messageCount,
    required List<String> inboxLines,
  }) {
    final summaryText = messageCount == 1
        ? '1 new message'
        : '$messageCount new messages';

    return AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: const Color(0xFF155DFC),
      icon: '@drawable/ic_notification',
      styleInformation: InboxStyleInformation(
        inboxLines,
        contentTitle: 'kobiPal',
        summaryText: summaryText,
      ),
      groupKey: androidGroupKey,
      setAsGroupSummary: true,
      groupAlertBehavior: GroupAlertBehavior.summary,
      subText: 'kobiPal • $summaryText',
      ticker: 'kobiPal • $summaryText',
    );
  }

  static DarwinNotificationDetails buildIosDetails({
    required PushNotificationDisplayModel model,
    List<DarwinNotificationAttachment>? attachments,
  }) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: model.iosSubtitle,
      threadIdentifier: iosThreadIdentifier,
      attachments: attachments,
      interruptionLevel: InterruptionLevel.active,
    );
  }

  static DarwinNotificationDetails buildIosGroupSummaryDetails({
    required int messageCount,
  }) {
    final summaryText = messageCount == 1
        ? '1 new message'
        : '$messageCount new messages';

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: summaryText,
      threadIdentifier: iosThreadIdentifier,
      interruptionLevel: InterruptionLevel.active,
    );
  }


  static String? _postTitleFromContent(Map<String, dynamic> data) {
    final rawTitle = data['post_title']?.toString().trim();
    if (rawTitle != null && rawTitle.isNotEmpty) {
      return rawTitle;
    }

    final rawContent = data['post_content']?.toString().trim()
        ?? data['content']?.toString().trim();
    if (rawContent == null || rawContent.isEmpty) {
      return null;
    }

    final segments = rawContent.split('\n\n');
    final title = segments.first.trim();
    return title.isEmpty ? null : title;
  }

  static String _initialsFromData(Map<String, dynamic> data, String username) {
    final raw = data['from_initials']?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return raw.toUpperCase();
    }

    final clean = username.replaceAll('@', '').trim();
    if (clean.isEmpty || clean == 'Someone') return 'SU';
    final parts = clean.split(RegExp(r'[\s_]+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return clean.length >= 2
        ? clean.substring(0, 2).toUpperCase()
        : clean[0].toUpperCase();
  }

  static String _timestampLabel(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'now';
    try {
      final dateTime = DateTime.parse(createdAt);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) return 'now';
      if (difference.inHours < 1) return '${difference.inMinutes}m';
      if (difference.inDays < 1) return '${difference.inHours}h';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return '${dateTime.day}/${dateTime.month}';
    } catch (_) {
      return 'now';
    }
  }
}
