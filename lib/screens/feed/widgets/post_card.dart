import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'delete_comment_dialog.dart';
import 'delete_post_dialog.dart';
import 'report_post_sheet.dart';
import 'block_user_dialog.dart';
import '../../../services/post_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/pal_toast.dart';
import '../../../utils/error_handler.dart';
import '../create_post_screen.dart';
import '../../admin/admin_user_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _menuReportIconUrl = 'assets/feedPage/reportIcon.svg';
const _menuBlockIconUrl = 'assets/feedPage/blockUser.svg';
const _menuDeleteIconUrl = 'assets/feedPage/deleteIcon.svg';
const _replyIconUrl = 'assets/feedPage/replyIcon.svg';

const _menuDividerColor = Color(0xFFE2E8F0);

const _menuBorderColor = Color(0x33FB2C36);

const _menuReportColor = Color(0xFFE7000B);
const _menuReportBackgroundColor = Color(0xFFFEF2F2);
const _menuBlockColor = Color(0xFF0F172B);
const _menuDeleteColor = Color(0xFFE7000B);

const _commentsSectionBackground = Color.fromRGBO(239, 246, 255, 0.3);

const _commentCardBorder = Color(0xFFE2E8F0);

const _commentMetaDotColor = Color(0xFF90A1B9);

const _commentMetaTextColor = Color(0xFF62748E);

const _commentAuthorColor = Color(0xFF0F172B);

const _commentBodyColor = Color(0xFF45556C);

const _commentReactionColor = Color(0xFF314158);

const _commentAvatarBackground = Color(0xFFF1F5F9);

enum PostCardVariant { top, topPost2, hot, hotPost2, newPost, wod, moderator, admin }

class PostCardData {
  const PostCardData({
    required this.variant,

    required this.username,

    required this.timeAgo,

    required this.location,

    required this.category,

    required this.title,

    required this.body,

    required this.commentsCount,

    required this.votes,

    this.id,

    this.avatarAsset,
    this.profilePictureUrl,
    this.initials,

    this.comments,

    this.badges,

    this.userId,
  });

  final PostCardVariant variant;

  final String username;

  final String timeAgo;

  final String location;

  final String category;

  final String title;

  final String body;

  final int commentsCount;

  final int votes;

  final String? id;

  final String? avatarAsset;
  final String? profilePictureUrl;
  final String? initials;

  final List<CommentData>? comments;

  final List<String>? badges;

  final String? userId;

  PostCardData copyWith({int? votes, List<CommentData>? comments}) {
    return PostCardData(
      variant: variant,

      username: username,

      timeAgo: timeAgo,

      location: location,

      category: category,

      title: title,

      body: body,

      commentsCount: commentsCount,

      votes: votes ?? this.votes,

      id: id,

      avatarAsset: avatarAsset,
      profilePictureUrl: profilePictureUrl,
      initials: initials,

      comments: comments ?? this.comments,

      badges: badges ?? this.badges,

      userId: userId,
    );
  }
}

class CommentData {
  const CommentData({
    required this.id,

    required this.author,

    required this.timeAgo,

    required this.body,

    required this.upvotes,

    required this.downvotes,

    this.avatarAsset,
    this.profilePictureUrl,
    this.initials,

    this.replies = const [],

    this.status = 'active',

    this.userId,

    this.userVote = 0, // 1 = upvoted, -1 = downvoted, 0 = neutral
  });

  final String id;

  final String author;

  final String timeAgo;

  final String body;

  final int upvotes;

  final int downvotes;

  final String? avatarAsset;
  final String? profilePictureUrl;
  final String? initials;

  final List<CommentData> replies;

  final String status;

  final String? userId;

  final int userVote; // 1 = upvoted, -1 = downvoted, 0 = neutral

