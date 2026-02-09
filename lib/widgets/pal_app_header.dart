import 'package:flutter/material.dart';
import '../core/responsive/responsive.dart';

/// A reusable sticky header widget for app screens
/// Displays the Pal logo, branding, and optionally a Post button
class PalAppHeader extends StatelessWidget {
  const PalAppHeader({super.key, this.onPostTap, this.showPostButton = false});

  /// Callback when Post button is tapped
  final VoidCallback? onPostTap;

  /// Whether to show the Post button
  final bool showPostButton;

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _slate200 = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Responsive.scaledPadding(context, 80),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _slate200, width: 0.755)),
      ),
      padding: EdgeInsets.only(
        right: Responsive.scaledPadding(context, 12),
        top: Responsive.scaledPadding(context, 4),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/LogoCropped.png',
              width: Responsive.widthPercent(context, 40).clamp(150.0, 250.0),
              height: Responsive.scaledPadding(context, 60),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: Responsive.widthPercent(context, 40).clamp(150.0, 250.0),
                  height: Responsive.scaledPadding(context, 60),
                  color: Colors.grey[200],
                  child: const Icon(Icons.error_outline),
                );
              },
            ),
          ),
          if (showPostButton && onPostTap != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
              height: Responsive.scaledPadding(context, 40),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(
                  Responsive.responsiveRadius(context, 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPostTap,
                  borderRadius: BorderRadius.circular(
                    Responsive.responsiveRadius(context, 14),
                  ),
                  child: Padding(
                    padding: Responsive.responsiveSymmetric(
                      context,
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: Responsive.scaledIcon(context, 16),
                        ),
                        SizedBox(width: Responsive.scaledPadding(context, 6)),
                        Text(
                          'Post',
                          style: Responsive.responsiveTextStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                            letterSpacing: -0.1504,
                          ),
                        ),
                      ],
                    ),
                  ),
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
