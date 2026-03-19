// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../widgets/pal_bottom_nav_bar.dart';
// import 'admin_settings_screen.dart';
// import '../feed/widgets/post_card.dart';

// class WodScreen extends StatefulWidget {
//   const WodScreen({super.key});

//   @override
//   State<WodScreen> createState() => _WodScreenState();
// }

// class _WodScreenState extends State<WodScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FBFF),
//       body: SafeArea(
//         bottom: false,
//         child: Column(
//           children: [
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
//                       transform: Matrix4.rotationY(3.14159),
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
//                       'Wahala of the day (WOD)',
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
//             MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildPostsContent() {
//     // ... hardcoded mock posts ...
//   }
//
//   Widget _buildPostCard({ ... }) {
//     // ... PostCard builder ...
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/pal_loading_widgets.dart';
import '../../services/app_cache.dart';
import 'admin_settings_screen.dart';
import '../feed/widgets/post_card.dart';

class WodScreen extends StatefulWidget {
  const WodScreen({super.key});

  @override
  State<WodScreen> createState() => _WodScreenState();
}

class _WodScreenState extends State<WodScreen> {
  Map<String, dynamic>? _wodPost;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWodStats();
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    final seconds = (raw is num) ? raw.toInt() : int.tryParse(raw.toString()) ?? 0;
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return '${seconds ~/ 60}m ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ago';
    return '${seconds ~/ 86400}d ago';
  }

  Future<void> _fetchWodStats() async {
    try {
      setState(() { _isLoading = true; _error = null; });

      // Use AppCache — returns cached data on revisit, or waits for in-flight request
      // that was kicked off by prefetchWod() during the navigation animation.
      final data = await AppCache().getWod();

      debugPrint('[WOD] raw: $data');

      Map<String, dynamic>? post;
      if (data.isNotEmpty) {
        final inner = data['post'] ?? data['data'];
        if (inner is Map && inner.isNotEmpty) {
          post = Map<String, dynamic>.from(inner);
        }
      }

      debugPrint('[WOD] parsed post: $post');

      setState(() { _wodPost = post; _isLoading = false; });
    } catch (e) {
      debugPrint('[WOD] error: $e');
      setState(() { _error = e.toString(); _isLoading = false; });
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
                      'Wahala of the day (WOD)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 36 / 20, // line-height: 36px
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
              child: _isLoading
                  ? const _WodSkeleton()
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                        )
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(15, 28, 15, 120),
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
            MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
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
            // Pinned WOD Section
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'PINNED WOD',
                    style: TextStyle(
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
              ),
            ),
            const SizedBox(height: 12),
            if (_wodPost != null)
              _buildPostCardFromData(_wodPost!, variant: PostCardVariant.wod)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No WOD post available',
                      style: TextStyle(color: Color(0xFF62748E))),
                ),
              ),
            const SizedBox(height: 32),

            // History Section
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
                      fontStyle: FontStyle.normal,
                      height: 16 / 14,
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildPostCardFromData(Map<String, dynamic> post,
      {PostCardVariant variant = PostCardVariant.wod}) {
    // Flat fields from get-wod-post response
    final username = (post['username'] ?? '').toString();
    final initials = username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : (username.isNotEmpty ? username[0].toUpperCase() : 'U');

    final timeAgo = '';

    return _buildPostCard(
      username: username.startsWith('@') ? username : '@$username',
      timeAgo: timeAgo,
      initials: initials,
      location: (post['location_name'] ?? '').toString(),
      topic: (post['category_name'] ?? '').toString(),
      title: (post['content'] ?? '').toString(),
      body: '',
      voteCount: (post['net_score'] as num?)?.toInt() ?? 0,
      commentCount: (post['comment_count'] as num?)?.toInt() ?? 0,
      variant: variant,
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
    // Determine initials based on variant
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
      showOverflowMenu: variant != PostCardVariant.admin, // Hide three dots for admin variant
    );
  }
}

// ── Skeleton shown while WOD data is loading ───────────────────────────────
class _WodSkeleton extends StatelessWidget {
  const _WodSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 28, 15, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingPostSkeleton(),
          const SizedBox(height: 16),
          const LoadingPostSkeleton(),
        ],
      ),
    );
  }
}
