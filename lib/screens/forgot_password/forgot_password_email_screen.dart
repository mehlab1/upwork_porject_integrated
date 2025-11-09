import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../otp/otp_verification_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isSubmitting = false;
  final AuthService _authService = AuthService();

  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _headlineColor = Color(0xFF0F172A);
  static const Color _bodyColor = Color(0xFF45556C);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        _emailError = email.isEmpty
            ? 'Email is required'
            : 'Enter a valid email address';
      });
      return;
    }
    
    setState(() {
      _emailError = null;
      _isSubmitting = true;
    });

    try {
      // Call forgot-password edge function
      // This calls request_password_reset_otp RPC which:
      // - Checks rate limits (3 per hour)
      // - Creates OTP record with 15-minute expiration
      // - Sends OTP via email
      final response = await _authService.forgotPassword(email: email);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Password reset code sent to your email'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to OTP verification screen
      // For password reset, OTP is collected and passed to reset-password screen
      // The reset-password edge function verifies the OTP when resetting
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: email,
            isPasswordReset: true, // Flag to indicate this is for password reset
            onSuccess: (otpCode) {
              // Pass OTP code to reset password screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    email: email,
                    otpCode: otpCode,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        if (e.toString().contains('rate limit') || e.toString().contains('too many')) {
          _emailError = 'Too many requests. Please try again later.';
        } else {
          _emailError = e.toString().contains('not found') || e.toString().contains('does not exist')
              ? 'If this email exists, a password reset code has been sent.'
              : 'Failed to send password reset code. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: _headlineColor,
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: _headlineColor,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 22),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _headlineColor,
                          fontFamily: 'Rubik',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please enter your email to reset the password',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: _bodyColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _emailError == null
                                ? const Color(0xFF155DFC)
                                : Colors.red,
                            width: 1,
                          ),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 18),
                            Icon(
                              Icons.email_outlined,
                              color: _primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) {
                                  setState(() {
                                    _emailError = null;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Email',
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _headlineColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_emailError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _emailError!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'We will send a 4-digit code to this email. The code is valid for 5 minutes.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _bodyColor.withOpacity(0.7),
                          height: 1.4,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
