import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/responsive/responsive.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/auth_remember_me_service.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_service.dart';
import '../../services/admin_service.dart';
import '../../widgets/pal_toast.dart';
import '../signup/signup_screen.dart';
import '../forgot_password/forgot_password_email_screen.dart';
import '../otp/otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final AuthRememberMeService _rememberMeService = AuthRememberMeService();
  final AdminService _adminService = AdminService();

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey400 = Color(0xFF8A8D9E);
  static const Color _grey600 = Color(0xFF6F7786);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: Responsive.heightPercent(context, 20)),

                      // Login title - centered, responsive, Rubik Medium
                      Text(
                        'Login ',
                        style: Responsive.responsiveTextStyle(
                          context,
                          fontSize: 40,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF100B3C),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(
                        height: Responsive.heightPercent(context, 10),
                      ), // Space to email field
                      // Static form section (no transitions)
                      Column(
                        children: [
                          // Email field - centered, responsive width
                          Center(
                            child: SizedBox(
                              width: Responsive.widthPercent(
                                context,
                                90,
                              ).clamp(280.0, 400.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: Responsive.scaledPadding(
                                      context,
                                      60,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: _emailError != null
                                            ? Colors.red
                                            : _primaryColor,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.responsiveRadius(
                                          context,
                                          10,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: Responsive.scaledPadding(
                                            context,
                                            20,
                                          ),
                                        ),
                                        // Email icon
                                        SvgPicture.asset(
                                          'assets/authPages/email.svg',
                                          width: Responsive.scaledIcon(
                                            context,
                                            18,
                                          ),
                                          height: Responsive.scaledIcon(
                                            context,
                                            18,
                                          ),
                                          colorFilter: ColorFilter.mode(
                                            _grey400,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        SizedBox(
                                          width: Responsive.scaledPadding(
                                            context,
                                            10,
                                          ),
                                        ),
                                        // Email input
                                        Expanded(
                                          child: TextField(
                                            key: const ValueKey(
                                              'login_email_field',
                                            ),
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            onChanged: (value) {
                                              setState(() {
                                                _emailError = null;
                                              });
                                            },
                                            style:
                                                Responsive.responsiveTextStyle(
                                                  context,
                                                  fontSize: 16,
                                                  color: _primary900,
                                                  fontFamily: 'Rubik',
                                                ),
                                            decoration: InputDecoration(
                                              hintText: 'Email',
                                              hintStyle:
                                                  Responsive.responsiveTextStyle(
                                                    context,
                                                    fontSize: 16,
                                                    color: _grey400,
                                                    fontFamily: 'Rubik',
                                                  ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  Responsive.responsiveSymmetric(
                                                    context,
                                                    vertical: 19,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_emailError != null)
                                    Padding(
                                      padding: Responsive.responsivePadding(
                                        context,
                                        top: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: Responsive.scaledIcon(
                                              context,
                                              14,
                                            ),
                                            color: Colors.red,
                                          ),
                                          SizedBox(
                                            width: Responsive.scaledPadding(
                                              context,
                                              4,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              _emailError!,
                                              style:
                                                  Responsive.responsiveTextStyle(
                                                    context,
                                                    fontSize: 12,
                                                    color: Colors.red,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            height: Responsive.scaledPadding(context, 20),
                          ),

                          // Password field - centered, responsive width
                          Center(
                            child: SizedBox(
                              width: Responsive.widthPercent(
                                context,
                                90,
                              ).clamp(280.0, 400.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: Responsive.scaledPadding(
                                      context,
                                      60,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: _passwordError != null
                                            ? Colors.red
                                            : _primaryColor,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.responsiveRadius(
                                          context,
                                          11,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: Responsive.scaledPadding(
                                            context,
                                            20,
                                          ),
                                        ),
                                        // Password icon
                                        SvgPicture.asset(
                                          'assets/authPages/Exclude.svg',
                                          width: Responsive.scaledIcon(
                                            context,
                                            18,
                                          ),
                                          height: Responsive.scaledIcon(
                                            context,
                                            18,
                                          ),
                                          colorFilter: ColorFilter.mode(
                                            _grey400,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        SizedBox(
                                          width: Responsive.scaledPadding(
                                            context,
                                            10,
                                          ),
                                        ),
                                        // Password input
                                        Expanded(
                                          child: TextField(
                                            key: const ValueKey(
                                              'login_password_field',
                                            ),
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            onChanged: (value) {
                                              setState(() {
                                                _passwordError = null;
                                              });
                                            },
                                            style:
                                                Responsive.responsiveTextStyle(
                                                  context,
                                                  fontSize: 16,
                                                  color: _primary900,
                                                  fontFamily: 'Rubik',
                                                ),
                                            decoration: InputDecoration(
                                              hintText: 'Password',
                                              hintStyle:
                                                  Responsive.responsiveTextStyle(
                                                    context,
                                                    fontSize: 16,
                                                    color: _grey600,
                                                    fontFamily: 'Rubik',
                                                  ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  Responsive.responsiveSymmetric(
                                                    context,
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        // Password visibility toggle
                                        IconButton(
                                          icon: SvgPicture.asset(
                                            'assets/authPages/hide.svg',
                                            width: Responsive.scaledIcon(
                                              context,
                                              20,
                                            ),
                                            height: Responsive.scaledIcon(
                                              context,
                                              20,
                                            ),
                                            colorFilter: ColorFilter.mode(
                                              _grey400,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        SizedBox(
                                          width: Responsive.scaledPadding(
                                            context,
                                            12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_passwordError != null)
                                    Padding(
                                      padding: Responsive.responsivePadding(
                                        context,
                                        top: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: Responsive.scaledIcon(
                                              context,
                                              14,
                                            ),
                                            color: Colors.red,
                                          ),
                                          SizedBox(
                                            width: Responsive.scaledPadding(
                                              context,
                                              4,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              _passwordError!,
                                              style:
                                                  Responsive.responsiveTextStyle(
                                                    context,
                                                    fontSize: 12,
                                                    color: Colors.red,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: Responsive.scaledPadding(context, 22),
                          ),

                          // Remember me - aligned with input forms
                          Center(
                            child: SizedBox(
                              width: Responsive.widthPercent(
                                context,
                                90,
                              ).clamp(280.0, 400.0),
                              child: Row(
                                children: [
                                  // Checkbox
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: Container(
                                      width: Responsive.scaledPadding(
                                        context,
                                        24.4,
                                      ),
                                      height: Responsive.scaledPadding(
                                        context,
                                        24,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _primaryColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.responsiveRadius(
                                            context,
                                            6,
                                          ),
                                        ),
                                        color: _rememberMe
                                            ? _primaryColor
                                            : Colors.white,
                                      ),
                                      child: _rememberMe
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: Responsive.scaledIcon(
                                                context,
                                                16,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: Responsive.scaledPadding(
                                      context,
                                      12,
                                    ),
                                  ),
                                  Text(
                                    'Remember me',
                                    style: Responsive.responsiveTextStyle(
                                      context,
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w500, // Rubik Regular
                                      color: _primary900,
                                      letterSpacing: 0.2,
                                      fontFamily: 'Rubik',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            height: Responsive.scaledPadding(context, 40),
                          ),

                          // Sign In button
                          Container(
                            width: Responsive.widthPercent(
                              context,
                              90,
                            ).clamp(280.0, 400.0),
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
                                        if (_validateLogin()) {
                                          if (!mounted) return;
                                          await _handleLogin();
                                        }
                                      },
                                borderRadius: BorderRadius.circular(
                                  Responsive.responsiveRadius(context, 20),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? SizedBox(
                                          width: Responsive.scaledIcon(
                                            context,
                                            20,
                                          ),
                                          height: Responsive.scaledIcon(
                                            context,
                                            20,
                                          ),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Sign In',
                                          style: Responsive.responsiveTextStyle(
                                            context,
                                            fontSize: 16,
                                            fontWeight: FontWeight
                                                .w500, // Poppins Medium
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 32)),

                      // Forgot Password link
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordEmailScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: Responsive.responsiveTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.normal, // Rubik Regular
                            color: _grey400,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 20)),

                      // Divider - responsive width and height
                      SizedBox(
                        width: Responsive.widthPercent(
                          context,
                          90,
                        ).clamp(280.0, 400.0),
                        height: Responsive.scaledPadding(context, 22),
                        child: Row(
                          children: [
                            // Left line (short, on the left)
                            Container(
                              width: Responsive.widthPercent(context, 20),
                              height: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            // Empty space in the center
                            const Spacer(),
                            // Right line (short, on the right)
                            Container(
                              width: Responsive.widthPercent(context, 20),
                              height: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 16)),

                      // Footer text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Responsive.responsiveTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.normal, // Rubik Regular
                            color: _grey400,
                            fontFamily: 'Rubik',
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: Responsive.responsiveTextStyle(
                                    context,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold, // Rubik Medium
                                    color: _primaryColor,
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 50)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _validateLogin() {
    bool isValid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate email
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      isValid = false;
    } else if (!email.contains('@')) {
      setState(() {
        _emailError = 'Email must contain @';
      });
      isValid = false;
    } else if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      isValid = false;
    } else {
      setState(() {
        _emailError = null;
      });
    }

    // Validate password
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      isValid = false;
    } else if (password.length < 8) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters';
      });
      isValid = false;
    } else {
      setState(() {
        _passwordError = null;
      });
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    try {
      print('=== LOGIN - REQUEST TO SIGN IN ===');
      print('Email: $email');
      print('Password length: ${password.length}');
      
      final signInResponse = await _authService.signIn(email: email, password: password);
      
      print('=== LOGIN - RESPONSE FROM SIGN IN ===');
      print('Has session: ${signInResponse.session != null}');
      print('Has user: ${signInResponse.user != null}');
      if (signInResponse.user != null) {
        print('User ID: ${signInResponse.user!.id}');
        print('User email: ${signInResponse.user!.email}');
        print('Email verified: ${signInResponse.user!.emailConfirmedAt != null}');
        print('Email confirmed at: ${signInResponse.user!.emailConfirmedAt}');
      }
      print('====================================');

      if (!mounted) return;

      // Check if email is verified via OTP
      if (signInResponse.user?.emailConfirmedAt == null) {
        // User is not verified - sign them out and redirect to OTP verification
        await _authService.signOut();
        
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        PalToast.show(
          context,
          message: 'Please verify your email with the OTP code sent to your email.',
          isError: true,
        );
        
        // Navigate to OTP verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              isPasswordReset: false,
              onSuccess: (otpCode) {
                // After OTP verification, user can login again
                // Navigate back to login screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }

      // Check if user is admin and store admin status
      final isAdmin = email.toLowerCase() == 'admin@kp2.com';
      await _adminService.setAdminStatus(isAdmin);

      // Save Remember Me preference after successful login
      await _rememberMeService.setRememberMe(_rememberMe);

      // Initialize FCM for push notifications
      try {
        await FCMService().initialize();
      } catch (e) {
        // FCM initialization failure shouldn't block login
        debugPrint('[LoginScreen] FCM initialization failed: $e');
      }

      // After successful sign-in, fetch profile to decide whether to
      // show the welcome modal / first-post card. This ensures all
      // logged-in users that have 0 posts see the onboarding UI.
      bool shouldShowWelcome = false;
      try {
        final postService = PostService();
        final profileResp = await postService.getProfile();
        final profile = profileResp['profile'] as Map<String, dynamic>?;
        int postCount = 0;
        if (profile != null) {
          final pc = profile['post_count'];
          if (pc is int) {
            postCount = pc;
          } else {
            postCount = int.tryParse(pc?.toString() ?? '') ?? 0;
          }
        }
        shouldShowWelcome = postCount == 0;
      } catch (e) {
        // On error, default to not showing the modal. Preserve safe behaviour.
        shouldShowWelcome = false;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {
          'showWelcomeModal': shouldShowWelcome,
          'showFirstPostCard': shouldShowWelcome,
        },
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
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final message = e.message.toLowerCase();
      if (message.contains('email') || message.contains('otp')) {
        setState(() {
          _emailError = e.message;
        });
      } else if (message.contains('password') ||
          message.contains('invalid login credentials')) {
        setState(() {
          _passwordError = 'Invalid email or password';
        });
      } else {
        setState(() {
          _emailError = e.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailError = 'An unexpected error occurred. Please try again.';
      });
    }
  }
}
