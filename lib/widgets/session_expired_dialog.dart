import 'dart:math' as math;

import 'package:flutter/material.dart';

class SessionExpiredResult {
  const SessionExpiredResult({required this.signIn});

  final bool signIn;
}

class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({super.key});

  static const Color _titleColor = Color(0xFF0F172B);
  static const Color _subtitleColor = Color(0xFF64748B);
  static const Color _bodyColor = Color(0xFF45556C);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _headerBg = Color(0xFFFFF3C4);
  static const Color _headerIcon = Color(0xFFEA580C);
  static const Color _buttonBorder = Color(0xFFE5E7EB);
  static const Color _buttonDark = Color(0xFF0F172B);

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
          height: 280 * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 280,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                      left: 0,
                      top: 26,
                      width: 330,
                      height: 47,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _headerBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                size: 24,
                                color: _headerIcon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11.99),
                          const SizedBox(
                            width: 270,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 270,
                                  child: Text(
                                    'Session Expired',
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
                                  width: 270,
                                  child: Text(
                                    'Authentication required',
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
                      left: 0,
                      top: 90,
                      width: 328,
                      height: 52,
                      child: Transform.translate(
                        offset: const Offset(0, -0.31),
                        child: const SizedBox(
                          width: 328,
                          height: 52,
                          child: Text(
                            'Your session has expired. Please sign in again to continue using Pal.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: _bodyColor,
                              height: 26 / 16,
                              letterSpacing: -0.31,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 205,
                      width: 330,
                      height: 49,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 0.76)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 159.00845336914062,
                              height: 35.99654006958008,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _titleColor,
                                  side: const BorderSide(color: Color(0x1A000000), width: 0.76),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(
                                  const SessionExpiredResult(signIn: false),
                                ),
                                child: const SizedBox(
                                  width: 121,
                                  height: 20,
                                  child: Text(
                                    'Continue as Guest',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 14,
                                      letterSpacing: -0.15,
                                      color: Color(0xFF0A0A0A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 11.99),
                            SizedBox(
                              width: 159.00845336914062,
                              height: 35.99654006958008,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _buttonDark,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(
                                  const SessionExpiredResult(signIn: true),
                                ),
                                child: const SizedBox(
                                  width: 45,
                                  height: 20,
                                  child: Text(
                                    'Sign In',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 14,
                                      letterSpacing: -0.15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

Future<SessionExpiredResult?> showSessionExpiredDialog(BuildContext context) {
  return showDialog<SessionExpiredResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const SessionExpiredDialog(),
  );
}
