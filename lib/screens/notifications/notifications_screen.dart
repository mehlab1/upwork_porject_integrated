import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _isPageLoading = false;
      });
    });
  }

  Future<void> _refreshNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _NotificationsHeader(),
            Expanded(
              child: PalRefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _notificationItems.length + 1,
                  separatorBuilder: (_, index) {
                    if (index == 0) {
                      return const SizedBox(height: 0);
                    }
                    return const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const _WelcomeNotificationCard();
                    }
                    final item = _notificationItems[index - 1];
                    return _NotificationTile(item: item);
                  },
                ),
              ),
            ),
            PalBottomNavigationBar(
              active: PalNavDestination.notifications,
              onHomeTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('/home');
              },
              onNotificationsTap: () {},
              onSettingsTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
    return Stack(
      children: [scaffold, if (_isPageLoading) const PalLoadingOverlay()],
    );
  }
}

class _WelcomeNotificationCard extends StatelessWidget {
  const _WelcomeNotificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(254, 242, 242, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🎉',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172A),
                        ),
                        children: [
                          TextSpan(text: 'Welcome to '),
                          TextSpan(
                            text: 'Pal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                '! A chill spot to vibe, swap ideas, learn, and grow together',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '2m ago',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFE7000B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            width: 28.07,
            height: 23.99,
            decoration: const BoxDecoration(
              color: Color(0xFFE7000B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25378200),
                topRight: Radius.circular(25378200),
                bottomLeft: Radius.circular(25378200),
                bottomRight: Radius.circular(25378200),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              '4',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: item.tileBackgroundColor),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationAvatar(item: item),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _NotificationHeadline(item: item)),
                    if (item.unread)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3358),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
                if (item.body != null) ...[
                  const SizedBox(height: 6),
                  if (item.bodyAsQuote)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0xFFCBD5E1), width: 3),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                      child: Text(
                        item.body!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF475467),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Text(
                        item.body!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ),
                ],
                if (item.ctaLabel != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/notifications/sharelink.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: Text(
                      item.ctaLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      backgroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.timestamp,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
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

class _NotificationHeadline extends StatelessWidget {
  const _NotificationHeadline({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    for (final part in item.headlineParts) {
      spans.add(
        TextSpan(
          text: part.text,
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: part.isEmphasized ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF0F172A),
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    const double size = 46.99876;
    if (item.avatarImageAsset != null) {
      final image = Image.asset(
        item.avatarImageAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );

      if (!item.hasAvatarBorder) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: image,
        );
      }

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: const Color(0xFF0F172B), width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      );
    }

    final BoxDecoration decoration = BoxDecoration(
      color: item.avatarGradient == null
          ? item.avatarBackground ?? const Color(0xFFF1F5F9)
          : null,
      gradient: item.avatarGradient,
      borderRadius: BorderRadius.circular(size / 2),
      border: item.hasAvatarBorder
          ? Border.all(color: const Color(0xFF0F172B), width: 3)
          : null,
    );

    if (item.avatarSvgAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        alignment: Alignment.center,
        child: SvgPicture.asset(
          item.avatarSvgAsset!,
          width: 24,
          height: 24,
          colorFilter: item.avatarIconColor != null
              ? ColorFilter.mode(item.avatarIconColor!, BlendMode.srcIn)
              : null,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Icon(
        item.avatarIcon ?? Icons.notifications_outlined,
        color: item.avatarIconColor ?? Colors.white,
        size: 24,
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.headlineParts,
    required this.timestamp,
    this.subtitle,
    this.body,
    this.bodyAsQuote = false,
    this.avatarImageAsset,
    this.avatarIcon,
    this.avatarSvgAsset,
    this.avatarBackground,
    this.avatarGradient,
    this.avatarIconColor,
    this.ctaLabel,
    this.unread = false,
    this.hasAvatarBorder = false,
    this.tileBackgroundColor,
  });

  final List<_HeadlinePart> headlineParts;
  final String? subtitle;
  final String? body;
  final bool bodyAsQuote;
  final String timestamp;
  final String? avatarImageAsset;
  final IconData? avatarIcon;
  final String? avatarSvgAsset;
  final Color? avatarBackground;
  final Gradient? avatarGradient;
  final Color? avatarIconColor;
  final String? ctaLabel;
  final bool unread;
  final bool hasAvatarBorder;
  final Color? tileBackgroundColor;
}

class _HeadlinePart {
  const _HeadlinePart(this.text, {this.isEmphasized = false});

  final String text;
  final bool isEmphasized;
}

const _notificationItems = [
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('chefjade', isEmphasized: true),
      _HeadlinePart(' mentioned you in a comment'),
    ],
    subtitle: 'Best shawarma spots in Lekki?',
    timestamp: '2m ago',
    avatarImageAsset: 'assets/feedPage/profile.png',
    unread: true,
    hasAvatarBorder: true,
    tileBackgroundColor: Color.fromRGBO(254, 242, 242, 0.4),
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('tolu_chef', isEmphasized: true),
      _HeadlinePart(' upvoted your post'),
    ],
    subtitle: 'Traffic update: Third Mainland Bridge',
    timestamp: '15m ago',
    avatarImageAsset: 'assets/feedPage/profile.png',
    unread: true,
    hasAvatarBorder: true,
    tileBackgroundColor: Color.fromRGBO(254, 242, 242, 0.4),
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('Your post is the hottest in Victoria Island right now!'),
    ],
    subtitle: 'Best jollof rice spots in VI',
    timestamp: '1h ago',
    avatarSvgAsset: 'assets/images/hotIcon.svg',
    avatarGradient: const LinearGradient(
      colors: [Color(0xFFFF6900), Color(0xFFE7000B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    avatarIconColor: Colors.white,
    unread: true,
    tileBackgroundColor: Color.fromRGBO(254, 242, 242, 0.4),
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('lagosian_pro', isEmphasized: true),
      _HeadlinePart(' upvoted your comment'),
    ],
    body: 'I totally agree! The traffic is insane during rush hour.',
    subtitle: 'Traffic update: Third Mainland Bridge',
    timestamp: '2h ago',
    avatarImageAsset: 'assets/feedPage/profile.png',
    hasAvatarBorder: true,
    bodyAsQuote: true,
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart(
        'Invite your friends to join Pal! Share your referral link and grow the community.',
      ),
    ],
    timestamp: '3h ago',
    avatarBackground: Color(0xFF00A63E),
    avatarSvgAsset: 'assets/notifications/sharelink.svg',
    avatarIconColor: Colors.white,
    ctaLabel: 'Share Link',
  ),
  _NotificationItem(
    headlineParts: [_HeadlinePart('Your post reached Top Posts this week!')],
    subtitle: 'Power outage in Lekki Phase 1 - again!',
    timestamp: '4h ago',
    avatarBackground: Color(0xFF9810FA),
    avatarSvgAsset: 'assets/notifications/topPost.svg',
    avatarIconColor: Colors.white,
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('foodie_naija', isEmphasized: true),
      _HeadlinePart(' mentioned you in a post'),
    ],
    subtitle: 'Where to get authentic suya in Lagos?',
    timestamp: '5h ago',
    avatarBackground: Color(0xFFEBF5FF),
    avatarIcon: Icons.alternate_email_rounded,
    avatarIconColor: Color(0xFF2563EB),
    hasAvatarBorder: true,
  ),
  _NotificationItem(
    headlineParts: [_HeadlinePart('Your report is under review')],
    subtitle: 'Spam post about fake investment',
    timestamp: '6h ago',
    avatarBackground: Color(0xFF314158),
    avatarSvgAsset: 'assets/notifications/underReview.svg',
    avatarIconColor: Colors.white,
  ),
  _NotificationItem(
    headlineParts: [_HeadlinePart('Your post is getting hot!')],
    subtitle: 'Best shawarma spots in Lekki?',
    timestamp: '8h ago',
    avatarSvgAsset: 'assets/images/hotIcon.svg',
    avatarGradient: const LinearGradient(
      colors: [Color(0xFFFF6900), Color(0xFFE7000B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    avatarIconColor: Colors.white,
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('ikoyi_babe', isEmphasized: true),
      _HeadlinePart(' shared your post'),
    ],
    subtitle: 'Best gym in Victoria Island?',
    timestamp: '12h ago',
    avatarImageAsset: 'assets/feedPage/profile.png',
    hasAvatarBorder: true,
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart('eko_boy', isEmphasized: true),
      _HeadlinePart(' upvoted your post'),
    ],
    subtitle: 'New restaurant in Ikoyi - must try!',
    timestamp: '1d ago',
    avatarImageAsset: 'assets/feedPage/profile.png',
    hasAvatarBorder: true,
  ),
  _NotificationItem(
    headlineParts: [_HeadlinePart('Your post is trending in Lekki Phase 1')],
    subtitle: 'Where to find good internet in Lagos',
    timestamp: '1d ago',
    avatarBackground: Color(0xFF9810FA),
    avatarSvgAsset: 'assets/notifications/topPost.svg',
    avatarIconColor: Colors.white,
  ),
  _NotificationItem(
    headlineParts: [
      _HeadlinePart(
        'Your account has been temporarily suspended for violating community guidelines. Please review our policies.',
      ),
    ],
    timestamp: '2d ago',
    avatarBackground: Color(0xFFC10007),
    avatarSvgAsset: 'assets/notifications/accountSuspended.svg',
    avatarIconColor: Colors.white,
  ),
];
