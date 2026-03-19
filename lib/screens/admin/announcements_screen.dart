// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../widgets/pal_bottom_nav_bar.dart';
// import 'admin_settings_screen.dart';
// import '../feed/widgets/post_card.dart';

// class AnnouncementsScreen extends StatefulWidget {
//   const AnnouncementsScreen({super.key});

//   @override
//   State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
// }

// class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
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
//             MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
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
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/announcements_service.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/pal_loading_widgets.dart';
import 'admin_settings_screen.dart';
import '../feed/widgets/post_card.dart';

// Approval menu widget with exact design specifications
class _ApprovalMenuWidget extends StatelessWidget {
  const _ApprovalMenuWidget({
    required this.onApproved,
    required this.onNotApproved,
  });

  final VoidCallback onApproved;
  final VoidCallback onNotApproved;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 219.99159240722656,
        padding: const EdgeInsets.all(5.99),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Approved option
            _ApprovalMenuItem(
              label: 'Approved',
              iconPath: 'assets/adminIcons/adminSettings/approved-tick-circle.svg',
              textColor: const Color(0xFF314158),
              onTap: onApproved,
            ),
            const SizedBox(height: 5.99),
            // Divider
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 5.99),
            // Not Approved option
            _ApprovalMenuItem(
              label: 'Not Approved',
              iconPath: 'assets/adminIcons/adminSettings/not-approved-close-circle.svg',
              textColor: const Color(0xFFE7000B),
              onTap: onNotApproved,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalMenuItem extends StatelessWidget {
  const _ApprovalMenuItem({
    required this.label,
    required this.iconPath,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        height: 20,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontSize: 14,
                height: 20 / 14, // line-height: 20px
                letterSpacing: -0.15,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final AnnouncementsService _service = AnnouncementsService();
  late Future<List<Map<String, dynamic>>> _announcementsFuture;
  OverlayEntry? _approvalMenuOverlay;
  final GlobalKey _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _service.getAnnouncements();
  }

  @override
  void dispose() {
    _removeApprovalMenu();
    super.dispose();
  }

  void _removeApprovalMenu() {
    _approvalMenuOverlay?.remove();
    _approvalMenuOverlay = null;
  }

  void _showApprovalMenu(BuildContext context, GlobalKey menuKey) {
    _removeApprovalMenu();

    final menuContext = menuKey.currentContext;
    if (menuContext == null || !menuContext.mounted) {
      return;
    }

    final renderBox = menuContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    const menuWidth = 219.99159240722656;
    const menuHeight = 104.94066619873047;

    // Calculate position, ensuring menu doesn't overflow screen
    double rightPosition = screenSize.width - (offset.dx + size.width) + 8;
    double bottomPosition = screenSize.height - offset.dy + 8;

    // Adjust if menu would overflow on the right
    if (rightPosition < 8) {
      rightPosition = 8;
    } else if (rightPosition + menuWidth > screenSize.width - 8) {
      rightPosition = screenSize.width - menuWidth - 8;
    }

    // Adjust if menu would overflow on the bottom
    if (bottomPosition < 8) {
      bottomPosition = offset.dy + size.height + 8;
    } else if (bottomPosition + menuHeight > screenSize.height - 8) {
      bottomPosition = screenSize.height - menuHeight - 8;
    }

    _approvalMenuOverlay = OverlayEntry(
      builder: (context) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification ||
              notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _removeApprovalMenu();
          }
          return false;
        },
        child: Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeApprovalMenu,
            child: Stack(
              children: [
                Positioned(
                  bottom: bottomPosition,
                  right: rightPosition,
                  child: GestureDetector(
                    onTap: () {
                      // Prevent tap from propagating to parent GestureDetector
                    },
                    child: _ApprovalMenuWidget(
                      onApproved: () {
                        _removeApprovalMenu();
                        // TODO: Handle approved action
                      },
                      onNotApproved: () {
                        _removeApprovalMenu();
                        // TODO: Handle not approved action
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_approvalMenuOverlay!);
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
            MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
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

  /// Skeleton placeholder shown while the fetch is in-flight.
  /// Uses the same section-heading + card layout as the real content so the
  /// page doesn't visually "jump" once data arrives.
  Widget _buildSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section label skeleton ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Container(
                width: 180,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // ── Post card skeletons ───────────────────────────────────────────
            for (int i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LoadingPostSkeleton(),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            for (int i = 0; i < 2; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LoadingPostSkeleton(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPostsContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final announcements = snapshot.data ?? [];

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
    bool isPendingApproval = false;
    if (a['is_active'] != true) {
      variant = PostCardVariant.admin; // history items
    } else if (a['is_pushed'] == true) {
      variant = PostCardVariant.moderator; // pinned
    } else {
      variant = PostCardVariant.moderator; // pending
      isPendingApproval = true;
    }

    final username = a['created_by_username'] ?? 'unknown';
    final displayName = username.startsWith('@') ? username : '@$username';
    final initials = username
        .replaceAll('@', '')
        .substring(0, username.replaceAll('@', '').length >= 2 ? 2 : 1)
        .toUpperCase();

    return _buildPostCard(
      username: displayName,
      timeAgo: _timeAgo(DateTime.parse(a['created_at'])),
      initials: initials,
      location: '',
      topic: a['type'] ?? '',
      title: a['title'] ?? '',
      body: a['message'] ?? '',
      voteCount: 0,
      commentCount: 0,
      variant: variant,
      isPendingApproval: isPendingApproval,
      announcementId: a['id']?.toString(),
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
    bool isPendingApproval = false,
    String? announcementId,
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

    // Create a unique menu key for each post if it's pending approval
    final menuKey = isPendingApproval ? GlobalKey() : null;

    return PostCard(
      data: postData,
      showOverflowMenu: variant != PostCardVariant.admin,
      externalMenuKey: menuKey,
      onCustomMenuTap: isPendingApproval
          ? () {
              if (menuKey != null) {
                _showApprovalMenu(context, menuKey);
              }
            }
          : null,
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}