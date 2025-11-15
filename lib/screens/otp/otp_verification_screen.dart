import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/auth_service.dart';

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
                  Text(
                    'Confirm OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500, // Rubik Medium
                      color: _primary900,
                      fontFamily: 'Rubik',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Email text
                  Text(
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

                  const SizedBox(height: 45),

                  // OTP input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_otpLength, (index) {
                      final isActive = _focusNodes[index].hasFocus;
                      final isLast = index == _otpLength - 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                          _focusNodes[index].requestFocus();
                        },
                        child: Container(
                          width: 50,
                          height: 60,
                          margin: EdgeInsets.only(right: isLast ? 0 : 12),
                          decoration: BoxDecoration(
                            color: isActive ? _lightBlue : _grey100,
                            border: isActive
                                ? Border.all(color: _primaryColor, width: 1)
                                : null,
                            borderRadius: BorderRadius.circular(16.0),
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
                                fontSize: 32,
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
                  ),

                  const SizedBox(height: 42),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Resend code text/button
                  Builder(
                    builder: (context) {
                      final timeString = _formatResendTime();
                      if (_resendSeconds > 0) {
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
                        return TextButton(
                          onPressed: _isResending ? null : () => _handleResendOtp(),
                          child: _isResending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                  ),
                                )
                              : Text(
                                  'Resend code',
                                  style: TextStyle(
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

                  const SizedBox(height: 18),

                  // Continue button
                  Container(
                    width: 338,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isLoading ? _primaryColor.withOpacity(0.7) : _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : () async {
                          // Verify OTP
                          final otp = _controllers.map((c) => c.text).join('');
                          if (otp.length == _otpLength) {
                            await _handleVerifyOtp(otp);
                          } else {
                            setState(() {
                              _errorMessage = 'Please enter the complete OTP code';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
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
      await _authService.verifyOtp(
        email: widget.email,
        token: otp,
      );

      if (!mounted) return;

      // OTP verified successfully - navigate to login page
      // User needs to sign in with their email and password to get a valid session
      setState(() {
        _isLoading = false;
      });

      // Show success message before redirecting
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP verified successfully! Please sign in with your email and password.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
        arguments: {'showWelcomeModal': true, 'showFirstPostCard': true},
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      // Only show error if it's not about session creation (OTP verification failed)
      final errorMessage = e.message.toLowerCase();
      if (!errorMessage.contains('createSession') && 
          !errorMessage.contains('session creation failed')) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      } else {
        // OTP was verified, just session creation failed - redirect to login
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP verified successfully! Please sign in with your email and password.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: {'showWelcomeModal': true, 'showFirstPostCard': true},
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isPasswordReset 
              ? 'Password reset code resent successfully'
              : 'OTP resent successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
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
