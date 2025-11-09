import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PostCardVariant { top, hot, newPost }

class PostCardData {
  const PostCardData({
    required this.variant,
    required this.username,
    required this.timeAgo,
    required this.location,
    required this.category,
    required this.title,
    required this.body,
    required this.commentsCount,
    required this.votes,
    this.avatarAsset,
  });

  final PostCardVariant variant;
  final String username;
  final String timeAgo;
  final String location;
  final String category;
  final String title;
  final String body;
  final int commentsCount;
  final int votes;
  final String? avatarAsset;
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.data});

  final PostCardData data;

  @override
  Widget build(BuildContext context) {
    final palette = _PostCardPalette.fromVariant(data.variant);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostHeader(data: data, palette: palette),
                  const SizedBox(height: 24),
                  _PostTitle(title: data.title, color: palette.titleColor),
                  const SizedBox(height: 16),
                  _PostBody(body: data.body),
                  const SizedBox(height: 24),
                  _PostFooter(data: data, palette: palette),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.data, required this.palette});

  final PostCardData data;
  final _PostCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(asset: data.avatarAsset),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    data.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.timeAgo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    icon: 'assets/images/locationIcon.svg',
                    label: data.location,
                    background: const Color(0xFFEFF4FF),
                    foreground: const Color(0xFF155DFC),
                    borderColor: const Color(0xFFBDD6FF),
                  ),
                  _Badge(
                    icon: 'assets/images/askIcon.svg',
                    label: data.category,
                    background: const Color(0xFFEFFDF4),
                    foreground: const Color(0xFF15803D),
                    borderColor: const Color(0xFFBDE9CE),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ReactionColumn(data: data, palette: palette),
      ],
    );
  }
}

class _PostTitle extends StatelessWidget {
  const _PostTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Text(
      body,
      style: const TextStyle(
        fontSize: 14,
        height: 1.65,
        color: Color(0xFF45556C),
        fontFamily: 'Inter',
      ),
    );
  }
}

class _PostFooter extends StatelessWidget {
  const _PostFooter({required this.data, required this.palette});

  final PostCardData data;
  final _PostCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.commentBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: palette.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${data.commentsCount} comments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.accentColor,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.more_horiz, size: 24, color: palette.metaColor),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 47,
      height: 47,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8EDFF),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset != null
          ? SvgPicture.asset(asset!, fit: BoxFit.cover)
          : const Icon(Icons.person, color: Color(0xFF155DFC), size: 22),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  final String icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionColumn extends StatelessWidget {
  const _ReactionColumn({required this.data, required this.palette});

  final PostCardData data;
  final _PostCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoteButton(
          icon: 'assets/images/upArrow.svg',
          background: palette.voteButtonBackground,
          borderColor: palette.voteBorderColor,
          iconColor: palette.accentColor,
        ),
        const SizedBox(height: 8),
        Text(
          '${data.votes}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: palette.accentColor,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        _VoteButton(
          icon: 'assets/images/downArrow.svg',
          background: Colors.white,
          borderColor: palette.voteBorderColor,
          iconColor: palette.downvoteColor,
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.background,
    required this.borderColor,
    required this.iconColor,
  });

  final String icon;
  final Color background;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(
        child: SvgPicture.asset(
          icon,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _PostCardPalette {
  const _PostCardPalette({
    required this.borderColor,
    required this.titleColor,
    required this.accentColor,
    required this.metaColor,
    required this.commentBackground,
    required this.voteButtonBackground,
    required this.voteBorderColor,
    required this.downvoteColor,
  });

  final Color borderColor;
  final Color titleColor;
  final Color accentColor;
  final Color metaColor;
  final Color commentBackground;
  final Color voteButtonBackground;
  final Color voteBorderColor;
  final Color downvoteColor;

  static _PostCardPalette fromVariant(PostCardVariant variant) {
    switch (variant) {
      case PostCardVariant.top:
        return _PostCardPalette(
          borderColor: const Color(0xFFE2E8F0),
          titleColor: const Color(0xFF0F172A),
          accentColor: const Color(0xFF155DFC),
          metaColor: const Color(0xFF94A3B8),
          commentBackground: const Color(0xFFEFF4FF),
          voteButtonBackground: const Color(0xFFE6F0FF),
          voteBorderColor: const Color(0xFFBDD6FF),
          downvoteColor: const Color(0xFF1D4ED8),
        );
      case PostCardVariant.hot:
        return _PostCardPalette(
          borderColor: const Color(0xFFFFE1C3),
          titleColor: const Color(0xFF331B09),
          accentColor: const Color(0xFFFF7A00),
          metaColor: const Color(0xFFB4692E),
          commentBackground: const Color(0xFFFFF4EA),
          voteButtonBackground: const Color(0xFFFFF1E6),
          voteBorderColor: const Color(0xFFFFD6AE),
          downvoteColor: const Color(0xFFFB923C),
        );
      case PostCardVariant.newPost:
        return _PostCardPalette(
          borderColor: const Color(0xFFE2E8F0),
          titleColor: const Color(0xFF0F172A),
          accentColor: const Color(0xFF334155),
          metaColor: const Color(0xFF94A3B8),
          commentBackground: const Color(0xFFF1F5F9),
          voteButtonBackground: const Color(0xFFF3F4F6),
          voteBorderColor: const Color(0xFFE2E8F0),
          downvoteColor: const Color(0xFF64748B),
        );
    }
  }
}
