import 'package:flutter/material.dart';
import 'package:pal/screens/feed/widgets/post_card.dart';
import 'package:pal/services/post_service.dart';
import 'package:pal/services/profile_service.dart';
import 'package:pal/widgets/profile_avatar_widget.dart';
import 'package:intl/intl.dart';

const _pageBackground = Color(0xFFF7FBFF);
const _headerTitleColor = Color(0xFF0F172B);
const _headerSubtitleColor = Color(0xFF45556C);
const _headerMetaColor = Color(0xFF62748E);

class UpvotedPostsScreen extends StatefulWidget {
  const UpvotedPostsScreen({super.key});

  static const routeName = '/settings/upvoted-posts';

  @override
  State<UpvotedPostsScreen> createState() => _UpvotedPostsScreenState();
}

class _UpvotedPostsScreenState extends State<UpvotedPostsScreen> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  
  List<PostCardData> _posts = [];
  ProfileData? _profileData;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalUpvotedPosts = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch upvoted posts and profile in parallel
      final results = await Future.wait([
        _postService.getUpvotedPosts(limit: 100, offset: 0),
        _profileService.getProfileData(),
      ]);

      if (!mounted) return;

      final postsResponse = results[0] as Map<String, dynamic>;
      final profileData = results[1] as ProfileData?;

      final postsList = postsResponse['posts'] as List<dynamic>? ?? [];
      final totalUpvoted = postsResponse['total_upvoted_posts'] as int? ?? postsList.length;
      final mappedPosts = postsList
          .map((post) => _mapPostToCardData(post as Map<String, dynamic>))
          .whereType<PostCardData>()
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

  PostCardData? _mapPostToCardData(Map<String, dynamic> post) {
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

    // Extract profile picture URL
    String? profilePictureUrl = (post['profile_picture_url'] ?? 
        profile?['profile_picture_url'] ?? 
        post['avatar_url'] ?? 
        profile?['avatar_url'])?.toString();

    // Generate initials from username
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
    final initials = generateInitials(username);

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
            ),
            Expanded(
              child: Container(
                color: _pageBackground,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
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
                            ? const Center(
                                child: Text('No upvoted posts yet'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(15, 24, 15, 32),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  final post = _posts[index];
                                  return Align(
                                    alignment: Alignment.center,
                                    child: PostCard(data: post, isYourPosts: false),
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
  });

  final int totalPosts;
  final ProfileData? profileData;

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
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF0F172B),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: profileData != null && profileData!.hasPicture
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
                      const SizedBox(height: 4),
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

