import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/responsive/responsive.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../settings/community_guidelines_screen.dart';
import '../otp/otp_verification_screen.dart';
import 'signup_screen.dart';

class EmailCollectionScreen extends StatefulWidget {
  const EmailCollectionScreen({super.key});

  @override
  State<EmailCollectionScreen> createState() => _EmailCollectionScreenState();
}

class _EmailCollectionScreenState extends State<EmailCollectionScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _emailError;
  String? _termsError;

  // Backend service
  final AuthService _authService = AuthService();

  // Colors matching signup_screen.dart exactly
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey400 = Color(0xFF8A8D9E);
  static const Color _grey700 = Color(0xFF717182);
  static const Color _checkboxColor = Color(0xFF7265E3);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validates email format with comprehensive checks
  bool _isValidEmail(String email) {
    if (!email.contains('@') || !email.contains('.')) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    if (parts[0].isEmpty) return false;
    final domainPart = parts[1];
    final domainParts = domainPart.split('.');
    if (domainParts.length < 2) return false;
    final tld = domainParts.last;
    if (tld.length < 2) return false;
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Handles the "Sign up" button tap:
  /// 1. Validates email format
  /// 2. Checks terms agreement
  /// 3. Sends OTP to the email
  /// 4. Navigates to OTP verification screen
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();

    // Clear previous errors
    setState(() {
      _emailError = null;
      _termsError = null;
    });

    // Validate email
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Invalid email format. Use format: example@gmail.com';
      });
      return;
    }

    // Validate terms agreement
    if (!_agreeToTerms) {
      setState(() {
        _termsError = 'Please agree to the Terms of Use and Privacy Policy';
      });
      return;
    }

    // Send OTP
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendOtp(email: email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: email,
            onSuccess: (otpCode) {
              // OTP verified successfully → navigate to SignUpScreen with verified email
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SignUpScreen(email: email),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('rate') || errorStr.contains('limit')) {
        setState(() {
          _emailError = 'Too many requests. Please try again later.';
        });
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('timeout') ||
          errorStr.contains('socket')) {
        setState(() {
          _emailError = 'Network error. Please check your connection and try again.';
        });
      } else {
        setState(() {
          _emailError = 'Failed to send OTP. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: Responsive.scaledPadding(context, 78)),

                      // Title: "Your Email"
                      Center(
                        child: SizedBox(
                          width: Responsive.scaledPadding(context, 266).clamp(200.0, 266.0),
                          child: Text(
                            'Your Email',
                            style: TextStyle(
                              fontSize: Responsive.scaledFont(context, 32),
                              fontWeight: FontWeight.w500, // Medium
                              color: _primary900, // #100B3C
                              fontFamily: 'Rubik',
                              height: 1.2, // 120% line-height
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 57)),

                      // Instructional text
                      Padding(
                        padding: EdgeInsets.only(
                          left: Responsive.scaledPadding(context, 24),
                          right: Responsive.scaledPadding(context, 24),
                        ),
                        child: SizedBox(
                          width: Responsive.scaledPadding(context, 341).clamp(
                            0.0,
                            MediaQuery.of(context).size.width - Responsive.scaledPadding(context, 48),
                          ),
                          child: Text(
                            'Enter the email where you can be contacted.\nNo one will see this on your profile.',
                            style: TextStyle(
                              fontSize: Responsive.scaledFont(context, 16),
                              fontWeight: FontWeight.w400, // Regular
                              color: _primary900, // #100B3C
                              fontFamily: 'Rubik',
                              height: 1.4, // 140% line-height
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 44)),

                      // Email input field
                      Center(
                        child: SizedBox(
                          width: Responsive.widthPercent(context, 90).clamp(300.0, 342.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: Responsive.scaledPadding(context, 60).clamp(55.0, 65.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: _emailError != null ? Colors.red : _primaryColor,
                                    width: 0.758,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.responsiveRadius(context, 14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: Responsive.scaledPadding(context, 20)),
                                    // Email icon - using SVG asset to match login screen
                                    SvgPicture.asset(
                                      'assets/authPages/email.svg',
                                      width: Responsive.scaledIcon(context, 18),
                                      height: Responsive.scaledIcon(context, 18),
                                      colorFilter: ColorFilter.mode(
                                        _grey400,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    SizedBox(width: Responsive.scaledPadding(context, 10)),
                                    // Email text field
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        onChanged: (_) {
                                          setState(() {
                                            _emailError = null; // Clear error on type
                                          });
                                        },
                                        style: TextStyle(
                                          fontSize: Responsive.scaledFont(context, 16),
                                          color: _primary900,
                                          fontFamily: 'Inter',
                                          letterSpacing: -0.3125,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Email',
                                          hintStyle: TextStyle(
                                            fontSize: Responsive.scaledFont(context, 16),
                                            color: _grey700,
                                            fontFamily: 'Inter',
                                            letterSpacing: -0.3125,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: Responsive.scaledPadding(context, 4),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: Responsive.scaledPadding(context, 12)),
                                  ],
                                ),
                              ),
                              // Email error message
                              if (_emailError != null)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: Responsive.scaledPadding(context, 4),
                                    top: Responsive.scaledPadding(context, 6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: Responsive.scaledIcon(context, 14),
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: Responsive.scaledPadding(context, 4)),
                                      Expanded(
                                        child: Text(
                                          _emailError!,
                                          style: TextStyle(
                                            fontSize: Responsive.scaledFont(context, 12),
                                            color: Colors.red,
                                            fontFamily: 'Rubik',
                                            height: 1.4,
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

                      SizedBox(height: Responsive.scaledPadding(context, 80)),

                      // Sign up button
                      Center(
                        child: SizedBox(
                          width: Responsive.widthPercent(context, 90).clamp(300.0, 342.0),
                          child: Container(
                            height: Responsive.scaledPadding(context, 56).clamp(50.0, 60.0),
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
                                onTap: _isLoading ? null : _handleSendOtp,
                                borderRadius: BorderRadius.circular(
                                  Responsive.responsiveRadius(context, 20),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Sign up',
                                          style: TextStyle(
                                            fontSize: Responsive.scaledFont(context, 16),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 44)),

                      // Terms and conditions checkbox
                      Center(
                        child: SizedBox(
                          width: Responsive.widthPercent(context, 90).clamp(300.0, 342.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkbox
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _agreeToTerms = !_agreeToTerms;
                                        if (_agreeToTerms) {
                                          _termsError = null;
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: Responsive.scaledPadding(context, 24.476),
                                      height: Responsive.scaledPadding(context, 24),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _checkboxColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.responsiveRadius(context, 6),
                                        ),
                                        color: _agreeToTerms ? _checkboxColor : Colors.white,
                                      ),
                                      child: _agreeToTerms
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: Responsive.scaledIcon(context, 16),
                                            )
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: Responsive.scaledPadding(context, 12)),
                                  // Terms text
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CommunityGuidelinesScreen(),
                                          ),
                                        );
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: Responsive.scaledFont(context, 12),
                                            fontWeight: FontWeight.normal,
                                            color: _primary900,
                                            letterSpacing: 0.2,
                                            fontFamily: 'Rubik',
                                            height: 1.4,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: 'By signing up I agree, to the ',
                                            ),
                                            TextSpan(
                                              text: 'Terms of Use',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                                color: _primary900,
                                              ),
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                                color: _primary900,
                                              ),
                                            ),
                                            const TextSpan(text: '.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Terms error message
                              if (_termsError != null)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: Responsive.scaledPadding(context, 36),
                                    top: Responsive.scaledPadding(context, 6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: Responsive.scaledIcon(context, 14),
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: Responsive.scaledPadding(context, 4)),
                                      Expanded(
                                        child: Text(
                                          _termsError!,
                                          style: TextStyle(
                                            fontSize: Responsive.scaledFont(context, 12),
                                            color: Colors.red,
                                            fontFamily: 'Rubik',
                                            height: 1.4,
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

                      SizedBox(height: Responsive.scaledPadding(context, 70)),

                      // Divider line
                      Center(
                        child: SizedBox(
                          width: Responsive.scaledPadding(context, 338).clamp(280.0, 338.0),
                          height: Responsive.scaledPadding(context, 22),
                          child: SvgPicture.asset(
                            'assets/email-collection-page-divider.svg',
                            width: Responsive.scaledPadding(context, 338).clamp(280.0, 338.0),
                            height: Responsive.scaledPadding(context, 22),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 20)),

                      // Footer: "Already have an account? Sign In"
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: Responsive.scaledFont(context, 15),
                            fontWeight: FontWeight.normal,
                            color: _grey400,
                            fontFamily: 'Inter',
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                fontSize: Responsive.scaledFont(context, 15),
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                fontFamily: 'Inter',
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 30)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
