import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pal/widgets/pal_bottom_nav_bar.dart';

class ReviewerFaqScreen extends StatefulWidget {
  const ReviewerFaqScreen({super.key});

  static const routeName = '/settings/faq';

  @override
  State<ReviewerFaqScreen> createState() => _JmFaqScreenState();
}

class _JmFaqScreenState extends State<ReviewerFaqScreen> {
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
          'answer': 'Please visit kobipal.com for more information.',
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
                      for (
                        int sectionIndex = 0;
                        sectionIndex < _faqSections.length;
                        sectionIndex++
                      ) ...[
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
                        for (
                          int itemIndex = 0;
                          itemIndex <
                              (_faqSections[sectionIndex]['items'] as List)
                                  .length;
                          itemIndex++
                        ) ...[
                          _FaqItem(
                            question:
                                (_faqSections[sectionIndex]['items']
                                    as List<
                                      Map<String, String>
                                    >)[itemIndex]['question']!,
                            answer:
                                (_faqSections[sectionIndex]['items']
                                    as List<
                                      Map<String, String>
                                    >)[itemIndex]['answer']!,
                            isExpanded:
                                _expandedItems[_getGlobalIndex(
                                  sectionIndex,
                                  itemIndex,
                                )] ??
                                false,
                            onTap: () => _toggleItem(
                              _getGlobalIndex(sectionIndex, itemIndex),
                            ),
                            customHeight: (_faqSections[sectionIndex]['items']
                                    as List<Map<String, String>>)[itemIndex]['question'] ==
                                'What is \'Wahala of the Day\'?'
                                ? 211.0
                                : null,
                            customSpacing: (_faqSections[sectionIndex]['items']
                                    as List<Map<String, String>>)[itemIndex]['question'] ==
                                'What is \'Wahala of the Day\'?'
                                ? 16.0
                                : null,
                          ),
                          if (itemIndex <
                              (_faqSections[sectionIndex]['items'] as List)
                                      .length -
                                  1)
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
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.74),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 38, 16, 0),
      child: Transform.translate(
        offset: const Offset(0, -15),
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
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172B),
                  letterSpacing: -0.38,
                  height: 28.57 / 20, // line-height: 28.57px
                ),
              ),
            ),
          ],
        ),
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
    this.customHeight,
    this.customSpacing,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;
  final double? customHeight;
  final double? customSpacing;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use specified width, but ensure it doesn't exceed available space
          final cardWidth = constraints.maxWidth < 360.7061462402344
              ? constraints.maxWidth
              : 360.7061462402344;
          
          return Container(
            width: cardWidth,
            height: isExpanded && hasAnswer 
                ? (customHeight ?? 184.45513916015625) 
                : null,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: isExpanded && hasAnswer
                  ? Border.all(color: borderColor, width: 0.74)
                  : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
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
                          fontFamily: 'Inter',
                          letterSpacing: -0.3,
                          height: 20 / 14, // line-height: 20px
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
                  SizedBox(height: customSpacing ?? 24),
                  Text(
                    answer,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF45556C),
                      fontFamily: 'Inter',
                      letterSpacing: -0.15,
                      height: 22.75 / 12, // line-height: 22.75px
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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
        border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Left vertical accent line
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
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
                      fontFamily: 'Inter',
                      letterSpacing: -0.625,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you can\'t find the answer you\'re looking for, reach out to our community support team. We\'re here to help!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF45556C),
                      fontFamily: 'Inter',
                      letterSpacing: -0.3008,
                      height: 22.75 / 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 150.55,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF155DFC),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleContactSupport,
                        borderRadius: BorderRadius.circular(10),
                        child: const Center(
                          child: Text(
                            'Contact Support',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Inter',
                              letterSpacing: -0.2266,
                              height: 19.5 / 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
