import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final ValueChanged<String>? onSuccess;
  final bool isPasswordReset;

  const OtpVerificationScreen({
    super.key, 
    required this.email, 
    this.onSuccess,
    this.isPasswordReset = false,
  });

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

  // Backend service
  final AuthService _authService = AuthService();

  // Loading/error states
  bool _isVerifying = false;
  bool _isResending = false;
  String? _otpError;

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
    _resendTimer?.cancel();
    _resendSeconds = 52;
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

  String _formatResendTime() {
    final minutes = _resendSeconds ~/ 60;
    final seconds = _resendSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Handles OTP verification via backend edge function
  Future<void> _handleContinue() async {
    final otp = _controllers.map((c) => c.text).join('');
    if (otp.length != _otpLength) return;

    // For password reset flow: don't verify OTP here, pass it to the callback
    // The reset-password edge function will verify the OTP + reset password atomically
    if (widget.isPasswordReset) {
      widget.onSuccess?.call(otp);
      return;
    }

    // For email verification flow: verify OTP server-side first
    if (widget.onSuccess != null) {
      setState(() {
        _isVerifying = true;
        _otpError = null;
      });

      try {
        await _authService.verifyOtp(email: widget.email, token: otp);

        if (!mounted) return;

        setState(() {
          _isVerifying = false;
        });

        // OTP verified successfully - proceed
        widget.onSuccess!.call(otp);
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _otpError = e.message;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _otpError = 'Verification failed. Please try again.';
        });
      }
    } else {
      // Default fallback: navigate to home (legacy behavior)
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: const {'showWelcomeModal': true},
      );
    }
  }

  /// Handles resending OTP via backend edge function
  Future<void> _handleResend() async {
    if (_isResending || _resendSeconds > 0) return;

    setState(() {
      _isResending = true;
      _otpError = null;
    });

    try {
      await _authService.resendOtp(email: widget.email);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      // Clear OTP fields
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      _currentIndex = 0;

      // Restart timer
      _startResendTimer();

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP resent successfully!'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _otpError = 'Failed to resend OTP. Please try again.';
      });
    }
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
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalScreenPadding,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/otp/Confirm-otp-back-button.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF100B3C),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

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
                      'Code has been sent to ${widget.email}',
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
                      final bool hasOtpError = _otpError != null;
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
                                border: hasOtpError
                                  ? Border.all(color: const Color(0xFFE7000B), width: 1.5)
                                  : (isActive
                                      ? Border.all(color: _primaryColor, width: 1.5)
                                      : null),
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
                                    if (_otpError != null) {
                                      setState(() {
                                        _otpError = null;
                                      });
                                    }
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

                  // OTP error message
                  if (_otpError != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: horizontalScreenPadding),
                      child: Text(
                        _otpError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          fontFamily: 'Rubik',
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 42),

                  // Resend code text - tappable when timer expires
                  Builder(
                    builder: (context) {
                      if (_resendSeconds > 0) {
                        // Timer running - show countdown
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
                      } else {
                        // Timer expired - show tappable resend button
                        return GestureDetector(
                          onTap: _isResending ? null : _handleResend,
                          child: _isResending
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Resending...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _primaryColor,
                                        fontFamily: 'Rubik',
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _primaryColor,
                                    fontFamily: 'Rubik',
                                    letterSpacing: 0.2,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _primaryColor,
                                  ),
                                ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  // Continue button
                  Container(
                    width: contentWidth.clamp(260, 400),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isVerifying
                          ? _primaryColor.withOpacity(0.7)
                          : _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isVerifying ? null : _handleContinue,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
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
