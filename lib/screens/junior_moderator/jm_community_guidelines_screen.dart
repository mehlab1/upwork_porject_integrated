import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class JmCommunityGuidelinesScreen extends StatelessWidget {
  const JmCommunityGuidelinesScreen({super.key});

  static const routeName = '/settings/community-guidelines';
  static const _pagePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 24,
  );
  static const _sectionSpacing = SizedBox(height: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _GuidelinesAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    Padding(padding: _pagePadding, child: const _WelcomeCard()),
                    Padding(
                      padding: _pagePadding,
                      child: Column(
                        children: const [
                          _UnderstandingCategories(),
                          _sectionSpacing,
                          _MonthlyTopicSection(),
                          _sectionSpacing,
                          _CommunityRules(),
                          _sectionSpacing,
                          _ConsequencesSection(),
                          _sectionSpacing,
                          _FooterSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelinesAppBar extends StatelessWidget {
  const _GuidelinesAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF0F172B),
              size: 24,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Community Guidelines',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172B),
                letterSpacing: 0.07,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24.75, 24.75, 24.75, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/icon.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Pal',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172B),
                        letterSpacing: -0.31,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's keep our community safe and friendly",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF45556C),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Our forum is built on mutual respect and the shared goal of making Lagos better for everyone. These guidelines help ensure everyone has a positive experience. By participating, you agree to follow these rules.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF45556C),
              height: 1.62,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderstandingCategories extends StatelessWidget {
  const _UnderstandingCategories();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Understanding Post Categories',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172B),
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 16),
          const _CategoryCard(
            title: 'Gist',
            description:
                'Share news, updates, events, or interesting things happening in your neighborhood. Traffic alerts, power outages, new businesses, local events, or general community updates.',
            example:
                '"New restaurant opening in Ikoyi next week" or "Traffic alert: Lekki-Epe Expressway"',
            background: Color(0xFFFAF5FF),
            borderColor: Color(0xFFE9D4FF),
            titleColor: Color(0xFF59168B),
            exampleColor: Color(0xFF8200DB),
            iconAsset: 'assets/images/gistIcon.svg',
            iconColor: Color(0xFF8200DB),
          ),
          const SizedBox(height: 16),
          const _CategoryCard(
            title: 'Ask',
            description:
                'Ask for recommendations, advice, or help from the community. Best for seeking information, suggestions, or local knowledge from your neighbors.',
            example:
                '"Best barber in Lekki Phase 1?" or "Good mechanic around VI?"',
            background: Color(0xFFF0FDF4),
            borderColor: Color(0xFFB9F8CF),
            titleColor: Color(0xFF0D542B),
            exampleColor: Color(0xFF008236),
            iconAsset: 'assets/images/askIcon.svg',
            iconColor: Color(0xFF008236),
          ),
          const SizedBox(height: 16),
          const _CategoryCard(
            title: 'Discussion',
            description:
                'Start conversations about local issues, community matters, or topics that affect your area. Engage in thoughtful dialogue about neighborhood concerns or improvements.',
            example:
                '"Thoughts on the new security measures in Ikoyi?" or "How can we improve waste management?"',
            background: Color(0xFFFFFBEB),
            borderColor: Color(0xFFFEE685),
            titleColor: Color(0xFF7B3306),
            exampleColor: Color(0xFFBB4D00),
            iconAsset: 'assets/images/discussionIcon.svg',
            iconColor: Color(0xFFBB4D00),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.description,
    required this.example,
    required this.background,
    required this.borderColor,
    required this.titleColor,
    required this.exampleColor,
    required this.iconAsset,
    required this.iconColor,
  });

  final String title;
  final String description;
  final String example;
  final Color background;
  final Color borderColor;
  final Color titleColor;
  final Color exampleColor;
  final String iconAsset;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.756),
      ),
      padding: const EdgeInsets.fromLTRB(16.75, 16.75, 16.75, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF45556C),
              height: 1.62,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            example,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: exampleColor,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTopicSection extends StatelessWidget {
  const _MonthlyTopicSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF314158), Color(0xFF45556C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/dettyIcon.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Spotlight',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Each month, we feature a special topic for community discussion. This month's theme is highlighted across the feed to encourage focused conversation on relevant local holidays.",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xE6FFFFFF),
              height: 1.62,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Topic:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xCCFFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"Festive Season: Detty December"',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.15,
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

class _CommunityRules extends StatelessWidget {
  const _CommunityRules();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _RuleCard(
          iconBackground: Color(0xFFF0FFF7),
          iconAsset: 'assets/settings/inviteFriends.svg',
          iconTint: Color(0xFF008236),
          title: 'Be Respectful & Civil',
          body:
              'Treat everyone with respect. No harassment, hate speech, personal attacks, or bullying. Disagree with ideas, not people. We\'re all neighbors working to make Lagos better.',
          example:
              'Example: Instead of "You\'re stupid for thinking that," say "I disagree because..." or "I see it differently..."',
          extraBoxColor: Color(0xFFF8FAFC),
        ),
        SizedBox(height: 16),
        _RuleCard(
          iconBackground: Color(0xFFFFE5E7),
          iconAsset: 'assets/settings/noillegalContent.svg',
          iconTint: Color(0xFFE7000B),
          title: 'No Illegal Content',
          body:
              'Do not post anything illegal or that promotes illegal activity. This includes:',
          bulletPoints: [
            'Selling or promoting illegal goods or services',
            'Sharing pirated content or encouraging piracy',
            'Doxxing (sharing private information without consent)',
            'Scams, fraud, or financial schemes',
            'Content that violates local laws',
          ],
          extraNoteColor: Color(0xFFE7000B),
          extraNoteText:
              'Violations will result in immediate account suspension and may be reported to authorities.',
        ),
        SizedBox(height: 16),
        _RuleCard(
          iconBackground: Color(0xFFFFF1DB),
          iconAsset: 'assets/settings/languageIcon.svg',
          iconTint: Color(0xFFF54900),
          title: 'Watch Your Language',
          body:
              'Excessive profanity, vulgar language, or sexually explicit content is not allowed.  Keep the conversation respectful, inclusive, and free of content that could make others uncomfortable or unsafe.',
        ),
        SizedBox(height: 16),
        _RuleCard(
          iconBackground: Color(0xFFFFE5E7),
          iconAsset: 'assets/settings/noSpamIcon.svg',
          iconTint: Color(0xFFE7000B),
          title: 'No Spam or Self-Promotion',
          body:
              "Don't post repetitive content, excessive self-promotion, or unsolicited advertising. Genuine recommendations and helpful business suggestions are welcome, but blatant ads and spam are not.",
        ),
        SizedBox(height: 16),
        _RuleCard(
          iconBackground: Color(0xFFE0EDFF),
          iconAsset: 'assets/settings/commentIcon.svg',
          iconTint: Color(0xFF155DFC),
          title: 'Upvote & Downvote Responsibly',
          body:
              "Upvote posts and comments that contribute to the conversation. Downvote only if content is off-topic, misleading, or violates guidelines, not just because you disagree.\n\nDon't brigade or coordinate downvotes against specific users. Don't bully people by mass downvoting their posts. Use the downvote button fairly and responsibly.",
        ),
        SizedBox(height: 16),
        _RuleCard(
          iconBackground: Color(0xFFF3E8FF),
          iconAsset: 'assets/settings/commentIcon.svg',
          iconTint: Color(0xFF9810FA),
          title: 'Stay On Topic',
          body:
              'Keep posts relevant to Lagos and the selected neighborhood. Use the right category (Gist, Ask, Discussion) for your post.',
          chipLabels: const ['Gist', 'Ask', 'Discussion'],
        ),
        SizedBox(height: 16),
        _RuleCard(
          iconBackground: Color(0xFFFFF1DB),
          iconAsset: 'assets/settings/reportIcon.svg',
          iconTint: Color(0xFFE17100),
          title: "Report, Don't Retaliate",
          body:
              'If you see content that violates these guidelines, report it. Don\'t engage in arguments, harass the user, or retaliate. Let the moderators handle it. Fighting fire with fire only makes things worse.',
        ),
      ],
    );
  }
}

