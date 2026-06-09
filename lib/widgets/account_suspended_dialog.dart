import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _accountSuspendedIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4.92773 4.92676L19.0627 19.0628" stroke="#E7000B" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M11.9958 21.9905C17.5163 21.9905 21.9915 17.5153 21.9915 11.9948C21.9915 6.47428 17.5163 1.99902 11.9958 1.99902C6.47525 1.99902 2 6.47428 2 11.9948C2 17.5153 6.47525 21.9905 11.9958 21.9905Z" stroke="#E7000B" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class AccountSuspendedResult {
  const AccountSuspendedResult({required this.appealRequested});

  final bool appealRequested;
}

class AccountSuspendedDialog extends StatelessWidget {
  const AccountSuspendedDialog({
    super.key,
    required this.suspensionPeriod,
    required this.expires,
    required this.reason,
    this.onAppeal,
  });

  final String suspensionPeriod; // e.g. "7 days"
  final String expires; // e.g. "Nov 2, 2025"
  final String reason; // e.g. "Spam content"
  final VoidCallback? onAppeal;

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF0F172B);
    const subtitleColor = Color(0xFF64748B);
    const bodyColor = Color(0xFF45556C);
    const panelBackground = Color(0xFFF8FAFC);
    const panelBorder = Color(0xFFE2E8F0);
    const reasonColor = Color(0xFFE7000B);
    final width = MediaQuery.sizeOf(context).width;
    final scale = math.min(1.0, ((width - 32) / 360.0).clamp(0.0, 1.0));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SizedBox(
          width: 360 * scale,
          height: 417 * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 417,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 30,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Title area
                    Positioned(
                      left: 18,
                      top: 26,
                      width: 324,
                      height: 48,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE2E2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: SvgPicture.string(
                                _accountSuspendedIconSvg,
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 165,
                            height: 46,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 165,
                                  child: Text(
                                    'Account Suspended',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                      height: 1.4,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const SizedBox(
                                  width: 165,
                                  child: Text(
                                    'Temporary restriction',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: subtitleColor,
                                      height: 1.35,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A2A),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Color(0xFF2A2A2A), width: 2),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'A',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body text
                    Positioned(
                      left: 16,
                      top: 106,
                      width: 328,
                      height: 86,
                      child: const Text(
                        'Your account has been temporarily suspended due to violations of our community guidelines.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: bodyColor,
                          height: 1.6,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),

                    // Time duration container
                    Positioned(
                      left: 16,
                      top: 202,
                      width: 328,
                      height: 104,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: panelBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: panelBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: const Text(
                                    'Suspension Period:',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: bodyColor,
                                      letterSpacing: -0.15,
                                      height: 1.4286,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    suspensionPeriod,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172B),
                                      letterSpacing: -0.15,
                                      height: 1.4286,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  width: 54,
                                  child: const Text(
                                    'Expires:',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: bodyColor,
                                      letterSpacing: -0.15,
                                      height: 1.4286,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    expires,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172B),
                                      letterSpacing: -0.15,
                                      height: 1.4286,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  width: 54,
                                  child: const Text(
                                    'Reason:',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: bodyColor,
                                      letterSpacing: -0.15,
                                      height: 1.4286,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    reason,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: reasonColor,
                                      letterSpacing: -0.15,
                                      height: 1.4286,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buttons container
                    Positioned(
                      left: 15,
                      top: 344,
                      width: 330,
                      height: 49,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 0.76)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              height: 36,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF0A0A0A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(const AccountSuspendedResult(appealRequested: false)),
                                child: const Text('Close', style: TextStyle(color: Color(0xFF0A0A0A))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 162,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop(const AccountSuspendedResult(appealRequested: true));
                                  onAppeal?.call();
                                },
                                child: const Text('Appeal Suspension'),
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

Future<AccountSuspendedResult?> showAccountSuspendedDialog(
  BuildContext context, {
  required String suspensionPeriod,
  required String expires,
  required String reason,
  VoidCallback? onAppeal,
}) {
  return showDialog<AccountSuspendedResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => AccountSuspendedDialog(
      suspensionPeriod: suspensionPeriod,
      expires: expires,
      reason: reason,
      onAppeal: onAppeal,
    ),
  );
}
