import 'dart:math' as math;

import 'package:flutter/material.dart';

class InvalidContentDetectedResult {
  const InvalidContentDetectedResult({required this.editPost});

  final bool editPost;
}

class InvalidContentDetectedDialog extends StatelessWidget {
  const InvalidContentDetectedDialog({super.key});

  static const Color _titleColor = Color(0xFF0F172B);
  static const Color _subtitleColor = Color(0xFF64748B);
  static const Color _bodyColor = Color(0xFF45556C);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _warningBackground = Color(0xFFFEF2F2);
  static const Color _warningBorder = Color(0xFFFFC9C9);
  static const Color _warningTitle = Color(0xFFB91C1C);
  static const Color _warningText = Color(0xFFB91C1C);
  static const Color _warningIconBg = Color(0xFFFFF3C4);
  static const Color _warningIcon = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = math.min(1.0, ((width - 32) / 360.0).clamp(0.0, 1.0));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SizedBox(
          width: 360 * scale,
          height: 434.6647033691406 * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 434.6647033691406,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    top: BorderSide(color: _cardBorder, width: 1.51),
                    left: BorderSide(color: _cardBorder, width: 1.51),
                    right: BorderSide(color: _cardBorder, width: 1.51),
                    bottom: BorderSide(color: _cardBorder, width: 1.51),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 25,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 15,
                      top: 26,
                      width: 330,
                      height: 48,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _warningIconBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 24,
                                color: _warningIcon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11.99),
                          const SizedBox(
                            width: 177,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 177,
                                  child: Text(
                                    'Invalid Content Detected',
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _titleColor,
                                      height: 1.5,
                                      letterSpacing: -0.31,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3),
                                SizedBox(
                                  width: 177,
                                  child: Text(
                                    'Content validation failed',
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: _subtitleColor,
                                      height: 1.4286,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: 114,
                      width: 330,
                      height: 52,
                      child: const Text(
                        'Your post contains content that violates our community guidelines.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _bodyColor,
                          height: 1.6,
                          letterSpacing: -0.31,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: 191,
                      width: 330,
                      child: Column(
                        children: const [
                          _ValidationItem(
                            title: 'Profanity detected',
                            description: 'Please remove offensive language',
                            height: 65.49337768554688,
                          ),
                          SizedBox(height: 10),
                          _ValidationItem(
                            title: 'Spam links',
                            description: 'External links are not allowed',
                            height: 45.4979248046875,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 15,
                      right: 15,
                      top: 353,
                      child: Container(
                        height: 1,
                        color: const Color(0xFFF1F5F9),
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: 361,
                      width: 330,
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _titleColor,
                                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(
                                  const InvalidContentDetectedResult(editPost: false),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _titleColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(
                                  const InvalidContentDetectedResult(editPost: true),
                                ),
                                child: const Text('Edit Post'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidationItem extends StatelessWidget {
  const _ValidationItem({
    required this.title,
    required this.description,
    required this.height,
  });

  final String title;
  final String description;
  final double height;

  static const Color _title = Color(0xFFB91C1C);
  static const Color _description = Color(0xFFB91C1C);
  static const Color _border = Color(0xFFFFC9C9);
  static const Color _background = Color(0xFFFEF2F2);
  static const Color _icon = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(12.75, 12.75, 12.75, 0.76),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          top: BorderSide(color: _border, width: 0.76),
          left: BorderSide(color: _border, width: 0.76),
          right: BorderSide(color: _border, width: 0.76),
          bottom: BorderSide(color: _border, width: 0.76),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _icon, width: 1.4),
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _icon,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _title,
                      height: 1.45,
                      letterSpacing: -0.15,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _description,
                      height: 1.45,
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<InvalidContentDetectedResult?> showInvalidContentDetectedDialog(
  BuildContext context,
) {
  return showDialog<InvalidContentDetectedResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const InvalidContentDetectedDialog(),
  );
}
