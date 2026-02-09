import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../core/responsive/responsive.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/pal_toast.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Function(String)? onSuccess; // Changed to accept OTP code
  final bool isPasswordReset; // Flag to indicate password reset flow

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
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey100 = Color(0xFFDEDFE3);
  static const Color _lightBlue = Color(0xFFEFF6FF);
  static const Color _errorRed = Color(0xFFE7000B);
  static const Color _errorBackground = Color(0x1AF9E3E4); // #F9E3E41A

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
    final double horizontalScreenPadding = Responsive.scaledPadding(
      context,
      24,
    );
    final double contentWidth = Responsive.widthPercent(
      context,
      90,
    ).clamp(260.0, 400.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: Responsive.scaledPadding(context, 16),
                bottom: Responsive.scaledPadding(context, 16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back Button - only show if NOT in password reset flow
                  if (!widget.isPasswordReset)
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF0F172B),
                        size: 32,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  // Title - centered
                  Expanded(
                    child: Text(
                      'Confirm OTP',
                      style: Responsive.responsiveTextStyle(
                        context,
                        fontSize: 22,
                        fontWeight: FontWeight.bold, // Rubik bold
                        color: _primary900,
                        fontFamily: 'Rubik',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Spacer to balance the back button - only show if back button is visible
                  if (!widget.isPasswordReset)
                    const SizedBox(width: 40),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: Responsive.scaledPadding(context, 70)),

                    // Email text
                    Padding(
                      padding: Responsive.responsiveSymmetric(
                        context,
                        horizontal: horizontalScreenPadding,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Code has been sent to ${widget.email}',
                          style: TextStyle(
                            fontSize: Responsive.scaledFont(context, 16),
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF100B3C), // #100B3C
                            fontFamily: 'Rubik',
                            letterSpacing: 0,
                            height: 1.4, // 140%
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.scaledPadding(context, 45)),

                    // OTP input boxes (responsive sizing)
                    Padding(
                      padding: Responsive.responsiveSymmetric(
                        context,
                        horizontal: horizontalScreenPadding,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double available = constraints.maxWidth;
                          // Gaps scale with width but kept in reasonable bounds
                          final double gap = (available * 0.025).clamp(
                            8.0,
                            12.0,
                          );
                          final double edgeGap =
                              gap; // dynamic side spacing for first/last
                          // Subtract inner gaps and edge gaps from available to avoid overflow
                          double boxSize =
                              (available -
                                  (gap * (_otpLength - 1)) -
                                  (edgeGap * 2)) /
                              _otpLength;
                          // Clamp to sensible min/max to avoid overly large/small boxes
                          boxSize = boxSize.clamp(40.0, 56.0);
                          final double radius = boxSize / 3.5;
                          // edgeGap already accounted for in size calculation
                          final double textSize = (boxSize * 0.6).clamp(
                            20.0,
                            28.0,
                          );
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_otpLength, (index) {
                              final isActive = _focusNodes[index].hasFocus;
                              final isLast = index == _otpLength - 1;
                              final isFirst = index == 0;
                              final hasError = _errorMessage != null;
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
                                    color: hasError
                                        ? _errorBackground
                                        : (isActive ? _lightBlue : _grey100),
                                    border: hasError
                                        ? Border.all(
                                            color: _errorRed,
                                            width: 1,
                                          )
                                        : (isActive
                                            ? Border.all(
                                                color: _primaryColor,
                                                width: 1.5,
                                              )
                                            : null),
                                    boxShadow: isActive && !hasError
                                        ? [
                                            BoxShadow(
                                              color: _primaryColor.withOpacity(
                                                0.35,
                                              ),
                                              blurRadius: 0,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                    borderRadius: BorderRadius.circular(radius),
                                  ),
                                  child: Focus(
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent &&
                                          event.logicalKey ==
                                              LogicalKeyboardKey.backspace) {
                                        // Handle backspace
                                        if (_controllers[index].text.isEmpty &&
                                            index > 0) {
                                          // If current field is empty, move to previous and clear it
                                          _controllers[index - 1].clear();
                                          _currentIndex = index - 1;
                                          _focusNodes[index - 1].requestFocus();
                                          return KeyEventResult.handled;
                                        } else if (_controllers[index]
                                            .text
                                            .isNotEmpty) {
                                          // If current field has text, clear it
                                          _controllers[index].clear();
                                          return KeyEventResult.handled;
                                        }
                                      }
                                      return KeyEventResult.ignored;
                                    },
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
                                      style: Responsive.responsiveTextStyle(
                                        context,
                                        fontSize: textSize,
                                        fontWeight:
                                            FontWeight.w500, // Rubik Medium
                                        color: _primary900,
                                        fontFamily: 'Rubik',
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty &&
                                            index < _otpLength - 1) {
                                          _focusNodes[index].unfocus();
                                          _currentIndex = index + 1;
                                          _focusNodes[_currentIndex]
                                              .requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          // When field becomes empty, move to previous
                                          _currentIndex = index - 1;
                                          _focusNodes[_currentIndex]
                                              .requestFocus();
                                        }
                                      },
                                      onTap: () {
                                        setState(() {
                                          _currentIndex = index;
                                        });
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
                        },
                      ),
                    ),

                    // Error message - simple text with icon (right underneath input boxes)
                    // Always reserve space for error message to keep resend code position constant
                    Padding(
                      padding: Responsive.responsiveSymmetric(
                        context,
                        horizontal: horizontalScreenPadding,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double available = constraints.maxWidth;
                          final double gap = (available * 0.025).clamp(8.0, 12.0);
                          final double edgeGap = gap;
                          return Column(
                            children: [
                              if (_errorMessage != null)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: edgeGap + 4,
                                    top: Responsive.scaledPadding(context, 8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: _errorRed,
                                        size: Responsive.scaledIcon(context, 14),
                                      ),
                                      SizedBox(
                                        width: Responsive.scaledPadding(context, 4),
                                      ),
                                      Text(
                                        'invalid OTP',
                                        style: TextStyle(
                                          fontSize: Responsive.scaledFont(context, 14),
                                          fontWeight: FontWeight.w400,
                                          color: _errorRed,
                                          fontFamily: 'Inter',
                                          letterSpacing: 0,
                                          height: 1.14, // 16px / 14px = 1.14
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(height: Responsive.scaledPadding(context, 8)),
                              SizedBox(height: Responsive.scaledPadding(context, 24)),
                            ],
                          );
                        },
                      ),
                    ),

                    // Resend code text
                    Builder(
                      builder: (context) {
                        final timeString = _formatResendTime();
                        if (_resendSeconds > 0) {
                          // Show timer text (matches updated UI)
                          return RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: Responsive.responsiveTextStyle(
                                context,
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
                                  style: Responsive.responsiveTextStyle(
                                    context,
                                    color: _primaryColor,
                                    fontFamily: 'Rubik',
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Show resend button when timer expires (backend functionality)
                          return TextButton(
                            onPressed: _isResending
                                ? null
                                : () => _handleResendOtp(),
                            child: _isResending
                                ? SizedBox(
                                    width: Responsive.scaledIcon(context, 16),
                                    height: Responsive.scaledIcon(context, 16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _primaryColor,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Resend code',
                                    style: Responsive.responsiveTextStyle(
                                      context,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _primaryColor,
                                      fontFamily: 'Rubik',
                                    ),
                                  ),
                          );
                        }
                      },
                    ),

                    SizedBox(height: Responsive.scaledPadding(context, 27)),

                    // Continue button
                    Container(
                      width: contentWidth,
                      height: Responsive.scaledPadding(context, 56),
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? _primaryColor.withOpacity(0.7)
                            : _primaryColor,
                        borderRadius: BorderRadius.circular(
                          Responsive.responsiveRadius(context, 20),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  // Verify OTP
                                  final otp = _controllers
                                      .map((c) => c.text)
                                      .join('');
                                  if (otp.length == _otpLength) {
                                    await _handleVerifyOtp(otp);
                                  } else {
                                    setState(() {
                                      _errorMessage =
                                          'Please enter the complete OTP code';
                                    });
                                  }
                                },
                          borderRadius: BorderRadius.circular(
                            Responsive.responsiveRadius(context, 20),
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: Responsive.scaledIcon(context, 20),
                                    height: Responsive.scaledIcon(context, 20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: Responsive.responsiveTextStyle(
                                      context,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w500, // Rubik Medium
                                      color: Colors.white,
                                      fontFamily: 'Rubik',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.scaledPadding(context, 50)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles OTP verification with Supabase backend
  /// For password reset: Collects OTP and passes to reset-password screen
  /// The reset-password edge function verifies OTP when resetting password
  /// For signup: Verifies OTP using verify-otp edge function
  Future<void> _handleVerifyOtp(String otp) async {
    // For password reset flow, just collect OTP and proceed
    // The reset-password edge function will verify the OTP when resetting
    // We can't verify it here due to RLS policies on otp_verifications table
    if (widget.isPasswordReset) {
      // Validate that OTP is entered (6 digits)
      if (otp.length != 6) {
        setState(() {
          _errorMessage = 'Please enter the complete 6-digit code';
        });
        return;
      }

      // Proceed to reset password screen - verification happens there
      if (widget.onSuccess != null) {
        widget.onSuccess!(otp); // Pass OTP code to callback
      } else {
        // Should not happen, but handle gracefully
        Navigator.pop(context);
      }
      return;
    }

    // For signup flow, verify OTP
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify OTP using the edge function
      final response = await _authService.verifyOtp(
        email: widget.email,
        token: otp,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Check if session was created after OTP verification
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session != null && user != null) {
        // Session exists - user is logged in, initialize FCM and go to home
        try {
          await FCMService().initialize();
        } catch (e) {
          // FCM initialization failure shouldn't block navigation
          debugPrint('[OtpVerificationScreen] FCM initialization failed: $e');
        }

        // Show success message
        PalToast.show(context, message: 'Account created successfully!');

        // Navigate to home feed with welcome modal
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
          arguments: {'showWelcomeModal': true, 'showFirstPostCard': true},
        );

        // Show unread notifications after home screen loads
        // Wait a few seconds for home screen to fully load, then show notifications
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future<void>.delayed(const Duration(seconds: 3));
          if (mounted && Navigator.of(context).canPop() == false) {
            // Home screen is now loaded, show unread notifications
            final notificationService = NotificationService();
            await notificationService.showUnreadNotificationsInApp(context);
          }
        });
      } else {
        // No session - OTP verified but session creation failed
        // This shouldn't happen in normal flow, but handle gracefully
        PalToast.show(
          context,
          message:
              'OTP verified successfully! Please sign in with your email and password.',
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: {'showWelcomeModal': true, 'showFirstPostCard': true},
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final errorMessage = e.message.toLowerCase();

      // Check if it's about session creation (OTP was verified but session failed)
      if (errorMessage.contains('createsession') ||
          errorMessage.contains('session creation failed')) {
        // OTP was verified, just session creation failed
        setState(() {
          _isLoading = false;
        });

        PalToast.show(
          context,
          message:
              'OTP verified successfully! Please sign in with your email and password.',
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: {'showWelcomeModal': true, 'showFirstPostCard': true},
        );
      } else {
        // OTP verification actually failed
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
        PalToast.show(context, message: e.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      PalToast.show(
        context,
        message: 'An unexpected error occurred. Please try again.',
        isError: true,
      );
    }
  }

  /// Handles resending OTP
  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      // For password reset, use forgotPassword instead of resendOtp
      if (widget.isPasswordReset) {
        await _authService.forgotPassword(email: widget.email);
      } else {
        // For signup, use resendOtp
        await _authService.resendOtp(email: widget.email);
      }

      if (!mounted) return;

      // Clear all OTP input fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Reset focus to first field
      _currentIndex = 0;
      _focusNodes[0].requestFocus();

      // Reset the resend timer
      setState(() {
        _isResending = false;
        _resendSeconds = 52; // Reset to 52 seconds
      });

      _resendTimer?.cancel();
      _startResendTimer();

      // Show success message
      PalToast.show(
        context,
        message: widget.isPasswordReset
            ? 'Password reset code resent successfully'
            : 'OTP resent successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('wait') || errorStr.contains('rate limit')) {
          _errorMessage = e.toString();
        } else {
          _errorMessage = widget.isPasswordReset
              ? 'Failed to resend password reset code. Please try again.'
              : 'Failed to resend OTP. Please try again.';
        }
      });
    }
  }
}
