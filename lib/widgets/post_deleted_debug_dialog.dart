import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _postDeletedIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.99609 10.9951V16.9926" stroke="#45556C" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M13.9941 10.9951V16.9926" stroke="#45556C" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M18.9921 5.99756V19.9916C18.9921 20.5218 18.7815 21.0303 18.4066 21.4052C18.0317 21.7801 17.5232 21.9908 16.993 21.9908H6.9972C6.46699 21.9908 5.9585 21.7801 5.58358 21.4052C5.20867 21.0303 4.99805 20.5218 4.99805 19.9916V5.99756" stroke="#45556C" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M2.99805 5.99756H20.9904" stroke="#45556C" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M7.99609 5.99733V3.99817C7.99609 3.46797 8.20672 2.95947 8.58163 2.58456C8.95655 2.20965 9.46504 1.99902 9.99524 1.99902H13.9935C14.5238 1.99902 15.0322 2.20965 15.4072 2.58456C15.7821 2.95947 15.9927 3.46797 15.9927 3.99817V5.99733" stroke="#45556C" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class PostDeletedDebugDialog extends StatefulWidget {
  const PostDeletedDebugDialog({
    super.key,
    this.onClose,
    this.onUndo,
    this.onTimeout,
    this.timeoutSeconds = 30,
  });

  final FutureOr<void> Function()? onClose;
  final FutureOr<void> Function()? onUndo;
  final FutureOr<void> Function()? onTimeout;
  final int timeoutSeconds;

  @override
  State<PostDeletedDebugDialog> createState() => _PostDeletedDebugDialogState();
}

class _PostDeletedDebugDialogState extends State<PostDeletedDebugDialog> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _undoEnabled = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _undoEnabled = false;
        });

        final callback = widget.onTimeout;
        if (callback != null) {
          callback();
        }
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE2E8F0);
    const noteText = Color(0xFF973C00);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SizedBox(
          width: 360,
          height: 296,
          child: Material(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: borderColor, width: 1.51),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 10),
                    blurRadius: 15,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 13.49,
                    top: 24.49,
                    width: 330,
                    height: 47,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 47.99,
                          height: 47.99,
                          padding: const EdgeInsets.only(right: 0.01),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              _postDeletedIconSvg,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11.99),
                        SizedBox(
                          width: 141.34,
                          height: 47,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 141.34,
                                height: 24,
                                child: Text(
                                  'Post Deleted',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172B),
                                    height: 24 / 16,
                                    letterSpacing: -0.31,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 141.34,
                                height: 20,
                                child: Text(
                                  'Successfully removed',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF62748E),
                                    height: 20 / 14,
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
                    left: 13.49,
                    top: 87.49,
                    width: 332,
                    height: 52,
                    child: const Text(
                      'Your post has been permanently deleted from the feed.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF45556C),
                        height: 26 / 16,
                        letterSpacing: -0.31,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 13.49,
                    top: 151.49,
                    width: 330,
                    height: 66,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12.75, 12.75, 12.75, 0.76),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFEE685), width: 0.76),
                      ),
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Note: ',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: noteText,
                                height: 20 / 14,
                                letterSpacing: -0.15,
                              ),
                            ),
                            TextSpan(
                              text: 'You can undo this action within the next $_remainingSeconds seconds.',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: noteText,
                                height: 20 / 14,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 13.49,
                    top: 233.49,
                    width: 330,
                    height: 36,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 159.01,
                          height: 36,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFFFF),
                              side: const BorderSide(color: Color(0x1A000000), width: 0.76),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final callback = widget.onClose;
                              if (callback != null) {
                                callback();
                              }
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0A0A0A),
                                height: 20 / 14,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11.99),
                        SizedBox(
                          width: 159.01,
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _undoEnabled
                                  ? const Color(0xFF0F172B)
                                  : const Color(0xFF94A3B8),
                              disabledBackgroundColor: const Color(0xFF94A3B8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _undoEnabled
                                ? () {
                                    final callback = widget.onUndo;
                                    if (callback != null) {
                                      callback();
                                    }
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            child: const Text(
                              'Undo Delete',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFFFFF),
                                height: 20 / 14,
                                letterSpacing: -0.15,
                              ),
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
    );
  }
}

Future<void> showPostDeletedDebugDialog(
  BuildContext context, {
  int timeoutSeconds = 30,
  FutureOr<void> Function()? onUndo,
  FutureOr<void> Function()? onClose,
  FutureOr<void> Function()? onTimeout,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => PostDeletedDebugDialog(
      timeoutSeconds: timeoutSeconds,
      onUndo: onUndo,
      onClose: onClose,
      onTimeout: onTimeout,
    ),
  );
}
