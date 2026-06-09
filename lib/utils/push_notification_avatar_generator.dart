import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Generates square avatar bitmaps for Android push notifications.
class PushNotificationAvatarGenerator {
  static const Color initialsBackground = Color(0xFFF1F5F9);
  static const Color initialsTextColor = Color(0xFF314158);
  static const Color initialsBorderColor = Color(0xFF0F172B);

  /// Square avatar with centered initials in [#314158] on a light container.
  static Future<Uint8List?> generateSquareInitials(
    String initials, {
    int size = 256,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    final display = _normalizeInitials(initials);
    if (display.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dimension = size.toDouble();
    final borderRadius = dimension * 0.18;
    final borderWidth = dimension * 0.045;

    final rect = Rect.fromLTWH(0, 0, dimension, dimension);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(
      rrect,
      Paint()..color = initialsBackground,
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = initialsBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: display,
        style: TextStyle(
          color: initialsTextColor,
          fontSize: dimension * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (dimension - textPainter.width) / 2,
        (dimension - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[PushNotificationAvatarGenerator] Failed to rasterize initials: $e');
      return null;
    }
  }

  static String _normalizeInitials(String initials) {
    final trimmed = initials.trim();
    if (trimmed.isEmpty) return 'SU';
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed.toUpperCase();
  }
}
