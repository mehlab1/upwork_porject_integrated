import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'delete_comment_dialog.dart';
import 'delete_post_dialog.dart';
import 'report_post_sheet.dart';
import '../../../services/post_service.dart';
import '../../../widgets/error_dialog.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/time_formatter.dart';

const _menuReportIconUrl = 'assets/feedPage/reportIcon.svg';
const _menuDeleteIconUrl = 'assets/feedPage/deleteIcon.svg';
const _menuDividerColor = Color(0xFFE2E8F0);
const _menuBorderColor = Color(0x33FB2C36);
const _menuReportColor = Color(0xFF314158);
const _menuDeleteColor = Color(0xFFE7000B);
const _commentsSectionBackground = Color.fromRGBO(239, 246, 255, 0.3);
const _commentCardBorder = Color(0xFFE2E8F0);
const _commentMetaDotColor = Color(0xFF90A1B9);
const _commentMetaTextColor = Color(0xFF62748E);
const _commentAuthorColor = Color(0xFF0F172B);
const _commentBodyColor = Color(0xFF45556C);
const _commentReactionColor = Color(0xFF314158);
const _commentAvatarBackground = Color(0xFFF1F5F9);

enum PostCardVariant { top, hot, newPost }

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
    this.comments,
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
  final List<CommentData>? comments;

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
      comments: comments ?? this.comments,
    );
  }
}

class CommentData {
  const CommentData({
    required this.author,
    required this.timeAgo,
    required this.body,
    required this.upvotes,
    required this.downvotes,
    this.avatarAsset,
    this.initials,
  });

