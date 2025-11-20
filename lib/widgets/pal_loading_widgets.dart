import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PalLoadingOverlay extends StatelessWidget {
  const PalLoadingOverlay({super.key, this.showTagline = true});

  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFF), Color(0xFFE9F1FF)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF155DFC),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 32,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/images/icon.svg',
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(height: 44),
                const PalAnimatedLoadingBar(),
              ],
            ),
            if (showTagline)
              const Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Your every day ',
                          style: TextStyle(color: Color(0xFF90A1B9)),
                        ),
                        TextSpan(
                          text: 'community',
                          style: TextStyle(color: Color(0xFF155DFC)),
                        ),
                      ],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.15,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoadingPostSkeleton extends StatelessWidget {
  const LoadingPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE3EAF3);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Shimmer(
                child: CircleAvatar(radius: 23.5, backgroundColor: baseColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Shimmer(child: const _SkeletonBox(width: 120, height: 16)),
                    const SizedBox(height: 8),
                    _Shimmer(child: const _SkeletonBox(width: 160, height: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Shimmer(
                child: const _SkeletonBox(width: 64, height: 24, radius: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Shimmer(
            child: const _SkeletonBox(width: double.infinity, height: 18),
          ),
          const SizedBox(height: 14),
          _Shimmer(
            child: const _SkeletonBox(width: double.infinity, height: 16),
          ),
          const SizedBox(height: 10),
          _Shimmer(child: const _SkeletonBox(width: 260, height: 16)),
          const SizedBox(height: 18),
          Row(
            children: [
              _Shimmer(
                child: const _SkeletonBox(width: 92, height: 32, radius: 12),
              ),
              const SizedBox(width: 12),
              _Shimmer(
                child: const _SkeletonBox(width: 74, height: 32, radius: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE6EBF2),
                Color(0xFFFFFFFF),
                Color(0xFFE6EBF2),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (percent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

class PalAnimatedLoadingBar extends StatefulWidget {
  const PalAnimatedLoadingBar();

  @override
  State<PalAnimatedLoadingBar> createState() => _PalAnimatedLoadingBarState();
}

class _PalAnimatedLoadingBarState extends State<PalAnimatedLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25539800),
        child: Container(
          height: 4,
          color: const Color(0xFFE6EDF6),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                alignment: Alignment(
                  math.sin(_controller.value * math.pi * 2) * 0.6,
                  0,
                ),
                child: Container(
                  width: 66,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25539800),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF155DFC), Color(0xFF4F39F6)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
