// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../widgets/pal_bottom_nav_bar.dart';
// import 'moderator_settings_screen.dart';
// import '../feed/widgets/post_card.dart';

// class ModHotPostScreen extends StatefulWidget {
//   const ModHotPostScreen({super.key});

//   @override
//   State<ModHotPostScreen> createState() => _ModHotPostScreenState();
// }

// class _ModHotPostScreenState extends State<ModHotPostScreen> {
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
//                       'Hot Post',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontWeight: FontWeight.w500,
//                         fontSize: 20,
//                         height: 36 / 20, // line-height: 36px
//                         letterSpacing: 0.07,
//                         color: Color(0xFF0F172B),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(15, 28, 15, 120),
//                 child: _buildPostsContent(),
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

//   Widget _buildPostsContent() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final availableWidth = constraints.maxWidth;
//         final maxWidth = 600.0;
//         final cardWidth = availableWidth.clamp(360.0, maxWidth);
        
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Hottest Post Section
//             Align(
//               alignment: Alignment.center,
//               child: SizedBox(
//                 width: cardWidth,
//                 child: const Padding(
//                   padding: EdgeInsets.only(left: 12),
//                   child: Text(
//                     'HOTTEST POST',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       fontStyle: FontStyle.normal,
//                       height: 16 / 14, // line-height: 16px
//                       letterSpacing: 0.6,
//                       color: Color(0xFF62748E),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildPostCard(
//               username: '@pal_explorer',
//               timeAgo: '2h ago',
//               initials: 'PE',
//               location: 'Victoria Island (VI)',
//               topic: 'Ask',
//               title: 'Where should we host our next product meetup?',
//               body:
//                   'Looking for a cozy, semi-outdoor space around VI that can host about 30 people. Prefer somewhere with good WiFi and accessible parking.',
//               voteCount: 186,
//               commentCount: 3,
//               variant: PostCardVariant.hot,
//             ),
//             const SizedBox(height: 32),
//             // History Section
//             Align(
//               alignment: Alignment.center,
//               child: SizedBox(
//                 width: cardWidth,
//                 child: const Padding(
//                   padding: EdgeInsets.only(left: 12),
//                   child: Text(
//                     'HISTORY',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       fontStyle: FontStyle.normal,
//                       height: 16 / 14, // line-height: 16px
//                       letterSpacing: 0.6,
//                       color: Color(0xFF62748E),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildPostCard(
//               username: '@ikoyi_newbie',
//               timeAgo: '4d ago',
//               initials: 'IK',
//               location: 'Ikoyi',
//               topic: 'Ask',
//               title: '🚨 Community Guidelines Update - Important Information',
//               body:
//                   'Hello everyone! We\'re updating our community guidelines to ensure this remains a respectful and helpful space for all Lagos residents. Please be mindful of:\n1) No spam or self-promotion without adding value, \n2) Keep discussions civil and constructive, \n3) Verify information before sharing, especially about locations and events. \nLet\'s build a better community together!',
//               voteCount: 142,
//               commentCount: 1,
//               variant: PostCardVariant.hotPost2,
//             ),
//             const SizedBox(height: 24),
//             _buildPostCard(
//               username: '@lagos_explorer',
//               timeAgo: '3d ago',
//               initials: 'LE',
//               location: 'Victoria Island',
//               topic: 'Share',
//               title: 'Best Places to Visit in Lagos This Weekend',
//               body:
//                   'Looking for some fun activities this weekend? Here are my top recommendations:\n1) Visit the Lekki Conservation Centre for nature walks\n2) Check out the Nike Art Gallery for local art\n3) Enjoy the beach at Tarkwa Bay\n4) Try local cuisine at the food markets\nWhat are your favorite spots?',
//               voteCount: 98,
//               commentCount: 5,
//               variant: PostCardVariant.hotPost2,
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildPostCard({
//     required String username,
//     required String timeAgo,
//     required String initials,
//     required String location,
//     required String topic,
//     required String title,
//     required String body,
//     required int voteCount,
//     required int commentCount,
//     PostCardVariant variant = PostCardVariant.moderator,
//   }) {
//     // Determine initials based on variant
//     final String displayInitials = variant == PostCardVariant.moderator
//         ? 'MO'
//         : variant == PostCardVariant.admin
//             ? 'AD'
//             : initials;

//     final postData = PostCardData(
//       variant: variant,
//       username: username,
//       timeAgo: timeAgo,
//       location: location,
//       category: topic,
//       title: title,
//       body: body,
//       commentsCount: commentCount,
//       votes: voteCount,
//       initials: displayInitials,
//     );

//     return PostCard(
//       data: postData,
//       showOverflowMenu: variant != PostCardVariant.admin, // Hide three dots for admin variant
//     );
//   }

// }


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/pal_loading_widgets.dart';
import '../../services/app_cache.dart';
import 'moderator_settings_screen.dart';
import '../feed/widgets/post_card.dart';

class ModHotPostScreen extends StatefulWidget {
  const ModHotPostScreen({super.key});

  @override
  State<ModHotPostScreen> createState() => _ModHotPostScreenState();
}

class _ModHotPostScreenState extends State<ModHotPostScreen> {
  Map<String, dynamic>? _hotPost;
  Map<String, dynamic>? _weekPost;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotPost();
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';

    // If it's a numeric value (seconds)
    if (raw is num) {
      final seconds = raw.toInt();
      if (seconds < 60) return 'just now';
      if (seconds < 3600) return '${seconds ~/ 60}m ago';
      if (seconds < 86400) return '${seconds ~/ 3600}h ago';
      return '${seconds ~/ 86400}d ago';
    }

    if (raw is String) {
      // Try parsing as ISO 8601 date string
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inSeconds < 60) return 'just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      }
      // Already a formatted string like "2h ago"
      return raw;
    }

    // Fallback: try parsing as int string
    final seconds = int.tryParse(raw.toString()) ?? 0;
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return '${seconds ~/ 60}m ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ago';
    return '${seconds ~/ 86400}d ago';
  }

  Future<void> _loadHotPost() async {
    try {
      final data = await AppCache().getHotPost();
      debugPrint('[HotPostScreen] keys: ${data.keys}');

      Map<String, dynamic>? todayPost;
      Map<String, dynamic>? weekPost;

      // Try hottest_post first
      final hp = data['hottest_post'];
      if (hp is Map && hp.isNotEmpty) {
        todayPost = Map<String, dynamic>.from(hp);
      }

      // Extract from comparison
      final comparison = data['comparison'];
      if (comparison is Map) {
        final today = comparison['today'];
        if (today is Map && today.isNotEmpty) {
          // Use comparison.today as fallback if hottest_post is null
          todayPost ??= Map<String, dynamic>.from(today);
        }
        final week = comparison['week'];
        if (week is Map && week.isNotEmpty) {
          weekPost = Map<String, dynamic>.from(week);
        }
      }

      debugPrint('[HotPostScreen] todayPost: $todayPost');
      debugPrint('[HotPostScreen] weekPost: $weekPost');

      setState(() {
        _hotPost = todayPost;
        _weekPost = weekPost;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[HotPostScreen] error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
                      'Hot Post',
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(15, 28, 15, 120),
                child: _buildPostsContent(),
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

  Widget _buildPostsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxWidth = 600.0;
        final cardWidth = availableWidth.clamp(360.0, maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HOTTEST POST HEADER
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'HOTTEST POST',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 16 / 14,
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🔥 Dynamic Hottest Post
            if (_isLoading)
              const _ModHotPostSkeleton()
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFF62748E)),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load hot post',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF62748E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadHotPost,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_hotPost != null)
              _buildPostCardFromData(_hotPost!, variant: PostCardVariant.hot)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hot post available today',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // HISTORY HEADER
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'HISTORY',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 16 / 14,
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // History: week's hottest post
            if (_weekPost != null)
              _buildPostCardFromData(_weekPost!, variant: PostCardVariant.hotPost2)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No history available',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
    PostCardVariant variant = PostCardVariant.moderator,
  }) {
    final String displayInitials = variant == PostCardVariant.moderator
        ? 'MO'
        : variant == PostCardVariant.admin
            ? 'AD'
            : initials;

    final postData = PostCardData(
      variant: variant,
      username: username,
      timeAgo: timeAgo,
      location: location,
      category: topic,
      title: title,
      body: body,
      commentsCount: commentCount,
      votes: voteCount,
      initials: displayInitials,
    );

    return PostCard(
      data: postData,
      showOverflowMenu: variant != PostCardVariant.admin,
    );
  }

  Widget _buildPostCardFromData(Map<String, dynamic> post, {PostCardVariant variant = PostCardVariant.hot}) {
    final postUser = post['user'] ?? post['author'];
    final username = postUser is Map
        ? (postUser['username'] ?? '')
        : (post['username'] ?? '');
    final initials = username.isNotEmpty
        ? (username.length >= 2 ? username.substring(0, 2).toUpperCase() : username[0].toUpperCase())
        : 'U';

    final location = post['location'] is Map
        ? (post['location']['display_name'] ?? '')
        : (post['location_name'] ?? post['location']?.toString() ?? '');
    final category = post['category'] is Map
        ? (post['category']['display_name'] ?? '')
        : (post['category_name'] ?? post['category']?.toString() ?? '');

    // content_preview from comparison, content from full post
    final content = (post['content_preview'] ?? post['content'] ?? '').toString();
    final title = (post['title'] ?? '').toString();

    return _buildPostCard(
      username: username.startsWith('@') ? username : '@$username',
      timeAgo: _formatTimeAgo(post['time_ago'] ?? post['created_at']),
      initials: initials,
      location: location,
      topic: category,
      title: title.isNotEmpty ? title : content,
      body: title.isNotEmpty ? content : '',
      voteCount: (post['net_score'] as num?)?.toInt() ?? (post['net_votes'] as num?)?.toInt() ?? 0,
      commentCount: (post['comment_count'] as num?)?.toInt() ?? 0,
      variant: variant,
    );
  }
}
class _ModHotPostSkeleton extends StatelessWidget {
  const _ModHotPostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        LoadingPostSkeleton(),
        SizedBox(height: 16),
        LoadingPostSkeleton(),
      ],
    );
  }
}