import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pal/widgets/pal_bottom_nav_bar.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  static const routeName = '/settings/faq';

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final Map<int, bool> _expandedItems = {
    0: true, // First item expanded by default
  };

  final List<Map<String, dynamic>> _faqSections = [
    {
      'title': 'Getting Started',
      'items': [
        {
          'question': 'What is this Pal about?',
          'answer':
              'This is a community forum for to share news, ask questions, discuss topics, and connect with people in your area.',
        },
        {
          'question': 'How do I create a post?',
          'answer':
              'Tap the \'+\' button at the bottom of your screen to create a new post. Choose from three categories: Gist (share news), Ask (get recommendations), or Discussion (start conversations). Select your location and write your post.',
        },
        {
          'question': 'What are the different post categories?',
          'answer':
              'We have three main categories: \'Gist\' for sharing news and updates, \'Ask\' for getting recommendations and help, and \'Discussion\' for starting community conversations. There\'s also a special Monthly spotlight for highlighted topic of the month.',
        },
      ],
    },
    {
      'title': 'Posting & Engagement',
      'items': [
        {
          'question': 'How does voting work?',
          'answer':
              'You can upvote posts and comments you find helpful or interesting. You can also downvote content that doesn\'t contribute to the discussion.',
        },
        {
          'question': 'What is \'Wahala of the Day\'?',
          'answer':
              'Wahala of the Day is is a featured post that\'s highlighted for 24 hours based on trending topics, community interest, or platform recommendations. WOD is designed to spark conversation, spotlight relevant content, or bring the community together. These posts are pinned at the top of the feed for 24 hours and have a distinctive design with a special badge.',
        },
        {
          'question': 'Can I delete my posts?',
          'answer':
              'Yes! Tap the three dots menu on your post to  delete it.  You can delete posts at any time.',
        },
        {
          'question': 'How do I filter posts by location?',
          'answer':
              'Use the location filter at the top of the feed to see posts from specific neighborhoods.',
        },
      ],
    },
    {
      'title': 'Guidelines',
      'items': [
        {
          'question': 'What are the community rules?',
          'answer':
              'Our full Community Guidelines are available on a dedicated page. You can access it from the Settings menu. The guidelines cover respectful behavior, prohibited content, and how to report violations.',
        },
        {
          'question': 'How do I report inappropriate content?',
          'answer':
              'Tap the three dots menu on any post or comment and select \'Report\'. Choose the reason for reporting (spam, harassment, inappropriate content, etc.) and our moderation team will review it.',
        },
        {
          'question': 'What happens if I violate the rules?',
          'answer':
              'First-time violations usually result in a warning. Repeated violations may lead to temporary suspension or permanent ban depending on severity. We want to keep this community safe and welcoming for everyone.',
        },
      ],
    },
    {
      'title': 'Account & Privacy',
      'items': [
        {
          'question': 'Is my location shared publicly?',
          'answer':
              'No, We only show the neighborhood you select when creating a post (e.g., \'Lekki\' or \'VI\'). You have control over which area you associate with each post.',
        },
        {
          'question': 'How do I block a user?',
          'answer':
              'Go to a user\'s profile or tap the three dots on their post, then select \'Block User\'. Blocked users cannot see your posts or comment on your content. Exception: Platform-pinned posts remain visible to everyone. You can manage blocked users in Settings > Blocked Accounts.',
        },
        {
          'question': 'Can I use the Pal anonymously?',
          'answer':
              'Yes, you can create posts and comments with just your username. We don\'t require real names or personal information. However, we encourage building a positive reputation in the community.',
        },
      ],
    },
    {
      'title': 'Features & Technical',
      'items': [
        {
          'question': 'What does \'Hot\', \'New\', and \'Top\' mean?',
          'answer':
              '\'Hot\' shows trending posts with recent engagement. \'New\' displays the latest posts. \'Top\' ranks posts by engagement.',
        },
        {
          'question': 'How do I enable notifications?',
          'answer':
              'Go to Settings and toggle on Notifications. You\'ll receive alerts for comments on your posts, replies to your comments, and important community announcements. You can customize notification preferences anytime.',
        },
        {
          'question': 'Is there a web app?',
          'answer':
              'Please visit kobipal.com for more information.',
        },
      ],
    },
  ];

  int _getGlobalIndex(int sectionIndex, int itemIndex) {
    int globalIndex = 0;
    for (int i = 0; i < sectionIndex; i++) {
      globalIndex += (_faqSections[i]['items'] as List).length;
    }
    return globalIndex + itemIndex;
  }

  void _toggleItem(int index) {
    setState(() {
      _expandedItems[index] = !(_expandedItems[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FaqAppBar(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int sectionIndex = 0; sectionIndex < _faqSections.length; sectionIndex++) ...[
                        // Section heading
                        Padding(
                          padding: EdgeInsets.only(
                            left: 4,
                            top: sectionIndex == 0 ? 0 : 32,
                            bottom: 12,
                          ),
                          child: Text(
                            _faqSections[sectionIndex]['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172B),
                              fontFamily: 'Inter',
                              letterSpacing: -0.625,
                              height: 24 / 16,
                            ),
                          ),
                        ),
                        // Section items
                        for (int itemIndex = 0; itemIndex < (_faqSections[sectionIndex]['items'] as List).length; itemIndex++) ...[
                          _FaqItem(
                            question: (_faqSections[sectionIndex]['items'] as List<Map<String, String>>)[itemIndex]['question']!,
                            answer: (_faqSections[sectionIndex]['items'] as List<Map<String, String>>)[itemIndex]['answer']!,
                            isExpanded: _expandedItems[_getGlobalIndex(sectionIndex, itemIndex)] ?? false,
                            onTap: () => _toggleItem(_getGlobalIndex(sectionIndex, itemIndex)),
                          ),
                          if (itemIndex < (_faqSections[sectionIndex]['items'] as List).length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                      const SizedBox(height: 32),
                      const _StillHaveQuestionsCard(),
                      const SizedBox(height: 120), // Space for bottom nav bar
                    ],
                  ),
                ),
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
        onSettingsTap: () {},
        showNotificationDot: true,
      ),
    );
  }
}

class _FaqAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.755),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 38, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Transform.rotate(
              angle: 3.14159, // 180 degrees to face left (backwards)
              child: SvgPicture.asset(
                'assets/settings/dropDownIcon.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0F172B),
                  BlendMode.srcIn,
                ),
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172B),
                letterSpacing: 0.07,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAnswer = answer.isNotEmpty;
    final backgroundColor = isExpanded && hasAnswer
        ? const Color(0xFFF7FBFF)
        : Colors.white;
    final borderColor = isExpanded && hasAnswer
        ? Colors.black.withOpacity(0.2)
        : const Color(0xFF0F172B).withOpacity(0.2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172B),
                      letterSpacing: -0.15,
                      height: 1.43,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.rotate(
                  angle: isExpanded
                      ? -1.5708 // -90 degrees - point up when expanded
                      : 1.5708, // 90 degrees - point down when collapsed
                  child: SvgPicture.asset(
                    'assets/settings/dropDownIcon.svg',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      const Color(0xFF0F172B).withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded && hasAnswer) ...[
              const SizedBox(height: 20),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF45556C),
                  letterSpacing: -0.15,
                  height: 1.9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StillHaveQuestionsCard extends StatelessWidget {
  const _StillHaveQuestionsCard();

  void _handleContactSupport() {
    // TODO: Implement contact support functionality
    // This could open an email client, navigate to a support screen, or show a dialog
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF155DFC).withOpacity(0.3),
            width: 3,
          ),
          top: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
          right: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Still have questions?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172B),
              letterSpacing: -0.15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'If you can\'t find the answer you\'re looking for, reach out to our community support team. We\'re here to help!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF45556C),
              letterSpacing: -0.15,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleContactSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155DFC),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
