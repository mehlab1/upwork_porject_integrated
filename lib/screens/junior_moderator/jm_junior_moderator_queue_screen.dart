import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'jm_settings_screen.dart';
import '../../services/app_cache.dart';

class JmJuniorModeratorQueueScreen extends StatefulWidget {
  const JmJuniorModeratorQueueScreen({super.key});

  @override
  State<JmJuniorModeratorQueueScreen> createState() =>
      _JmJuniorModeratorQueueScreenState();
}

class _JmJuniorModeratorQueueScreenState
    extends State<JmJuniorModeratorQueueScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedTab = 'Posts'; // 'Posts', 'Comments'
  bool _isLoading = true;
  String? _error;

  List<dynamic> _newPosts = [];
  List<dynamic> _historyPosts = [];

  List<dynamic> _newComments = [];
  List<dynamic> _historyComments = [];

  @override
  void initState() {
    super.initState();
    _fetchAllQueues();
  }

  Future<void> _fetchAllQueues() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      await Future.wait([
        _fetchPosts('new'),
        _fetchPosts('history'),
        _fetchComments('new'),
        _fetchComments('history'),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[JmJrModQueue] error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Safely extract a list from edge-function response data.
  List<dynamic> _extractList(dynamic data, String key) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'] ?? data;
      if (inner is Map && inner.containsKey(key)) {
        return (inner[key] as List?) ?? [];
      }
      return (data[key] as List?) ?? [];
    }
    return [];
  }

  Future<void> _fetchPosts(String queueType) async {
    if (queueType == 'new') {
      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final cached = await AppCache().getJmQueuePosts();
      if (cached.isNotEmpty) {
        final posts = _extractList(cached, 'posts');
        debugPrint('[JmJrModQueue] posts (new) from cache: ${posts.length}');
        _newPosts = posts;
        return;
      }
    } else {
      // Use AppCache for history too
      final cached = await AppCache().getJmQueuePostsHistory();
      if (cached.isNotEmpty) {
        final posts = _extractList(cached, 'posts');
        debugPrint('[JmJrModQueue] posts (history) from cache: ${posts.length}');
        _historyPosts = posts;
        return;
      }
    }

    final user = _supabase.auth.currentUser;

    final response = await _supabase.functions.invoke(
      'get-junior-moderator-queue-posts',
      method: HttpMethod.get,
      queryParameters: {
        'p_moderator_id': user!.id,
        'p_queue_type': queueType,
        'p_limit': '20',
        'p_offset': '0',
      },
    );

    debugPrint('[JmJrModQueue] posts ($queueType) raw: ${response.data}');
    final posts = _extractList(response.data, 'posts');
    debugPrint('[JmJrModQueue] posts ($queueType) parsed count: ${posts.length}');

    if (queueType == 'new') {
      _newPosts = posts;
    } else {
      _historyPosts = posts;
    }
  }

  Future<void> _fetchComments(String queueType) async {
    if (queueType == 'new') {
      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final cached = await AppCache().getJmQueueCommentsNew();
      if (cached.isNotEmpty) {
        _newComments = _extractList(cached, 'comments');
        debugPrint('[JmJrModQueue] comments (new) from cache: ${_newComments.length}');
        return;
      }
    } else {
      // Use AppCache for history too
      final cached = await AppCache().getJmQueueCommentsHistory();
      if (cached.isNotEmpty) {
        _historyComments = _extractList(cached, 'comments');
        debugPrint('[JmJrModQueue] comments (history) from cache: ${_historyComments.length}');
        return;
      }
    }

    final user = _supabase.auth.currentUser;

    final response = await _supabase.functions.invoke(
      'get-junior-moderator-queue-comments',
      method: HttpMethod.get,
      queryParameters: {
        'p_moderator_id': user!.id,
        'p_queue_type': queueType,
        'p_limit': '20',
        'p_offset': '0',
      },
    );

    debugPrint('[JmJrModQueue] comments ($queueType) raw: ${response.data}');
    final comments = _extractList(response.data, 'comments');
    debugPrint('[JmJrModQueue] comments ($queueType) parsed count: ${comments.length}');

    if (queueType == 'new') {
      _newComments = comments;
    } else {
      _historyComments = comments;
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
                      'Junior Moderator Queue',
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
                                onPressed: _fetchAllQueues,
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
    if (_selectedTab == 'Posts') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEW QUEUE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF62748E),
                  letterSpacing: 0.6,
                  fontFamily: 'Inter')),
          const SizedBox(height: 12),
          if (_newPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No new posts in queue',
                    style: TextStyle(color: Color(0xFF62748E), fontFamily: 'Inter', fontSize: 14)),
              ),
            )
          else
            ..._newPosts.map((post) => _buildPostCardFromData(post)).toList(),
          const SizedBox(height: 32),
          const Text('HISTORY',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF62748E),
                  letterSpacing: 0.6,
                  fontFamily: 'Inter')),
          const SizedBox(height: 12),
          if (_historyPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No history available',
                    style: TextStyle(color: Color(0xFF62748E), fontFamily: 'Inter', fontSize: 14)),
              ),
            )
          else
            ..._historyPosts.map((post) => _buildPostCardFromData(post)).toList(),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEW QUEUE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF62748E),
                  letterSpacing: 0.6,
                  fontFamily: 'Inter')),
          const SizedBox(height: 12),
          if (_newComments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No new comments in queue',
                    style: TextStyle(color: Color(0xFF62748E), fontFamily: 'Inter', fontSize: 14)),
              ),
            )
          else
            ..._newComments
                .map((comment) => _buildCommentCardFromData(comment))
                .toList(),
          const SizedBox(height: 32),
          const Text('HISTORY',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF62748E),
                  letterSpacing: 0.6,
                  fontFamily: 'Inter')),
          const SizedBox(height: 12),
          if (_historyComments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No history available',
                    style: TextStyle(color: Color(0xFF62748E), fontFamily: 'Inter', fontSize: 14)),
              ),
            )
          else
            ..._historyComments
                .map((comment) => _buildCommentCardFromData(comment))
                .toList(),
        ],
      );
    }
  }

  Widget _buildTabButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        height: 29,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172B) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF0F172B), fontFamily: 'Inter')),
      ),
    );
  }

  // Build Post Card from API data
  Widget _buildPostCardFromData(dynamic post) {
    final postUser = post['user'] ?? post['author'];
    final username = postUser?['username'] ?? post['username'] ?? '';
    return _buildPostCard(
      username: '@$username',
      timeAgo: _formatTimeAgo(post['time_ago'] ?? post['created_at']),
      initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
      location: post['location'] is Map
          ? (post['location']['display_name'] ?? '')
          : (post['location']?.toString() ?? ''),
      topic: post['category'] is Map
          ? (post['category']['display_name'] ?? '')
          : (post['category']?.toString() ?? ''),
      title: post['title'] ?? '',
      body: post['content'] ?? '',
      voteCount: (post['net_votes'] as num?)?.toInt() ?? (post['net_score'] as num?)?.toInt() ?? 0,
      commentCount: (post['comment_count'] as num?)?.toInt() ?? 0,
    );
  }

  // Build Comment Card from API data
  Widget _buildCommentCardFromData(dynamic comment) {
    final commentUser = comment['user'] ?? comment['author'];
    final username = commentUser?['username'] ?? comment['username'] ?? '';
    return _buildCommentCard(
      username: '@$username',
      timeAgo: _formatTimeAgo(comment['time_ago'] ?? comment['created_at']),
      initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
      comment: comment['content'] ?? '',
      voteCount: (comment['net_votes'] as num?)?.toInt() ?? (comment['net_score'] as num?)?.toInt() ?? 0,
    );
  }

  Widget _buildPostCard({
    required String username, required String timeAgo, required String initials,
    required String location, required String topic, required String title,
    required String body, required int voteCount, required int commentCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final maxCardWidth = 360.0;
        final cardWidth = screenWidth < maxCardWidth ? screenWidth - 30 : maxCardWidth;
        
        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.76),
          ),
          padding: const EdgeInsets.only(top: 0, left: 0, right: 16, bottom: 16),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47, height: 47,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F172B), width: 3)),
                child: ClipOval(child: ProfileAvatarWidget(imageUrl: null, initials: initials, size: 41, borderWidth: 0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(username.startsWith('@') ? username : '@$username', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172B), fontFamily: 'Inter', letterSpacing: -0.15)),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(fontSize: 12, color: Color(0xFF90A1B9), fontFamily: 'Inter')),
                      const SizedBox(width: 8),
                      Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF62748E), fontFamily: 'Inter')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SvgPicture.asset('assets/images/locationIcon.svg', width: 12, height: 12, colorFilter: const ColorFilter.mode(Color(0xFF45556C), BlendMode.srcIn)),
                          const SizedBox(width: 6),
                          Text(location, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF45556C), fontFamily: 'Inter')),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF7BF1A8), width: 0.756)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SvgPicture.asset('assets/images/askIcon.svg', width: 12, height: 12, colorFilter: const ColorFilter.mode(Color(0xFF008236), BlendMode.srcIn)),
                          const SizedBox(width: 6),
                          const Text('Ask', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF008236), fontFamily: 'Inter')),
                        ]),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 0.756, vertical: 8.756),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: SvgPicture.asset('assets/images/upArrow.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF45556C), BlendMode.srcIn)), onPressed: () {}),
                  const SizedBox(height: 4),
                  Text(voteCount.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172B), fontFamily: 'Inter')),
                  const SizedBox(height: 4),
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: SvgPicture.asset('assets/images/downArrow.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF45556C), BlendMode.srcIn)), onPressed: () {}),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172B), fontFamily: 'Inter', letterSpacing: -0.31)),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF45556C), fontFamily: 'Inter', letterSpacing: -0.15, height: 1.625)),
          const SizedBox(height: 12),
          Row(children: [
            SvgPicture.asset('assets/settings/commentIcon.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF45556C), BlendMode.srcIn)),
            const SizedBox(width: 8),
            Text('$commentCount comment${commentCount != 1 ? 's' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF45556C), fontFamily: 'Inter', letterSpacing: -0.15)),
          ]),
        ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentCard({
    required String username, required String timeAgo, required String initials,
    required String comment, required int voteCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0), width: 2)), child: ClipOval(child: ProfileAvatarWidget(imageUrl: null, initials: initials, size: 29, borderWidth: 0))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172B), fontFamily: 'Inter', letterSpacing: -0.15)),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(fontSize: 12, color: Color(0xFF90A1B9), fontFamily: 'Inter')),
                  const SizedBox(width: 8),
                  Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF62748E), fontFamily: 'Inter')),
                ]),
                const SizedBox(height: 6),
                Text(comment, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF45556C), fontFamily: 'Inter', letterSpacing: -0.15, height: 1.625)),
                const SizedBox(height: 6),
                Row(children: [
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: SvgPicture.asset('assets/images/upArrow.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF45556C), BlendMode.srcIn)), onPressed: () {}),
                  const SizedBox(width: 6),
                  Text(voteCount.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF314158), fontFamily: 'Inter', letterSpacing: -0.15)),
                  const SizedBox(width: 6),
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: SvgPicture.asset('assets/images/downArrow.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF45556C), BlendMode.srcIn)), onPressed: () {}),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
