// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../widgets/pal_bottom_nav_bar.dart';
// import 'moderator_settings_screen.dart';
// import '../feed/widgets/post_card.dart';

// class ModAnnouncementsScreen extends StatefulWidget {
//   const ModAnnouncementsScreen({super.key});

//   @override
//   State<ModAnnouncementsScreen> createState() => _ModAnnouncementsScreenState();
// }

// class _ModAnnouncementsScreenState extends State<ModAnnouncementsScreen> {
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
//                       'Announcements',
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
//             // Pinned Announcements Section
//             Align(
//               alignment: Alignment.center,
//               child: SizedBox(
//                 width: cardWidth,
//                 child: const Padding(
//                   padding: EdgeInsets.only(left: 12),
//                   child: Text(
//                     'PINNED ANNOUNCEMENTS',
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
//               username: '@party_person',
//               timeAgo: '5d ago',
//               initials: 'PA',
//               location: 'Surulere',
//               topic: 'Ask',
//               title: '🚨 Community Guidelines Update - Important Information',
//               body:
//                   'Hello everyone! We\'re updating our community guidelines to ensure this remains a respectful and helpful space for all Lagos residents. Please be mindful of:\n1) No spam or self-promotion without adding value, \n2) Keep discussions civil and constructive, \n3) Verify information before sharing, especially about locations and events. \nLet\'s build a better community together!',
//               voteCount: 87,
//               commentCount: 1,
//             ),
//             const SizedBox(height: 32),
//             // Pending Approvals Section
//             Align(
//               alignment: Alignment.center,
//               child: SizedBox(
//                 width: cardWidth,
//                 child: const Padding(
//                   padding: EdgeInsets.only(left: 12),
//                   child: Text(
//                     'PENDING APPROVALS',
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
//               variant: PostCardVariant.moderator,
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
//               variant: PostCardVariant.admin,
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

import '../../services/announcements_service.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/pal_loading_widgets.dart';
import 'moderator_settings_screen.dart';
import '../feed/widgets/post_card.dart';

class ModAnnouncementsScreen extends StatefulWidget {
  const ModAnnouncementsScreen({super.key});

  @override
  State<ModAnnouncementsScreen> createState() => _ModAnnouncementsScreenState();
}

class _ModAnnouncementsScreenState extends State<ModAnnouncementsScreen> {
  final AnnouncementsService _service = AnnouncementsService();
  late Future<List<Map<String, dynamic>>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _service.getAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
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

  Widget _buildHeader() {
    return Container(
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
              'Announcements',
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
    );
  }

  Widget _buildPostsContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAnnouncementSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint('[ModAnnouncements] Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFF62748E)),
                const SizedBox(height: 12),
                Text(
                  'Failed to load announcements',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF62748E),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _announcementsFuture = _service.getAnnouncements();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                'No announcements yet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF62748E),
                ),
              ),
            ),
          );
        }

        // is_pushed + is_active = pinned (live announcement)
        // is_active + !is_pushed = pending approval
        // !is_active = archived / history
        final pinned = announcements
            .where((a) => a['is_active'] == true && a['is_pushed'] == true)
            .toList();
        final pending = announcements
            .where((a) => a['is_active'] == true && a['is_pushed'] != true)
            .toList();
        final history = announcements
            .where((a) => a['is_active'] != true)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth.clamp(360.0, 600.0);

            return Column(
              children: [
                if (pinned.isNotEmpty)
                  _buildSection('PINNED ANNOUNCEMENTS', pinned, cardWidth),
                if (pending.isNotEmpty)
                  _buildSection('PENDING APPROVALS', pending, cardWidth),
                if (history.isNotEmpty)
                  _buildSection('HISTORY', history, cardWidth),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSection(
      String title, List<Map<String, dynamic>> items, double cardWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cardWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Color(0xFF62748E),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(_mapAnnouncementToPostCard),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _mapAnnouncementToPostCard(Map<String, dynamic> a) {
    // Determine variant based on whether it's pushed (active) or archived
    PostCardVariant variant;
    if (a['is_active'] != true) {
      variant = PostCardVariant.admin; // history items
    } else if (a['is_pushed'] == true) {
      variant = PostCardVariant.moderator; // pinned
    } else {
      variant = PostCardVariant.moderator; // pending
    }

    final username = a['created_by_username'] ?? 'unknown';
    final displayName = username.startsWith('@') ? username : '@$username';
    final initials = username
        .replaceAll('@', '')
        .substring(0, username.replaceAll('@', '').length >= 2 ? 2 : 1)
        .toUpperCase();

    final createdAt = a['created_at'];
    final timeAgo = createdAt != null
        ? _timeAgo(DateTime.tryParse(createdAt.toString()) ?? DateTime.now())
        : '';

    return _buildPostCard(
      username: displayName,
      timeAgo: timeAgo,
      initials: initials,
      location: '',
      topic: a['type'] ?? '',
      title: a['title'] ?? '',
      body: a['message'] ?? '',
      voteCount: 0,
      commentCount: 0,
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
    required PostCardVariant variant,
  }) {
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
      initials: variant == PostCardVariant.admin ? 'AD' : initials,
    );

    return PostCard(
      data: postData,
      showOverflowMenu: variant != PostCardVariant.admin,
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Widget _buildAnnouncementSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingPostSkeleton(),
          SizedBox(height: 12),
          LoadingPostSkeleton(),
          SizedBox(height: 12),
          LoadingPostSkeleton(),
        ],
      ),
    );
  }
}