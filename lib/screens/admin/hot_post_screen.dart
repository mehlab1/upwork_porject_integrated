import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import 'admin_settings_screen.dart';
import '../feed/widgets/post_card.dart';

class HotPostScreen extends StatefulWidget {
  const HotPostScreen({super.key});

  @override
  State<HotPostScreen> createState() => _HotPostScreenState();
}

class _HotPostScreenState extends State<HotPostScreen> {
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
                      'Hot Post',
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

  Widget _buildPostsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxWidth = 600.0;
        final cardWidth = availableWidth.clamp(360.0, maxWidth);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hottest Post Section
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
                      fontStyle: FontStyle.normal,
                      height: 16 / 14, // line-height: 16px
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPostCard(
              username: '@pal_explorer',
              timeAgo: '2h ago',
              initials: 'PE',
              location: 'Victoria Island (VI)',
              topic: 'Ask',
              title: 'Where should we host our next product meetup?',
              body:
                  'Looking for a cozy, semi-outdoor space around VI that can host about 30 people. Prefer somewhere with good WiFi and accessible parking.',
              voteCount: 186,
              commentCount: 3,
              variant: PostCardVariant.hot,
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
                      height: 16 / 14, // line-height: 16px
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPostCard(
              username: '@ikoyi_newbie',
              timeAgo: '4d ago',
              initials: 'IK',
              location: 'Ikoyi',
              topic: 'Ask',
              title: '🚨 Community Guidelines Update - Important Information',
              body:
                  'Hello everyone! We\'re updating our community guidelines to ensure this remains a respectful and helpful space for all Lagos residents. Please be mindful of:\n1) No spam or self-promotion without adding value, \n2) Keep discussions civil and constructive, \n3) Verify information before sharing, especially about locations and events. \nLet\'s build a better community together!',
              voteCount: 142,
              commentCount: 1,
              variant: PostCardVariant.hotPost2,
            ),
            const SizedBox(height: 24),
            _buildPostCard(
              username: '@lagos_explorer',
              timeAgo: '3d ago',
              initials: 'LE',
              location: 'Victoria Island',
              topic: 'Share',
              title: 'Best Places to Visit in Lagos This Weekend',
              body:
                  'Looking for some fun activities this weekend? Here are my top recommendations:\n1) Visit the Lekki Conservation Centre for nature walks\n2) Check out the Nike Art Gallery for local art\n3) Enjoy the beach at Tarkwa Bay\n4) Try local cuisine at the food markets\nWhat are your favorite spots?',
              voteCount: 98,
              commentCount: 5,
              variant: PostCardVariant.hotPost2,
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