  CommentData copyWith({
    String? id,

    String? author,

    String? timeAgo,

    String? body,

    int? upvotes,

    int? downvotes,

    String? avatarAsset,
    String? profilePictureUrl,
    String? initials,

    List<CommentData>? replies,

    String? status,

    String? userId,

    int? userVote,
  }) {
    return CommentData(
      id: id ?? this.id,

      author: author ?? this.author,

      timeAgo: timeAgo ?? this.timeAgo,

      body: body ?? this.body,

      upvotes: upvotes ?? this.upvotes,

      downvotes: downvotes ?? this.downvotes,

      avatarAsset: avatarAsset ?? this.avatarAsset,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,

      initials: initials ?? this.initials,

      replies: replies ?? this.replies,

      status: status ?? this.status,

      userId: userId ?? this.userId,

      userVote: userVote ?? this.userVote,
    );
  }
}

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.data,
    this.isPinnedAdmin = false,
    this.isYourPosts = false,
    this.showOverflowMenu = true,
    this.isUpvotedPostsScreen = false,
    this.initialCommentsExpanded = false,
    this.onPostDeleted,
  });

  final PostCardData data;

  final bool isPinnedAdmin;

  final bool isYourPosts;

  final bool showOverflowMenu;

  final bool isUpvotedPostsScreen;

  final bool initialCommentsExpanded;

  final ValueChanged<String>? onPostDeleted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _menuKey = GlobalKey();

  OverlayEntry? _overlayEntry;

  bool _showComments = false;

  final TextEditingController _commentController = TextEditingController();

  late int _currentVotes;

  int _userVote = 0; // 1 = upvoted, -1 = downvoted, 0 = neutral

  List<CommentData> _comments = const [];

  int? _actualCommentCount; // Store the actual comment count from API

  int? _activeReplyIndex;

  final TextEditingController _replyController = TextEditingController();

  final List<String> _recentCommentErrors = [];

  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  final AdminService _adminService = AdminService();
  final Map<String, ProfileData> _commentProfileCache = {};

  String? _currentUsername;
  String? _currentUserId;
  String? _currentUserProfilePictureUrl;
  String? _currentUserInitials;

  PostCardData get data => widget.data;

  List<CommentData> get _currentComments {
    if (_comments.isEmpty && (widget.data.comments?.isNotEmpty ?? false)) {
      _comments = _cloneComments(widget.data.comments!);
    }

    return _comments;
  }

  @override
  void initState() {
    super.initState();

    _currentVotes = data.votes;

    _comments = _cloneComments(widget.data.comments ?? const []);

    // Initialize comment count from feed data, but we'll verify it when comments are loaded
    // Don't trust feed count as it might include deleted comments
    _actualCommentCount =
        null; // Start with null, will be set when comments are loaded

    // Set initial comments expanded state if requested
    _showComments = widget.initialCommentsExpanded;

    // Hardcode upvote for WOD variant
    if (data.variant == PostCardVariant.wod) {
      _userVote = 1;
    }

    _loadCurrentUsername();
    _loadCurrentUserId();

    // Load comments in background to get accurate count (only if feed shows comments exist)
    // Also load if comments should be expanded initially
    if ((data.commentsCount > 0 || widget.initialCommentsExpanded) && data.id != null) {
      // Load comments in background to get accurate count of active comments
      Future.microtask(() => _loadComments());
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      debugPrint('Failed to load current user ID: $e');
    }
  }

  bool get _isOwnPost {
    if (_currentUserId == null || data.userId == null) {
      // Fallback to widget.isYourPosts if userId is not available
      return widget.isYourPosts;
    }
    return _currentUserId == data.userId;
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final response = await _postService.getProfile();

      final profile = response['profile'] as Map<String, dynamic>?;

      if (profile != null && mounted) {
        final username = profile['username']?.toString();
        final profilePictureUrl =
            (profile['profile_picture_url'] ?? profile['avatar_url'])
                ?.toString();
        final displayName = profile['display_name']?.toString();
        final firstName = profile['first_name']?.toString();
        final lastName = profile['last_name']?.toString();

        // Generate initials: prefer first/last name, fallback to display name, then username
        String initials = 'U';
        if (firstName != null && firstName.isNotEmpty) {
          initials = firstName[0].toUpperCase();
          if (lastName != null && lastName.isNotEmpty) {
            initials += lastName[0].toUpperCase();
          }
        } else if (displayName != null && displayName.isNotEmpty) {
          final parts = displayName.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            initials = parts[0][0].toUpperCase();
            if (parts.length > 1 && parts[1].isNotEmpty) {
              initials += parts[1][0].toUpperCase();
            }
          }
        } else if (username != null && username.isNotEmpty) {
          final cleanUsername = username.startsWith('@')
              ? username.substring(1)
              : username;
          if (cleanUsername.isNotEmpty) {
            initials = cleanUsername[0].toUpperCase();
          }
        }

        setState(() {
          if (username != null && username.isNotEmpty) {
            _currentUsername = username.startsWith('@')
                ? username
                : '@$username';
          }
          _currentUserProfilePictureUrl = profilePictureUrl;
          _currentUserInitials = initials;
        });
      }
    } catch (e) {
      // Silently fail - will use fallback '@user'

      debugPrint('Failed to load username: $e');
    }
  }

  String _mapReportReasonToBackendEnum(String reasonTitle) {
    const reasonMap = {
      'Spam or misleading': 'spam',

      'Harassment or hate speech': 'harassment',

      'Inappropriate content': 'inappropriate_content',

      'False information': 'misinformation',

      'Other': 'other',
    };

    return reasonMap[reasonTitle] ?? 'other';
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data.comments != widget.data.comments) {
      _comments = _cloneComments(widget.data.comments ?? const []);
    }
  }

  @override
  void dispose() {
    _removeOverlay();

    _commentController.dispose();

    _replyController.dispose();

    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();

    _overlayEntry = null;
  }

  /// Load comments from the API when comments section is expanded
  Future<void> _loadComments() async {
    if (data.id == null) return;

    try {
      final response = await _postService.getComments(postId: data.id!);

      if (!mounted) return;

      final commentsList = response['comments'] as List<dynamic>? ?? [];

      // Extract unique user IDs from comments for profile fetching
      final Set<String> userIds = {};
      for (final comment in commentsList) {
        if (comment is Map<String, dynamic>) {
          final userId = comment['user_id']?.toString();
          if (userId != null && userId.isNotEmpty) {
            userIds.add(userId);
          }
          // Also check replies
          final replies = comment['replies'] as List<dynamic>? ?? [];
          for (final reply in replies) {
            if (reply is Map<String, dynamic>) {
              final replyUserId = reply['user_id']?.toString();
              if (replyUserId != null && replyUserId.isNotEmpty) {
                userIds.add(replyUserId);
              }
            }
          }
        }
      }

      // Fetch profiles for comments that don't have profile picture in response
      await _fetchProfilesForComments(userIds);

      final mappedComments = commentsList
          .map((comment) => _mapCommentFromResponse(comment))
          .whereType<CommentData>()
          .toList();

      // Calculate actual comment count (including replies)
      final actualCount = _totalCommentCount(mappedComments);

      setState(() {
        _comments = mappedComments;
        // Update the actual comment count from loaded comments
        _actualCommentCount = actualCount;
      });
    } catch (e) {
      debugPrint('Failed to load comments: $e');
      // Don't show error to user - just log it
    }
  }

  /// Fetch profiles for comment authors if not already cached
  Future<void> _fetchProfilesForComments(Set<String> userIds) async {
    for (final userId in userIds) {
      // Skip if already cached
      if (_commentProfileCache.containsKey(userId)) continue;

      try {
        final profileData = await _profileService.getProfileDataByUserId(
          userId,
        );
        if (profileData != null && mounted) {
          _commentProfileCache[userId] = profileData;
        }
      } catch (e) {
        debugPrint(
          'ERROR: Failed to fetch profile for comment user $userId: $e',
        );
        // Continue fetching other profiles even if one fails
      }
    }
  }

  /// Map comment from API response to CommentData
  CommentData? _mapCommentFromResponse(dynamic commentData) {
    if (commentData is! Map<String, dynamic>) return null;

    final id = commentData['id']?.toString() ?? '';
    if (id.isEmpty) return null;

    final profile = commentData['profiles'] as Map<String, dynamic>?;
    final username =
        (commentData['username'] ?? profile?['username'] ?? '@user').toString();
    final author = username.startsWith('@') ? username : '@$username';

    final createdAt = commentData['created_at'] != null
        ? DateTime.tryParse(commentData['created_at'].toString())
        : null;

    final content = commentData['content']?.toString() ?? '';
    final upvotes = _parseInt(commentData['upvote_count'] ?? 0);
    final downvotes = _parseInt(commentData['downvote_count'] ?? 0);
    final status = commentData['status']?.toString() ?? 'active';

    // Extract user's vote state from API response
    int userVote = 0;
    final userVoteStr = commentData['user_vote']?.toString().toLowerCase();
    if (userVoteStr == 'upvote') {
      userVote = 1;
    } else if (userVoteStr == 'downvote') {
      userVote = -1;
    }

    // Get replies if present
    final repliesData = commentData['replies'] as List<dynamic>? ?? [];
    final replies = repliesData
        .map((reply) => _mapCommentFromResponse(reply))
        .whereType<CommentData>()
        .toList();

    // Extract profile picture URL
    String? profilePictureUrl =
        (commentData['profile_picture_url'] ??
                profile?['profile_picture_url'] ??
                commentData['avatar_url'] ??
                profile?['avatar_url'])
            ?.toString();

    // Get user_id to fetch profile if picture not in comment data
    final userId = commentData['user_id']?.toString();
    String? initials;

    // If no profile picture in comment data, try fetching from profile cache
    if ((profilePictureUrl == null || profilePictureUrl.isEmpty) &&
        userId != null &&
        _commentProfileCache.containsKey(userId)) {
      final cachedProfile = _commentProfileCache[userId]!;
      profilePictureUrl = cachedProfile.pictureUrl;
      initials = cachedProfile.initials;
    }

    // Get initials from username if not available from cached profile
    if (initials == null || initials.isEmpty) {
      String generateInitials(String name) {
        final cleanName = name.replaceAll('@', '').trim();
        if (cleanName.isEmpty) return 'U';
        final parts = cleanName.split(RegExp(r'[\s_]+'));
        if (parts.length >= 2) {
          return (parts.first[0] + parts.last[0]).toUpperCase();
        } else if (cleanName.length >= 2) {
          return cleanName.substring(0, 2).toUpperCase();
        } else {
          return cleanName[0].toUpperCase();
        }
      }

      final initial = generateInitials(username);
      initials = initial;
    }

    return CommentData(
      id: id,
      author: author,
      timeAgo: _formatTimeAgo(createdAt),
      body: content,
      upvotes: upvotes,
      downvotes: downvotes,
      profilePictureUrl: profilePictureUrl,
      initials: initials,
      replies: replies,
      status: status,
      userId: userId,
      userVote: userVote,
    );
  }

  int _parseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'just now';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${difference.inDays ~/ 7}w ago';
  }

  void _handleCommentError(
    Object error,
    StackTrace stackTrace, {
    String? customMessage,
  }) {
    final message = customMessage ?? 'Comment thread update failed: $error';

    _recentCommentErrors.insert(0, message);

    if (_recentCommentErrors.length > 5) {
      _recentCommentErrors.removeLast();
    }

    debugPrint(message);

    if (!mounted) return;

    // Check if it's a network error
    if (ErrorHandler.isNetworkError(error)) {
      ErrorHandler.showOfflineToast(context);
    } else {
      PalToast.show(
        context,
        message: customMessage ?? 'Something went wrong while posting your comment.',
        isError: true,
      );
    }
  }

  List<CommentData> _cloneComments(List<CommentData> source) {
    if (source.isEmpty) return <CommentData>[];

    return source
        .map(
          (comment) => comment.copyWith(
            id: comment.id,

            status: comment.status,

            replies: _cloneComments(comment.replies),
          ),
        )
        .toList();
  }

  int _totalCommentCount(List<CommentData> items) {
    int total = 0;

    for (final comment in items) {
      // Only count comments with status 'active'

      if (comment.status == 'active') {
        total += 1;

        // Recursively count active replies

        total += _totalCommentCount(comment.replies);
      }
    }

    return total;
  }

  Future<void> _addComment(String text) async {
    if (data.id == null) return;

    final trimmed = text.trim();

    // Validate length according to backend (1-500 chars)

    if (trimmed.isEmpty) return;

    if (trimmed.length > 500) {
      if (mounted) {
        PalToast.show(
          context,
          message: 'Comment must be 500 characters or less.',
          isError: true,
        );
      }

      return;
    }

    // Optimistically update UI

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final username = _currentUsername ?? '@user';

    // Use current user's profile picture and initials
    final initials = _currentUserInitials ?? 'U';

    final optimisticComment = CommentData(
      id: tempId,

      author: username,

      timeAgo: 'just now',

      body: trimmed,

      upvotes: 0,

      downvotes: 0,

      initials: initials,

      profilePictureUrl: _currentUserProfilePictureUrl,

      replies: const [],

      status: 'active',
    );

    final updated = [optimisticComment, ..._currentComments];

    setState(() {
      _comments = updated;
      // Update comment count optimistically
      _actualCommentCount = _totalCommentCount(updated);
    });

    if (_commentController.text.isNotEmpty) {
      _commentController.text = '';
    }

    FocusScope.of(context).unfocus();

    // Call backend

    try {
      final response = await _postService.createComment(
        postId: data.id!,

        content: trimmed,
      );

      // Check for success and handle response according to edge function format

      if (response['success'] == true &&
          response['comment'] != null &&
          mounted) {
        final commentData = response['comment'] as Map<String, dynamic>;

        final realId = commentData['id']?.toString() ?? tempId;

        // Extract username - check multiple possible fields

        final realUsername =
            (commentData['username'] ??
                    commentData['author'] ??
                    commentData['profiles']?['username'] ??
                    username)
                ?.toString() ??
            username;

        final createdAt = commentData['created_at'] != null
            ? DateTime.tryParse(commentData['created_at'].toString())
            : null;

        final upvotes = _parseInt(commentData['upvote_count'] ?? 0);

        final downvotes = _parseInt(commentData['downvote_count'] ?? 0);

        final status = commentData['status']?.toString() ?? 'active';

        final content = commentData['content']?.toString() ?? trimmed;

        // Extract user's vote state from API response
        int userVote = 0;
        final userVoteStr = commentData['user_vote']?.toString().toLowerCase();
        if (userVoteStr == 'upvote') {
          userVote = 1;
        } else if (userVoteStr == 'downvote') {
          userVote = -1;
        }

        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          final index = updatedComments.indexWhere((c) => c.id == tempId);

          if (index != -1) {
            updatedComments[index] = optimisticComment.copyWith(
              id: realId,

              author: realUsername.startsWith('@')
                  ? realUsername
                  : '@$realUsername',

              timeAgo: _formatTimeAgo(createdAt),

              upvotes: upvotes,

              downvotes: downvotes,

              body: content,

              status: status,

              userVote: userVote,
            );

            _comments = updatedComments;
            // Update comment count after adding a comment
            _actualCommentCount = _totalCommentCount(updatedComments);
            // Reload comments to ensure sync with backend and get updated count
            _loadComments();
          }
        });
      } else if (response['success'] == false && mounted) {
        // Handle content moderation or other blocking errors

        final errorMessage =
            response['message'] ??
            response['error'] ??
            'Your comment could not be posted.';

        // Remove optimistic comment

        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          updatedComments.removeWhere((c) => c.id == tempId);

          _comments = updatedComments;
        });

        _handleCommentError(
          Exception(errorMessage),
          StackTrace.current,
          customMessage: errorMessage,
        );
      } else if (mounted) {
        // Unexpected response format

        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          updatedComments.removeWhere((c) => c.id == tempId);

          _comments = updatedComments;
        });

        _handleCommentError(
          Exception('Unexpected response from server'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      // Remove optimistic comment on error

      if (mounted) {
        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          updatedComments.removeWhere((c) => c.id == tempId);

          _comments = updatedComments;
        });

        // Extract error message from exception

        final errorStr = error.toString().replaceFirst('Exception: ', '');

        String? customMessage;

        if (errorStr.contains('Comment blocked') ||
            errorStr.contains('inappropriate content')) {
          customMessage = errorStr;
        } else if (errorStr.contains('Post not found')) {
          customMessage = 'The post you are commenting on no longer exists.';
        } else if (errorStr.contains('content is required') ||
            errorStr.contains('must be between')) {
          customMessage =
              'Invalid comment. Please check the comment length (1-500 characters).';
        } else if (errorStr.contains('Unauthorized')) {
          customMessage = 'You must be logged in to post comments.';
        }

        _handleCommentError(error, stackTrace, customMessage: customMessage);
      }
    }
  }

  Future<void> _addReply(int parentIndex, String text) async {
    if (data.id == null) return;

    final trimmed = text.trim();

    // Validate length according to backend (1-500 chars)

    if (trimmed.isEmpty) return;

    if (trimmed.length > 500) {
      if (mounted) {
        PalToast.show(
          context,
          message: 'Reply must be 500 characters or less.',
          isError: true,
        );
      }

      return;
    }

    final current = List<CommentData>.from(_currentComments);

    if (parentIndex < 0 || parentIndex >= current.length) {
      return;
    }

    final parent = current[parentIndex];

    // Optimistically update UI

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final username = _currentUsername ?? '@user';

    // Use current user's profile picture and initials
    final initials = _currentUserInitials ?? 'U';

    final optimisticReply = CommentData(
      id: tempId,

      author: username,

      timeAgo: 'just now',

      body: trimmed,

      upvotes: 0,

      downvotes: 0,

      initials: initials,

      profilePictureUrl: _currentUserProfilePictureUrl,

      replies: const [],

      status: 'active',
    );

    final updatedReplies = List<CommentData>.from(parent.replies)
      ..add(optimisticReply);

    current[parentIndex] = parent.copyWith(replies: updatedReplies);

    setState(() {
      _comments = current;

      _activeReplyIndex = null;

      if (_replyController.text.isNotEmpty) {
        _replyController.text = '';
      }
    });

    FocusScope.of(context).unfocus();

    // Call backend

    try {
      final response = await _postService.createComment(
        postId: data.id!,

        content: trimmed,

        parentId: parent.id,
      );

      // Check for success and handle response according to edge function format

      if (response['success'] == true &&
          response['comment'] != null &&
          mounted) {
        final commentData = response['comment'] as Map<String, dynamic>;

        final realId = commentData['id']?.toString() ?? tempId;

        // Extract username - check multiple possible fields

        final realUsername =
            (commentData['username'] ??
                    commentData['author'] ??
                    commentData['profiles']?['username'] ??
                    username)
                ?.toString() ??
            username;

        final createdAt = commentData['created_at'] != null
            ? DateTime.tryParse(commentData['created_at'].toString())
            : null;

        final upvotes = _parseInt(commentData['upvote_count'] ?? 0);

        final downvotes = _parseInt(commentData['downvote_count'] ?? 0);

        final status = commentData['status']?.toString() ?? 'active';

        final content = commentData['content']?.toString() ?? trimmed;

        // Extract user's vote state from API response
        int userVote = 0;
        final userVoteStr = commentData['user_vote']?.toString().toLowerCase();
        if (userVoteStr == 'upvote') {
          userVote = 1;
        } else if (userVoteStr == 'downvote') {
          userVote = -1;
        }

        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          if (parentIndex < updatedComments.length) {
            final updatedParent = updatedComments[parentIndex];

            final updatedParentReplies = List<CommentData>.from(
              updatedParent.replies,
            );

            final replyIndex = updatedParentReplies.indexWhere(
              (r) => r.id == tempId,
            );

            if (replyIndex != -1) {
              updatedParentReplies[replyIndex] = optimisticReply.copyWith(
                id: realId,

                author: realUsername.startsWith('@')
                    ? realUsername
                    : '@$realUsername',

                timeAgo: _formatTimeAgo(createdAt),

                upvotes: upvotes,

                downvotes: downvotes,

                body: content,

                status: status,

                userVote: userVote,
              );

              updatedComments[parentIndex] = updatedParent.copyWith(
                replies: updatedParentReplies,
              );

              _comments = updatedComments;
              // Update comment count after adding a reply
              _actualCommentCount = _totalCommentCount(updatedComments);
            }
          }
        });
      } else if (response['success'] == false && mounted) {
        // Handle content moderation or other blocking errors

        final errorMessage =
            response['message'] ??
            response['error'] ??
            'Your reply could not be posted.';

        // Remove optimistic reply

        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          if (parentIndex < updatedComments.length) {
            final updatedParent = updatedComments[parentIndex];

            final updatedParentReplies = List<CommentData>.from(
              updatedParent.replies,
            );

            updatedParentReplies.removeWhere((r) => r.id == tempId);

            updatedComments[parentIndex] = updatedParent.copyWith(
              replies: updatedParentReplies,
            );

            _comments = updatedComments;
          }
        });

        _handleCommentError(
          Exception(errorMessage),
          StackTrace.current,
          customMessage: errorMessage,
        );
      } else if (mounted) {
        // Unexpected response format

        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          if (parentIndex < updatedComments.length) {
            final updatedParent = updatedComments[parentIndex];

            final updatedParentReplies = List<CommentData>.from(
              updatedParent.replies,
            );

            updatedParentReplies.removeWhere((r) => r.id == tempId);

            updatedComments[parentIndex] = updatedParent.copyWith(
              replies: updatedParentReplies,
            );

            _comments = updatedComments;
          }
        });

        _handleCommentError(
          Exception('Unexpected response from server'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      // Remove optimistic reply on error

      if (mounted) {
        setState(() {
          final updatedComments = List<CommentData>.from(_currentComments);

          if (parentIndex < updatedComments.length) {
            final updatedParent = updatedComments[parentIndex];

            final updatedParentReplies = List<CommentData>.from(
              updatedParent.replies,
            );

            updatedParentReplies.removeWhere((r) => r.id == tempId);

            updatedComments[parentIndex] = updatedParent.copyWith(
              replies: updatedParentReplies,
            );

            _comments = updatedComments;
          }
        });

        // Extract error message from exception

        final errorStr = error.toString().replaceFirst('Exception: ', '');

        String? customMessage;

        if (errorStr.contains('Comment blocked') ||
            errorStr.contains('inappropriate content')) {
          customMessage = errorStr;
        } else if (errorStr.contains('Post not found')) {
          customMessage = 'The post you are replying to no longer exists.';
        } else if (errorStr.contains('Comment not found') ||
            errorStr.contains('Parent comment not found')) {
          customMessage = 'The comment you are replying to no longer exists.';
        } else if (errorStr.contains('Cannot reply to a reply')) {
          customMessage =
              'You can only reply to top-level comments, not to replies.';
        } else if (errorStr.contains('content is required') ||
            errorStr.contains('must be between')) {
          customMessage =
              'Invalid reply. Please check the reply length (1-500 characters).';
        } else if (errorStr.contains('Unauthorized')) {
          customMessage = 'You must be logged in to post replies.';
        }

        _handleCommentError(error, stackTrace, customMessage: customMessage);
      }
    }
  }

  void _toggleInlineReply(int index) {
    try {
      setState(() {
        if (_activeReplyIndex == index) {
          _activeReplyIndex = null;

          if (_replyController.text.isNotEmpty) {
            _replyController.text = '';
          }
        } else {
          _activeReplyIndex = index;

          if (_replyController.text.isNotEmpty) {
            _replyController.text = '';
          }
        }
      });
    } catch (error, stackTrace) {
      _handleCommentError(error, stackTrace);
    }
  }

  void _toggleMenu(BuildContext parentContext) async {
    if (!mounted) return;

    // Check if user is admin
    final isAdmin = await _adminService.isAdmin();

    if (isAdmin) {
      // Show admin menu from bottom
      _showAdminMenu(parentContext);
      return;
    }

    // Regular user menu (existing logic)
    if (_overlayEntry != null) {
      _removeOverlay();

      return;
    }

    final menuContext = _menuKey.currentContext;

    if (menuContext == null || !menuContext.mounted) {
      return;
    }

    final renderBox = menuContext.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.attached) return;

    final size = renderBox.size;

    final offset = renderBox.localToGlobal(Offset.zero);

    final isOwnPost = _isOwnPost;
    final showReport = !isOwnPost;
    final showBlock = !isOwnPost;
    final showDelete = isOwnPost;

    _overlayEntry = OverlayEntry(
      builder: (context) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Close menu on any scroll event
          if (notification is ScrollStartNotification ||
              notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _removeOverlay();
          }
          return false;
        },
        child: Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: Stack(
              children: [
                Positioned(
                  bottom: MediaQuery.of(context).size.height - offset.dy + 8,
                  right:
                      MediaQuery.of(context).size.width -
                      (offset.dx + size.width) +
                      8,
                  child: GestureDetector(
                    onTap: () {
                      // Prevent tap from propagating to parent GestureDetector
                      // This keeps the menu open when clicking on the popover itself
                    },
                    child: _PostActionsPopover(
                      showReport: showReport,
                      showBlock: showBlock,
                      showDelete: showDelete,
                      onReport: showReport
                          ? () async {
                              _removeOverlay();

                              if (!mounted) return;

                              await _showReportPostSheet(parentContext);
                            }
                          : null,
                      onBlock: showBlock
                          ? () async {
                              _removeOverlay();
                              if (!mounted) return;
                              await _handleBlockUser(parentContext);
                            }
                          : null,
                      onDelete: showDelete
                          ? () async {
                              _removeOverlay();

                              if (!mounted) return;

                              await _showDeleteDialog(
                                parentContext,
                                data.title,
                              );
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(parentContext, rootOverlay: true).insert(_overlayEntry!);
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AdminPostMenu(
        postData: data,
        onEdit: () {
          Navigator.of(context).pop();
          // Navigate to create post screen with post data for editing
          showCreatePostModal(context, postData: data);
        },
        onViewProfile: () {
          Navigator.of(context).pop();
          // Navigate to admin user profile screen
          if (data.userId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AdminUserProfileScreen(
                  userId: data.userId!,
                  username: data.username,
                  profilePictureUrl: data.profilePictureUrl,
                  initials: data.initials,
                ),
              ),
            );
          }
        },
        onPin: () {
          Navigator.of(context).pop();
          // TODO: Implement pin post functionality
        },
        onWarn: () {
          Navigator.of(context).pop();
          // TODO: Implement warn conversation functionality
        },
        onMute: () {
          Navigator.of(context).pop();
          // TODO: Implement mute conversation functionality
        },
        onHide: () {
          Navigator.of(context).pop();
          // TODO: Implement hide conversation functionality
        },
        onFlag: () {
          Navigator.of(context).pop();
          _showReportPostSheet(context);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _showDeleteDialog(context, data.title);
        },
      ),
    );
  }

  Widget _buildPostCardContainer({
    required PostCardData data,
    required _PostCardPalette palette,
    required bool isAdminPinned,
    required bool allowOverflowMenu,
    required bool shouldShowMoreButton,
  }) {
    final content = Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: data.variant == PostCardVariant.wod ? null : Colors.white,
        gradient: data.variant == PostCardVariant.wod
            ? const LinearGradient(
                colors: [
                  Color(0xFFB4DDC5), // #B4DDC5
                  Color(0xFFFFFFFF), // #FFFFFF
                  Color(0xFFFFFFFF), // #FFFFFF
                ],
                stops: [0.0, 0.35, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (palette.showHeader)
            _HighlightHeader(
              palette: palette,
              variant: data.variant,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PostHeader(
                  data: data,
                  palette: palette,
                  votes: _currentVotes,
                  isUpvoted: _userVote == 1,
                  isDownvoted: _userVote == -1,
                  onUpvote: _handleUpvote,
                  onDownvote: _handleDownvote,
                  showMetaBadges: !isAdminPinned,
                  customBadge: isAdminPinned ? _AdminBadge() : null,
                  isUpvotedPostsScreen: widget.isUpvotedPostsScreen,
                ),
                const SizedBox(height: 24),
                _PostTitle(
                  title: data.title,
                  color: palette.titleColor,
                ),
                const SizedBox(height: 16),
                _PostBody(body: data.body),
                const SizedBox(height: 24),
                _PostFooter(
                  data: data.copyWith(comments: _currentComments),
                  palette: palette,
                  onMoreTap: shouldShowMoreButton
                      ? () => _toggleMenu(context)
                      : null,
                  moreButtonKey: shouldShowMoreButton ? _menuKey : null,
                  onToggleComments: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                    if (_showComments &&
                        (_comments.isEmpty || _actualCommentCount == null) &&
                        data.id != null) {
                      _loadComments();
                    }
                  },
                  commentsExpanded: _showComments,
                  showMoreButton: shouldShowMoreButton,
                  isYourPosts: widget.isYourPosts,
                  commentCount: _actualCommentCount ??
                      (_currentComments.isNotEmpty
                          ? _totalCommentCount(_currentComments)
                          : data.commentsCount),
                ),
                if (_showComments) ...[
                  const _PostCommentsDivider(),
                  _CommentsSection(
                    palette: palette,
                    data: data.copyWith(comments: _currentComments),
                    controller: _commentController,
                    onSubmitComment: _addComment,
                    onReplyToComment: _toggleInlineReply,
                    activeReplyIndex: _activeReplyIndex,
                    replyController: _replyController,
                    onSubmitReply: _addReply,
                    onReportComment: (comment) =>
                        _showReportCommentSheet(context, comment),
                    onDeleteComment: (comment) =>
                        _showDeleteCommentDialog(context, comment),
                    onBlockComment: (comment) =>
                        _handleBlockCommentUser(context, comment),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (data.variant == PostCardVariant.moderator) {
      return Container(
        padding: const EdgeInsets.all(1.51),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x80FF0F7B), // rgba(255, 15, 123, 0.5)
              Color(0x80F89B29), // rgba(248, 155, 41, 0.5)
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: content,
        ),
      );
    } else if (data.variant == PostCardVariant.admin) {
      return Container(
        padding: const EdgeInsets.all(1.51),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x804F39F6), // rgba(79, 57, 246, 0.5)
              Color(0x809810FA), // rgba(152, 16, 250, 0.5)
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: content,
        ),
      );
    } else if (data.variant == PostCardVariant.wod) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0x80100C08), // #100C0880 = rgba(16, 12, 8, 0.5)
            width: 1.51,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000), // #00000040 = rgba(0, 0, 0, 0.25)
              offset: Offset(0, 4),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: content,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: palette.outerBorderColor,
            width: 1.51027,
          ),
        ),
        child: content,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PostCardPalette.fromVariant(data.variant);

    final bool isAdminPinned = widget.isPinnedAdmin;
    final bool allowOverflowMenu = widget.showOverflowMenu;
    // Hide three dots menu for admin variant
    final bool shouldShowMoreButton = !isAdminPinned && 
                                      allowOverflowMenu && 
                                      data.variant != PostCardVariant.admin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),

      child: Align(
        alignment: Alignment.center,

        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive width with small margins
            // Use constraints.maxWidth which accounts for parent padding
            final availableWidth = constraints.maxWidth;
            final maxWidth =
                600.0; // Max width to prevent posts from being too wide
            // Use available width but clamp between min (360) and max (600)
            // The parent already has 16px padding on each side, so we use the available width
            final cardWidth = availableWidth.clamp(360.0, maxWidth);

            return SizedBox(
              width: cardWidth,

              child: _buildPostCardContainer(
                data: data,
                palette: palette,
                isAdminPinned: isAdminPinned,
                allowOverflowMenu: allowOverflowMenu,
                shouldShowMoreButton: shouldShowMoreButton,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleUpvote() async {
    if (data.id == null) return;

    final previousVote = _userVote;

    final previousVotes = _currentVotes;

    setState(() {
      if (_userVote == 1) {
        // Already upvoted, unvote (remove the upvote)

        _currentVotes = (_currentVotes - 1).clamp(0, double.infinity).toInt();

        _userVote = 0;
      } else {
        if (_userVote == -1) {
          // Currently downvoted, switch to upvote (remove downvote, add upvote = +2)

          _currentVotes += 2;
        } else {
          // Neutral, add upvote

          _currentVotes += 1;
        }

        _userVote = 1;
      }
    });

    try {
      final voteType = previousVote == 1 ? 'remove' : 'upvote';

      final response = await _postService.votePost(
        postId: data.id!,
        voteType: voteType,
      );

      // Sync with backend response to ensure consistency

      if (response['net_score'] != null && mounted) {
        final netScore = _parseInt(response['net_score']);

        final userVoteStr = response['user_vote']?.toString().toLowerCase();

        setState(() {
          _currentVotes = netScore.clamp(0, double.infinity).toInt();

          // Map backend user_vote string to our integer state

          if (userVoteStr == 'upvote') {
            _userVote = 1;
          } else if (userVoteStr == 'downvote') {
            _userVote = -1;
          } else {
            _userVote = 0;
          }
        });
      }
    } catch (e) {
      // Revert on error

      if (mounted) {
        setState(() {
          _currentVotes = previousVotes;

          _userVote = previousVote;
        });

        // Check if it's a network error
        if (ErrorHandler.isNetworkError(e)) {
          ErrorHandler.showOfflineToast(context);
        } else {
          PalToast.show(
            context,
            message: 'Failed to vote: ${e.toString().replaceFirst('Exception: ', '')}',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleDownvote() async {
    if (data.id == null) return;

    final previousVote = _userVote;

    final previousVotes = _currentVotes;

    setState(() {
      if (_userVote == -1) {
        // Already downvoted, unvote (remove the downvote)

        _currentVotes += 1;

        _userVote = 0;
      } else {
        if (_userVote == 1) {
          // Currently upvoted, switch to downvote (remove upvote, add downvote = -2)

          _currentVotes = (_currentVotes - 2).clamp(0, double.infinity).toInt();
        } else {
          // Neutral, add downvote (but don't go negative)

          _currentVotes = (_currentVotes - 1).clamp(0, double.infinity).toInt();
        }

        _userVote = -1;
      }
    });

    try {
      final voteType = previousVote == -1 ? 'remove' : 'downvote';

      final response = await _postService.votePost(
        postId: data.id!,
        voteType: voteType,
      );

      // Sync with backend response to ensure consistency

      if (response['net_score'] != null && mounted) {
        final netScore = _parseInt(response['net_score']);

        final userVoteStr = response['user_vote']?.toString().toLowerCase();

        setState(() {
          _currentVotes = netScore.clamp(0, double.infinity).toInt();

          // Map backend user_vote string to our integer state

          if (userVoteStr == 'upvote') {
            _userVote = 1;
          } else if (userVoteStr == 'downvote') {
            _userVote = -1;
          } else {
            _userVote = 0;
          }
        });
      }
    } catch (e) {
      // Revert on error

      if (mounted) {
        setState(() {
          _currentVotes = previousVotes;

          _userVote = previousVote;
        });

        // Check if it's a network error
        if (ErrorHandler.isNetworkError(e)) {
          ErrorHandler.showOfflineToast(context);
        } else {
          PalToast.show(
            context,
            message: 'Failed to vote: ${e.toString().replaceFirst('Exception: ', '')}',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _showDeleteCommentDialog(
    BuildContext context,

    CommentData comment,
  ) async {
    final preview = comment.body.length > 60
        ? '${comment.body.substring(0, 57)}...'
        : comment.body;

    final result = await showDialog<DeleteCommentResult>(
      context: context,

      barrierDismissible: false,

      builder: (_) => DeleteCommentDialog(commentPreview: preview),
    );

    if (result?.confirmed == true && context.mounted) {
      try {
        await _postService.deleteComment(commentId: comment.id);

        // Remove comment from local state

        setState(() {
          final updated = List<CommentData>.from(_currentComments);

          // Find and remove comment (including from replies)

          _removeCommentRecursive(updated, comment.id);

          _comments = updated;

          // Update comment count after deletion
          _actualCommentCount = _totalCommentCount(updated);
        });

        // Reload comments from API to ensure count is accurate
        if (data.id != null) {
          _loadComments();
        }

        if (context.mounted) {
          PalToast.show(
            context,
            message: 'Comment deleted successfully.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          final errorStr = e.toString().replaceFirst('Exception: ', '');

          final errorStrLower = errorStr.toLowerCase();

          String errorMessage;

          // Check for permission/ownership errors

          if (errorStrLower.contains('cannot delete another user\'s comment') ||
              errorStrLower.contains('cannot delete') ||
              errorStrLower.contains('not owner') ||
              errorStrLower.contains('only owner') ||
              errorStrLower.contains('permission denied') ||
              errorStrLower.contains('forbidden')) {
            errorMessage = 'You can only delete your own comments.';
          } else if (errorStrLower.contains('comment not found')) {
            errorMessage = 'This comment no longer exists.';
          } else if (errorStrLower.contains('unauthorized')) {
            errorMessage = 'You must be logged in to delete comments.';
          } else {
            // Use the original error message if it's user-friendly, otherwise show generic message

            errorMessage = errorStr.isNotEmpty
                ? errorStr
                : 'Failed to delete comment. Please try again.';
          }

          // Check if it's a network error
          if (ErrorHandler.isNetworkError(e)) {
            ErrorHandler.showOfflineToast(context);
          } else {
            PalToast.show(
              context,
              message: errorMessage,
              isError: true,
            );
          }
        }
      }
    }
  }

  void _removeCommentRecursive(List<CommentData> comments, String commentId) {
    comments.removeWhere((comment) => comment.id == commentId);

    for (final comment in comments) {
      if (comment.replies.isNotEmpty) {
        final replies = List<CommentData>.from(comment.replies);

        _removeCommentRecursive(replies, commentId);

        // Update the comment's replies

        final index = comments.indexOf(comment);

        if (index != -1) {
          comments[index] = comment.copyWith(replies: replies);
        }
      }
    }
  }

  Future<void> _showReportPostSheet(BuildContext context) async {
    if (data.id == null) return;

    final result = await showModalBottomSheet<ReportResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReportPostSheet(subject: ReportSubject.post),
    );

    if (result != null && context.mounted) {
      try {
        final backendReason = _mapReportReasonToBackendEnum(result.reason);
        await _postService.reportPost(
          postId: data.id!,
          reason: backendReason,
          description: result.details.isNotEmpty ? result.details : null,
        );

        if (context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const ReportSuccessDialog(),
          );
          // Show success toast after dialog is closed
          if (context.mounted) {
            PalToast.show(
              context,
              message: 'Report submitted successfully',
              heading: 'Report submitted successfully',
              subtext: 'Our moderation team will review your report within 24 hours',
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          final errorStr = e.toString().replaceFirst('Exception: ', '');
          final errorStrLower = errorStr.toLowerCase();

          String errorHeading;
          String errorSubtext;

          // Check for "cannot report own post" error (case-insensitive)
          if (errorStrLower.contains('cannot report own post') ||
              errorStrLower.contains('cannot report your own post') ||
              errorStrLower.contains('you cannot report your own post')) {
            errorHeading = 'Failed to submit report';
            errorSubtext = 'You cannot report your own post.';
          } else if (errorStrLower.contains('already reported')) {
            errorHeading = 'Failed to submit report';
            errorSubtext = 'You have already reported this post.';
          } else if (errorStrLower.contains('post not found')) {
            errorHeading = 'Failed to submit report';
            errorSubtext = 'This post no longer exists.';
          } else if (errorStrLower.contains('unauthorized')) {
            errorHeading = 'Failed to submit report';
            errorSubtext = 'You must be logged in to report posts.';
        } else {
          // Use generic error message for general failures
          errorHeading = 'Failed to submit report';
          errorSubtext = 'Please try again.';
        }

        // Check if it's a network error
        if (ErrorHandler.isNetworkError(e)) {
          ErrorHandler.showOfflineToast(context);
        } else {
          PalToast.show(
            context,
            message: errorHeading,
            heading: errorHeading,
            subtext: errorSubtext,
            isError: true,
          );
        }
        }
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String title) async {
    if (data.id == null) return;

    final result = await showDialog<DeletePostResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeletePostDialog(postTitle: title),
    );

    if (result?.confirmed != true) return;

    // Simple: call edge function and show message based on response
    try {
      final response = await _postService.deletePost(postId: data.id!);

      // Check response from edge function
      if (response['success'] == true) {
        // Notify parent widget about deletion
        if (mounted && widget.onPostDeleted != null) {
          widget.onPostDeleted!(data.id!);
        }
        // Show success message
        if (mounted) {
          PalToast.show(context, message: 'Post deleted successfully');
        }
      } else {
        // Show error from response
        final message =
            response['message']?.toString() ?? 'Failed to delete post.';
        if (mounted) {
          PalToast.show(
            context,
            message: 'Failed to delete post',
            heading: 'Failed to delete post',
            subtext: 'Please check your connection and try again',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network error
        if (ErrorHandler.isNetworkError(e)) {
          ErrorHandler.showOfflineToast(context);
        } else {
          // Handle exception
          final errorStr = e.toString().replaceFirst('Exception: ', '');
          final errorStrLower = errorStr.toLowerCase();

          String errorHeading = 'Failed to delete post';
          String errorSubtext;

          if (errorStrLower.contains('cannot delete another user\'s post') ||
              errorStrLower.contains('you cannot delete another user\'s post')) {
            errorSubtext = 'You cannot delete another user\'s post.';
          } else if (errorStrLower.contains('cannot delete') ||
              errorStrLower.contains('not owner') ||
              errorStrLower.contains('only owner') ||
              errorStrLower.contains('permission denied') ||
              errorStrLower.contains('forbidden') ||
              errorStrLower.contains('not authorized')) {
            errorSubtext = 'You can only delete your own posts.';
          } else if (errorStrLower.contains('post not found')) {
            errorSubtext = 'This post no longer exists.';
          } else if (errorStrLower.contains('unauthorized')) {
            errorSubtext = 'You must be logged in to delete posts.';
          } else {
            // For general failures
            errorSubtext = 'Please try again.';
          }

          PalToast.show(
            context,
            message: errorHeading,
            heading: errorHeading,
            subtext: errorSubtext,
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleBlockUser(BuildContext context, {String? userId}) async {
    final username = data.username.isNotEmpty ? data.username : '@pal_user';

    // Get user ID - prefer passed userId, then from data, otherwise try to get from profile
    String? blockedUserId = userId ?? data.userId;

    if (blockedUserId == null || blockedUserId.isEmpty) {
      // If we don't have userId, we can't block - show error
      if (mounted) {
        PalToast.show(
          context,
          message: 'Unable to block user: user ID not available',
          isError: true,
        );
      }
      return;
    }

    final result = await showDialog<BlockUserResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlockUserDialog(username: username),
    );

    if (result?.confirmed == true && mounted) {
      try {
        await _postService.blockUser(blockedUserId: blockedUserId);
        if (mounted) {
          PalToast.show(
            context,
            message:
                'You\'ve blocked $username. You won\'t see each other\'s posts, except for official platform-pinned posts, which remain visible to all users.',
          );
        }
      } catch (e) {
        if (mounted) {
          // Check if it's a network error
          if (ErrorHandler.isNetworkError(e)) {
            ErrorHandler.showOfflineToast(context);
          } else {
            final errorMessage = e.toString().replaceFirst('Exception: ', '');
            PalToast.show(
              context,
              message: 'Failed to block user: $errorMessage',
              isError: true,
            );
          }
        }
      }
    }
  }

  Future<void> _handleBlockCommentUser(
    BuildContext context,
    CommentData comment,
  ) async {
    final username = comment.author.isNotEmpty ? comment.author : '@pal_user';

    // Get user ID from comment
    final blockedUserId = comment.userId;

    if (blockedUserId == null || blockedUserId.isEmpty) {
      // If we don't have userId, we can't block - show error
      if (mounted) {
        PalToast.show(
          context,
          message: 'Unable to block user: user ID not available',
          isError: true,
        );
      }
      return;
    }

    final result = await showDialog<BlockUserResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlockUserDialog(username: username),
    );

    if (result?.confirmed == true && mounted) {
      try {
        await _postService.blockUser(blockedUserId: blockedUserId);
        if (mounted) {
          PalToast.show(
            context,
            message:
                'You\'ve blocked $username. You won\'t see each other\'s posts, except for official platform-pinned posts, which remain visible to all users.',
          );
        }
      } catch (e) {
        if (mounted) {
          // Check if it's a network error
          if (ErrorHandler.isNetworkError(e)) {
            ErrorHandler.showOfflineToast(context);
          } else {
            final errorMessage = e.toString().replaceFirst('Exception: ', '');
            PalToast.show(
              context,
              message: 'Failed to block user: $errorMessage',
              isError: true,
            );
          }
        }
      }
    }
  }

  Future<void> _showReportCommentSheet(
    BuildContext context,

    CommentData comment,
  ) async {
    final result = await showModalBottomSheet<ReportResult?>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) => const ReportPostSheet(subject: ReportSubject.comment),
    );

    if (result != null && context.mounted) {
      try {
        final backendReason = _mapReportReasonToBackendEnum(result.reason);

        await _postService.reportComment(
          commentId: comment.id,

          reason: backendReason,

          description: result.details.isNotEmpty ? result.details : null,
        );

        if (context.mounted) {
          await showDialog<void>(
            context: context,

            barrierDismissible: false,

            builder: (_) => const ReportSuccessDialog(),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final errorStr = e.toString().replaceFirst('Exception: ', '');

          final errorStrLower = errorStr.toLowerCase();

          String errorMessage;

          // Check for "cannot report own comment" error (case-insensitive)

          if (errorStrLower.contains('cannot report own comment') ||
              errorStrLower.contains('cannot report your own comment') ||
              errorStrLower.contains('you cannot report your own comment')) {
            errorMessage = 'You cannot report your own comment.';
          } else if (errorStrLower.contains('already reported')) {
            errorMessage = 'You have already reported this comment.';
          } else if (errorStrLower.contains('comment not found')) {
            errorMessage = 'This comment no longer exists.';
          } else if (errorStrLower.contains('unauthorized')) {
            errorMessage = 'You must be logged in to report comments.';
          } else {
            // Use the original error message if it's user-friendly, otherwise show generic message

            errorMessage = errorStr.isNotEmpty
                ? errorStr
                : 'Failed to submit report. Please try again.';
          }

          // Check if it's a network error
          if (ErrorHandler.isNetworkError(e)) {
            ErrorHandler.showOfflineToast(context);
          } else {
            PalToast.show(
              context,
              message: errorMessage,
              isError: true,
            );
          }
        }
      }
    }
  }
}

class _HighlightHeader extends StatelessWidget {
  const _HighlightHeader({required this.palette, this.variant});

  final _PostCardPalette palette;
  final PostCardVariant? variant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,

      width: double.infinity,

        child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),

            topRight: Radius.circular(24),
          ),

          // For WOD variant, make background transparent so parent gradient shows through
          color: variant == PostCardVariant.wod ? Colors.transparent : null,
          gradient: variant == PostCardVariant.wod
              ? null  // No gradient for WOD - use parent's gradient
              : LinearGradient(
                  colors: palette.headerGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          border: variant == PostCardVariant.wod
              ? const Border(
                  bottom: BorderSide(color: Color(0x4D010B13), width: 1),
                )
              : null,
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Align(
            alignment: Alignment.centerLeft,

            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.headerPillColor,

                borderRadius: BorderRadius.circular(8),

                boxShadow: palette.headerPillShadows,
              ),

              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 3.1, 8.5, 2.9),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    SvgPicture.asset(
                      palette.headerIconAsset,

                      width: 13,

                      height: 13,

                      colorFilter: const ColorFilter.mode(
                        Colors.white,

                        BlendMode.srcIn,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      palette.headerLabel,

                      style: const TextStyle(
                        fontSize: 11.5,

                        fontWeight: FontWeight.w600,

                        color: Colors.white,

                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.data,

    required this.palette,

    required this.votes,

    required this.isUpvoted,

    required this.isDownvoted,

    required this.onUpvote,

    required this.onDownvote,

    this.showMetaBadges = true,

    this.customBadge,

    this.isUpvotedPostsScreen = false,
  });

  final PostCardData data;

  final _PostCardPalette palette;

  final int votes;

  final bool isUpvoted;

  final bool isDownvoted;

  final VoidCallback onUpvote;

  final VoidCallback onDownvote;

  final bool showMetaBadges;

  final Widget? customBadge;

  final bool isUpvotedPostsScreen;

  @override
  Widget build(BuildContext context) {
    final bool hasBadges = showMetaBadges || customBadge != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        data.variant == PostCardVariant.wod
            ? Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0EA54D), width: 3), // #0EA54D
                ),
                child: _Avatar(
                  asset: data.avatarAsset,
                  profilePictureUrl: data.profilePictureUrl,
                  initials: data.initials,
                  borderColor: palette.avatarBorderColor,
                  variant: data.variant,
                ),
              )
            : data.variant == PostCardVariant.moderator
                ? Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF0F7B), Color(0xFFF89B29)],
                      ),
                    ),
                    child: _Avatar(
                      asset: data.avatarAsset,
                      profilePictureUrl: data.profilePictureUrl,
                      initials: data.initials,
                      borderColor: palette.avatarBorderColor,
                      variant: data.variant,
                    ),
                  )
                : data.variant == PostCardVariant.admin
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF4F39F6), Color(0xFF9810FA)],
                          ),
                        ),
                        child: _Avatar(
                          asset: data.avatarAsset,
                          profilePictureUrl: data.profilePictureUrl,
                          initials: data.initials,
                          borderColor: palette.avatarBorderColor,
                          variant: data.variant,
                        ),
                      )
                    : _Avatar(
                    asset: data.avatarAsset,
                    profilePictureUrl: data.profilePictureUrl,
                    initials: data.initials,
                    borderColor: palette.avatarBorderColor,
                    variant: data.variant,
                  ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      data.variant == PostCardVariant.moderator
                          ? '@moderator'
                          : data.variant == PostCardVariant.admin
                              ? '@admin'
                              : data.variant == PostCardVariant.wod
                                  ? '@moderator'
                                  : data.username.startsWith('@') ? data.username : '@${data.username}',

                      style: const TextStyle(
                        fontSize: 14,

                        fontWeight: FontWeight.w600,

                        color: Color(0xFF0F172A),

                        fontFamily: 'Inter',
                        letterSpacing: -0.15,
                      ),

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    '•',

                    style: TextStyle(
                      fontSize: 14,

                      color: Color(0xFF94A3B8),

                      fontFamily: 'Inter',
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    data.timeAgo,

                    style: const TextStyle(
                      fontSize: 12,

                      color: Color(0xFF64748B),

                      fontFamily: 'Inter',
                    ),

                    maxLines: 1,
                  ),
                ],
              ),

              if (data.variant == PostCardVariant.moderator) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: 102,
                  height: 29,
                  child: SvgPicture.asset(
                    'assets/moderator-icons/settings-icons/Moderator-badge.svg',
                    width: 102,
                    height: 29,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Return empty container if asset fails to load
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ] else if (data.variant == PostCardVariant.admin) ...[
                const SizedBox(height: 12),
                const _AdminBadge(),
              ] else if (data.variant == PostCardVariant.wod) ...[
                const SizedBox(height: 12),
                const _AdminBadge(),
              ] else if (hasBadges) ...[
                const SizedBox(height: 12),

                if (showMetaBadges)
                  Row(
                    children: [
                      Flexible(
                        child: _Badge(
                          icon: 'assets/images/locationIcon.svg',

                          label: data.location,

                          background: palette.locationBackground,

                          foreground: palette.locationForeground,

                          borderColor: palette.locationBorder,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: _Badge(
                          icon: 'assets/images/askIcon.svg',

                          label: data.category,

                          background: const Color(0xFFEFFDF4),

                          foreground: const Color(0xFF15803D),

                          borderColor: const Color(0xFFBDE9CE),
                        ),
                      ),
                    ],
                  )
                else if (customBadge != null)
                  Align(
                    alignment: Alignment.centerLeft,

                    child: SizedBox(width: 70.43, child: customBadge!),
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 12),

        _VotePanel(
          data: data,

          palette: palette,

          votes: votes,

          isUpvoted: isUpvoted,

          isDownvoted: isDownvoted,

          onUpvote: onUpvote,

          onDownvote: onDownvote,

          isUpvotedPostsScreen: isUpvotedPostsScreen,
        ),
      ],
    );
  }
}

class _PostTitle extends StatelessWidget {
  const _PostTitle({required this.title, required this.color});

  final String title;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,

      style: TextStyle(
        fontSize: 18,

        fontWeight: FontWeight.w700,

        height: 1.25,

        color: color,

        fontFamily: 'Inter',
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Text(
      body,

      style: const TextStyle(
        fontSize: 14,

        height: 1.65,

        color: Color(0xFF45556C),

        fontFamily: 'Inter',
      ),
    );
  }
}

class _PostFooter extends StatelessWidget {
  const _PostFooter({
    required this.data,

    required this.palette,

    required this.onToggleComments,

    this.commentsExpanded = false,

    this.onMoreTap,

    this.moreButtonKey,

    this.showMoreButton = true,

    this.commentCount,

    this.isYourPosts = false,
  });

  final PostCardData data;

  final _PostCardPalette palette;

  final VoidCallback onToggleComments;

  final bool commentsExpanded;

  final VoidCallback? onMoreTap;

  final GlobalKey? moreButtonKey;

  final bool showMoreButton;

  final int? commentCount;

  final bool isYourPosts;

  @override
  Widget build(BuildContext context) {
    final comments = data.comments ?? const [];

    final computedCount =
        commentCount ??
        (comments.isNotEmpty ? comments.length : data.commentsCount);

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),

          onTap: onToggleComments,

          child: Container(
            height: 36,

            padding: const EdgeInsets.symmetric(horizontal: 12),

            decoration: BoxDecoration(
              color: Colors.transparent,

              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,

                  size: 16,

                  color: palette.commentAccentColor,
                ),

                const SizedBox(width: 8),

                Text(
                  '$computedCount comments',

                  style: TextStyle(
                    fontSize: 14,

                    fontWeight: FontWeight.w600,

                    color: palette.commentAccentColor,

                    fontFamily: 'Inter',
                  ),
                ),

                const SizedBox(width: 6),

                Icon(
                  commentsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,

                  size: 18,

                  color: palette.commentAccentColor,
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        if (showMoreButton)
          InkWell(
            key: moreButtonKey,

            borderRadius: BorderRadius.circular(20),

            onTap: onMoreTap,

            child: Padding(
              padding: const EdgeInsets.all(4),

              child: isYourPosts
                  ? SvgPicture.asset(
                      _menuDeleteIconUrl,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF0A0A0A),
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(Icons.more_horiz, size: 18, color: palette.metaColor),
            ),
          ),
      ],
    );
  }
}

Future<void> _showReportPostSheet(BuildContext context) async {
  final result = await showModalBottomSheet<ReportResult?>(
    context: context,

    isScrollControlled: true,

    backgroundColor: Colors.transparent,

    builder: (_) => const ReportPostSheet(),
  );

  if (result != null && context.mounted) {
    await showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (_) => const ReportSuccessDialog(),
    );
  }
}

