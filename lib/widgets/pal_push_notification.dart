import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/push_notification_group_store.dart';
import '../utils/push_notification_builder.dart';
import 'pal_app_icon.dart';

/// A slide-down push notification banner shown at the top of the screen.
/// Call [PalPushNotification.show] to display it using an OverlayEntry.
class PalPushNotification extends StatefulWidget {
  const PalPushNotification({
    super.key,
    required this.title,
    required this.message,
    this.data,
    this.groupModels = const [],
    this.icon,
    this.duration = const Duration(seconds: 4),
    required this.onRequestClose,
    required this.onExpandedChanged,
  });

  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final List<PushNotificationDisplayModel> groupModels;
  final Widget? icon;
  final Duration duration;
  final VoidCallback onRequestClose;
  final ValueChanged<bool> onExpandedChanged;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    Map<String, dynamic>? data,
    Widget? icon,
    Duration duration = const Duration(seconds: 4),
  }) async {
    var groupModels = <PushNotificationDisplayModel>[];
    if (data != null) {
      await PushNotificationGroupStore.add(data);
      final recentData = await PushNotificationGroupStore.getRecentData();
      groupModels = recentData
          .map((entry) => PushNotificationBuilder.fromRemoteData(entry))
          .toList();
    }

    final overlay = Overlay.of(context);

    OverlayEntry? barrierEntry;
    OverlayEntry? contentEntry;
    bool isClosed = false;
    bool contentRemoved = false;
    bool barrierRemoved = false;

    void closeAll() {
      if (isClosed) return;
      isClosed = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (contentEntry != null && !contentRemoved) {
          contentRemoved = true;
          try {
            contentEntry!.remove();
          } catch (_) {}
        }

        if (barrierEntry != null && !barrierRemoved) {
          barrierRemoved = true;
          try {
            barrierEntry!.remove();
          } catch (_) {}
        }
      });
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
          data: data,
          groupModels: groupModels,
          icon: icon,
          duration: duration,
          onRequestClose: closeAll,
          onExpandedChanged: (expanded) {
            if (expanded && barrierEntry != null && !isClosed) {
              try {
                overlay.insert(barrierEntry!, below: contentEntry!);
              } catch (e) {
                debugPrint('PalPushNotification: Error inserting barrier: $e');
              }
            } else if (barrierEntry != null && !isClosed && !barrierRemoved) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!barrierRemoved && !isClosed) {
                  barrierRemoved = true;
                  try {
                    barrierEntry!.remove();
                  } catch (_) {}
                }
              });
            }
          },
        ),
      ),
    );

    try {
      overlay.insert(contentEntry!);
    } catch (e) {
      debugPrint('PalPushNotification: Error inserting content: $e');
    }
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

  PushNotificationDisplayModel? get _currentModel {
    if (widget.data == null) return null;
    return PushNotificationBuilder.fromRemoteData(
      widget.data!,
      fallbackTitle: widget.title,
      fallbackBody: widget.message,
    );
  }

  bool get _showGroupSummary => widget.groupModels.length > 1;

  @override
  Widget build(BuildContext context) {
    final model = _currentModel;

    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PushNotificationShell(
              child: _showGroupSummary
                  ? _GroupSummaryPushCard(
                      count: widget.groupModels.length,
                      previewModel: model,
                      expanded: _expanded,
                      onToggle: () {
                        setState(() => _expanded = !_expanded);
                        widget.onExpandedChanged(_expanded);
                      },
                    )
                  : model == null
                      ? _GenericPushCard(
                          title: widget.title,
                          message: widget.message,
                        )
                      : _SinglePushCard(model: model),
            ),
            if (_expanded && _showGroupSummary)
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: _ExpandedGroupList(models: widget.groupModels),
              ),
          ],
        ),
      ),
    );
  }
}

class _SinglePushCard extends StatelessWidget {
  const _SinglePushCard({required this.model});

  final PushNotificationDisplayModel model;

  @override
  Widget build(BuildContext context) {
    return switch (model.variant) {
      PushNotificationVariant.postUpvote => _PostUpvotePushCard(model: model),
      PushNotificationVariant.commentSocial => _SocialPushCard(model: model),
      PushNotificationVariant.postComment => _SocialPushCard(model: model),
      PushNotificationVariant.generic => _GenericPushCard(
          title: model.androidTitle,
          message: model.androidBody ?? '',
        ),
    };
  }
}

class _GroupSummaryPushCard extends StatelessWidget {
  const _GroupSummaryPushCard({
    required this.count,
    required this.previewModel,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final PushNotificationDisplayModel? previewModel;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final summaryText = count == 1 ? '1 new message' : '$count new messages';
    final preview = previewModel?.inAppPreviewLine ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _AppIconBadge(size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _KobiPalBrandText(fontSize: 14),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Color(0xFF90A1B9))),
                  const SizedBox(width: 6),
                  Text(
                    summaryText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF62748E),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF45556C),
                    fontFamily: 'Inter',
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0x4D8EC5FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x4D8EC5FF)),
            ),
            child: Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFF155DFC),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandedGroupList extends StatelessWidget {
  const _ExpandedGroupList({required this.models});

  final List<PushNotificationDisplayModel> models;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (models.length > 1)
          Positioned(
            left: 17,
            top: 36,
            bottom: 36,
            child: Container(
              width: 2,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < models.length; i++) ...[
              _InlineGroupItem(model: models[i]),
              if (i != models.length - 1)
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
            ],
          ],
        ),
      ],
    );
  }
}

