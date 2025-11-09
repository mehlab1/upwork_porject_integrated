import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otpCode,
  });

  final String email;
  final String otpCode;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isSubmitting = false;
  int _passwordStrength = 0;
  bool _passwordsMatch = false;
  final AuthService _authService = AuthService();

  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _headlineColor = Color(0xFF0F172A);
  static const Color _bodyColor = Color(0xFF45556C);
  static const Color _borderColor = Color(0xFFD0D5DD);
  static const Color _greyIconColor = Color(0xFF8A8D9E);
  static const Color _greenSuccess = Color(0xFF00A63E);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPassword() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength > 4 ? 4 : strength;
  }

  bool _validateForm() {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    String? passwordError;
    String? confirmError;

    if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }
    if (confirm != password) {
      confirmError = 'Passwords do not match';
    }

    setState(() {
      _passwordError = passwordError;
      _confirmPasswordError = confirmError;
    });

    return passwordError == null && confirmError == null;
  }

  Future<void> _handleReset() async {
    if (!_validateForm()) return;
    
    setState(() => _isSubmitting = true);

    try {
      // Call reset-password edge function
      // This edge function calls verify_password_reset_otp RPC which:
      // - Verifies the OTP (checks expiration, attempts, validity)
      // - Validates password strength (8-128 chars, uppercase, lowercase, number, special char)
      // - Hashes password with bcrypt
      // - Updates password in auth.users table
      // All in one atomic operation
      final response = await _authService.resetPassword(
        email: widget.email,
        otpCode: widget.otpCode,
        newPassword: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Password reset successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      
      // Set appropriate error messages
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('otp') || errorMessage.contains('code') || errorMessage.contains('expired')) {
        // OTP error - might need to go back
        setState(() {
          _passwordError = 'Invalid or expired reset code. Please request a new one.';
        });
      } else if (errorMessage.contains('password') || errorMessage.contains('strength')) {
        setState(() {
          _passwordError = e.message;
        });
      } else {
        setState(() {
          _passwordError = 'Failed to reset password. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      
      setState(() {
        _passwordError = 'An unexpected error occurred. Please try again.';
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
                  ),
                  const Spacer(),
                  Text(
                    'Set New Password',
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a New Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _headlineColor,
                                fontFamily: 'Rubik',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your new password must be different from previously used passwords.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: _bodyColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPasswordField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onToggleVisibility: _togglePassword,
                        errorText: _passwordError,
                        showSuccess:
                            _passwordError == null &&
                            _passwordController.text.isNotEmpty &&
                            _passwordStrength >= 3,
                        onChanged: (value) {
                          setState(() {
                            _passwordError = null;
                            _passwordStrength = _calculatePasswordStrength(
                              value.trim(),
                            );
                            _passwordsMatch =
                                value.trim() ==
                                    _confirmPasswordController.text.trim() &&
                                value.trim().isNotEmpty;
                          });
                        },
                      ),
                      if (_passwordController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            left: 6,
                            right: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 6,
                                child: Row(
                                  children: List.generate(4, (index) {
                                    final filled = index < _passwordStrength;
                                    return Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          right: index < 3 ? 6 : 0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: filled
                                              ? _primaryColor
                                              : _borderColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _passwordStrength >= 3
                                    ? 'Strong password'
                                    : 'Use 6+ characters with a mix of letters, numbers & symbols',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _passwordStrength >= 3
                                      ? const Color(0xFF00A63E)
                                      : _bodyColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: _toggleConfirmPassword,
                        errorText: _confirmPasswordError,
                        showSuccess:
                            _passwordsMatch &&
                            _confirmPasswordError == null &&
                            _confirmPasswordController.text.isNotEmpty,
                        onChanged: (value) {
                          setState(() {
                            _confirmPasswordError = null;
                            _passwordsMatch =
                                value.trim() ==
                                    _passwordController.text.trim() &&
                                value.trim().isNotEmpty;
                          });
                        },
                      ),
                      if (_passwordsMatch &&
                          _confirmPasswordError == null &&
                          _confirmPasswordController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 6,
                            left: 6,
                            bottom: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF00A63E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Passwords match',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF00A63E),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
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
                  onPressed: _isSubmitting ? null : _handleReset,
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
                          'Reset password',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? errorText,
    bool showSuccess = false,
    ValueChanged<String>? onChanged,
  }) {
    final borderColor = errorText != null ? Colors.red : _primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 0.758),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              SvgPicture.asset(
                'assets/images/passwordIcon.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(_greyIconColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: 16,
                    color: _headlineColor,
                    fontFamily: 'Inter',
                    letterSpacing: -0.3125,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'My Strong Password Here',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              if (showSuccess) ...[
                const SizedBox(width: 12),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _greenSuccess, width: 1),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: _greenSuccess,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _greyIconColor,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
