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
  bool _isAtTopDuringRefresh = true; // Track if we're at top during refresh

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..repeat();

  double get _progress =>
      _isRefreshing ? 1 : (_pullExtent / _triggerDistance).clamp(0.0, 1.0);

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    // Only refresh if we've actually pulled down enough
    if (_pullExtent < _triggerDistance) {
      setState(() => _pullExtent = 0);
      return;
    }
    setState(() {
      _isRefreshing = true;
      _isAtTopDuringRefresh = true; // Start refresh at top
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullExtent = 0;
          _isAtTopDuringRefresh = true;
        });
      }
    }
  }

  bool _handleNotification(ScrollNotification notification) {
    // Only allow pull-to-refresh when at the very top (pixels <= 0)
    final isAtTop = notification.metrics.pixels <= 0;
    
    // If refreshing, track if user scrolls away from top
    if (_isRefreshing) {
      if (!isAtTop && notification.metrics.pixels > 0) {
        // User scrolled away during refresh - hide indicator but don't cancel refresh
        if (_isAtTopDuringRefresh) {
          setState(() {
            _isAtTopDuringRefresh = false;
          });
        }
      } else if (isAtTop && notification.metrics.pixels <= 0) {
        // User scrolled back to top during refresh - show indicator again
        if (!_isAtTopDuringRefresh) {
          setState(() {
            _isAtTopDuringRefresh = true;
          });
        }
      }
      // Don't allow new pull-to-refresh gestures while already refreshing
      return false;
    }
    
    if (notification is ScrollUpdateNotification) {
      // Only respond to pull down when at the top
      if (isAtTop && notification.metrics.pixels < 0) {
        final next = (-notification.metrics.pixels).clamp(
          0.0,
          _triggerDistance,
        );
        if ((next - _pullExtent).abs() > 0.5) {
          setState(() => _pullExtent = next);
        }
      } else if (!isAtTop && _pullExtent != 0) {
        // Reset if scrolled away from top
        setState(() => _pullExtent = 0);
      } else if (isAtTop && notification.metrics.pixels >= 0 && _pullExtent != 0) {
        // Reset if at top but not pulling down
        setState(() => _pullExtent = 0);
      }
    } else if (notification is OverscrollNotification) {
      // Only allow overscroll when at the top and pulling down (negative overscroll)
      if (isAtTop && notification.overscroll < 0) {
        final next = (_pullExtent + notification.overscroll.abs()).clamp(
          0.0,
          _triggerDistance,
        );
        if ((next - _pullExtent).abs() > 0.5) {
          setState(() => _pullExtent = next);
        }
      } else if (!isAtTop && _pullExtent != 0) {
        // Reset if not at top
        setState(() => _pullExtent = 0);
      }
    } else if (notification is ScrollEndNotification) {
      // Trigger refresh if pulled enough, otherwise reset
      if (_pullExtent >= _triggerDistance && isAtTop) {
        _handleRefresh();
      } else if (_pullExtent != 0) {
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
    // Show indicator when:
    // 1. Pulling down (not refreshing, but progress > 0)
    // 2. Refreshing AND at top (standard behavior)
    // Hide indicator when refreshing but user scrolled away
    final showIndicator = (!_isRefreshing && _progress > 0.05) || 
                          (_isRefreshing && _isAtTopDuringRefresh);
    final double translateY = -30 * (1 - _progress);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.transparent,
            backgroundColor: Colors.transparent,
            strokeWidth: 0,
            displacement: 64,
            // Only trigger when at the top
            triggerMode: RefreshIndicatorTriggerMode.onEdge,
            child: widget.child,
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
      ),
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
