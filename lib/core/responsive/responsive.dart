import 'package:flutter/material.dart';

/// Responsive utility class for handling screen sizes and scaling
class Responsive {
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get screen width as a percentage
  static double widthPercent(BuildContext context, double percent) {
    return screenWidth(context) * (percent / 100);
  }

  /// Get screen height as a percentage
  static double heightPercent(BuildContext context, double percent) {
    return screenHeight(context) * (percent / 100);
  }

  /// Scale font size based on screen width
  /// Uses a base width of 375 (iPhone X/11 standard) for scaling
  static double scaledFont(BuildContext context, double fontSize) {
    final width = screenWidth(context);
    // Use 375 as base width (standard iPhone width)
    final scaleFactor = width / 375.0;
    // Clamp scale factor between 0.8 and 1.2 to prevent extreme scaling
    final clampedScale = scaleFactor.clamp(0.8, 1.2);
    return fontSize * clampedScale;
  }

  /// Scale padding based on screen width
  static double scaledPadding(BuildContext context, double padding) {
    final width = screenWidth(context);
    final scaleFactor = width / 375.0;
    final clampedScale = scaleFactor.clamp(0.7, 1.3);
    return padding * clampedScale;
  }

  /// Scale icon size based on screen width
  static double scaledIcon(BuildContext context, double iconSize) {
    final width = screenWidth(context);
    final scaleFactor = width / 375.0;
    final clampedScale = scaleFactor.clamp(0.8, 1.2);
    return iconSize * clampedScale;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      final scaled = scaledPadding(context, all);
      return EdgeInsets.all(scaled);
    }

    return EdgeInsets.only(
      left: left != null ? scaledPadding(context, left) : (horizontal ?? 0),
      right: right != null ? scaledPadding(context, right) : (horizontal ?? 0),
      top: top != null ? scaledPadding(context, top) : (vertical ?? 0),
      bottom: bottom != null ? scaledPadding(context, bottom) : (vertical ?? 0),
    );
  }

  /// Get responsive symmetric padding
  static EdgeInsets responsiveSymmetric(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? scaledPadding(context, horizontal) : 0,
      vertical: vertical != null ? scaledPadding(context, vertical) : 0,
    );
  }

  /// Check if device is small (width < 360)
  static bool isSmallDevice(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// Check if device is medium (360 <= width < 600)
  static bool isMediumDevice(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  /// Check if device is large (width >= 600)
  static bool isLargeDevice(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// Get responsive text style
  static TextStyle responsiveTextStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    String? fontFamily,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize != null ? scaledFont(context, fontSize) : null,
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Get responsive border radius
  static double responsiveRadius(BuildContext context, double radius) {
    final width = screenWidth(context);
    final scaleFactor = width / 375.0;
    final clampedScale = scaleFactor.clamp(0.8, 1.2);
    return radius * clampedScale;
  }
}