Future<void> _showDeleteDialog(BuildContext context, String title) async {
  final result = await showDialog<DeletePostResult>(
    context: context,

    barrierDismissible: false,

    builder: (_) => DeletePostDialog(postTitle: title),
  );

  if (result?.confirmed == true && context.mounted) {
    // TODO: Hook into actual delete logic when available.

    PalToast.show(
      context,
      message: 'Post deleted (placeholder).',
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    this.asset,
    this.profilePictureUrl,
    this.initials,
    required this.borderColor,
    this.variant,
  });

  final String? asset;
  final String? profilePictureUrl;
  final String? initials;
  final Color borderColor;
  final PostCardVariant? variant;

  @override
  Widget build(BuildContext context) {
    // Determine if this is a special role (admin/moderator/wod) or regular user
    final isSpecialRole = variant == PostCardVariant.moderator ||
        variant == PostCardVariant.admin ||
        variant == PostCardVariant.wod;
    
    // Check if this is a hardcoded post (has asset)
    // PNG files like 'assets/feedPage/profile.png' are valid hardcoded assets for seed posts
    final isDefaultProfileAsset = asset != null && (
      asset!.contains('profile.svg') ||
      asset == 'assets/feedPage/profile.svg' ||
      asset == 'assets/images/profile.svg'
    );
    final hasAsset = asset != null && !isDefaultProfileAsset;
    
    // For regular users (not special roles and not hardcoded posts):
    // - Show profile picture if available
    // - If profile picture fails to load or doesn't exist, show initials
    // For hardcoded posts: use asset
    // For special roles: use their specific initials if no profile picture
    
    final hasNetworkImage =
        profilePictureUrl != null && profilePictureUrl!.isNotEmpty;
    
    // For moderator variant, always use 'MO' as initials if no profile picture or asset
    // For admin variant, always use 'AD' as initials if no profile picture or asset
    // For WOD variant, always use 'MO' as initials if no profile picture or asset
    // For regular users, use provided initials or 'U' as fallback
    final displayInitials = variant == PostCardVariant.moderator
        ? 'MO'
        : variant == PostCardVariant.admin
            ? 'AD'
            : variant == PostCardVariant.wod
                ? 'MO'
                : (initials ?? 'U');

    final backgroundColor = (variant == PostCardVariant.wod ||
            variant == PostCardVariant.moderator ||
            variant == PostCardVariant.admin ||
            variant == PostCardVariant.newPost ||
            variant == PostCardVariant.top ||
            variant == PostCardVariant.topPost2 ||
            variant == PostCardVariant.hot ||
            variant == PostCardVariant.hotPost2)
        ? const Color(0xFFF1F5F9)
        : Colors.white;

    final borderWidth = (variant == PostCardVariant.wod ||
            variant == PostCardVariant.moderator ||
            variant == PostCardVariant.admin)
        ? 0.0
        : 3.0;

    // For newPost variant, apply exact positioning (top: 0.39px, left: 0.25px)
    final isNewPost = variant == PostCardVariant.newPost;
    
    // Inner content size (excluding border)
    final innerSize = borderWidth > 0 ? 47.0 - (borderWidth * 2) : 47.0;
    
    // Build the inner content (image or initials) with clipping
    Widget innerContent = Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAsset
          // Hardcoded posts: use asset (for seed posts with avatarAsset set)
          ? _Avatar._buildImage(asset!, displayInitials, _buildInitialsPlaceholder)
          : hasNetworkImage
          // Regular users and special roles: try to load profile picture, fallback to initials on error
          ? Image.network(
              profilePictureUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                // Show initials while loading
                if (loadingProgress == null) return child;
                return _buildInitialsPlaceholder(displayInitials);
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback to initials if profile picture fails to load
                // This ensures regular users always see initials when image fails
                return _buildInitialsPlaceholder(displayInitials);
              },
            )
          // No profile picture and no asset: show initials
          // This ensures regular users without profile pictures always see initials
          : _buildInitialsPlaceholder(displayInitials),
    );
    
    // Wrap with border container (border is separate from clipped content)
    Widget avatarContent = borderWidth > 0
        ? Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Center(child: innerContent),
          )
        : Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
            ),
            clipBehavior: Clip.antiAlias,
            child: innerContent,
          );
    
    // For newPost variant, apply exact positioning (top: 0.39px, left: 0.25px)
    if (isNewPost) {
      return Transform.translate(
        offset: const Offset(0.25, 0.39),
        child: avatarContent,
      );
    }
    
    return avatarContent;
  }

  Widget _buildInitialsPlaceholder(String initials) {
    final backgroundColor = (variant == PostCardVariant.wod ||
            variant == PostCardVariant.moderator ||
            variant == PostCardVariant.admin ||
            variant == PostCardVariant.newPost ||
            variant == PostCardVariant.top ||
            variant == PostCardVariant.topPost2 ||
            variant == PostCardVariant.hot ||
            variant == PostCardVariant.hotPost2)
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF155DFC);
    final textColor = (variant == PostCardVariant.wod ||
            variant == PostCardVariant.moderator ||
            variant == PostCardVariant.admin ||
            variant == PostCardVariant.newPost ||
            variant == PostCardVariant.top ||
            variant == PostCardVariant.topPost2 ||
            variant == PostCardVariant.hot ||
            variant == PostCardVariant.hotPost2)
        ? const Color(0xFF314158)
        : Colors.white;

    return Container(
      color: backgroundColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  static Widget _buildImage(String path, String initials, Widget Function(String) buildInitialsPlaceholder) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.cover,
        placeholderBuilder: (_) =>
            Image.asset('assets/feedPage/profile.png', fit: BoxFit.cover),
        errorBuilder: (_, __, ___) => buildInitialsPlaceholder(initials),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => buildInitialsPlaceholder(initials),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,

    required this.label,

    required this.background,

    required this.foreground,

    required this.borderColor,
  });

  final String icon;

  final String label;

  final Color background;

  final Color foreground;

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,

      padding: const EdgeInsets.symmetric(horizontal: 8),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(6),

        border: Border.all(color: borderColor, width: 1),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,

            width: 12,

            height: 12,

            colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          ),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              label,

              style: TextStyle(
                fontSize: 10,

                fontWeight: FontWeight.w600,

                color: foreground,

                fontFamily: 'Inter',
              ),

              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        final bool hasFiniteWidth = availableWidth.isFinite;

        final double badgeWidth = hasFiniteWidth
            ? math.min(availableWidth, 70.43)
            : 70.43;

        return Container(
          width: badgeWidth,

          height: 19.98,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(80),

            gradient: const LinearGradient(
              colors: [Color(0xFF4F39F6), Color(0xFF9810FA)],

              begin: Alignment.centerLeft,

              end: Alignment.centerRight,
            ),

            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),

                blurRadius: 8,

                offset: Offset(0, 4),
              ),
            ],
          ),

          padding: EdgeInsets.zero,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            mainAxisSize: MainAxisSize.min,

            children: [
              SvgPicture.asset(
                'assets/feedPage/adminIcon.svg',

                width: 12,

                height: 12,

                placeholderBuilder: (_) =>
                    const SizedBox(width: 12, height: 12),

                colorFilter: const ColorFilter.mode(
                  Colors.white,

                  BlendMode.srcIn,
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                'Admin',

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: FontWeight.w600,

                  color: Colors.white,

                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VotePanel extends StatelessWidget {
  const _VotePanel({
    required this.data,

    required this.palette,

    required this.votes,

    required this.isUpvoted,

    required this.isDownvoted,

    required this.onUpvote,

    required this.onDownvote,

    this.isUpvotedPostsScreen = false,
  });

  final PostCardData data;

  final _PostCardPalette palette;

  final int votes;

  final bool isUpvoted;

  final bool isDownvoted;

  final VoidCallback onUpvote;

  final VoidCallback onDownvote;

  final bool isUpvotedPostsScreen;

  @override
  Widget build(BuildContext context) {
    // Background color when arrow is clicked/highlighted - variant-specific
    Color voteBackgroundColor;
    switch (data.variant) {
      case PostCardVariant.hot:
      case PostCardVariant.hotPost2:
        voteBackgroundColor = const Color(0xFFF54900); // #F54900 for hot posts
        break;
      case PostCardVariant.top:
      case PostCardVariant.topPost2:
        voteBackgroundColor =
            palette.voteButtonBackground; // Blue for top posts
        break;
      case PostCardVariant.newPost:
        voteBackgroundColor = const Color(0xFF0F172B); // Dark for new posts
        break;
      case PostCardVariant.wod:
        voteBackgroundColor = const Color(0xFF008236); // #008236 for wod posts
        break;
      case PostCardVariant.moderator:
        voteBackgroundColor = const Color(0xFF0F172B); // Dark for moderator posts
        break;
      case PostCardVariant.admin:
        voteBackgroundColor = const Color(0xFF0F172B); // Dark for admin posts
        break;
    }

    // For upvoted posts screen, always show highlighted upvote with #314158
    final Color upBackground = isUpvotedPostsScreen
        ? const Color(0xFF314158) // Highlighted upvote for upvoted posts screen
        : (isUpvoted ? voteBackgroundColor : Colors.transparent);
    final Color downBackground = isDownvoted
        ? voteBackgroundColor
        : Colors.transparent;

    // Vote icon colors based on variant - #CA3500 only for hot posts
    Color defaultIconColor;
    switch (data.variant) {
      case PostCardVariant.top:
      case PostCardVariant.topPost2:
        defaultIconColor = const Color(0xFF1447E6); // rgba(20, 71, 230, 1)
        break;
      case PostCardVariant.hot:
      case PostCardVariant.hotPost2:
        defaultIconColor = const Color(0xFFCA3500); // #CA3500 for hot posts
        break;
      case PostCardVariant.newPost:
        defaultIconColor = const Color(
          0xFF0F172B,
        ); // Default color for new posts
        break;
      case PostCardVariant.wod:
        defaultIconColor = const Color(0xFF008236); // #008236 for wod posts
        break;
      case PostCardVariant.moderator:
        defaultIconColor = const Color(0xFF0F172B); // Default color for moderator posts
        break;
      case PostCardVariant.admin:
        defaultIconColor = const Color(0xFF0F172B); // Default color for admin posts
        break;
    }

    // For upvoted posts screen, always show white icon since background is highlighted
    final Color upIconColor = isUpvotedPostsScreen
        ? Colors.white
        : (isUpvoted ? Colors.white : defaultIconColor);
    final Color downIconColor = isDownvoted ? Colors.white : defaultIconColor;

    // For moderator and admin variants, use different spacing
    final bool isModeratorOrAdmin = data.variant == PostCardVariant.moderator || 
                                     data.variant == PostCardVariant.admin;
    final double gapSize = isModeratorOrAdmin ? 3.99 : 10.0;
    final double verticalPadding = isModeratorOrAdmin ? 7.99 : 12.0;

    final votePanelContent = Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        _VoteButton(
          icon: 'assets/images/upArrow.svg',

          background: upBackground,

          borderColor: isUpvoted
              ? palette.voteBorderColor
              : Colors.transparent,

          iconColor: upIconColor,

          size: 34,

          iconSize: 16,

          onPressed: onUpvote,
        ),

        SizedBox(height: gapSize),

        Text(
          '$votes',

          style: TextStyle(
            fontSize: 16,

            fontWeight: FontWeight.bold,

            color: (data.variant == PostCardVariant.hot ||
                    data.variant == PostCardVariant.hotPost2)
                ? const Color(0xFFCA3500) // #CA3500 for hot posts
                : (data.variant == PostCardVariant.wod
                    ? const Color(0xFF008236) // #008236 for WOD posts
                    : (data.variant == PostCardVariant.newPost
                        ? defaultIconColor // Match arrow color for normal posts
                        : palette.accentColor)), // Original color for other variants

            fontFamily: 'Inter',
          ),
        ),

        SizedBox(height: gapSize),

        _VoteButton(
          icon: 'assets/images/downArrow.svg',

          background: downBackground,

          borderColor: isDownvoted
              ? palette.voteBorderColor
              : Colors.transparent,

          iconColor: downIconColor,

          size: 34,

          iconSize: 16,

          onPressed: onDownvote,
        ),
      ],
    );

    if (data.variant == PostCardVariant.moderator) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Base dimensions from design
          const double baseWidth = 51.79672622680664;
          const double baseScreenWidth = 360.0; // Common mobile screen width
          
          // Calculate responsive width based on screen width
          final screenWidth = MediaQuery.of(context).size.width;
          final scaleFactor = screenWidth / baseScreenWidth;
          final responsiveWidth = baseWidth * scaleFactor.clamp(0.8, 1.2); // Clamp to prevent extreme scaling
          
          return Container(
            width: responsiveWidth,
            padding: const EdgeInsets.all(0.76),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF0F7B), // #FF0F7B
                  Color(0xFFF89B29), // #F89B29
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette.votePanelGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.only(top: verticalPadding, bottom: verticalPadding),
              child: votePanelContent,
            ),
          );
        },
      );
    }

    if (data.variant == PostCardVariant.admin) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Base dimensions from design
          const double baseWidth = 51.79672622680664;
          const double baseScreenWidth = 360.0; // Common mobile screen width
          
          // Calculate responsive width based on screen width
          final screenWidth = MediaQuery.of(context).size.width;
          final scaleFactor = screenWidth / baseScreenWidth;
          final responsiveWidth = baseWidth * scaleFactor.clamp(0.8, 1.2); // Clamp to prevent extreme scaling
          
          return Container(
            width: responsiveWidth,
            padding: const EdgeInsets.all(0.76),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4F39F6), // #4F39F6
                  Color(0xFF9810FA), // #9810FA
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette.votePanelGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.only(top: verticalPadding, bottom: verticalPadding),
              child: votePanelContent,
            ),
          );
        },
      );
    }

    return Container(
      width: 65,

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.votePanelGradient,

          begin: Alignment.topCenter,

          end: Alignment.bottomCenter,
        ),

        borderRadius: BorderRadius.circular(16),

        border: data.variant == PostCardVariant.wod
            ? Border.all(color: const Color(0xFF008236), width: 0.76) // #008236 on all sides
            : Border.all(color: palette.votePanelBorderColor, width: 1.2),
      ),

      padding: const EdgeInsets.symmetric(vertical: 12),

      child: votePanelContent,
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,

    required this.background,

    required this.borderColor,

    required this.iconColor,

    this.size = 28,

    this.iconSize = 14,

    this.onPressed,
  });

  final String icon;

  final Color background;

  final Color borderColor;

  final Color iconColor;

  final double size;

  final double iconSize;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final borderWidth = borderColor.opacity == 0 ? 0.0 : 1.0;

    final child = Container(
      width: size,

      height: size,

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: borderColor, width: borderWidth),
      ),

      child: Center(
        child: SvgPicture.asset(
          icon,

          width: iconSize,

          height: iconSize,

          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );

    if (onPressed == null) {
      return child;
    }

    // Use GestureDetector instead of InkWell for better cross-platform compatibility
    // InkWell can have hit testing issues on iOS, especially with small buttons
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque, // Ensures entire area is tappable on iOS
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}

