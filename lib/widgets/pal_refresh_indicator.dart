import 'package:flutter/material.dart';

class PalRefreshIndicator extends StatefulWidget {
  const PalRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<PalRefreshIndicator> createState() => _PalRefreshIndicatorState();
}

class _PalRefreshIndicatorState extends State<PalRefreshIndicator>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 100;
  double _pullExtent = 0;
  bool _isRefreshing = false;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..repeat();

  double get _progress =>
      _isRefreshing ? 1 : (_pullExtent / _triggerDistance).clamp(0.0, 1.0);

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullExtent = 0;
        });
      }
    }
  }

  bool _handleNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0) {
        final next = (-notification.metrics.pixels).clamp(
          0.0,
          _triggerDistance,
        );
        if ((next - _pullExtent).abs() > 0.5) {
          setState(() => _pullExtent = next);
        }
      } else if (_pullExtent != 0) {
        setState(() => _pullExtent = 0);
      }
    } else if (notification is OverscrollNotification) {
      if (notification.metrics.pixels <= 0 && notification.overscroll < 0) {
        final next = (_pullExtent + notification.overscroll.abs()).clamp(
          0.0,
          _triggerDistance,
        );
        if ((next - _pullExtent).abs() > 0.5) {
          setState(() => _pullExtent = next);
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_pullExtent != 0) {
        setState(() => _pullExtent = 0);
      }
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = _isRefreshing || _progress > 0.05;
    final double translateY = -30 * (1 - _progress);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleNotification,
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.transparent,
            backgroundColor: Colors.transparent,
            strokeWidth: 0,
            displacement: 64,
            child: widget.child,
          ),
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: showIndicator ? 1 : 0,
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: _DotLoader(
                  controller: _controller,
                  progress: _progress,
                  refreshing: _isRefreshing,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotLoader extends StatelessWidget {
  const _DotLoader({
    required this.controller,
    required this.progress,
    required this.refreshing,
  });

  final AnimationController controller;
  final double progress;
  final bool refreshing;

  static const _dotSizes = [6.0, 9.0, 12.0];

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 40,
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final animationValue = refreshing
                ? controller.value
                : clampedProgress;
            final colors = const [
              Color(0xFF99B7FF),
              Color(0xFF6FA0FF),
              Color(0xFF155DFC),
            ];
            final dotColors = List<Color>.generate(3, (index) {
              final shifted = (animationValue * 3 + index) % 3;
              return colors[shifted.floor()];
            });
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final baseSize = _dotSizes[index];
                final animatedSize = refreshing
                    ? baseSize
                    : baseSize + clampedProgress * (index == 2 ? 1.5 : 1);
                return Container(
                  width: animatedSize,
                  height: animatedSize,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: dotColors[index].withOpacity(
                      refreshing ? 1 : (0.4 + clampedProgress * 0.6),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