class _ChipStyle {
  const _ChipStyle({
    required this.background,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color text;
}

const Map<String, _ChipStyle> _chipStyles = {
  'gist': _ChipStyle(
    background: Color(0xFFFAF5FF),
    border: Color(0xFFE9D4FF),
    text: Color(0xFF8200DB),
  ),
  'ask': _ChipStyle(
    background: Color(0xFFF0FDF4),
    border: Color(0xFFB9F8CF),
    text: Color(0xFF008236),
  ),
  'discussion': _ChipStyle(
    background: Color(0xFFFFFBEB),
    border: Color(0xFFFEE685),
    text: Color(0xFFBB4D00),
  ),
};

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.iconBackground,
    required this.iconAsset,
    this.iconTint,
    required this.title,
    required this.body,
    this.extraBoxColor,
    this.example,
    this.bulletPoints = const [],
    this.extraNoteColor,
    this.extraNoteText,
    this.chipLabels,
  });

  final Color iconBackground;
  final String iconAsset;
  final Color? iconTint;
  final String title;
  final String body;
  final Color? extraBoxColor;
  final String? example;
  final List<String> bulletPoints;
  final Color? extraNoteColor;
  final String? extraNoteText;
  final List<String>? chipLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.756),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: iconTint == null
                    ? null
                    : ColorFilter.mode(iconTint!, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0F172B),
                    letterSpacing: -0.31,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF45556C),
                    height: 1.62,
                    letterSpacing: -0.15,
                  ),
                ),
                if (bulletPoints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bulletPoints
                        .map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ' ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF45556C),
                                    height: 1.55,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF45556C),
                                      letterSpacing: -0.15,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (extraBoxColor != null &&
                    example != null &&
                    example!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: extraBoxColor!,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Text(
                      example!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ] else if (example != null && example!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    example!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172B),
                      height: 1.4,
                    ),
                  ),
                ],
                if (chipLabels != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: chipLabels!.map((label) {
                      final _ChipStyle style =
                          _chipStyles[label.toLowerCase()] ??
                          const _ChipStyle(
                            background: Color(0xFFF8FAFC),
                            border: Color(0xFFE2E8F0),
                            text: Color(0xFF0F172B),
                          );
                      return Chip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: style.text,
                          ),
                        ),
                        backgroundColor: style.background,
                        side: BorderSide(color: style.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (extraNoteText != null && extraNoteText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    extraNoteText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: extraNoteColor ?? const Color(0xFFE7000B),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsequencesSection extends StatelessWidget {
  const _ConsequencesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172B),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consequences',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Violations may result in:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCAD5E2),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 16),
          const _ConsequencesListItem(text: 'Warning and post removal'),
          const _ConsequencesListItem(text: 'Temporary suspension (3-30 days)'),
          const _ConsequencesListItem(
            text: 'Permanent ban for severe or repeated violations',
          ),
          const _ConsequencesListItem(
            text: 'Report to authorities for illegal content',
          ),
          const SizedBox(height: 16),
          Text(
            'We want everyone to enjoy Pal, so please follow these guidelines and help us maintain a positive, welcoming community.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCAD5E2),
              height: 1.62,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsequencesListItem extends StatelessWidget {
  const _ConsequencesListItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCAD5E2),
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFCAD5E2),
                letterSpacing: -0.15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF45556C),
              letterSpacing: -0.15,
            ),
            children: [
              const TextSpan(text: 'Questions about our guidelines? '),
              TextSpan(
                text: 'Contact us',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF45556C),
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated: October 2025',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF62748E),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}