class _PostActionsPopover extends StatelessWidget {
  const _PostActionsPopover({
    this.onReport,
    this.onDelete,
    this.onBlock,
    this.showReport = false,
    this.showDelete = false,
    this.showBlock = false,
  });

  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final VoidCallback? onBlock;
  final bool showReport;
  final bool showDelete;
  final bool showBlock;

  @override
  Widget build(BuildContext context) {
    final menuChildren = <Widget>[];

    void addMenuItem({
      required String label,
      required Color color,
      required String iconUrl,
      required VoidCallback onTap,
      Color? backgroundColor,
    }) {
      final menuItem = _PopoverMenuItem(
        label: label,
        color: color,
        iconUrl: iconUrl,
        onTap: onTap,
        backgroundColor: backgroundColor,
      );

      // Add margin on all sides for Report Post and Block User buttons
      if (label == 'Report Post' || label == 'Block User') {
        menuChildren.add(
          Padding(padding: const EdgeInsets.all(8), child: menuItem),
        );
      } else {
        menuChildren.add(menuItem);
      }
    }

    if (showReport && onReport != null) {
      addMenuItem(
        label: 'Report Post',
        color: _menuReportColor,
        iconUrl: _menuReportIconUrl,
        onTap: onReport!,
        backgroundColor: _menuReportBackgroundColor,
      );
    }

    if (showBlock && onBlock != null) {
      addMenuItem(
        label: 'Block User',
        color: _menuBlockColor,
        iconUrl: _menuBlockIconUrl,
        onTap: onBlock!,
      );
    }

    if (showDelete && onDelete != null) {
      addMenuItem(
        label: 'Delete Post',
        color: _menuDeleteColor,
        iconUrl: _menuDeleteIconUrl,
        onTap: onDelete!,
      );
    }

    if (menuChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 188,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _menuBorderColor, width: 0.756),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: menuChildren,
        ),
      ),
    );
  }
}