  final String author;
  final String timeAgo;
  final String body;
  final int upvotes;
  final int downvotes;
  final String? avatarAsset;
  final String? initials;
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.data, this.isPinnedAdmin = false, this.postService});

  final PostCardData data;
  final bool isPinnedAdmin;
  final PostService? postService;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _menuKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _showComments = false;
  bool _isLoadingComments = false;
  bool _commentsLoaded = false;
  List<CommentData> _loadedComments = const [];
  final TextEditingController _commentController = TextEditingController();
  late int _currentVotes;
  int _userVote = 0; // 1 = upvoted, -1 = downvoted, 0 = neutral
  late final PostService _postService;

  PostCardData get data => widget.data;

  @override
  void initState() {
    super.initState();
    _currentVotes = data.votes;
    _postService = widget.postService ?? PostService();
  }

  @override
  void dispose() {
    _removeOverlay();
    _commentController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMenu(BuildContext parentContext) {
    if (!mounted) return;
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

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
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
                child: _PostActionsPopover(
                  onReport: () async {
                    _removeOverlay();
                    if (!mounted) return;
                    // Check if post has an ID before showing report sheet
                    if (data.id != null) {
                      await _showReportPostSheet(parentContext, data.id!);
                    }
                  },
                  onDelete: () async {
                    _removeOverlay();
                    if (!mounted) return;
                    await _showDeleteDialog(parentContext, data.title, data.id, _postService);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(parentContext, rootOverlay: true).insert(_overlayEntry!);
  }

  Future<void> _loadComments() async {
    print('=== DEBUG: Starting _loadComments ===');
    // Only load comments if the post has an ID and comments aren't already loaded
    if (data.id == null) {
      print('ERROR: Cannot load comments - post ID is null');
      return;
    }
    
    if (_commentsLoaded) {
      print('DEBUG: Comments already loaded, skipping');
      return;
    }
    
    if (_isLoadingComments) {
      print('DEBUG: Already loading comments, skipping');
      return;
    }

    print('DEBUG: Setting _isLoadingComments to true');
    setState(() {
      _isLoadingComments = true;
    });

    try {
      print('DEBUG: Calling _postService.getComments with postId: ${data.id}');
      final response = await _postService.getComments(postId: data.id!);
      print('DEBUG: Received response from getComments: $response');
      
      if (response['success'] == true) {
        print('DEBUG: Success response received');
        final List<dynamic> commentsData = response['comments'] as List<dynamic>;
        print('DEBUG: Comments data length: ${commentsData.length}');
        final List<CommentData> comments = commentsData.map((comment) {
          print('DEBUG: Processing comment: $comment');
          // Map the comment data to CommentData objects
          if (comment is Map<String, dynamic>) {
            return CommentData(
              author: comment['username'] as String? ?? 'Anonymous',
              timeAgo: TimeFormatter.formatTimeAgo(comment['created_at'] as String? ?? DateTime.now().toIso8601String()),
              body: comment['content'] as String? ?? '',
              upvotes: (comment['upvote_count'] as num?)?.toInt() ?? 0,
              downvotes: (comment['downvote_count'] as num?)?.toInt() ?? 0,
              avatarAsset: comment['profile_picture_url'] as String?,
              initials: _getInitials(comment['username'] as String?),
            );
          }
          print('DEBUG: Comment is not a Map, using default');
          return const CommentData(
            author: 'Anonymous',
            timeAgo: 'Just now',
            body: '',
            upvotes: 0,
            downvotes: 0,
          );
        }).toList();

        if (mounted) {
          print('DEBUG: Updating state with ${comments.length} comments');
          setState(() {
            _loadedComments = comments;
            _isLoadingComments = false;
            _commentsLoaded = true;
          });
        }
      } else {
        print('DEBUG: Error response received');
        if (mounted) {
          setState(() {
            _isLoadingComments = false;
          });
          
          String errorMessage = response['error'] as String? ?? 'Failed to load comments';
          if (response.containsKey('details')) {
            errorMessage += ': ${response['details']}';
          }
          
          // Show human-readable error
          ErrorHandler.showHumanReadableError(
            context,
            technicalError: errorMessage,
            customTitle: 'Comments Error',
            customSubtitle: 'Unable to load comments',
          );
        }
      }
    } catch (e) {
      print('=== ERROR: Exception in _loadComments ===');
      print('Exception: ${e.toString()}');
      print('Exception type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        
        // Show human-readable error
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: e.toString(),
          customTitle: 'Comments Error',
          customSubtitle: 'Unable to load comments',
          onTryAgain: _loadComments, // Allow retry
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PostCardPalette.fromVariant(data.variant);
    final bool isAdminPinned = widget.isPinnedAdmin;
    
    // Determine which comments to display
    final List<CommentData> displayComments = _loadedComments.isNotEmpty 
        ? _loadedComments 
        : (data.comments ?? const []);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: palette.outerBorderColor,
                width: 1.51027,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (palette.showHeader) _HighlightHeader(palette: palette),
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
                          data: data,
                          palette: palette,
                          onMoreTap: isAdminPinned
                              ? null
                              : () => _toggleMenu(context),
                          moreButtonKey: isAdminPinned ? null : _menuKey,
                          onToggleComments: () async {
                            setState(() {
                              _showComments = !_showComments;
                            });
                            
                            // Load comments when expanding the section
                            if (_showComments) {
                              await _loadComments();
                            }
                          },
                          commentsExpanded: _showComments,
                          showMoreButton: !isAdminPinned,
                        ),
                        if (_showComments) ...[
                          const _PostCommentsDivider(),
                          _CommentsSection(
                            palette: palette,
                            data: data.copyWith(comments: displayComments),
                            controller: _commentController,
                            onReportComment: (comment) =>
                                _showReportCommentSheet(context, comment),
                            onDeleteComment: (comment) =>
                                _showDeleteCommentDialog(context, comment),
                            isLoading: _isLoadingComments,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleUpvote() async {
    // Don't allow voting on hardcoded posts (they don't have IDs)
    if (data.id == null) {
      return;
    }
    
    try {
      // Send 'upvote' - the backend will toggle if already upvoted
      final response = await _postService.votePost(
        postId: data.id!,
        voteType: 'upvote',
      );
      
      if (response['success'] == true) {
        setState(() {
          _currentVotes = response['net_score'] as int? ?? _currentVotes;
          // Update user vote state based on response
          _userVote = response['user_vote'] == 'upvote' ? 1 : 0;
        });
      }
    } catch (e) {
      // Show human-readable error
      if (mounted) {
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: e.toString(),
          customTitle: 'Voting Error',
          customSubtitle: 'Unable to process vote',
          onTryAgain: _handleUpvote, // Allow retry
        );
      }
    }
  }

  void _handleDownvote() async {
    // Don't allow voting on hardcoded posts (they don't have IDs)
    if (data.id == null) {
      return;
    }
    
    try {
      // Send 'downvote' - the backend will toggle if already downvoted
      final response = await _postService.votePost(
        postId: data.id!,
        voteType: 'downvote',
      );
      
      if (response['success'] == true) {
        setState(() {
          _currentVotes = response['net_score'] as int? ?? _currentVotes;
          // Update user vote state based on response
          _userVote = response['user_vote'] == 'downvote' ? -1 : 0;
        });
      }
    } catch (e) {
      // Show human-readable error
      if (mounted) {
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: e.toString(),
          customTitle: 'Voting Error',
          customSubtitle: 'Unable to process vote',
          onTryAgain: _handleDownvote, // Allow retry
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted (placeholder).')),
      );
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
      builder: (_) => const ReportPostSheet(), // No postId for comment reporting
    );

    if (result != null && context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ReportSuccessDialog(),
      );
    }
  }

  /// Extract initials from username
  String _getInitials(String? username) {
    if (username == null || username.isEmpty) return '?';
    
    // Split by space and take first letter of first two words
    final words = username.split(' ');
    if (words.isEmpty) return '?';
    
    String initials = words[0][0].toUpperCase();
    if (words.length > 1) {
      initials += words[1][0].toUpperCase();
    }
    
    return initials;
  }

  _PostCardPalette _getPostPalette(PostCardVariant variant) {
    switch (variant) {
      case PostCardVariant.top:
        return _PostCardPalette(
          borderColor: const Color(0x4DBEDBFF),
          titleColor: const Color(0xFF0F172A),
          accentColor: const Color(0xFF155DFC),
          metaColor: const Color(0xFF94A3B8),
          commentBackground: const Color(0x1A2B7FFF),
          commentBorderColor: const Color(0xFF2B7FFF),
          commentAccentColor: const Color(0xFF2B7FFF),
          voteButtonBackground: const Color(0xFF2B7FFF),
          voteBorderColor: Colors.transparent,
          downvoteColor: const Color(0xFF1D4ED8),
          avatarBorderColor: const Color(0xFF2B7FFF),
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
          locationForeground: const Color.fromRGBO(43, 127, 255, 1),
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
          commentAccentColor: const Color(0xFFFF6900),
          voteButtonBackground: const Color(0xFFFF6900),
          voteBorderColor: Colors.transparent,
          downvoteColor: const Color(0xFFF97316),
          avatarBorderColor: const Color(0xFFFF6900),
          votePanelGradient: const [
            Color.fromRGBO(255, 237, 212, 1),
            Color.fromRGBO(255, 247, 237, 1),
          ],
          votePanelBorderColor: const Color(0xFFFFB86A),
          outerBorderColor: const Color(0xFFFFB86A),
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
          headerLabel: '🔥 Hotest Post',
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
          avatarBorderColor: const Color(0xFF45556C),
          votePanelGradient: const [
            Color.fromRGBO(248, 250, 252, 1),
            Color.fromRGBO(248, 250, 252, 1),
          ],
          votePanelBorderColor: const Color.fromRGBO(226, 232, 240, 1),
          outerBorderColor: const Color(0xFFB3BAC5),
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

class _HighlightHeader extends StatelessWidget {
  const _HighlightHeader({required this.palette});

  final _PostCardPalette palette;

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
          gradient: LinearGradient(
            colors: palette.headerGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
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

  @override
  Widget build(BuildContext context) {
    final bool hasBadges = showMetaBadges || customBadge != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          asset: data.avatarAsset,
          borderColor: palette.avatarBorderColor,
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
                      data.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      data.timeAgo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (hasBadges) ...[
                const SizedBox(height: 12),
                if (showMetaBadges)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        icon: 'assets/images/locationIcon.svg',
                        label: data.location,
                        background: palette.locationBackground,
                        foreground: palette.locationForeground,
                        borderColor: palette.locationBorder,
                      ),
                      _Badge(
                        icon: 'assets/images/askIcon.svg',
                        label: data.category,
                        background: const Color(0xFFEFFDF4),
                        foreground: const Color(0xFF15803D),
                        borderColor: const Color(0xFFBDE9CE),
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
  });

  final PostCardData data;
  final _PostCardPalette palette;
  final VoidCallback onToggleComments;
  final bool commentsExpanded;
  final VoidCallback? onMoreTap;
  final GlobalKey? moreButtonKey;
  final bool showMoreButton;

  @override
  Widget build(BuildContext context) {
    final comments = data.comments ?? const [];
    final displayedCount = comments.isNotEmpty
        ? comments.length
        : data.commentsCount;
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
                  '$displayedCount comments',
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
              child: Icon(Icons.more_horiz, size: 24, color: palette.metaColor),
            ),
          ),
      ],
    );
  }
}

Future<void> _showReportPostSheet(BuildContext context, String postId) async {
  final result = await showModalBottomSheet<ReportResult?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReportPostSheet(postId: postId),
  );

  if (result != null && context.mounted) {
    if (result.success) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ReportSuccessDialog(),
      );
    }
  }
}

Future<void> _showDeleteDialog(BuildContext context, String title, String? postId, PostService postService) async {
  final result = await showDialog<DeletePostResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DeletePostDialog(postTitle: title),
  );

  if (result?.confirmed == true && context.mounted) {
    // Check if post has an ID before attempting to delete
    if (postId != null) {
      try {
        final response = await postService.deletePost(postId: postId);
        if (response['success'] == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Post deleted successfully')),
          );
          // TODO: Refresh the feed or remove the post from UI
        }
      } catch (e) {
        if (context.mounted) {
          // Show human-readable error
          ErrorHandler.showHumanReadableError(
            context,
            technicalError: e.toString(),
            customTitle: 'Delete Post Error',
            customSubtitle: 'Unable to delete post',
          );
        }
      }
    } else {
      if (context.mounted) {
        // Show human-readable error
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: 'Cannot delete this post',
          customTitle: 'Delete Post Error',
          customSubtitle: 'Invalid post',
        );
      }
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.asset, required this.borderColor});

  final String? asset;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 47,
      height: 47,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset != null
          ? _Avatar._buildImage(asset!)
          : _Avatar._buildDefaultImage(),
    );
  }

  static Widget _buildImage(String path) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.cover,
        placeholderBuilder: (_) =>
            Image.asset('assets/feedPage/profile.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          SvgPicture.asset('assets/feedPage/profile.svg', fit: BoxFit.cover),
    );
  }

  static Widget _buildDefaultImage() {
    return Image.asset(
      'assets/feedPage/profile.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          SvgPicture.asset('assets/feedPage/profile.svg', fit: BoxFit.cover),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(80),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
              fontFamily: 'Inter',
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
  });

  final PostCardData data;
  final _PostCardPalette palette;
  final int votes;
  final bool isUpvoted;
  final bool isDownvoted;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  @override
  Widget build(BuildContext context) {
    final Color upBackground = palette.voteButtonBackground;
    const Color downBackground = Colors.transparent;
    final bool isNewVariant = data.variant == PostCardVariant.newPost;
    final Color upIconColor = isNewVariant
        ? palette.upvoteIconColor
        : (isUpvoted ? Colors.white : palette.upvoteIconColor);
    final Color downIconColor = palette.downvoteColor;

    return Container(
      width: 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.votePanelGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.votePanelBorderColor, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VoteButton(
            icon: 'assets/images/upArrow.svg',
            background: upBackground,
            borderColor: palette.voteBorderColor,
            iconColor: upIconColor,
            size: 34,
            iconSize: 16,
            onPressed: onUpvote,
          ),
          const SizedBox(height: 10),
          Text(
            '$votes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.accentColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          _VoteButton(
            icon: 'assets/images/downArrow.svg',
            background: downBackground,
            borderColor: Colors.transparent,
            iconColor: downIconColor,
            size: 26,
            iconSize: 14,
            onPressed: onDownvote,
          ),
        ],
      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _PostActionsPopover extends StatelessWidget {
  const _PostActionsPopover({required this.onReport, required this.onDelete});

  final VoidCallback onReport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
          children: [
            _PopoverMenuItem(
              label: 'Report Post',
              color: _menuReportColor,
              iconUrl: _menuReportIconUrl,
              onTap: onReport,
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _menuDividerColor,
            ),
            _PopoverMenuItem(
              label: 'Delete Post',
              color: _menuDeleteColor,
              iconUrl: _menuDeleteIconUrl,
              onTap: onDelete,
            ),
          ],
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
  });

  final String label;
  final Color color;
  final String iconUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    required this.onReportComment,
    required this.onDeleteComment,
    this.isLoading = false,
  });

  final _PostCardPalette palette;
  final PostCardData data;
  final TextEditingController controller;
  final ValueChanged<CommentData> onReportComment;
  final ValueChanged<CommentData> onDeleteComment;
  final bool isLoading;

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
              postId: data.id ?? '', // Pass the post ID
            ),
            if (isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Loading comments...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (int i = 0; i < comments.length; i++) ...[
                _CommentCard(
                  palette: palette,
                  comment: comments[i],
                  onReport: () => onReportComment(comments[i]),
                  onDelete: () => onDeleteComment(comments[i]),
                ),
                if (i != comments.length - 1) const SizedBox(height: 12),
              ],
            ] else if (data.id != null) ...[
              // Show loading indicator or message when there are no comments but the post has an ID
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentInputField extends StatefulWidget {
  const _CommentInputField({required this.palette, required this.controller, required this.postId});

  final _PostCardPalette palette;
  final TextEditingController controller;
  final String postId;

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  bool _isSubmitting = false;
  final PostService _postService = PostService();

  Future<void> _submitComment() async {
    print('=== DEBUG: Starting _submitComment ===');
    
    // Check if postId is valid
    print('DEBUG: Post ID: "${widget.postId}"');
    if (widget.postId.isEmpty) {
      print('ERROR: Cannot post comment - Invalid post ID');
      if (mounted) {
        // Show human-readable error
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: 'Cannot post comment: This post does not support comments',
          customTitle: 'Comment Error',
          customSubtitle: 'Invalid post',
        );
      }
      return;
    }
    
    final content = widget.controller.text.trim();
    print('DEBUG: Comment content length: ${content.length}');
    
    // Validate input
    if (content.isEmpty) {
      print('ERROR: Comment content is empty');
      if (mounted) {
        // Show human-readable error
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: 'Please enter a comment',
          customTitle: 'Comment Error',
          customSubtitle: 'Empty comment',
        );
      }
      return;
    }
    
    if (content.length > 500) {
      print('ERROR: Comment content too long - ${content.length} characters');
      if (mounted) {
        // Show human-readable error
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: 'Comment must be 500 characters or less',
          customTitle: 'Comment Error',
          customSubtitle: 'Comment too long',
        );
      }
      return;
    }

    print('DEBUG: Setting _isSubmitting to true');
    setState(() {
      _isSubmitting = true;
    });

    try {
      print('DEBUG: Calling _postService.createComment');
      print('DEBUG: Parameters - postId: ${widget.postId}, content: ${content.substring(0, math.min(content.length, 50))}${content.length > 50 ? '...' : ''}');
      
      final response = await _postService.createComment(
        postId: widget.postId,
        content: content,
      );
      
      print('DEBUG: Received response from createComment: $response');

      if (response['success'] == true) {
        print('DEBUG: Comment creation successful');
        // Clear the input field
        widget.controller.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment posted successfully')),
          );
        }
        
        // TODO: Update the UI to show the new comment
        // This would typically involve calling a callback to refresh the comments list
      } else {
        print('DEBUG: Comment creation failed - success flag is false');
        final errorMessage = response['error'] ?? response['message'] ?? 'Failed to post comment';
        print('DEBUG: Error message: $errorMessage');
        if (mounted) {
          // Show human-readable error
          ErrorHandler.showHumanReadableError(
            context,
            technicalError: errorMessage,
            customTitle: 'Comment Error',
            customSubtitle: 'Unable to post comment',
          );
        }
      }
    } catch (e) {
      print('=== ERROR: Exception in _submitComment ===');
      print('Exception: ${e.toString()}');
      print('Exception type: ${e.runtimeType}');
      
      if (mounted) {
        // Show human-readable error
        ErrorHandler.showHumanReadableError(
          context,
          technicalError: e.toString(),
          customTitle: 'Comment Error',
          customSubtitle: 'Unable to post comment',
          onTryAgain: _submitComment, // Allow retry
        );
      }
    } finally {
      print('DEBUG: Finally block - setting _isSubmitting to false');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Disable comment submission for posts without valid IDs
    final bool canComment = widget.postId.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: widget.controller,
              maxLines: 3,
              minLines: 3,
              enabled: canComment, // Disable text field for invalid posts
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: canComment ? 'Share your thoughts...' : 'Comments not available for this post',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF90A1B9),
                  letterSpacing: -0.1504,
                  fontFamily: 'Inter',
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF272727),
                height: 1.6,
                fontFamily: 'Inter',
                letterSpacing: -0.1504,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: canComment && !_isSubmitting ? _submitComment : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF155DFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.send, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting ? 'Sending' : 'Reply',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
  });

  final _PostCardPalette palette;
  final CommentData comment;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _menuKey = GlobalKey();

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
                  onReport: () {
                    _removeOverlay();
                    widget.onReport();
                  },
                  onDelete: () {
                    _removeOverlay();
                    widget.onDelete();
                  },
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _commentCardBorder, width: 0.756),
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
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_horiz,
                              size: 18,
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
                      children: [
                        _CommentReaction(
                          icon: 'assets/images/upArrow.svg',
                          count: comment.upvotes,
                          color: _commentReactionColor,
                        ),
                        const SizedBox(width: 16),
                        _CommentReaction(
                          icon: 'assets/images/downArrow.svg',
                          count: comment.downvotes,
                          color: _commentReactionColor,
                        ),
                      ],
                    ),
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

