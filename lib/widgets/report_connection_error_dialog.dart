import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReportConnectionErrorDialog extends StatelessWidget {
  const ReportConnectionErrorDialog({
    super.key,
    this.onCancel,
    this.onTryAgain,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF0A0A0A);
    const subtitleColor = Color(0xFF64748B);
    const bodyColor = Color(0xFF475569);
    const errorBorder = Color(0xFFFECACA);
    const errorBackground = Color(0xFFFEF2F2);
    const errorText = Color(0xFF9F0712);
    const cancelBorder = Color(0xFFE5E7EB);
    const tryAgainColor = Color(0xFF111B3A);

    final width = MediaQuery.sizeOf(context).width;
    final scale = math.min(1.0, ((width - 32) / 360.0).clamp(0.0, 1.0));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SizedBox(
          width: 360 * scale,
          height: 273 * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 273,
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
                    Positioned(
                      left: 15.49,
                      top: 24.49,
                      width: 330,
                      height: 47,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 47.99,
                            height: 47.99,
                            decoration: BoxDecoration(
                              color: errorBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/feedPage/No-Internet-connection-icon.svg',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11.99),
                              const SizedBox(
                            width: 153.29,
                            height: 45.99,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Connection Error',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                    height: 1.5,
                                    letterSpacing: -0.31,
                                  ),
                                ),
                                SizedBox(height: 0.51),
                                Text(
                                  'Unable to submit report',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: subtitleColor,
                                    height: 1.4286,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      left: 15.49,
                      top: 87.49,
                      width: 330,
                      height: 52,
                      child: Text(
                        'We couldn\'t connect to the server. Please\ncheck your internet connection and try again.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: bodyColor,
                          height: 1.4286,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15.49,
                      top: 151.49,
                      width: 330,
                      height: 46,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12.75, 12.75, 12.75, 0.76),
                        decoration: BoxDecoration(
                          color: errorBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: errorBorder, width: 0.76),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Error: ',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4286,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              TextSpan(
                                text: 'Network request failed',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4286,
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9F0712),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15.49,
                      top: 213.49,
                      width: 330,
                      height: 36,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 159.01,
                            height: 36,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: cancelBorder, width: 0.76),
                                backgroundColor: Colors.white,
                                foregroundColor: titleColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                  height: 1.4286,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                onCancel?.call();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 11.99),
                          SizedBox(
                            width: 159.01,
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tryAgainColor,
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
                                  color: Colors.white,
                                  height: 1.4286,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                onTryAgain?.call();
                              },
                              child: const Text('Try Again'),
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

Future<void> showReportConnectionErrorDialog(
  BuildContext context, {
  VoidCallback? onCancel,
  VoidCallback? onTryAgain,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => ReportConnectionErrorDialog(
      onCancel: onCancel,
      onTryAgain: onTryAgain,
    ),
  );
}