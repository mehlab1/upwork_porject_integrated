import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

/// A slide-down push notification banner shown at the top of the screen.
/// Call [PalPushNotification.show] to display it using an OverlayEntry.
class PalPushNotification extends StatefulWidget {
  const PalPushNotification({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.duration = const Duration(seconds: 3),
    required this.onRequestClose,
    required this.onExpandedChanged,
  });

  final String title;
  final String message;
  final Widget? icon;
  final Duration duration;
  final VoidCallback onRequestClose;
  final ValueChanged<bool> onExpandedChanged;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    Widget? icon,
    Duration duration = const Duration(seconds: 3),
  }) async {
    final overlay = Overlay.of(context);

    late OverlayEntry barrierEntry;
    late OverlayEntry contentEntry;

    void closeAll() {
      contentEntry.remove();
      barrierEntry.remove();
    }

    barrierEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: closeAll,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    contentEntry = OverlayEntry(
      builder: (ctx) => PalPushNotificationOverlay(
        child: PalPushNotification(
          title: title,
          message: message,
          icon: icon,
          duration: duration,
          onRequestClose: closeAll,
          onExpandedChanged: (expanded) {
            if (expanded) {
              // Show tap-outside barrier
              overlay.insert(barrierEntry, below: contentEntry);
            } else {
              barrierEntry.remove();
            }
          },
        ),
      ),
    );

    overlay.insert(contentEntry);
  }

  @override
  State<PalPushNotification> createState() => _PalPushNotificationState();
}

class PalPushNotificationOverlay extends StatelessWidget {
  const PalPushNotificationOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top > 0 ? 4 : 8,
            left: 12,
            right: 12,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PalPushNotificationState extends State<PalPushNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future<void>.delayed(widget.duration, () async {
      if (!mounted) return;
      if (!_expanded) {
        await _controller.reverse();
        if (mounted) widget.onRequestClose();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<PalInlineNotificationItem> demoItems = [
      PalInlineNotificationItem(
        avatarAsset: 'assets/feedPage/profile.png',
        username: 'lagosian_pro',
        actionText: 'upvoted your comment',
        content: 'I totally agree! The traffic is insane during rush hour……',
        timeAgo: '16m',
      ),
      PalInlineNotificationItem(
        avatarAsset: 'assets/feedPage/profile.png',
        username: 'naija_foodie',
        actionText: 'mentioned you in a comment',
        content: 'Check out that new spot in VI — you will love it!',
        timeAgo: '1h',
      ),
    ];

    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NotificationCard(
              title: widget.title,
              message: widget.message,
              leading:
                  widget.icon ??
                  const Icon(
                    Icons.notifications,
                    color: Color(0xFF155DFC),
                    size: 22,
                  ),
              expanded: _expanded,
              onToggle: () {
                setState(() {
                  _expanded = !_expanded;
                });
                widget.onExpandedChanged(_expanded);
              },
            ),
            if (_expanded)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x1A000000),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in demoItems) ...[
                      _InlineNotificationItem(item: item),
                      if (item != demoItems.last)
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.message,
    required this.leading,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final String message;
  final Widget leading;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1A000000), width: 0.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left icon div with app icon on blue background
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF155DFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: svg.SvgPicture.asset(
                  'assets/images/icon.svg',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // "Kobi" + bold "Pal"
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Inter',
                            decoration: TextDecoration.none,
                          ),
                          children: [
                            TextSpan(
                              text: 'Kobi',
                              style: TextStyle(fontWeight: FontWeight.w200),
                            ),
                            TextSpan(
                              text: 'Pal',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFF90A1B9)),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '2 new messages',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF62748E),
                          fontFamily: 'Inter',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF45556C),
                      fontFamily: 'Inter',
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing dropdown icon chip (vertically centered)
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0x4D8EC5FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x4D8EC5FF),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: const Color(0xFF155DFC),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PalInlineNotificationItem {
  PalInlineNotificationItem({
    required this.avatarAsset,
    required this.username,
    required this.actionText,
    required this.content,
    required this.timeAgo,
  });

  final String avatarAsset;
  final String username;
  final String actionText;
  final String content;
  final String timeAgo;
}

class _InlineNotificationItem extends StatelessWidget {
  const _InlineNotificationItem({required this.item});

  final PalInlineNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Square avatar with thick border + bottom-right app icon badge
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0F172B), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(item.avatarAsset, fit: BoxFit.cover),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF155DFC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: svg.SvgPicture.asset(
                      'assets/images/icon.svg',
                      width: 10,
                      height: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    item.username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172B),
                      fontFamily: 'Inter',
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    item.actionText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF62748E),
                      fontFamily: 'Inter',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172B),
                  height: 1.35,
                  fontFamily: 'Inter',
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.timeAgo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172B),
            fontFamily: 'Inter',
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
