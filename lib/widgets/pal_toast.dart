import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/responsive/responsive.dart';

class PalToast {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isVisible) {
      hide();
    }

    final overlay = Overlay.of(context);
    _overlayEntry = _createOverlayEntry(context, message);

    overlay.insert(_overlayEntry!);
    _isVisible = true;

    Future.delayed(duration, () {
      hide();
    });
  }

  static void hide() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  static OverlayEntry _createOverlayEntry(
    BuildContext context,
    String message,
  ) {
    // Position above navigation bar (responsive)
    final bottomOffset = Responsive.scaledPadding(context, 110.0);
    
    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottomOffset,
        left: Responsive.scaledPadding(context, 16),
        right: Responsive.scaledPadding(context, 16),
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _ToastWidget(message: message),
          ),
        ),
      ),
    );
  }
}

class _ToastWidget extends StatelessWidget {
  const _ToastWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromRGBO(0, 0, 0, 0.1),
          width: 0.756,
        ),
        borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: Responsive.responsiveSymmetric(
        context,
        horizontal: 13.76,
        vertical: 16.75,
      ),
      child: Row(
        children: [
          Container(
            width: Responsive.scaledPadding(context, 19.995),
            height: Responsive.scaledPadding(context, 19.995),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/checkIcon.svg',
                width: Responsive.scaledIcon(context, 12),
                height: Responsive.scaledIcon(context, 12),
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.scaledPadding(context, 12)),
          Expanded(
            child: Text(
              message,
              style: Responsive.responsiveTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
                fontFamily: 'Inter',
                letterSpacing: -0.0762,
                height: 19.5 / 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

