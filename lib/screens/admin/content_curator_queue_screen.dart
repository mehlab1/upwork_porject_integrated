import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'admin_settings_screen.dart';

class ContentCuratorQueueScreen extends StatefulWidget {
  const ContentCuratorQueueScreen({super.key});

  @override
  State<ContentCuratorQueueScreen> createState() =>
      _ContentCuratorQueueScreenState();
}

class _ContentCuratorQueueScreenState
    extends State<ContentCuratorQueueScreen> {
  String _selectedTab = 'Comments'; // 'Posts', 'Comments' - Comments is default

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
                      'Content Curator Queue',
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
              child: SingleChildScrollView(
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
              MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
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
        // New Queue Section
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
        _buildPostCard(
          username: '@party_person',
          timeAgo: '5d ago',
          initials: 'PA',
          location: 'Surulere',
          topic: 'Ask',
          title: 'Surulere nightlife - Where\'s the party at?',
          body:
              'Looking for good nightlife spots in Surulere. Not too expensive but with good music and vibes. What are your favorites? Clubs, bars, lounges?',
          voteCount: 87,
          commentCount: 1,
        ),
        const SizedBox(height: 32),
        // History Section
        const Text(
          'HISTORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF62748E),
            letterSpacing: 0.6,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          username: '@ikoyi_newbie',
          timeAgo: '4d ago',
          initials: 'IK',
          location: 'Ikoyi',
          topic: 'Ask',
          title: 'Best places to hang out in Ikoyi on weekends?',
          body:
              'Just moved to Ikoyi and looking for cool spots to relax on weekends. Restaurants, lounges, parks - what do you recommend? Not trying to break the bank but willing to spend for quality.',
          voteCount: 142,
          commentCount: 1,
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          username: '@party_person',
          timeAgo: '5d ago',
          initials: 'PA',
          location: 'Surulere',
          topic: 'Ask',
          title: 'Surulere nightlife - Where\'s the party at?',
          body:
              'Looking for good nightlife spots in Surulere. Not too expensive but with good music and vibes. What are your favorites? Clubs, bars, lounges?',
          voteCount: 87,
          commentCount: 1,
        ),
      ],
    );
  }

  Widget _buildCommentsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New Queue Section
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
        _buildCommentCard(
          username: '@lagosian_boy',
          timeAgo: '1h ago',
          initials: 'LB',
          comment:
              'You NEED to try the one at Yellow Chilli! Best I\'ve ever had, hands down.',
          voteCount: 45,
        ),
        const SizedBox(height: 12),
        _buildCommentCard(
          username: '@naija_gourmet',
          timeAgo: '30m ago',
          initials: 'NG',
          comment:
              'Party jollof is undefeated! There\'s something about that smoky flavor from the firewood.',
          voteCount: 38,
        ),
        const SizedBox(height: 32),
        // History Section
        const Text(
          'HISTORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF62748E),
            letterSpacing: 0.6,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        _buildCommentCard(
          username: '@lagosian_boy',
          timeAgo: '1h ago',
          initials: 'LB',
          comment:
              'You NEED to try the one at Yellow Chilli! Best I\'ve ever had, hands down.',
          voteCount: 45,
        ),
        const SizedBox(height: 12),
        _buildCommentCard(
          username: '@naija_gourmet',
          timeAgo: '30m ago',
          initials: 'NG',
          comment:
              'Party jollof is undefeated! There\'s something about that smoky flavor from the firewood.',
          voteCount: 38,
        ),
        const SizedBox(height: 12),
        _buildCommentCard(
          username: '@anonymous',
          timeAgo: 'just now',
          initials: 'AN',
          comment: 'checking',
          voteCount: 1,
        ),
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

