import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'jm_settings_screen.dart';
import '../../services/app_cache.dart';

class JmContentCuratorQueueScreen extends StatefulWidget {
  const JmContentCuratorQueueScreen({super.key});

  @override
  State<JmContentCuratorQueueScreen> createState() =>
      _JmContentCuratorQueueScreenState();
}

class _JmContentCuratorQueueScreenState
    extends State<JmContentCuratorQueueScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedTab = 'Comments'; // 'Posts', 'Comments' - Comments is default
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  List<Map<String, dynamic>> _extractList(dynamic data, String key) {
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map) {
      final inner = data['data'] ?? data;
      if (inner is Map && inner.containsKey(key)) {
        return List<Map<String, dynamic>>.from((inner[key] as List?) ?? []);
      }
      if (data.containsKey(key)) {
        return List<Map<String, dynamic>>.from((data[key] as List?) ?? []);
      }
    }
    return [];
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check both caches — return early only if both are filled
      final cachedPosts = await AppCache().getCcQueuePosts();
      final cachedComments = await AppCache().getCcQueueCommentsNew();
      if (cachedPosts.isNotEmpty && cachedComments.isNotEmpty) {
        final posts = _extractList(cachedPosts, 'posts');
        final comments = _extractList(cachedComments, 'comments');
        debugPrint('[JmCuratorQueue] from cache: ${posts.length} posts, ${comments.length} comments');
        if (mounted) {
          setState(() {
            _posts = posts;
            _comments = comments;
            _isLoading = false;
          });
        }
        return;
      }

      final results = await Future.wait([
        _supabase.functions.invoke(
          'get-content-curator-queue-posts',
          queryParameters: {
            'queue_type': 'new',
            'limit': '20',
            'offset': '0',
          },
        ),
        _supabase.functions.invoke(
          'get-content-curator-queue-comments',
          queryParameters: {
            'queue_type': 'new',
            'limit': '20',
            'offset': '0',
          },
        ),
      ]);

      final postsResponse = results[0];
      final commentsResponse = results[1];

      debugPrint('[JmCuratorQueue] posts raw=${postsResponse.data}');
      debugPrint('[JmCuratorQueue] comments raw=${commentsResponse.data}');

      setState(() {
        _posts = _extractList(postsResponse.data, 'posts');
        _comments = _extractList(commentsResponse.data, 'comments');
        _isLoading = false;
      });

      debugPrint('[JmCuratorQueue] parsed ${_posts.length} posts, ${_comments.length} comments');
    } catch (e) {
      debugPrint('[JmCuratorQueue] Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';
    if (raw is num) {
      final seconds = raw.toInt();
      if (seconds < 60) return 'just now';
      if (seconds < 3600) return '${seconds ~/ 60}m ago';
      if (seconds < 86400) return '${seconds ~/ 3600}h ago';
      return '${seconds ~/ 86400}d ago';
    }
    if (raw is String) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inSeconds < 60) return 'just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      }
      return raw;
    }
    final seconds = int.tryParse(raw.toString()) ?? 0;
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return '${seconds ~/ 60}m ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ago';
    return '${seconds ~/ 86400}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159),
                      child: SvgPicture.asset(
                        'assets/adminIcons/adminSettings/Icon-2.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Content Curator Queue',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 36 / 20,
                        letterSpacing: 0.07,
                        color: Color(0xFF0F172B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(15, 8, 15, 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton('Posts', _selectedTab == 'Posts'),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'Comments',
                      _selectedTab == 'Comments',
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFF62748E)),
                              const SizedBox(height: 12),
                              const Text(
                                'Failed to load queue',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF62748E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _fetchData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 120),
                          child: _buildContentForTab(),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PalBottomNavigationBar(
          active: PalNavDestination.settings,
          onHomeTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacementNamed('/home');
          },
          onNotificationsTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
          onSettingsTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const JmSettingsScreen()),
            );
          },
        ),
    );
  }

  Widget _buildContentForTab() {
    switch (_selectedTab) {
      case 'Comments':
        return _buildCommentsContent();
      case 'Posts':
      default:
        return _buildPostsContent();
    }
  }

  Widget _buildPostsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEW QUEUE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF62748E),
            letterSpacing: 0.6,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        if (_posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No posts in queue',
                  style: TextStyle(color: Color(0xFF62748E), fontFamily: 'Inter', fontSize: 14)),
            ),
          )
        else
          ..._posts.map((p) {
            final author = p['user'] ?? p['author'] ?? {};
            final username = author is Map ? (author['username'] ?? 'unknown') : 'unknown';
            final location = p['location'] is Map
                ? (p['location']['display_name'] ?? p['location']['name'] ?? '')
                : (p['location_name'] ?? '');
            final category = p['category'] is Map
                ? (p['category']['display_name'] ?? p['category']['name'] ?? '')
                : (p['category_name'] ?? '');
            final timeAgo = _formatTimeAgo(p['time_ago'] ?? p['created_at']);
            return _buildPostCard(
              username: '@$username',
              timeAgo: timeAgo,
              initials: username.length >= 2
                  ? username.substring(0, 2).toUpperCase()
                  : username.toUpperCase(),
              location: location,
              topic: category,
              title: p['title'] ?? '',
              body: p['content'] ?? '',
              voteCount: (p['net_votes'] as num?)?.toInt() ?? (p['vote_count'] as num?)?.toInt() ?? 0,
              commentCount: (p['comment_count'] as num?)?.toInt() ?? 0,
            );
          }),
      ],
    );
  }

  Widget _buildCommentsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEW QUEUE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF62748E),
            letterSpacing: 0.6,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No comments in queue',
                  style: TextStyle(color: Color(0xFF62748E), fontFamily: 'Inter', fontSize: 14)),
            ),
          )
        else
          ..._comments.map((c) {
            final author = c['user'] ?? c['author'] ?? {};
            final username = author is Map ? (author['username'] ?? 'unknown') : 'unknown';
            final timeAgo = _formatTimeAgo(c['time_ago'] ?? c['created_at']);
            return _buildCommentCard(
              username: '@$username',
              timeAgo: timeAgo,
              initials: username.length >= 2
                  ? username.substring(0, 2).toUpperCase()
                  : username.toUpperCase(),
              comment: c['content'] ?? '',
              voteCount: (c['net_votes'] as num?)?.toInt() ?? (c['vote_count'] as num?)?.toInt() ?? 0,
            );
          }),
      ],
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        height: 29,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172B) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF0F172B),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required String username,
    required String timeAgo,
    required String initials,
    required String location,
    required String topic,
    required String title,
    required String body,
    required int voteCount,
    required int commentCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar, username, badges, and voting
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with border
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F172B), width: 3),
                ),
                child: ClipOval(
                  child: ProfileAvatarWidget(
                    imageUrl: null,
                    initials: initials,
                    size: 41,
                    borderWidth: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Username and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username.startsWith('@') ? username : '@$username',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172B),
                            fontFamily: 'Inter',
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF90A1B9),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF62748E),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location and topic badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.756,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/images/locationIcon.svg',
                                width: 12,
                                height: 12,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF45556C),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF45556C),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF7BF1A8),
                              width: 0.756,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/images/askIcon.svg',
                                width: 12,
                                height: 12,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF008236),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ask',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF008236),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Voting section
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 0.756,
                  vertical: 8.756,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 0.756,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.asset(
                        'assets/images/upArrow.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF45556C),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voteCount.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172B),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.asset(
                        'assets/images/downArrow.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF45556C),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post title (starts from left edge)
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172B),
              fontFamily: 'Inter',
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 12),
          // Post body (starts from left edge)
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF45556C),
              fontFamily: 'Inter',
              letterSpacing: -0.15,
              height: 1.625,
            ),
          ),
          const SizedBox(height: 12),
          // Comment count (starts from left edge)
          Row(
            children: [
              SvgPicture.asset(
                'assets/settings/commentIcon.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF45556C),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$commentCount comment${commentCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF45556C),
                  fontFamily: 'Inter',
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard({
    required String username,
    required String timeAgo,
    required String initials,
    required String comment,
    required int voteCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with border
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
            child: ClipOval(
              child: ProfileAvatarWidget(
                imageUrl: null,
                initials: initials,
                size: 29,
                borderWidth: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172B),
                        fontFamily: 'Inter',
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF90A1B9),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF62748E),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF45556C),
                    fontFamily: 'Inter',
                    letterSpacing: -0.15,
                    height: 1.625,
                  ),
                ),
                const SizedBox(height: 6),
                // Voting section
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.asset(
                        'assets/images/upArrow.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF45556C),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 6),
                    Text(
                      voteCount.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF314158),
                        fontFamily: 'Inter',
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.asset(
                        'assets/images/downArrow.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF45556C),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
