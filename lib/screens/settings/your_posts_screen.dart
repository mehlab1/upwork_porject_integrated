import 'package:flutter/material.dart';
import 'package:pal/screens/feed/widgets/post_card.dart';

const _pageBackground = Color(0xFFF7FBFF);
const _headerTitleColor = Color(0xFF0F172B);
const _headerSubtitleColor = Color(0xFF45556C);
const _headerMetaColor = Color(0xFF62748E);

class YourPostsScreen extends StatelessWidget {
  const YourPostsScreen({super.key});

  static const routeName = '/settings/your-posts';

  static const List<PostCardData> _yourPosts = [
    PostCardData(
      variant: PostCardVariant.newPost,
      username: '@lagosian_pro',
      timeAgo: '2h ago',
      location: 'Ikoyi',
      category: 'Ask',
      title: 'Best places to hang out in Ikoyi on weekends?',
      body:
          'Just moved to Ikoyi and looking for cool spots to relax on weekends. Restaurants, lounges, parks - what do you recommend? Not trying to break the bank but willing to spend for quality.',
      commentsCount: 1,
      votes: 142,
      avatarAsset: 'assets/feedPage/profile.png',
    ),
    PostCardData(
      variant: PostCardVariant.newPost,
      username: '@lagosian_pro',
      timeAgo: '5h ago',
      location: 'Victoria Island',
      category: 'Gist',
      title: 'Best jollof rice spots in VI',
      body:
          'Just tried the new restaurant on Akin Adesola and their jollof is fire! 🔥',
      commentsCount: 12,
      votes: 45,
      avatarAsset: 'assets/feedPage/profile.png',
    ),
    PostCardData(
      variant: PostCardVariant.newPost,
      username: '@lagosian_pro',
      timeAgo: '1d ago',
      location: 'Lagos Mainland',
      category: 'Discussion',
      title: 'Traffic update: Third Mainland Bridge',
      body:
          'Heavy traffic on Third Mainland Bridge heading to the island. Use alternative routes.',
      commentsCount: 8,
      votes: 67,
      avatarAsset: 'assets/feedPage/profile.png',
    ),
    PostCardData(
      variant: PostCardVariant.newPost,
      username: '@lagosian_pro',
      timeAgo: '2d ago',
      location: 'Lekki Phase 1',
      category: 'Gist',
      title: 'Power outage in Lekki Phase 1 - again!',
      body:
          'Anyone else experiencing power issues? This is the third time this week.',
      commentsCount: 45,
      votes: 89,
      avatarAsset: 'assets/feedPage/profile.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _YourPostsHeader(totalPosts: _yourPosts.length),
            Expanded(
              child: Container(
                color: _pageBackground,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 24, 15, 32),
                  itemCount: _yourPosts.length,
                  itemBuilder: (context, index) {
                    final post = _yourPosts[index];
                    return Align(
                      alignment: Alignment.center,
                      child: PostCard(data: post, isYourPosts: true),
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

class _YourPostsHeader extends StatelessWidget {
  const _YourPostsHeader({required this.totalPosts});

  final int totalPosts;

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
                    child: Image.asset(
                      'assets/feedPage/profile.png',
                      fit: BoxFit.cover,
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
                            'Your Posts',
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
                      const Text(
                        '@lagosian_pro',
                        style: TextStyle(
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
