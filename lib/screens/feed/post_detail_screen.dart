import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/pal_loading_widgets.dart';
import 'widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.commentId,
  });

  static const routeName = '/post-detail';

  final String postId;
  final String? commentId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  PostCardData? _postData;
  
  // In-memory cache for post data (simple cache)
  static final Map<String, PostCardData> _postCache = {};

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    // Check cache first
    if (_postCache.containsKey(widget.postId)) {
      setState(() {
        _postData = _postCache[widget.postId];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final response = await _postService.getPost(postId: widget.postId);
      
      if (!mounted) return;

      if (response['success'] == true && response['post'] != null) {
        final post = response['post'] as Map<String, dynamic>;
        final cardData = await _mapPostResponseToCardData(post);
        
        if (cardData != null && mounted) {
          // Cache the post data
          _postCache[widget.postId] = cardData;
          
          setState(() {
            _postData = cardData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Post not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Post not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      final isNotFound = errorMessage.toLowerCase().contains('not found') ||
          errorMessage.toLowerCase().contains('404');
      
      setState(() {
        _hasError = true;
        _errorMessage = isNotFound ? 'Post not found' : 'Failed to load post';
        _isLoading = false;
      });
    }
  }

  Future<PostCardData?> _mapPostResponseToCardData(
    Map<String, dynamic> post,
  ) async {
    final content = (post['content'] ?? '').toString().trim();
    if (content.isEmpty) {
      return null;
    }

    // Parse title and body from content (similar to feed_home_screen logic)
    String title = '';
    String body = content;
    
    // Try to extract title from content (first line or segment)
    final segments = content.split('\n\n');
    if (segments.isNotEmpty) {
      title = segments.first.trim();
      if (segments.length > 1) {
        body = segments.sublist(1).join('\n\n').trim();
      }
    }
    
    if (title.isEmpty) {
      title = 'Community Post';
    }
    if (body.isEmpty) {
      body = content;
    }

    final username = (post['username'] ?? '@pal_user').toString();
    final category = (post['category_name'] ?? '').toString();
    final location = (post['location_name'] ?? '').toString();
    final userId = post['user_id']?.toString();

    // Get profile picture URL and initials
    String? profilePictureUrl = post['profile_picture_url']?.toString();
    String? initials;
    
    if (userId != null) {
      // Try to get profile data for initials and picture
      try {
        final profileData = await _profileService.getProfileDataByUserId(userId);
        if (profileData != null) {
          profilePictureUrl = profileData.pictureUrl ?? profilePictureUrl;
          initials = profileData.initials;
        }
      } catch (e) {
        // Silently fail - use fallback
      }
    }

    // Generate initials from username if not available
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
      initials = generateInitials(username);
    }

    final createdAt = DateTime.tryParse(post['created_at']?.toString() ?? '');

    final commentsCount = _parseInt(
      post['comment_count'] ?? post['comments_count'] ?? 0,
    );
    
    // Use net_score for votes (upvote_count - downvote_count)
    final votes = _parseInt(
      post['net_score'] ?? 
      ((_parseInt(post['upvote_count'] ?? 0) - _parseInt(post['downvote_count'] ?? 0))),
    );

    return PostCardData(
      id: post['id']?.toString(),
      variant: PostCardVariant.newPost,
      username: username.isEmpty ? '@pal_user' : username,
      timeAgo: _formatTimeAgo(createdAt),
      location: location,
      category: category,
      title: title,
      body: body,
      commentsCount: commentsCount,
      votes: votes,
      avatarAsset: 'assets/feedPage/profile.png',
      profilePictureUrl: profilePictureUrl,
      initials: initials,
      badges: [],
      userId: userId,
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
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back arrow and title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Post Notification',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
            PalBottomNavigationBar(
              active: PalNavDestination.notifications,
              onHomeTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushNamed('/home');
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

    // Show loading overlay on top if loading
    if (_isLoading) {
      return Stack(
        children: [
          scaffold,
          const PalLoadingOverlay(),
        ],
      );
    }

    return scaffold;
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage ?? 'Post not found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_postData == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: PostCard(
        data: _postData!,
        showOverflowMenu: true,
        // Auto-expand comments if commentId is provided
        initialCommentsExpanded: widget.commentId != null,
      ),
    );
  }
}