class _CommentReaction extends StatelessWidget {
  const _CommentReaction({
    required this.icon,
    required this.count,
    required this.color,
  });

  final String icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: SvgPicture.asset(
              icon,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _CommentActionsPopover extends StatelessWidget {
  const _CommentActionsPopover({
    required this.onReport,
    required this.onDelete,
  });

  final VoidCallback onReport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PopoverMenuItem(
              label: 'Report Comment',
              color: _menuReportColor,
              iconUrl: _menuReportIconUrl,
              onTap: onReport,
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _menuDividerColor,
            ),
            _PopoverMenuItem(
              label: 'Delete Comment',
              color: _menuDeleteColor,
              iconUrl: _menuDeleteIconUrl,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({this.asset, this.initials});

  final String? asset;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    if (asset != null && asset!.isNotEmpty) {
      if (asset!.startsWith('http')) {
        return CircleAvatar(radius: 16, backgroundImage: NetworkImage(asset!));
      }
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: SvgPicture.asset(
            asset!,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: _commentAvatarBackground,
      child: Text(
        initials ?? '',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF314158),
          fontFamily: 'Inter',
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
          accentColor: const Color(0xFF155DFC),
          metaColor: const Color(0xFF94A3B8),
          commentBackground: const Color(0x1A2B7FFF),
          commentBorderColor: const Color(0xFF2B7FFF),
          commentAccentColor: const Color(0xFF2B7FFF),
          voteButtonBackground: const Color(0xFF2B7FFF),
          voteBorderColor: Colors.transparent,
          downvoteColor: const Color(0xFF1D4ED8),
          avatarBorderColor: const Color(0xFF2B7FFF),
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
          locationForeground: const Color.fromRGBO(43, 127, 255, 1),
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
          commentAccentColor: const Color(0xFFFF6900),
          voteButtonBackground: const Color(0xFFFF6900),
          voteBorderColor: Colors.transparent,
          downvoteColor: const Color(0xFFF97316),
          avatarBorderColor: const Color(0xFFFF6900),
          votePanelGradient: const [
            Color.fromRGBO(255, 237, 212, 1),
            Color.fromRGBO(255, 247, 237, 1),
          ],
          votePanelBorderColor: const Color(0xFFFFB86A),
          outerBorderColor: const Color(0xFFFFB86A),
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
          headerLabel: '🔥 Hotest Post',
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
          avatarBorderColor: const Color(0xFF45556C),
          votePanelGradient: const [
            Color.fromRGBO(248, 250, 252, 1),
            Color.fromRGBO(248, 250, 252, 1),
          ],
          votePanelBorderColor: const Color.fromRGBO(226, 232, 240, 1),
          outerBorderColor: const Color(0xFFB3BAC5),
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
