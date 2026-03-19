import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'widgets/jm_post_card.dart';
import 'package:pal/services/post_service.dart';
import 'package:pal/services/profile_service.dart';
import 'package:pal/widgets/profile_avatar_widget.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:intl/intl.dart';

const _pageBackground = Color(0xFFF7FBFF);
const _headerTitleColor = Color(0xFF0F172B);
const _headerSubtitleColor = Color(0xFF45556C);
const _headerMetaColor = Color(0xFF62748E);

class JmUpvotedPostsScreen extends StatefulWidget {
  const JmUpvotedPostsScreen({super.key});

  static const routeName = '/settings/upvoted-posts';

  @override
  State<JmUpvotedPostsScreen> createState() => _JmUpvotedPostsScreenState();
}

class _JmUpvotedPostsScreenState extends State<JmUpvotedPostsScreen> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();

  List<JmPostCardData> _posts = [];
  ProfileData? _profileData;
  late bool _isLoading;
  String? _errorMessage;
  int _totalUpvotedPosts = 0;
  // Profile cache for posts (similar to feed section)
  final Map<String, ProfileData> _profileCache = {};

  @override
  void initState() {
    super.initState();
    // Skip the loading spinner if data is already cached
    _isLoading = !_postService.isUpvotedPostsCached;
    _loadData();
  }

  Future<void> _loadData() async {
    _errorMessage = null;

    try {
      // Fetch upvoted posts and profile in parallel.
      // getUpvotedPosts returns instantly if prefetched — no spinner needed.
      final results = await Future.wait([
        _postService.getUpvotedPosts(limit: 100, offset: 0),
        _profileService.getProfileData(),
      ]);

      if (!mounted) return;

      final postsResponse = results[0] as Map<String, dynamic>;
      final profileData = results[1] as ProfileData?;

      final postsList = postsResponse['posts'] as List<dynamic>? ?? [];
      final totalUpvoted =
          postsResponse['total_upvoted_posts'] as int? ?? postsList.length;
      
      // Convert to List<Map<String, dynamic>> for profile fetching
      final postsListTyped = postsList
          .map((post) {
            if (post is Map<String, dynamic>) {
              return post;
            }
            if (post is Map) {
              return Map<String, dynamic>.from(post);
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      
      // Fetch profiles for posts (like in feed section)
      await _fetchProfilesForPosts(postsListTyped);
      
      final mappedPosts = postsListTyped
          .map((post) => _mapPostToCardData(post))
          .whereType<JmPostCardData>()
          .toList();

      setState(() {
        _posts = mappedPosts;
        _profileData = profileData;
        _totalUpvotedPosts = totalUpvoted;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Fetch profiles for unique user IDs from posts (parallel fetching for performance)
  Future<void> _fetchProfilesForPosts(List<Map<String, dynamic>> posts) async {
    // Extract unique user IDs that need fetching
    final Set<String> profileUserIds = {};

    for (final post in posts) {
      final userId = post['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        if (!_profileCache.containsKey(userId)) {
          profileUserIds.add(userId);
        }
      }
    }

    if (profileUserIds.isEmpty) return;

    // Fetch all profiles in parallel
    final profileFutures = profileUserIds.map((userId) async {
      try {
        final profileData = await _profileService.getProfileDataByUserId(
          userId,
        );
        return MapEntry(userId, profileData);
      } catch (e) {
        debugPrint('ERROR: Failed to fetch profile for user $userId: $e');
        return MapEntry(userId, null);
      }
    });

    // Wait for all fetches to complete in parallel
    final profileResults = await Future.wait(profileFutures);
    for (final result in profileResults) {
      if (result.value != null) {
        _profileCache[result.key] = result.value!;
      }
    }
  }

  JmPostCardData? _mapPostToCardData(Map<String, dynamic> post) {
    final rawTitle = (post['title'] ?? '').toString().trim();
    final rawBody = (post['body'] ?? '').toString().trim();
    final content = (post['content'] ?? '').toString().trim();
    if (rawTitle.isEmpty && rawBody.isEmpty && content.isEmpty) {
      return null;
    }

    String title = rawTitle;
    String body = rawBody;
    if (title.isEmpty) {
      final segments = content.split('\n\n');
      if (segments.isNotEmpty) {
        title = segments.first.trim();
        if (body.isEmpty && segments.length > 1) {
          body = segments.sublist(1).join('\n\n').trim();
        }
      }
    }
    if (body.isEmpty) {
      body = content.isNotEmpty ? content : title;
    }
    if (title.isEmpty) {
      title = 'Community Post';
    }

    final profile = post['profiles'] as Map<String, dynamic>?;
    final categoryMap = post['categories'] as Map<String, dynamic>?;
    final locationMap = post['locations'] as Map<String, dynamic>?;

    final username = (post['username'] ?? profile?['username'] ?? '@pal_user')
        .toString();
    final category = (post['category_name'] ?? categoryMap?['name'] ?? '')
        .toString();
    final location = (post['location_name'] ?? locationMap?['name'] ?? '')
        .toString();

    // Get user_id from post
    final userId = post['user_id']?.toString();

    // Fetch profile picture URL from cached profile data (via get-profile edge function)
    String? profilePictureUrl;
    String? initials;

    if (userId != null && _profileCache.containsKey(userId)) {
      final cachedProfile = _profileCache[userId]!;
      profilePictureUrl =
          cachedProfile.pictureUrl; // Uses profile_picture_url or avatar_url
      initials = cachedProfile.initials;
    }

    // Fallback to post data if cache doesn't have profile yet
    if (profilePictureUrl == null || profilePictureUrl.isEmpty) {
      profilePictureUrl =
          (post['profile_picture_url'] ??
                  profile?['profile_picture_url'] ??
                  post['avatar_url'] ??
                  profile?['avatar_url'])
              ?.toString();
    }

    // Generate initials from username if not available from cached profile
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
      post['comments_count'] ?? post['comment_count'] ?? post['replies_count'],
    );
    final votes = _parseInt(
      post['votes'] ??
          post['upvote_count'] ??
          post['engagement_score'] ??
          post['net_score'],
    );

    return JmPostCardData(
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
      // Don't set avatarAsset for backend posts - let them show initials if no profile picture
      // Only hardcoded seed posts should have avatarAsset set
      avatarAsset: null,
      profilePictureUrl: profilePictureUrl,
      initials: initials,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _UpvotedPostsHeader(
              totalPosts: _totalUpvotedPosts,
              profileData: _profileData,
              isLoading: _isLoading,
            ),
            Expanded(
              child: Container(
                color: _pageBackground,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _posts.isEmpty
                    ? const Center(child: Text('No upvoted posts yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(15, 24, 15, 32),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return Align(
                            alignment: Alignment.center,
                            child: JmPostCard(
                              data: post,
                              isYourPosts: false,
                              showOverflowMenu: false,
                              isUpvotedPostsScreen: true,
                            ),
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

class _UpvotedPostsHeader extends StatelessWidget {
  const _UpvotedPostsHeader({
    required this.totalPosts,
    this.profileData,
    this.isLoading = false,
  });

  final int totalPosts;
  final ProfileData? profileData;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_left,
                size: 24,
                color: Color(0xFF45556C),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: const Color(0xFF0F172B),
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isLoading
                        ? _ProfileShimmer(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : profileData != null && profileData!.hasPicture
                            ? Image.network(
                                profileData!.pictureUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    ProfileAvatarWidget(
                                      imageUrl: null,
                                      initials: profileData!.initials,
                                      size: 32,
                                    ),
                              )
                            : ProfileAvatarWidget(
                                imageUrl: null,
                                initials: profileData?.initials ?? 'U',
                                size: 32,
                              ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Posts You Upvoted',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _headerTitleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _headerMetaColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$totalPosts posts',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _headerSubtitleColor,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profileData?.formattedUsername ?? '@user',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _headerSubtitleColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
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

class _ProfileShimmer extends StatefulWidget {
  const _ProfileShimmer({required this.child});

  final Widget child;

  @override
  State<_ProfileShimmer> createState() => _ProfileShimmerState();
}

class _ProfileShimmerState extends State<_ProfileShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE6EBF2),
                Color(0xFFFFFFFF),
                Color(0xFFE6EBF2),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4 transform(Rect bounds, {ui.TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (percent * 2 - 1),
      0.0,
      0.0,
    );
  }
}