class _PopoverMenuItem extends StatelessWidget {
  const _PopoverMenuItem({
    required this.label,

    required this.color,

    required this.iconUrl,

    required this.onTap,
    this.backgroundColor,
  });

  final String label;

  final Color color;

  final String iconUrl;

  final VoidCallback onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(10),

      child: Container(
        decoration: backgroundColor != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        padding: const EdgeInsets.all(12),

        child: Row(
          children: [
            SvgPicture.asset(
              iconUrl,

              width: 16,

              height: 16,

              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),

            const SizedBox(width: 10),

            Text(
              label,

              style: TextStyle(
                fontSize: 14,

                fontWeight: FontWeight.w500,

                color: color,

                fontFamily: 'Inter',

                letterSpacing: -0.1504,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCommentsDivider extends StatelessWidget {
  const _PostCommentsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),

      child: Container(
        width: double.infinity,

        height: 1,

        color: const Color(0xFFBEDBFF),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.palette,

    required this.data,

    required this.controller,

    required this.onSubmitComment,

    required this.onReplyToComment,

    this.activeReplyIndex,

    this.replyController,

    this.onSubmitReply,

    required this.onReportComment,

    required this.onDeleteComment,

    this.onBlockComment,
  });

  final _PostCardPalette palette;

  final PostCardData data;

  final TextEditingController controller;

  final ValueChanged<String> onSubmitComment;

  final ValueChanged<int> onReplyToComment;

  final int? activeReplyIndex;

  final TextEditingController? replyController;

  final void Function(int parentIndex, String reply)? onSubmitReply;

  final ValueChanged<CommentData> onReportComment;

  final ValueChanged<CommentData> onDeleteComment;

  final ValueChanged<CommentData>? onBlockComment;

  @override
  Widget build(BuildContext context) {
    final comments = data.comments ?? const [];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _commentsSectionBackground,

        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),

      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _CommentInputField(
              palette: palette,

              controller: controller,

              buttonLabel: 'Reply',

              onSubmit: onSubmitComment,
            ),

            if (comments.isNotEmpty) ...[
              const SizedBox(height: 16),

              for (int i = 0; i < comments.length; i++) ...[
                _CommentCard(
                  palette: palette,

                  comment: comments[i],

                  onReport: () => onReportComment(comments[i]),

                  onDelete: () => onDeleteComment(comments[i]),

                  onBlock: onBlockComment != null
                      ? () => onBlockComment!(comments[i])
                      : null,

                  onReply: () => onReplyToComment(i),
                ),

                if (replyController != null &&
                    onSubmitReply != null &&
                    activeReplyIndex == i)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 8),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Replying to indicator
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Replying to ${comments[i].author}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF62748E),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        _CommentInputField(
                          palette: palette,

                          controller: replyController!,

                          buttonLabel: 'Reply',

                          onSubmit: (value) => onSubmitReply!(i, value),

                          autoClear: false,
                        ),
                      ],
                    ),
                  ),

                if (comments[i].replies.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  for (int j = 0; j < comments[i].replies.length; j++) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 28),

                      child: _CommentCard(
                        palette: palette,

                        comment: comments[i].replies[j],

                        onReport: () => onReportComment(comments[i].replies[j]),

                        onDelete: () => onDeleteComment(comments[i].replies[j]),

                        onBlock: onBlockComment != null
                            ? () => onBlockComment!(comments[i].replies[j])
                            : null,

                        isReply: true,
                      ),
                    ),