class _InlineGroupItem extends StatelessWidget {
  const _InlineGroupItem({required this.model});

  final PushNotificationDisplayModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarWithBadge(
          imageUrl: model.profilePictureUrl,
          initials: model.resolvedInitials,
          size: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontFamily: 'Inter',
                          color: Color(0xFF0F172A),
                        ),
                        children: [
                          TextSpan(
                            text: model.displayUsername,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' ${model.actionText}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    model.timestampLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              if (model.postTitle != null && model.postTitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  model.postTitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.15,
                    color: Color(0xFF62748E),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuoteContent extends StatelessWidget {
  const _QuoteContent({required this.text, this.useAccentColor = false});

  final String text;
  final bool useAccentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFCBD5E1), width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: useAccentColor
              ? const Color(0xFF155DFC)
              : const Color(0xFF475467),
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _PushNotificationShell extends StatelessWidget {
  const _PushNotificationShell({required this.child});

  final Widget child;

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
        child: child,
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  const _AppIconBadge({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return PalAppIcon(
      size: size,
      borderRadius: size > 24 ? 8 : 4,
    );
  }
}

class _AppBrandHeader extends StatelessWidget {
  const _AppBrandHeader({required this.timestampLabel});

  final String timestampLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _AppIconBadge(),
        const SizedBox(width: 6),
        const _KobiPalBrandText(fontSize: 13),
        const Spacer(),
        Text(
          timestampLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF62748E),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _KobiPalBrandText extends StatelessWidget {
  const _KobiPalBrandText({this.fontSize = 14});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF0F172A),
          fontFamily: 'Inter',
        ),
        children: const [
          TextSpan(text: 'Kobi', style: TextStyle(fontWeight: FontWeight.w200)),
          TextSpan(text: 'Pal', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    this.imageUrl,
    this.initials = 'SU',
    this.size = 40,
  });

  final String? imageUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final badgeSize = size * 0.4;
    const borderRadius = 8.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: const Color(0xFF0F172B), width: 2),
              color: const Color(0xFFF1F5F9),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.network(imageUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      initials.length >= 2
                          ? initials.substring(0, 2).toUpperCase()
                          : initials.toUpperCase(),
                      style: TextStyle(
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF314158),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: PalAppIcon(
              size: badgeSize,
              borderRadius: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPushCard extends StatelessWidget {
  const _SocialPushCard({required this.model});

  final PushNotificationDisplayModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarWithBadge(
          imageUrl: model.profilePictureUrl,
          initials: model.resolvedInitials,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontFamily: 'Inter',
                          color: Color(0xFF0F172A),
                        ),
                        children: [
                          TextSpan(
                            text: model.displayUsername,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' ${model.actionText}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    model.timestampLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              if (model.postTitle != null && model.postTitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  model.postTitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.15,
                    color: Color(0xFF62748E),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PostUpvotePushCard extends StatelessWidget {
  const _PostUpvotePushCard({required this.model});

  final PushNotificationDisplayModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const _AppIconBadge(),
            const SizedBox(width: 6),
            const _KobiPalBrandText(fontSize: 13),
            const SizedBox(width: 6),
            const Text('•', style: TextStyle(color: Color(0xFF90A1B9))),
            const SizedBox(width: 6),
            Text(
              model.timestampLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF62748E),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontFamily: 'Inter',
                    color: Color(0xFF0F172A),
                  ),
                  children: [
                    TextSpan(
                      text: model.displayUsername,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' ${model.actionText}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (model.hasProfileImage)
              _SquareThumbnail.network(
                url: model.profilePictureUrl!,
                fallbackInitials: model.resolvedInitials,
              )
            else
              _SquareThumbnail.initials(model.resolvedInitials),
          ],
        ),
      ],
    );
  }
}

class _SquareThumbnail extends StatelessWidget {
  const _SquareThumbnail.network({
    required this.url,
    required this.fallbackInitials,
  }) : initials = null;

  const _SquareThumbnail.initials(this.initials)
      : url = null,
        fallbackInitials = null;

  final String? url;
  final String? fallbackInitials;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final label = (initials ?? fallbackInitials ?? 'SU');
    final display = label.length >= 2
        ? label.substring(0, 2).toUpperCase()
        : label.toUpperCase();

    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _SquareThumbnail.initials(display),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0F172B), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        display,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF314158),
        ),
      ),
    );
  }
}

class _GenericPushCard extends StatelessWidget {
  const _GenericPushCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AppIconBadge(size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _KobiPalBrandText(),
              const SizedBox(height: 2),
              Text(
                message.isNotEmpty ? message : title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF45556C),
                  fontFamily: 'Inter',
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
