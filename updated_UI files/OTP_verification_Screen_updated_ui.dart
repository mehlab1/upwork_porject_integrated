import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onSuccess;

  const OtpVerificationScreen({super.key, required this.email, this.onSuccess});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  int _currentIndex = 0;
  int _resendSeconds = 52;
  Timer? _resendTimer;

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey100 = Color(0xFFDEDFE3);
  static const Color _lightBlue = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Focus on first OTP box when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendSeconds > 0) {
            _resendSeconds--;
          } else {
            _resendSeconds = 0;
            timer.cancel();
          }
        });
      }
    });
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return email;
    }
    final maskedUsername =
        '${username.substring(0, 2)}${'*' * (username.length - 2)}';
    return '$maskedUsername@$domain';
  }

  String _formatResendTime() {
    final minutes = _resendSeconds ~/ 60;
    final seconds = _resendSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalScreenPadding = 24; // consistent side padding
    final double contentWidth = screenWidth - (horizontalScreenPadding * 2);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: _primary900,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: horizontalScreenPadding),
                    child: Text(
                      'Confirm OTP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500, // Rubik Medium
                        color: _primary900,
                        fontFamily: 'Rubik',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email text
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: horizontalScreenPadding),
                    child: Text(
                      'Code has been send to ${_maskEmail(widget.email)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal, // Rubik Regular
                        color: _primary900,
                        fontFamily: 'Rubik',
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 45),

                  // OTP input boxes (responsive sizing)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalScreenPadding,
                    ),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final double available = constraints.maxWidth;
                      // Gaps scale with width but kept in reasonable bounds
                      final double gap = (available * 0.025).clamp(8.0, 12.0);
                      final double edgeGap = gap; // dynamic side spacing for first/last
                      // Subtract inner gaps and edge gaps from available to avoid overflow
                      double boxSize =
                          (available - (gap * (_otpLength - 1)) - (edgeGap * 2)) /
                              _otpLength;
                      // Clamp to sensible min/max to avoid overly large/small boxes
                      boxSize = boxSize.clamp(40.0, 56.0);
                      final double radius = boxSize / 3.5;
                      // edgeGap already accounted for in size calculation
                      final double textSize = (boxSize * 0.6).clamp(20.0, 28.0);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_otpLength, (index) {
                          final isActive = _focusNodes[index].hasFocus;
                          final isLast = index == _otpLength - 1;
                          final isFirst = index == 0;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                              });
                              _focusNodes[index].requestFocus();
                            },
                            child: Container(
                              width: boxSize,
                              height: boxSize,
                              margin: EdgeInsets.only(
                                left: isFirst ? edgeGap : 0,
                                right: isLast ? edgeGap : gap,
                              ),
                              decoration: BoxDecoration(
                                color: isActive ? _lightBlue : _grey100,
                                border: isActive
                                    ? Border.all(color: _primaryColor, width: 1.5)
                                    : null,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: _primaryColor.withOpacity(0.35),
                                          blurRadius: 0,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  showCursor: false,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(1),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: TextStyle(
                                    fontSize: textSize,
                                    fontWeight: FontWeight.w500, // Rubik Medium
                                    color: _primary900,
                                    fontFamily: 'Rubik',
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty &&
                                        index < _otpLength - 1) {
                                      _focusNodes[index].unfocus();
                                      _currentIndex = index + 1;
                                      _focusNodes[_currentIndex].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _currentIndex = index - 1;
                                      _focusNodes[_currentIndex].requestFocus();
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),

                  const SizedBox(height: 42),

                  // Resend code text
                  Builder(
                    builder: (context) {
                      final timeString = _formatResendTime();
                      return RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal, // Rubik Regular
                            color: _primary900,
                            fontFamily: 'Rubik',
                            letterSpacing: 0.2,
                          ),
                          children: [
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text: '($timeString)',
                              style: TextStyle(
                                color: _primaryColor,
                                fontFamily: 'Rubik',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Continue button
                  Container(
                    width: contentWidth.clamp(260, 400),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Verify OTP
                          final otp = _controllers.map((c) => c.text).join('');
                          if (otp.length == _otpLength) {
                            if (widget.onSuccess != null) {
                              widget.onSuccess!.call();
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/home',
                                arguments: const {'showWelcomeModal': true},
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500, // Rubik Medium
                              color: Colors.white,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}