                    if (j != comments[i].replies.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],

                if (i != comments.length - 1) const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentInputField extends StatefulWidget {
  const _CommentInputField({
    required this.palette,

    required this.controller,

    this.onSubmit,

    this.buttonLabel = 'Reply',

    this.autoClear = true,
  });

  static const int _maxCommentLength = 280;

  static const Color _hintColor = Color(0xFF90A1B9);

  static const Color _textColor = Color(0xFF272727);

  static const Color _limitColor = Color(0xFF94A3B8);

  static const Color _errorColor = Color(0xFFE7000B);

  static const Color _primaryBlue = Color(0xFF155DFC);

  final _PostCardPalette palette;

  final TextEditingController controller;

  final ValueChanged<String>? onSubmit;

  final String buttonLabel;

  final bool autoClear;

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  final PostService _postService = PostService();
  List<ProfileData> _mentionSuggestions = [];
  bool _showMentionSuggestions = false;
  int _mentionStartIndex = -1;
  String _mentionQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPosition = selection.baseOffset;

    // Find the last @ symbol before cursor
    if (cursorPosition < 0) return;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      // Check if there's a space after @ (meaning mention is complete)
      final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
      if (!textAfterAt.contains(' ') && !textAfterAt.contains('\n')) {
        // Extract query after @
        _mentionQuery = textAfterAt.trim();
        _mentionStartIndex = lastAtIndex;

        // Debounce search to avoid too many API calls
        _searchDebounceTimer?.cancel();
        _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          // Show suggestions even with empty query (just "@")
          // If query is empty, search with empty string to get default/popular users
          _searchUsers(_mentionQuery);
        });
      } else {
        setState(() {
          _showMentionSuggestions = false;
          _mentionSuggestions = [];
        });
      }
    } else {
      setState(() {
        _showMentionSuggestions = false;
        _mentionSuggestions = [];
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      // Search with query
      final response = await _postService.searchUsers(query: query, limit: 10);

      if (mounted) {
        final usersList = response['users'] as List<dynamic>? ?? [];
        final profileDataList = usersList
            .map((u) => ProfileData.fromMap(u as Map<String, dynamic>))
            .toList();

        setState(() {
          _mentionSuggestions = profileDataList;
          // Show suggestions if we have results
          _showMentionSuggestions = _mentionSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) {
        setState(() {
          _showMentionSuggestions = false;
          _mentionSuggestions = [];
        });
      }
    }
  }

  void _selectMention(ProfileData user) {
    final username = user.username;
    if (username.isEmpty) return;

    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPosition = selection.baseOffset;

    // Replace the mention query with the selected username
    final textBeforeCursor = text.substring(0, _mentionStartIndex);
    final textAfterMention = text.substring(cursorPosition);
    final newText = '$textBeforeCursor@$username $textAfterMention';

    // Update text and move cursor after the inserted username
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _mentionStartIndex + username.length + 2, // +2 for @ and space
      ),
    );

    setState(() {
      _showMentionSuggestions = false;
      _mentionSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),

      padding: const EdgeInsets.all(12),

      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,

        builder: (context, value, _) {
          final String text = value.text;

          final int characterCount = text.length;

          final bool isOverLimit =
              characterCount > _CommentInputField._maxCommentLength;

          final bool isEmpty = text.trim().isEmpty;

          final bool isEnabled = !isEmpty && !isOverLimit;

          final Color iconColor = isEnabled ? Colors.white : Colors.white70;

          final TextStyle inputStyle = TextStyle(
            fontSize: 14,

            fontWeight: FontWeight.w400,

            color: isOverLimit
                ? _CommentInputField._errorColor
                : _CommentInputField._textColor,

            height: 1.6,

            fontFamily: 'Inter',

            letterSpacing: -0.1504,
          );

          final TextStyle counterStyle = TextStyle(
            fontSize: 12,

            fontWeight: FontWeight.w500,

            color: isOverLimit
                ? _CommentInputField._errorColor
                : _CommentInputField._limitColor,

            fontFamily: 'Inter',
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Mention suggestions dropdown - appears ABOVE the comment input
              if (_showMentionSuggestions && _mentionSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEFF6FF),
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _mentionSuggestions.length,
                    itemBuilder: (context, index) {
                      final user = _mentionSuggestions[index];
                      final username = user.username.replaceAll('@', '');
                      final displayName = user.displayName ?? username;
                      final profilePictureUrl = user.pictureUrl;
                      final initials = user.initials;

                      return InkWell(
                        onTap: () => _selectMention(user),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Profile picture or avatar
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      profilePictureUrl != null &&
                                          profilePictureUrl.isNotEmpty
                                      ? null
                                      : const Color(0xFF155DFC),
                                  border:
                                      profilePictureUrl != null &&
                                          profilePictureUrl.isNotEmpty
                                      ? null
                                      : Border.all(
                                          color: const Color(0xFFF1F5F9),
                                          width: 1.51,
                                        ),
                                  image:
                                      profilePictureUrl != null &&
                                          profilePictureUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            profilePictureUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    profilePictureUrl == null ||
                                        profilePictureUrl!.isEmpty
                                    ? Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child:
                                    displayName != username &&
                                        displayName.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF0F172B),
                                              fontFamily: 'Inter',
                                              letterSpacing: -0.1504,
                                              height: 1.67,
                                            ),
                                          ),
                                          Text(
                                            '@$username',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF90A1B9),
                                              fontFamily: 'Inter',
                                              letterSpacing: -0.1504,
                                              height: 2.0,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '@$username',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0F172B),
                                          fontFamily: 'Inter',
                                          letterSpacing: -0.1504,
                                          height: 1.67,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Comment input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 0.755,
                  ),
                ),
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _CommentInputField._hintColor,
                      letterSpacing: -0.1504,
                      fontFamily: 'Inter',
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: inputStyle,
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,

                child: Text(
                  '$characterCount/${_CommentInputField._maxCommentLength} characters',

                  style: counterStyle,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,

                children: [
                  SizedBox(
                    width: 90,

                    child: ElevatedButton(
                      onPressed: isEnabled
                          ? () {
                              final value = widget.controller.text.trim();

                              if (value.isEmpty) return;

                              if (widget.autoClear) {
                                widget.controller.clear();
                              }

                              widget.onSubmit?.call(value);

                              if (widget.autoClear) {
                                FocusScope.of(context).unfocus();
                              }
                            }
                          : null,

                      style: ElevatedButton.styleFrom(
                        elevation: 0,

                        backgroundColor: _CommentInputField._primaryBlue,

                        disabledForegroundColor: Colors.white70,

                        disabledBackgroundColor: _CommentInputField._primaryBlue
                            .withOpacity(0.3),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),

                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        mainAxisSize: MainAxisSize.min,

                        children: [
                          SvgPicture.asset(
                            _replyIconUrl,

                            width: 16,

                            height: 16,

                            colorFilter: ColorFilter.mode(
                              iconColor,

                              BlendMode.srcIn,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            widget.buttonLabel,

                            style: TextStyle(
                              fontSize: 14,

                              fontWeight: FontWeight.w500,

                              color: iconColor,

                              fontFamily: 'Inter',

                              letterSpacing: -0.1504,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  const _CommentCard({
    required this.palette,

    required this.comment,

    required this.onReport,

    required this.onDelete,

    this.onBlock,

    this.onReply,

    this.isReply = false,
  });

  final _PostCardPalette palette;

  final CommentData comment;

  final VoidCallback onReport;

  final VoidCallback onDelete;

  final VoidCallback? onBlock;

  final VoidCallback? onReply;

  final bool isReply;

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  OverlayEntry? _overlayEntry;

  final GlobalKey _menuKey = GlobalKey();

  int? _currentVotes;

  int _userVote = 0; // 1 = upvoted, -1 = downvoted, 0 = neutral

  final PostService _postService = PostService();

  String? _currentUserId;

  bool _isVoting = false; // Flag to prevent multiple simultaneous votes

  @override
  void initState() {
    super.initState();

    _currentVotes = _initialVotes;
    // Initialize user vote from comment data (persisted state from backend)
    // This ensures the vote highlight is shown when user reopens the app
    _userVote = widget.comment.userVote;
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      debugPrint('Failed to load current user ID: $e');
    }
  }

  bool get _isOwnComment {
    if (_currentUserId == null || widget.comment.userId == null) {
      return false;
    }
    return _currentUserId == widget.comment.userId;
  }

  int _parseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  void didUpdateWidget(covariant _CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.comment.upvotes != widget.comment.upvotes ||
        oldWidget.comment.downvotes != widget.comment.downvotes) {
      _currentVotes = _initialVotes;
    }
    
    // Update user vote state from new comment data
    if (oldWidget.comment.userVote != widget.comment.userVote) {
      _userVote = widget.comment.userVote;
    }
  }

  int get _initialVotes => widget.comment.upvotes - widget.comment.downvotes;

  int get _currentVotesValue => _currentVotes ?? _initialVotes;

  String get _currentVotesLabel => _currentVotesValue.toString();

  Future<void> _handleUpvote() async {
    // Prevent multiple simultaneous votes
    if (_isVoting) return;
    
    final previousVote = _userVote;

    final previousVotes = _currentVotes;

    setState(() {
      _isVoting = true;
      int updated = _currentVotesValue;

      if (_userVote == 1) {
        // Already upvoted, unvote (remove the upvote)

        updated -= 1;

        _userVote = 0;
      } else if (_userVote == -1) {
        // Currently downvoted, switch to upvote (remove downvote, add upvote = +2)

        updated += 2;

        _userVote = 1;
      } else {
        // Neutral, add upvote

        updated += 1;

        _userVote = 1;
      }

      _currentVotes = updated;
    });

    try {
      final voteType = previousVote == 1 ? 'remove' : 'upvote';

      final response = await _postService.voteComment(
        commentId: widget.comment.id,
        voteType: voteType,
      );

      // Check if response indicates an error
      if (mounted && response['success'] == false) {
        final errorMessage = (response['message'] ?? response['error'] ?? 'Failed to vote').toString().toLowerCase();
        
        // Handle specific error gracefully - don't show error for duplicate vote attempts
        final isDuplicateVoteError = errorMessage.contains('you have not voted') ||
            errorMessage.contains('not voted on this comment') ||
            errorMessage.contains('already voted') ||
            errorMessage.contains('have not voted') ||
            errorMessage.contains('failed to vote you have not voted') ||
            errorMessage.contains('you have not voted on this comment') ||
            errorMessage.contains('unable to vote') ||
            errorMessage.contains('you have already voted') ||
            errorMessage.contains('already voted on this') ||
            errorMessage.contains('you have already voted on this post') ||
            errorMessage.contains('you have already voted on this comment');
        
        setState(() {
          _currentVotes = previousVotes;
          _userVote = previousVote;
          _isVoting = false;
        });

        // Only show error if it's not a duplicate vote error
        if (!isDuplicateVoteError) {
          PalToast.show(
            context,
            message: 'Failed to vote: ${response['message'] ?? response['error'] ?? 'Unknown error'}',
            isError: true,
          );
        }
        return;
      }

      // Sync with backend response to ensure consistency
      if (mounted && response['upvote_count'] != null) {
        final upvotes = _parseInt(response['upvote_count']);
        final downvotes = _parseInt(response['downvote_count'] ?? 0);
        final userVoteStr = response['user_vote']?.toString().toLowerCase();

        setState(() {
          // Update vote counts from backend
          final netScore = upvotes - downvotes;
          _currentVotes = netScore;

          // Map backend user_vote string to our integer state
          if (userVoteStr == 'upvote') {
            _userVote = 1;
          } else if (userVoteStr == 'downvote') {
            _userVote = -1;
          } else {
            _userVote = 0;
          }
          _isVoting = false;
        });
      } else if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        
        // Handle specific error gracefully - don't show error for duplicate vote attempts
        final isDuplicateVoteError = errorMessage.contains('you have not voted') ||
            errorMessage.contains('not voted on this comment') ||
            errorMessage.contains('already voted') ||
            errorMessage.contains('have not voted') ||
            errorMessage.contains('failed to vote you have not voted') ||
            errorMessage.contains('you have not voted on this comment') ||
            errorMessage.contains('unable to vote') ||
            errorMessage.contains('you have already voted') ||
            errorMessage.contains('already voted on this') ||
            errorMessage.contains('you have already voted on this post') ||
            errorMessage.contains('you have already voted on this comment');
        
        setState(() {
          _currentVotes = previousVotes;
          _userVote = previousVote;
          _isVoting = false;
        });

        // Only show error if it's not a duplicate vote error
        if (!isDuplicateVoteError) {
          // Check if it's a network error
          if (ErrorHandler.isNetworkError(e)) {
            ErrorHandler.showOfflineToast(context);
          } else {
            PalToast.show(
              context,
              message: 'Failed to vote: ${e.toString().replaceFirst('Exception: ', '')}',
              isError: true,
            );
          }
        }
      }
    }
  }

  Future<void> _handleDownvote() async {
    // Prevent multiple simultaneous votes
    if (_isVoting) return;
    
    final previousVote = _userVote;

    final previousVotes = _currentVotes;

    setState(() {
      _isVoting = true;
      int updated = _currentVotesValue;

      if (_userVote == -1) {
        // Already downvoted, unvote (remove the downvote)

        updated += 1;

        _userVote = 0;
      } else if (_userVote == 1) {
        // Currently upvoted, switch to downvote (remove upvote, add downvote = -2)

        updated -= 2;

        _userVote = -1;
      } else {
        // Neutral, add downvote (count can go negative)

        updated -= 1;

        _userVote = -1;
      }

      _currentVotes = updated;
    });

    try {
      final voteType = previousVote == -1 ? 'remove' : 'downvote';

      final response = await _postService.voteComment(
        commentId: widget.comment.id,
        voteType: voteType,
      );

      // Check if response indicates an error
      if (mounted && response['success'] == false) {
        final errorMessage = (response['message'] ?? response['error'] ?? 'Failed to vote').toString().toLowerCase();
        
        // Handle specific error gracefully - don't show error for duplicate vote attempts
        final isDuplicateVoteError = errorMessage.contains('you have not voted') ||
            errorMessage.contains('not voted on this comment') ||
            errorMessage.contains('already voted') ||
            errorMessage.contains('have not voted') ||
            errorMessage.contains('failed to vote you have not voted') ||
            errorMessage.contains('you have not voted on this comment') ||
            errorMessage.contains('unable to vote') ||
            errorMessage.contains('you have already voted') ||
            errorMessage.contains('already voted on this') ||
            errorMessage.contains('you have already voted on this post') ||
            errorMessage.contains('you have already voted on this comment');
        
        setState(() {
          _currentVotes = previousVotes;
          _userVote = previousVote;
          _isVoting = false;
        });

        // Only show error if it's not a duplicate vote error
        if (!isDuplicateVoteError) {
          PalToast.show(
            context,
            message: 'Failed to vote: ${response['message'] ?? response['error'] ?? 'Unknown error'}',
            isError: true,
          );
        }
        return;
      }

      // Sync with backend response to ensure consistency
      if (mounted && response['upvote_count'] != null) {
        final upvotes = _parseInt(response['upvote_count']);
        final downvotes = _parseInt(response['downvote_count'] ?? 0);
        final userVoteStr = response['user_vote']?.toString().toLowerCase();

        setState(() {
          // Update vote counts from backend
          final netScore = upvotes - downvotes;
          _currentVotes = netScore;

          // Map backend user_vote string to our integer state
          if (userVoteStr == 'upvote') {
            _userVote = 1;
          } else if (userVoteStr == 'downvote') {
            _userVote = -1;
          } else {
            _userVote = 0;
          }
          _isVoting = false;
        });
      } else if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        
        // Handle specific error gracefully - don't show error for duplicate vote attempts
        final isDuplicateVoteError = errorMessage.contains('you have not voted') ||
            errorMessage.contains('not voted on this comment') ||
            errorMessage.contains('already voted') ||
            errorMessage.contains('have not voted') ||
            errorMessage.contains('failed to vote you have not voted') ||
            errorMessage.contains('you have not voted on this comment') ||
            errorMessage.contains('unable to vote') ||
            errorMessage.contains('you have already voted') ||
            errorMessage.contains('already voted on this') ||
            errorMessage.contains('you have already voted on this post') ||
            errorMessage.contains('you have already voted on this comment');
        
        setState(() {
          _currentVotes = previousVotes;
          _userVote = previousVote;
          _isVoting = false;
        });

        // Only show error if it's not a duplicate vote error
        if (!isDuplicateVoteError) {
          // Check if it's a network error
          if (ErrorHandler.isNetworkError(e)) {
            ErrorHandler.showOfflineToast(context);
          } else {
            PalToast.show(
              context,
              message: 'Failed to vote: ${e.toString().replaceFirst('Exception: ', '')}',
              isError: true,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();

    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();

    _overlayEntry = null;
  }

  void _toggleMenu() {
    if (!mounted) return;

    if (_overlayEntry != null) {
      _removeOverlay();

      return;
    }

    final context = _menuKey.currentContext;

    if (context == null || !context.mounted) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.attached) {
      return;
    }

    final size = renderBox.size;

    final offset = renderBox.localToGlobal(Offset.zero);

    final isOwnComment = _isOwnComment;
    final showReport = !isOwnComment;
    final showBlock = !isOwnComment;
    final showDelete = isOwnComment;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,

          onTap: _removeOverlay,

          child: Stack(
            children: [
              Positioned(
                bottom:
                    MediaQuery.of(overlayContext).size.height - offset.dy + 8,

                right:
                    MediaQuery.of(overlayContext).size.width -
                    (offset.dx + size.width) +
                    8,

                child: _CommentActionsPopover(
                  showReport: showReport,
                  showBlock: showBlock,
                  showDelete: showDelete,
                  onReport: showReport
                      ? () {
                          _removeOverlay();
                          widget.onReport();
                        }
                      : null,
                  onBlock: showBlock && widget.onBlock != null
                      ? () {
                          _removeOverlay();
                          widget.onBlock!();
                        }
                      : null,
                  onDelete: showDelete
                      ? () {
                          _removeOverlay();
                          widget.onDelete();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;

    final palette = widget.palette;

    final bool hasUpvoted = _userVote == 1;

    final bool hasDownvoted = _userVote == -1;

    final bool isReply = widget.isReply;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(isReply ? 12 : 14),

        border: Border.all(
          color: isReply
              ? _commentCardBorder.withOpacity(0.7)
              : _commentCardBorder,

          width: 0.756,
        ),
      ),

      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _CommentAvatar(
                asset: comment.avatarAsset,
                profilePictureUrl: comment.profilePictureUrl,
                initials: comment.initials,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  comment.author,

                                  style: const TextStyle(
                                    fontSize: 14,

                                    fontWeight: FontWeight.w600,

                                    color: _commentAuthorColor,

                                    fontFamily: 'Inter',

                                    letterSpacing: -0.1504,
                                  ),

                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 6),

                              const Text(
                                '•',

                                style: TextStyle(
                                  fontSize: 12,

                                  color: _commentMetaDotColor,

                                  fontFamily: 'Inter',
                                ),
                              ),

                              const SizedBox(width: 6),

                              Text(
                                comment.timeAgo,

                                style: const TextStyle(
                                  fontSize: 12,

                                  color: _commentMetaTextColor,

                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),

                        InkWell(
                          key: _menuKey,

                          borderRadius: BorderRadius.circular(16),

                          onTap: _toggleMenu,

                          child: Padding(
                            padding: const EdgeInsets.all(4),

                            child: Icon(
                              Icons.more_horiz,
                              size: 16,
                              color: _commentMetaTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      comment.body,

                      style: const TextStyle(
                        fontSize: 14,

                        fontWeight: FontWeight.w400,

                        color: _commentBodyColor,

                        fontFamily: 'Inter',

                        height: 1.6,

                        letterSpacing: -0.1504,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        _CommentVoteButton(
                          iconAsset: 'assets/images/upArrow.svg',

                          isActive: hasUpvoted,

                          onTap: _isVoting ? () {} : _handleUpvote,

                          activeColor: palette.commentAccentColor,
                        ),

                        const SizedBox(width: 12),

                        Text(
                          _currentVotesLabel,

                          style: const TextStyle(
                            fontSize: 14,

                            fontWeight: FontWeight.w600,

                            color: _commentReactionColor,

                            fontFamily: 'Inter',

                            letterSpacing: -0.1504,
                          ),
                        ),

                        const SizedBox(width: 12),

                        _CommentVoteButton(
                          iconAsset: 'assets/images/downArrow.svg',

                          isActive: hasDownvoted,

                          onTap: _isVoting ? () {} : _handleDownvote,

                          activeColor: palette.downvoteColor,
                        ),
                      ],
                    ),

                    if (!isReply && widget.onReply != null) ...[
                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: widget.onReply,

                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,

                          minimumSize: Size.zero,

                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                          foregroundColor: _commentMetaTextColor,
                        ),

                        child: const Text(
                          'Reply',

                          style: TextStyle(
                            fontSize: 13,

                            fontWeight: FontWeight.w500,

                            color: _commentMetaTextColor,

                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentActionsPopover extends StatelessWidget {
  const _CommentActionsPopover({
    this.onReport,
    this.onDelete,
    this.onBlock,
    this.showReport = false,
    this.showDelete = false,
    this.showBlock = false,
  });

  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final VoidCallback? onBlock;
  final bool showReport;
  final bool showDelete;
  final bool showBlock;

  @override
  Widget build(BuildContext context) {
    final menuChildren = <Widget>[];

    void addMenuItem({
      required String label,
      required Color color,
      required String iconUrl,
      required VoidCallback onTap,
      Color? backgroundColor,
    }) {
      final menuItem = _PopoverMenuItem(
        label: label,
        color: color,
        iconUrl: iconUrl,
        onTap: onTap,
        backgroundColor: backgroundColor,
      );
      menuChildren.add(menuItem);
    }

    if (showReport && onReport != null) {
      addMenuItem(
        label: 'Report Comment',
        color: _menuReportColor,
        iconUrl: _menuReportIconUrl,
        onTap: onReport!,
        backgroundColor: _menuReportBackgroundColor,
      );
    }

    if (showBlock && onBlock != null) {
      if (menuChildren.isNotEmpty) {
        menuChildren.add(
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: _menuDividerColor,
          ),
        );
      }
      addMenuItem(
        label: 'Block User',
        color: _menuBlockColor,
        iconUrl: _menuBlockIconUrl,
        onTap: onBlock!,
      );
    }

    if (showDelete && onDelete != null) {
      if (menuChildren.isNotEmpty) {
        menuChildren.add(
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: _menuDividerColor,
          ),
        );
      }
      addMenuItem(
        label: 'Delete Comment',
        color: _menuDeleteColor,
        iconUrl: _menuDeleteIconUrl,
        onTap: onDelete!,
      );
    }

    if (menuChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 176,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _menuBorderColor, width: 0.756),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: menuChildren,
        ),
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({this.asset, this.profilePictureUrl, this.initials});

  final String? asset;
  final String? profilePictureUrl;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    // Prefer network image (profilePictureUrl), then asset, then initials
    final hasNetworkImage =
        profilePictureUrl != null && profilePictureUrl!.isNotEmpty;
    
    // Check if asset is a default profile image (SVG only) - if so, treat it as no asset and show initials
    // PNG files like 'assets/feedPage/profile.png' are valid hardcoded assets for seed posts
    final isDefaultProfileAsset = asset != null && (
      asset!.contains('profile.svg') ||
      asset == 'assets/feedPage/profile.svg' ||
      asset == 'assets/images/profile.svg'
    );
    
    final hasAsset = asset != null && asset!.isNotEmpty && !isDefaultProfileAsset;
    final displayInitials = initials ?? 'U';

    Widget buildImageWidget(String path) {
      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(path, width: 32, height: 32, fit: BoxFit.cover);
      }

      return ClipOval(
        child: Image.asset(
          path,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsPlaceholder(displayInitials),
        ),
      );
    }

    return ClipOval(
      child: hasAsset && asset!.startsWith('http')
          // Network asset (unlikely but handle it)
          ? CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(asset!),
              onBackgroundImageError: (_, __) {},
              child: _buildInitialsPlaceholder(displayInitials),
            )
          : hasAsset
          // Hardcoded comments: use asset (for seed posts with avatarAsset set)
          ? ClipOval(child: buildImageWidget(asset!))
          : hasNetworkImage
          // Regular users: try to load profile picture, fallback to initials on error
          ? Image.network(
              profilePictureUrl!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                // Show initials while loading
                if (loadingProgress == null) return child;
                return _buildInitialsPlaceholder(displayInitials);
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback to initials if profile picture fails to load
                // This ensures regular users always see initials when image fails
                return _buildInitialsPlaceholder(displayInitials);
              },
            )
          // No profile picture and no asset: show initials
          // This ensures regular users without profile pictures always see initials
          : _buildInitialsPlaceholder(displayInitials),
    );
  }

  Widget _buildInitialsPlaceholder(String initials) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _commentAvatarBackground,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF314158),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _PostCardPalette {
  const _PostCardPalette({
    required this.borderColor,

    required this.titleColor,

    required this.accentColor,

    required this.metaColor,

    required this.commentBackground,

    required this.commentBorderColor,

    required this.commentAccentColor,

    required this.voteButtonBackground,

    required this.voteBorderColor,

    required this.downvoteColor,

    required this.avatarBorderColor,

    required this.votePanelGradient,

    required this.votePanelBorderColor,

    required this.outerBorderColor,

    required this.outerShadowPrimary,

    required this.outerShadowSecondary,

    required this.outerShadowTertiary,

    required this.showHeader,

    required this.headerGradient,

    required this.headerBorderColor,

    required this.headerPillColor,

    required this.headerPillShadows,

    required this.headerLabel,

    required this.headerIconAsset,

    required this.locationBackground,

    required this.locationBorder,

    required this.locationForeground,

    required this.upvoteIconColor,

    required this.commentsSectionBackground,

    required this.commentBubbleBorderColor,
  });

  final Color borderColor;

  final Color titleColor;

  final Color accentColor;

  final Color metaColor;

  final Color commentBackground;

  final Color commentBorderColor;

  final Color commentAccentColor;

  final Color voteButtonBackground;

  final Color voteBorderColor;

  final Color downvoteColor;

  final Color avatarBorderColor;

  final List<Color> votePanelGradient;

  final Color votePanelBorderColor;

  final Color outerBorderColor;

  final Color outerShadowPrimary;

  final Color outerShadowSecondary;

  final Color outerShadowTertiary;

  final bool showHeader;

  final List<Color> headerGradient;

  final Color headerBorderColor;

  final Color headerPillColor;

  final List<BoxShadow> headerPillShadows;

  final String headerLabel;

  final String headerIconAsset;

  final Color locationBackground;

  final Color locationBorder;

  final Color locationForeground;

  final Color upvoteIconColor;

  final Color commentsSectionBackground;

  final Color commentBubbleBorderColor;

  static _PostCardPalette fromVariant(PostCardVariant variant) {
    switch (variant) {
      case PostCardVariant.top:
        return _PostCardPalette(
          borderColor: const Color(0x4DBEDBFF),

          titleColor: const Color(0xFF0F172A),

          accentColor: const Color(0xFF1447E6),

          metaColor: const Color(0xFF94A3B8),

          commentBackground: const Color(0x1A2B7FFF),

          commentBorderColor: const Color(0xFF2B7FFF),

          commentAccentColor: const Color(0xFF1447E6),

          voteButtonBackground: const Color(0xFF2B7FFF),

          voteBorderColor: Colors.transparent,

          downvoteColor: const Color(0xFF1D4ED8),

          avatarBorderColor: const Color(0xFF5A8DFC),

          votePanelGradient: const [Color(0xFFF0F6FF), Color(0xFFE3ECFF)],

          votePanelBorderColor: const Color(0xFF8EC5FF),

          outerBorderColor: const Color(0xFF8EC5FF),

          outerShadowPrimary: Colors.transparent,

          outerShadowSecondary: Colors.transparent,

          outerShadowTertiary: Colors.transparent,

          showHeader: true,

          headerGradient: const [
            Color(0xFFEFF6FF),

            Color(0xB8EEF2F8),

            Color(0x00ECE8E8),
          ],

          headerBorderColor: Colors.transparent,

          headerPillColor: const Color(0xFF2B7FFF),

          headerPillShadows: const [
            BoxShadow(
              color: Color(0x332B7FFF),

              blurRadius: 4,

              offset: Offset(0, 2),
            ),

            BoxShadow(
              color: Color(0x332B7FFF),

              blurRadius: 6,

              offset: Offset(0, 3),
            ),
          ],

          headerLabel: '👑 Top Post',

          headerIconAsset: 'assets/images/topIcon.svg',

          locationBackground: const Color.fromRGBO(239, 246, 255, 1),

          locationBorder: const Color.fromRGBO(165, 210, 255, 1),

          locationForeground: const Color(0xFF1447E6),

          upvoteIconColor: Colors.white,

          commentsSectionBackground: const Color.fromRGBO(239, 246, 255, 0.35),

          commentBubbleBorderColor: const Color(0xFFBDD6FF),
        );

      case PostCardVariant.topPost2:
        return _PostCardPalette(
          borderColor: const Color(0x4DBEDBFF),

          titleColor: const Color(0xFF0F172A),

          accentColor: const Color(0xFF1447E6),

          metaColor: const Color(0xFF94A3B8),

          commentBackground: const Color(0x1A2B7FFF),

          commentBorderColor: const Color(0xFF2B7FFF),

          commentAccentColor: const Color(0xFF1447E6),

          voteButtonBackground: const Color(0xFF2B7FFF),

          voteBorderColor: Colors.transparent,

          downvoteColor: const Color(0xFF1D4ED8),

          avatarBorderColor: const Color(0xFF5A8DFC),

          votePanelGradient: const [Color(0xFFF0F6FF), Color(0xFFE3ECFF)],

          votePanelBorderColor: const Color(0xFF8EC5FF),

          outerBorderColor: const Color(0xFF8EC5FF),

          outerShadowPrimary: Colors.transparent,

          outerShadowSecondary: Colors.transparent,

          outerShadowTertiary: Colors.transparent,

          showHeader: false, // No header badge for topPost2

          headerGradient: const [
            Color(0xFFEFF6FF),

            Color(0xB8EEF2F8),

            Color(0x00ECE8E8),
          ],

          headerBorderColor: Colors.transparent,

          headerPillColor: const Color(0xFF2B7FFF),

          headerPillShadows: const [
            BoxShadow(
              color: Color(0x332B7FFF),

              blurRadius: 4,

              offset: Offset(0, 2),
            ),

            BoxShadow(
              color: Color(0x332B7FFF),

              blurRadius: 6,

              offset: Offset(0, 3),
            ),
          ],

          headerLabel: '👑 Top Post',

          headerIconAsset: 'assets/images/topIcon.svg',

          locationBackground: const Color.fromRGBO(239, 246, 255, 1),

          locationBorder: const Color.fromRGBO(165, 210, 255, 1),

          locationForeground: const Color(0xFF1447E6),

          upvoteIconColor: Colors.white,

          commentsSectionBackground: const Color.fromRGBO(239, 246, 255, 0.35),

          commentBubbleBorderColor: const Color(0xFFBDD6FF),
        );

      case PostCardVariant.hot:
        return _PostCardPalette(
          borderColor: const Color(0xFFFFD0A6),

          titleColor: const Color(0xFF331B09),

          accentColor: const Color(0xFFFF7A00),

          metaColor: const Color(0xFFB4692E),

          commentBackground: const Color(0x1AFF6900),

          commentBorderColor: const Color(0xFFFF6900),

          commentAccentColor: const Color(0xFFCA3500),

          voteButtonBackground: const Color(0xFFFF6900),

          voteBorderColor: Colors.transparent,

          downvoteColor: const Color(0xFFF97316),

          avatarBorderColor: const Color(0xFFFFB86A),

          votePanelGradient: const [
            Color.fromRGBO(255, 237, 212, 1),

            Color.fromRGBO(255, 247, 237, 1),
          ],

          votePanelBorderColor: const Color(0xFFFFB86A),

          outerBorderColor: const Color(0xFFFFB86A), // #FFB86A

          outerShadowPrimary: Colors.transparent,

          outerShadowSecondary: Colors.transparent,

          outerShadowTertiary: Colors.transparent,

          showHeader: true,

          headerGradient: const [
            Color.fromRGBO(255, 247, 237, 1),

            Color.fromRGBO(236, 232, 232, 0),
          ],

          headerBorderColor: Colors.transparent,

          headerPillColor: const Color(0xFFFF6900),

          headerPillShadows: const [
            BoxShadow(
              color: Color(0x33FF6900),

              blurRadius: 4,

              offset: Offset(0, 2),
            ),

            BoxShadow(
              color: Color(0x33FF6900),

              blurRadius: 6,

              offset: Offset(0, 3),
            ),
          ],

          headerLabel: '🔥 Hottest Post',

          headerIconAsset: 'assets/images/hotIcon.svg',

          locationBackground: const Color.fromRGBO(255, 247, 237, 1),

          locationBorder: const Color.fromRGBO(255, 184, 106, 1),

          locationForeground: const Color.fromRGBO(202, 53, 0, 1),

          upvoteIconColor: Colors.white,

          commentsSectionBackground: const Color.fromRGBO(255, 247, 237, 0.4),

          commentBubbleBorderColor: const Color(0xFFFFB86A),
        );

      case PostCardVariant.hotPost2:
        return _PostCardPalette(
          borderColor: const Color(0xFFFFD0A6),

          titleColor: const Color(0xFF331B09),

          accentColor: const Color(0xFFFF7A00),

          metaColor: const Color(0xFFB4692E),

          commentBackground: const Color(0x1AFF6900),

          commentBorderColor: const Color(0xFFFF6900),

          commentAccentColor: const Color(0xFFCA3500),

          voteButtonBackground: const Color(0xFFFF6900),

          voteBorderColor: Colors.transparent,

          downvoteColor: const Color(0xFFF97316),

          avatarBorderColor: const Color(0xFFFFB86A),

          votePanelGradient: const [
            Color.fromRGBO(255, 237, 212, 1),

            Color.fromRGBO(255, 247, 237, 1),
          ],

          votePanelBorderColor: const Color(0xFFFFB86A),

          outerBorderColor: const Color(0xFFFFB86A), // #FFB86A

          outerShadowPrimary: Colors.transparent,

          outerShadowSecondary: Colors.transparent,

          outerShadowTertiary: Colors.transparent,

          showHeader: false, // No header badge for hotPost2

          headerGradient: const [
            Color.fromRGBO(255, 247, 237, 1),

            Color.fromRGBO(236, 232, 232, 0),
          ],

          headerBorderColor: Colors.transparent,

          headerPillColor: const Color(0xFFFF6900),

          headerPillShadows: const [
            BoxShadow(
              color: Color(0x33FF6900),

              blurRadius: 4,

              offset: Offset(0, 2),
            ),

            BoxShadow(
              color: Color(0x33FF6900),

              blurRadius: 6,

              offset: Offset(0, 3),
            ),
          ],

          headerLabel: '🔥 Hottest Post',

          headerIconAsset: 'assets/images/hotIcon.svg',

          locationBackground: const Color.fromRGBO(255, 247, 237, 1),

          locationBorder: const Color.fromRGBO(255, 184, 106, 1),

          locationForeground: const Color.fromRGBO(202, 53, 0, 1),

          upvoteIconColor: Colors.white,

          commentsSectionBackground: const Color.fromRGBO(255, 247, 237, 0.4),

          commentBubbleBorderColor: const Color(0xFFFFB86A),
        );

      case PostCardVariant.newPost:
        return _PostCardPalette(
          borderColor: const Color(0xFFD1D6DE),

          titleColor: const Color(0xFF0F172A),

          accentColor: const Color.fromRGBO(15, 23, 43, 1),

          metaColor: const Color(0xFF94A3B8),

          commentBackground: const Color(0x1A45556C),

          commentBorderColor: const Color(0xFF45556C),

          commentAccentColor: const Color(0xFF45556C),

          voteButtonBackground: Colors.transparent,

          voteBorderColor: Colors.transparent,

          downvoteColor: const Color(0xFF64748B),

          avatarBorderColor: const Color(0xFF0F172B), // #0F172B

          votePanelGradient: const [
            Color.fromRGBO(248, 250, 252, 1),

            Color.fromRGBO(248, 250, 252, 1),
          ],

          votePanelBorderColor: const Color.fromRGBO(226, 232, 240, 1),

          outerBorderColor: const Color(0xFFE2E8F0),

          outerShadowPrimary: Colors.transparent,

          outerShadowSecondary: Colors.transparent,

          outerShadowTertiary: Colors.transparent,

          showHeader: false,

          headerGradient: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],

          headerBorderColor: Colors.transparent,

          headerPillColor: Colors.transparent,

          headerPillShadows: const [],

          headerLabel: '',

          headerIconAsset: '',

          locationBackground: const Color.fromRGBO(248, 250, 252, 1),

          locationBorder: const Color.fromRGBO(226, 232, 240, 1),

          locationForeground: const Color(0xFF334155),

          upvoteIconColor: const Color.fromRGBO(15, 23, 43, 1),

          commentsSectionBackground: const Color.fromRGBO(248, 250, 252, 0.6),

          commentBubbleBorderColor: const Color(0xFFE2E8F0),
        );

      case PostCardVariant.wod:
        return _PostCardPalette(
          borderColor: const Color(0xFFD1D6DE),

          titleColor: const Color(0xFF0F172A),

          accentColor: const Color.fromRGBO(15, 23, 43, 1),

          metaColor: const Color(0xFF94A3B8),

          commentBackground: const Color(0x1A45556C),

          commentBorderColor: const Color(0xFF45556C),

          commentAccentColor: const Color(0xFF008236), // #008236

          voteButtonBackground: Colors.transparent,

          voteBorderColor: Colors.transparent,

          downvoteColor: const Color(0xFF64748B),

          avatarBorderColor: const Color(0xFF0EA54D), // #0EA54D

          votePanelGradient: const [
            Color(0xFFF8FFFB), // #F8FFFB
            Color(0xFFF8FFFB), // #F8FFFB
          ],

          votePanelBorderColor: const Color(0xFF008236), // #008236

          outerBorderColor: const Color(0x4D010B13),

          outerShadowPrimary: Colors.transparent,

          outerShadowSecondary: Colors.transparent,

          outerShadowTertiary: Colors.transparent,

          showHeader: true,

          headerGradient: const [Color(0xFFF5F5F5), Colors.white],

          headerBorderColor: Colors.transparent,

          headerPillColor: const Color(0xFF409965), // #409965

          headerPillShadows: const [
            BoxShadow(
              color: Color(0x33010B13),

              blurRadius: 4,

              offset: Offset(0, 2),
            ),

            BoxShadow(
              color: Color(0x33010B13),

              blurRadius: 6,

              offset: Offset(0, 3),
            ),
          ],

          headerLabel: ' Wahala of the Day "WOD" ',

          headerIconAsset: 'assets/feedPage/Megaphone.svg',

          locationBackground: const Color.fromRGBO(248, 250, 252, 1),

          locationBorder: const Color.fromRGBO(226, 232, 240, 1),

          locationForeground: const Color(0xFF334155),

          upvoteIconColor: const Color.fromRGBO(15, 23, 43, 1),

          commentsSectionBackground: const Color.fromRGBO(248, 250, 252, 0.6),

          commentBubbleBorderColor: const Color(0xFFE2E8F0),
        );

      case PostCardVariant.moderator:
        return _PostCardPalette(
          borderColor: const Color(0xFFD1D6DE),
          titleColor: const Color(0xFF0F172A),
          accentColor: const Color.fromRGBO(15, 23, 43, 1),
          metaColor: const Color(0xFF94A3B8),
          commentBackground: const Color(0x1A45556C),
          commentBorderColor: const Color(0xFF45556C),
          commentAccentColor: const Color(0xFF45556C),
          voteButtonBackground: Colors.transparent,
          voteBorderColor: Colors.transparent,
          downvoteColor: const Color(0xFF64748B),
          avatarBorderColor: const Color(0xFF45556C), // Not used for moderator, gradient border instead
          votePanelGradient: const [
            Color.fromRGBO(248, 250, 252, 1),
            Color.fromRGBO(248, 250, 252, 1),
          ],
          votePanelBorderColor: const Color.fromRGBO(226, 232, 240, 1),
          outerBorderColor: const Color(0xFFE2E8F0),
          outerShadowPrimary: Colors.transparent,
          outerShadowSecondary: Colors.transparent,
          outerShadowTertiary: Colors.transparent,
          showHeader: false,
          headerGradient: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
          headerBorderColor: Colors.transparent,
          headerPillColor: Colors.transparent,
          headerPillShadows: const [],
          headerLabel: '',
          headerIconAsset: '',
          locationBackground: const Color.fromRGBO(248, 250, 252, 1),
          locationBorder: const Color.fromRGBO(226, 232, 240, 1),
          locationForeground: const Color(0xFF334155),
          upvoteIconColor: const Color.fromRGBO(15, 23, 43, 1),
          commentsSectionBackground: const Color.fromRGBO(248, 250, 252, 0.6),
          commentBubbleBorderColor: const Color(0xFFE2E8F0),
        );

      case PostCardVariant.admin:
        return _PostCardPalette(
          borderColor: const Color(0xFFD1D6DE),
          titleColor: const Color(0xFF0F172A),
          accentColor: const Color.fromRGBO(15, 23, 43, 1),
          metaColor: const Color(0xFF94A3B8),
          commentBackground: const Color(0x1A45556C),
          commentBorderColor: const Color(0xFF45556C),
          commentAccentColor: const Color(0xFF45556C),
          voteButtonBackground: Colors.transparent,
          voteBorderColor: Colors.transparent,
          downvoteColor: const Color(0xFF64748B),
          avatarBorderColor: const Color(0xFF45556C), // Not used for admin, gradient border instead
          votePanelGradient: const [
            Color.fromRGBO(248, 250, 252, 1),
            Color.fromRGBO(248, 250, 252, 1),
          ],
          votePanelBorderColor: const Color.fromRGBO(226, 232, 240, 1),
          outerBorderColor: const Color(0xFFE2E8F0),
          outerShadowPrimary: Colors.transparent,
          outerShadowSecondary: Colors.transparent,
          outerShadowTertiary: Colors.transparent,
          showHeader: false,
          headerGradient: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
          headerBorderColor: Colors.transparent,
          headerPillColor: Colors.transparent,
          headerPillShadows: const [],
          headerLabel: '',
          headerIconAsset: '',
          locationBackground: const Color.fromRGBO(248, 250, 252, 1),
          locationBorder: const Color.fromRGBO(226, 232, 240, 1),
          locationForeground: const Color(0xFF334155),
          upvoteIconColor: const Color.fromRGBO(15, 23, 43, 1),
          commentsSectionBackground: const Color.fromRGBO(248, 250, 252, 0.6),
          commentBubbleBorderColor: const Color(0xFFE2E8F0),
        );
    }
  }
}

class _CommentVoteButton extends StatelessWidget {
  const _CommentVoteButton({
    required this.iconAsset,

    required this.isActive,

    required this.onTap,

    required this.activeColor,
  });

  final String iconAsset;

  final bool isActive;

  final VoidCallback onTap;

  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? Colors.white : _commentReactionColor;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(10),

        child: Container(
          width: 32,

          height: 32,

          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,

            borderRadius: BorderRadius.circular(10),
          ),

          child: Center(
            child: SvgPicture.asset(
              iconAsset,

              width: 14,

              height: 14,

              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

// Admin Post Menu Widget
class _AdminPostMenu extends StatelessWidget {
  const _AdminPostMenu({
    required this.postData,
    required this.onEdit,
    required this.onViewProfile,
    required this.onPin,
    required this.onWarn,
    required this.onMute,
    required this.onHide,
    required this.onFlag,
    required this.onDelete,
  });

  final PostCardData postData;
  final VoidCallback onEdit;
  final VoidCallback onViewProfile;
  final VoidCallback onPin;
  final VoidCallback onWarn;
  final VoidCallback onMute;
  final VoidCallback onHide;
  final VoidCallback onFlag;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFC6D2FF), width: 1.513),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 25,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Container(
                width: 101,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFA9CDFD),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Menu items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Post
                  _AdminMenuItem(
                    iconAsset: 'assets/adminIcons/adminpostMenu/edit.svg',
                    label: 'Edit Post',
                    textColor: const Color(0xFF314158),
                    onTap: onEdit,
                  ),

                  // View User's Profile
                  _AdminMenuItem(
                    iconAsset:
                        'assets/adminIcons/adminpostMenu/profile-circle.svg',
                    label: "View User's Profile",
                    textColor: const Color(0xFF314158),
                    onTap: onViewProfile,
                  ),

                  // Pin Post
                  _AdminMenuItem(
                    iconAsset: 'assets/adminIcons/adminpostMenu/PushPin.svg',
                    label: 'Pin Post',
                    textColor: const Color(0xFF314158),
                    onTap: onPin,
                  ),

                  // Separator
                  const _AdminMenuSeparator(),

                  // Warn Conversation
                  _AdminMenuItem(
                    iconAsset: 'assets/adminIcons/adminpostMenu/warning-2.svg',
                    label: 'Warn Conversation ',
                    textColor: const Color(0xFF314158),
                    onTap: onWarn,
                  ),

                  // Mute Conversation
                  _AdminMenuItem(
                    iconAsset:
                        'assets/adminIcons/adminpostMenu/volume-slash.svg',
                    label: 'Mute Conversation ',
                    textColor: const Color(0xFF314158),
                    onTap: onMute,
                  ),

                  // Hide Conversation
                  _AdminMenuItem(
                    iconAsset: 'assets/adminIcons/adminpostMenu/eye-slash.svg',
                    label: 'Hide Conversation ',
                    textColor: const Color(0xFF314158),
                    onTap: onHide,
                  ),

                  // Separator
                  const _AdminMenuSeparator(),

                  // Flag Conversation
                  _AdminMenuItem(
                    iconAsset: 'assets/adminIcons/adminpostMenu/flag-2.svg',
                    label: 'Flag Conversation ',
                    textColor: const Color(0xFFE7000B),
                    onTap: onFlag,
                  ),

                  // Delete Conversation
                  _AdminMenuItem(
                    iconAsset: 'assets/adminIcons/adminpostMenu/Icon.svg',
                    label: 'Delete Conversation ',
                    textColor: const Color(0xFFE7000B),
                    onTap: onDelete,
                  ),

                  // Bottom separator
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Divider(
                      height: 1,
                      thickness: 0.993,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  const _AdminMenuItem({
    required this.iconAsset,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuSeparator extends StatelessWidget {
  const _AdminMenuSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(color: Color(0xFFB8D0F0)),
    );
  }
}
