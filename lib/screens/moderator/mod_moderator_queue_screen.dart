// // ============================================================
// // HARDCODED VERSION (commented out) - replaced with edge function integration
// // ============================================================
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../widgets/pal_bottom_nav_bar.dart';
// import '../../widgets/profile_avatar_widget.dart';
// import 'moderator_settings_screen.dart';
//
// class ModModeratorQueueScreen extends StatefulWidget {
//   const ModModeratorQueueScreen({super.key});
//
//   @override
//   State<ModModeratorQueueScreen> createState() => _ModModeratorQueueScreenState();
// }
//
// class _ModModeratorQueueScreenState extends State<ModModeratorQueueScreen> {
//   String _selectedTab = 'Posts'; // 'Posts', 'Comments', 'Users'
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FBFF),
//       body: SafeArea(
//         bottom: false,
//         child: Column(
//           children: [
//             // Header
//             Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 border: Border(
//                   bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
//                 ),
//               ),
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.of(context).pop(),
//                     child: Transform(
//                       alignment: Alignment.center,
//                       transform: Matrix4.rotationY(
//                         3.14159,
//                       ), // Flip horizontally
//                       child: SvgPicture.asset(
//                         'assets/adminIcons/adminSettings/Icon-2.svg',
//                         width: 16,
//                         height: 16,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Text(
//                       'Moderator Queue',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontWeight: FontWeight.w500,
//                         fontSize: 20,
//                         height: 36 / 20,
//                         letterSpacing: 0.07,
//                         color: Color(0xFF0F172B),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Tabs
//             Container(
//               margin: const EdgeInsets.fromLTRB(15, 8, 15, 0),
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF1F5F9),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: _buildTabButton('Posts', _selectedTab == 'Posts'),
//                   ),
//                   Expanded(
//                     child: _buildTabButton(
//                       'Comments',
//                       _selectedTab == 'Comments',
//                     ),
//                   ),
//                   Expanded(
//                     child: _buildTabButton('Users', _selectedTab == 'Users'),
//                   ),
//                 ],
//               ),
//             ),
//             // Content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(15, 12, 15, 120),
//                 child: _buildContentForTab(),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: PalBottomNavigationBar(
//         active: PalNavDestination.settings,
//         onHomeTap: () {
//           Navigator.of(context).popUntil((route) => route.isFirst);
//           Navigator.of(context).pushReplacementNamed('/home');
//         },
//         onNotificationsTap: () {
//           Navigator.pushNamed(context, '/notifications');
//         },
//         onSettingsTap: () {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (_) => const ModeratorSettingsScreen()),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildContentForTab() {
//     switch (_selectedTab) {
//       case 'Comments':
//         return _buildCommentsContent();
//       case 'Users':
//         return _buildUsersContent();
//       case 'Posts':
//       default:
//         return _buildPostsContent();
//     }
//   }
//
//   Widget _buildPostsContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'NEW QUEUE',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             fontStyle: FontStyle.normal,
//             height: 16 / 14,
//             letterSpacing: 0.6,
//             color: Color(0xFF62748E),
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildPostCard(
//           username: '@party_person',
//           timeAgo: '5d ago',
//           initials: 'PA',
//           location: 'Surulere',
//           topic: 'Ask',
//           title: 'Surulere nightlife - Where\'s the party at?',
//           body:
//               'Looking for good nightlife spots in Surulere. Not too expensive but with good music and vibes. What are your favorites? Clubs, bars, lounges?',
//           voteCount: 87,
//           commentCount: 1,
//         ),
//         const SizedBox(height: 32),
//         const Text(
//           'HISTORY',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             fontStyle: FontStyle.normal,
//             height: 16 / 14,
//             letterSpacing: 0.6,
//             color: Color(0xFF62748E),
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildPostCard(
//           username: '@ikoyi_newbie',
//           timeAgo: '4d ago',
//           initials: 'IK',
//           location: 'Ikoyi',
//           topic: 'Ask',
//           title: 'Best places to hang out in Ikoyi on weekends?',
//           body:
//               'Just moved to Ikoyi and looking for cool spots to relax on weekends. Restaurants, lounges, parks - what do you recommend? Not trying to break the bank but willing to spend for quality.',
//           voteCount: 142,
//           commentCount: 1,
//         ),
//         const SizedBox(height: 12),
//         _buildPostCard(
//           username: '@party_person',
//           timeAgo: '5d ago',
//           initials: 'PA',
//           location: 'Surulere',
//           topic: 'Ask',
//           title: 'Surulere nightlife - Where\'s the party at?',
//           body:
//               'Looking for good nightlife spots in Surulere. Not too expensive but with good music and vibes. What are your favorites? Clubs, bars, lounges?',
//           voteCount: 87,
//           commentCount: 1,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCommentsContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'NEW QUEUE',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             fontStyle: FontStyle.normal,
//             height: 16 / 14,
//             letterSpacing: 0.6,
//             color: Color(0xFF62748E),
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildCommentCard(
//           username: '@lagosian_boy',
//           timeAgo: '1h ago',
//           initials: 'LB',
//           comment:
//               'You NEED to try the one at Yellow Chilli! Best I\'ve ever had, hands down.',
//           voteCount: 45,
//         ),
//         const SizedBox(height: 12),
//         _buildCommentCard(
//           username: '@naija_gourmet',
//           timeAgo: '30m ago',
//           initials: 'NG',
//           comment:
//               'Party jollof is undefeated! There\'s something about that smoky flavor from the firewood.',
//           voteCount: 38,
//         ),
//         const SizedBox(height: 32),
//         const Text(
//           'HISTORY',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             fontStyle: FontStyle.normal,
//             height: 16 / 14,
//             letterSpacing: 0.6,
//             color: Color(0xFF62748E),
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildCommentCard(
//           username: '@lagosian_boy',
//           timeAgo: '1h ago',
//           initials: 'LB',
//           comment:
//               'You NEED to try the one at Yellow Chilli! Best I\'ve ever had, hands down.',
//           voteCount: 45,
//         ),
//         const SizedBox(height: 12),
//         _buildCommentCard(
//           username: '@naija_gourmet',
//           timeAgo: '30m ago',
//           initials: 'NG',
//           comment:
//               'Party jollof is undefeated! There\'s something about that smoky flavor from the firewood.',
//           voteCount: 38,
//         ),
//         const SizedBox(height: 12),
//         _buildCommentCard(
//           username: '@anonymous',
//           timeAgo: 'just now',
//           initials: 'AN',
//           comment: 'checking',
//           voteCount: 1,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildUsersContent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'PENDING REVIEW',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             fontStyle: FontStyle.normal,
//             height: 16 / 14,
//             letterSpacing: 0.6,
//             color: Color(0xFF62748E),
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildUserCard(
//           username: '@foodie_naija',
//           initials: 'FN',
//           trustScore: 80,
//           status: 'pending',
//         ),
//         const SizedBox(height: 12),
//         _buildUserCard(
//           username: '@foodie_naija',
//           initials: 'FN',
//           trustScore: 80,
//           status: 'pending',
//         ),
//         const SizedBox(height: 32),
//         const Text(
//           'RESOLVED',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             fontStyle: FontStyle.normal,
//             height: 16 / 14,
//             letterSpacing: 0.6,
//             color: Color(0xFF62748E),
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildUserCard(
//           username: '@foodie_naija',
//           initials: 'FN',
//           trustScore: null,
//           status: 'resolved',
//           actionType: 'shadow_ban',
//         ),
//         const SizedBox(height: 12),
//         _buildUserCard(
//           username: '@foodie_naija',
//           initials: 'FN',
//           trustScore: null,
//           status: 'resolved',
//           actionType: 'suspended',
//         ),
//         const SizedBox(height: 12),
//         _buildUserCard(
//           username: '@foodie_naija',
//           initials: 'FN',
//           trustScore: null,
//           status: 'resolved',
//           actionType: 'banned',
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTabButton(String label, bool isActive) { ... }
//   Widget _buildPostCard({...}) { ... }
//   Widget _buildCommentCard({...}) { ... }
//   Widget _buildUserCard({...}) { ... }
//   Widget _buildActionButton(String actionType) { ... }
// }
// // ============================================================
// // END OF HARDCODED VERSION
// // ============================================================

import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'moderator_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_cache.dart';

class ModModeratorQueueScreen extends StatefulWidget {
  const ModModeratorQueueScreen({super.key});

  @override
  State<ModModeratorQueueScreen> createState() =>
      _ModModeratorQueueScreenState();
}

class _ModModeratorQueueScreenState
    extends State<ModModeratorQueueScreen> {

  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  int _selectedTabIndex = 0;

  // POSTS
  List<dynamic> _newPosts = [];
  List<dynamic> _historyPosts = [];

  // COMMENTS
  List<dynamic> _newComments = [];
  List<dynamic> _historyComments = [];

  // USERS
  List<dynamic> _pendingUsers = [];
  List<dynamic> _resolvedUsers = [];

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
      if (user == null) {
        throw Exception("User not authenticated");
      }

      await Future.wait([
        _fetchPosts('new'),
        _fetchPosts('history'),
        _fetchComments('new'),
        _fetchComments('history'),
        _fetchUsers('new'),
        _fetchUsers('history'),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Safely extract a list from edge-function response data.
  /// Handles: { success, data: { posts: [...] } }  OR  { posts: [...] }  OR  [...]
  List<dynamic> _extractList(dynamic data, String key) {
    if (data is List) return data;
    if (data is Map) {
      // Unwrap { success, data: { ... } } envelope first
      final inner = data['data'] ?? data;
      if (inner is Map && inner.containsKey(key)) {
        return (inner[key] as List?) ?? [];
      }
      // Fallback: try key directly on outer map
      return (data[key] as List?) ?? [];
    }
    return [];
  }

  /// Convert time_ago (seconds as num) to a human-readable string.
  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';
    final seconds = (raw is num) ? raw.toInt() : int.tryParse(raw.toString()) ?? 0;
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return '${seconds ~/ 60}m ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ago';
    return '${seconds ~/ 86400}d ago';
  }

  // ================= POSTS =================

  Future<void> _fetchPosts(String queueType) async {
    if (queueType == 'new') {
      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final cached = await AppCache().getModQueuePosts();
      if (cached.isNotEmpty) {
        final posts = _extractList(cached, 'posts');
        debugPrint('[ModQueue] posts (new) from cache: ${posts.length}');
        _newPosts = posts;
        return;
      }
    } else {
      // Use AppCache for history too
      final cached = await AppCache().getModQueuePostsHistory();
      if (cached.isNotEmpty) {
        final posts = _extractList(cached, 'posts');
        debugPrint('[ModQueue] posts (history) from cache: ${posts.length}');
        _historyPosts = posts;
        return;
      }
    }

    final user = _supabase.auth.currentUser;

    final response = await _supabase.functions.invoke(
      'get-moderator-queue-posts',
      method: HttpMethod.get,
      queryParameters: {
        'p_moderator_id': user!.id,
        'p_queue_type': queueType,
        'p_limit': '20',
        'p_offset': '0',
      },
    );

    debugPrint('[ModQueue] posts ($queueType) raw: ${response.data}');
    final posts = _extractList(response.data, 'posts');

    if (queueType == 'new') {
      _newPosts = posts;
    } else {
      _historyPosts = posts;
    }
  }

  // ================= COMMENTS =================

  Future<void> _fetchComments(String queueType) async {
    if (queueType == 'new') {
      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final cached = await AppCache().getModQueueCommentsNew();
      if (cached.isNotEmpty) {
        _newComments = _extractList(cached, 'comments');
        debugPrint('[ModQueue] comments (new) from cache: ${_newComments.length}');
        return;
      }
    } else {
      // Use AppCache for history too
      final cached = await AppCache().getModQueueCommentsHistory();
      if (cached.isNotEmpty) {
        _historyComments = _extractList(cached, 'comments');
        debugPrint('[ModQueue] comments (history) from cache: ${_historyComments.length}');
        return;
      }
    }

    final user = _supabase.auth.currentUser;

    final response = await _supabase.functions.invoke(
      'get-moderator-queue-comments',
      method: HttpMethod.get,
      queryParameters: {
        'p_moderator_id': user!.id,
        'p_queue_type': queueType,
        'p_limit': '20',
        'p_offset': '0',
      },
    );

    debugPrint('[ModQueue] comments ($queueType) raw: ${response.data}');
    final comments = _extractList(response.data, 'comments');

    if (queueType == 'new') {
      _newComments = comments;
    } else {
      _historyComments = comments;
    }
  }

  // ================= USERS =================

  Future<void> _fetchUsers(String queueType) async {
    if (queueType == 'new') {
      final cached = await AppCache().getModQueueUsersNew();
      if (cached.isNotEmpty) {
        _pendingUsers = _extractList(cached, 'users');
        debugPrint('[ModQueue] users (new) from cache: ${_pendingUsers.length}');
        return;
      }
    } else {
      final cached = await AppCache().getModQueueUsersHistory();
      if (cached.isNotEmpty) {
        _resolvedUsers = _extractList(cached, 'users');
        debugPrint('[ModQueue] users (history) from cache: ${_resolvedUsers.length}');
        return;
      }
    }

    final user = _supabase.auth.currentUser;

    final response = await _supabase.functions.invoke(
      'get-moderator-queue-users',
      method: HttpMethod.get,
      queryParameters: {
        'p_moderator_id': user!.id,
        'p_queue_type': queueType,
        'p_limit': '20',
        'p_offset': '0',
      },
    );

    debugPrint('[ModQueue] users ($queueType) raw: ${response.data}');
    final users = _extractList(response.data, 'users');

    if (queueType == 'new') {
      _pendingUsers = users;
    } else {
      _resolvedUsers = users;
    }
  }

  // ================= UI =================

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
                      transform: Matrix4.rotationY(
                        3.14159,
                      ), // Flip horizontally
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
                      'Moderator Queue',
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
                    child: _buildTabButton('Posts', _selectedTabIndex == 0, 0),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'Comments',
                      _selectedTabIndex == 1,
                      1,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton('Users', _selectedTabIndex == 2, 2),
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
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
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
            MaterialPageRoute(builder: (_) => const ModeratorSettingsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
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

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
            height: 16 / 14,
            letterSpacing: 0.6,
            color: Color(0xFF62748E),
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(dynamic post) {
    final postUser = post['user'] ?? post['author'];
    final username = postUser?['username'] ?? post['username'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildPostCard(
        username: '@$username',
        timeAgo: _formatTimeAgo(post['time_ago']),
        initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
        location: post['location'] is Map
            ? (post['location']['display_name'] ?? '')
            : (post['location']?.toString() ?? ''),
        topic: post['category'] is Map
            ? (post['category']['display_name'] ?? '')
            : (post['category']?.toString() ?? ''),
        title: post['title'] ?? '',
        body: post['content'] ?? '',
        voteCount: (post['net_votes'] as num?)?.toInt() ?? 0,
        commentCount: (post['comment_count'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    final commentUser = comment['user'] ?? comment['author'];
    final username = commentUser?['username'] ?? comment['username'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildCommentCard(
        username: '@$username',
        timeAgo: _formatTimeAgo(comment['time_ago']),
        initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
        comment: comment['content'] ?? '',
        voteCount: (comment['net_votes'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Widget _buildUserItem(dynamic user, {required String status}) {
    final username = user['username'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildUserCard(
        username: '@$username',
        initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
        trustScore: (user['trust_score'] as num?)?.toInt(),
        status: status,
        actionType: user['action_type'],
      ),
    );
  }

  Widget _buildContentForTab() {
    if (_selectedTabIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_newPosts.isNotEmpty) ...[
            _buildSectionHeader('NEW QUEUE'),
            ..._newPosts.map(_buildPostItem),
          ],
          if (_historyPosts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('HISTORY'),
            ..._historyPosts.map(_buildPostItem),
          ],
          if (_newPosts.isEmpty && _historyPosts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No posts in queue',
                    style: TextStyle(color: Color(0xFF62748E))),
              ),
            ),
        ],
      );
    }

    if (_selectedTabIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_newComments.isNotEmpty) ...[
            _buildSectionHeader('NEW QUEUE'),
            ..._newComments.map(_buildCommentItem),
          ],
          if (_historyComments.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('HISTORY'),
            ..._historyComments.map(_buildCommentItem),
          ],
          if (_newComments.isEmpty && _historyComments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No comments in queue',
                    style: TextStyle(color: Color(0xFF62748E))),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pendingUsers.isNotEmpty) ...[
          _buildSectionHeader('PENDING REVIEW'),
          ..._pendingUsers.map((u) => _buildUserItem(u, status: 'pending')),
        ],
        if (_resolvedUsers.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionHeader('RESOLVED'),
          ..._resolvedUsers.map((u) => _buildUserItem(u, status: 'resolved')),
        ],
        if (_pendingUsers.isEmpty && _resolvedUsers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('No users in queue',
                  style: TextStyle(color: Color(0xFF62748E))),
            ),
          ),
      ],
    );
  }

  // ===== CARD BUILDERS =====

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar, username, and voting
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
                        if (location.isNotEmpty)
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
                        if (location.isNotEmpty && topic.isNotEmpty)
                          const SizedBox(width: 8),
                        if (topic.isNotEmpty)
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
                                Text(
                                  topic,
                                  style: const TextStyle(
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
          // Post title
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
          // Post body
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
          // Comment count
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

  Widget _buildUserCard({
    required String username,
    required String initials,
    int? trustScore,
    required String status, // 'pending' or 'resolved'
    String? actionType, // 'shadow_ban', 'suspended', 'banned' (only for resolved)
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          ProfileAvatarWidget(
            imageUrl: null,
            initials: initials,
            size: 47,
            borderWidth: 0,
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172B),
                fontFamily: 'Inter',
                letterSpacing: -0.15,
              ),
            ),
          ),
          // Status indicator or action button
          if (status == 'pending' && trustScore != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: trustScore / 100,
                          strokeWidth: 3,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF155DFC),
                          ),
                        ),
                      ),
                      Text(
                        '$trustScore%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172B),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (status == 'resolved' && actionType != null)
            _buildActionButton(actionType),
        ],
      ),
    );
  }

  Widget _buildActionButton(String actionType) {
    String label;
    Color backgroundColor;

    switch (actionType) {
      case 'shadow_ban':
        label = 'Shadow Ban';
        backgroundColor = const Color(0xFF0F172B);
        break;
      case 'suspended':
        label = 'Suspended';
        backgroundColor = const Color(0xFF94292F);
        break;
      case 'banned':
        label = 'Banned';
        backgroundColor = const Color(0xFFE7000B);
        break;
      default:
        label = 'Action';
        backgroundColor = const Color(0xFF0F172B);
    }

    return Opacity(
      opacity: 0.5,
      child: Container(
        width: 123,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Inter',
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}
