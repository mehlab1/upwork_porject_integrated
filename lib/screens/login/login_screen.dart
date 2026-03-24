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
import '../../services/moderator_service.dart';
import '../../services/junior_moderator_service.dart';
import '../../services/reviewer_service.dart';
import '../../services/user_role_service.dart';
import '../../widgets/pal_toast.dart';
import '../../widgets/error_dialog.dart';
import '../../services/notification_count_manager.dart';
import '../signup/email_collection_screen.dart';
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
  final ModeratorService _moderatorService = ModeratorService();
  final JuniorModeratorService _juniorModeratorService = JuniorModeratorService();
  final ReviewerService _reviewerService = ReviewerService();
  final UserRoleService _userRoleService = UserRoleService();

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
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: _grey400,
                                            size: 20,
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
                                          const EmailCollectionScreen(),
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
      // HARDCODED ADMIN CREDENTIALS (for development/testing only)
      // TODO: Remove before production deployment
      const String hardcodedAdminEmail = 'admin@kp2.com';
      const String hardcodedAdminPassword = 'admin123';
      
      // HARDCODED MODERATOR CREDENTIALS (for development/testing only)
      // TODO: Remove before production deployment
      const String hardcodedModeratorEmail = 'moderator@kp2.com';
      const String hardcodedModeratorPassword = 'moderator123';
      
      // HARDCODED JUNIOR MODERATOR CREDENTIALS (for development/testing only)
      // TODO: Remove before production deployment
      const String hardcodedJuniorModeratorEmail = 'juniormoderator@kp2.com';
      const String hardcodedJuniorModeratorPassword = 'juniormoderator123';
      
      // HARDCODED REVIEWER CREDENTIALS (for development/testing only)
      // TODO: Remove before production deployment
      const String hardcodedReviewerEmail = 'reviewer@kp2.com';
      const String hardcodedReviewerPassword = 'reviewer123';
      
      // Check if credentials match hardcoded admin
      final bool isHardcodedAdmin = email.toLowerCase() == hardcodedAdminEmail.toLowerCase() && 
                                    password == hardcodedAdminPassword;
      
      // Check if credentials match hardcoded moderator
      final bool isHardcodedModerator = email.toLowerCase() == hardcodedModeratorEmail.toLowerCase() && 
                                        password == hardcodedModeratorPassword;
      
      // Check if credentials match hardcoded junior moderator
      final bool isHardcodedJuniorModerator = email.toLowerCase() == hardcodedJuniorModeratorEmail.toLowerCase() && 
                                              password == hardcodedJuniorModeratorPassword;
      
      // Check if credentials match hardcoded reviewer
      final bool isHardcodedReviewer = email.toLowerCase() == hardcodedReviewerEmail.toLowerCase() && 
                                      password == hardcodedReviewerPassword;
      
      print('=== LOGIN - REQUEST TO SIGN IN ===');
      print('Email: $email');
      print('Password length: ${password.length}');
      if (isHardcodedAdmin) {
        print('HARDCODED ADMIN LOGIN DETECTED');
      }
      if (isHardcodedModerator) {
        print('HARDCODED MODERATOR LOGIN DETECTED');
      }
      if (isHardcodedJuniorModerator) {
        print('HARDCODED JUNIOR MODERATOR LOGIN DETECTED');
      }
      if (isHardcodedReviewer) {
        print('HARDCODED REVIEWER LOGIN DETECTED');
      }
      
      AuthResponse? signInResponse;
      bool skipEmailVerificationCheck = false;
      bool isHardcodedAdminWithoutSupabase = false;
      bool isHardcodedModeratorWithoutSupabase = false;
      bool isHardcodedJuniorModeratorWithoutSupabase = false;
      bool isHardcodedReviewerWithoutSupabase = false;
      
      // For hardcoded admin, try to authenticate but bypass email verification
      if (isHardcodedAdmin) {
        try {
          signInResponse = await _authService.signIn(email: hardcodedAdminEmail, password: hardcodedAdminPassword);
          // If Supabase auth succeeds, allow bypassing email verification for admin
          skipEmailVerificationCheck = true;
          print('Hardcoded admin authenticated successfully with Supabase');
        } catch (e) {
          // If Supabase auth fails, note that we're proceeding without Supabase session
          // The account may not exist in Supabase yet - user can still test admin UI
          print('Hardcoded admin - Supabase auth failed (account may not exist): $e');
          print('Proceeding with hardcoded admin access (bypassing Supabase auth)');
          skipEmailVerificationCheck = true;
          isHardcodedAdminWithoutSupabase = true;
          // Note: Some features may not work without a Supabase session
        }
      }
      
      // For hardcoded moderator, try to authenticate but bypass email verification
      if (isHardcodedModerator && signInResponse == null) {
        try {
          signInResponse = await _authService.signIn(email: hardcodedModeratorEmail, password: hardcodedModeratorPassword);
          // If Supabase auth succeeds, allow bypassing email verification for moderator
          skipEmailVerificationCheck = true;
          print('Hardcoded moderator authenticated successfully with Supabase');
        } catch (e) {
          // If Supabase auth fails, note that we're proceeding without Supabase session
          // The account may not exist in Supabase yet - user can still test moderator UI
          print('Hardcoded moderator - Supabase auth failed (account may not exist): $e');
          print('Proceeding with hardcoded moderator access (bypassing Supabase auth)');
          skipEmailVerificationCheck = true;
          isHardcodedModeratorWithoutSupabase = true;
          // Note: Some features may not work without a Supabase session
        }
      }
      
      // For hardcoded junior moderator, try to authenticate but bypass email verification
      if (isHardcodedJuniorModerator && signInResponse == null) {
        try {
          signInResponse = await _authService.signIn(email: hardcodedJuniorModeratorEmail, password: hardcodedJuniorModeratorPassword);
          // If Supabase auth succeeds, allow bypassing email verification for junior moderator
          skipEmailVerificationCheck = true;
          print('Hardcoded junior moderator authenticated successfully with Supabase');
        } catch (e) {
          // If Supabase auth fails, note that we're proceeding without Supabase session
          // The account may not exist in Supabase yet - user can still test junior moderator UI
          print('Hardcoded junior moderator - Supabase auth failed (account may not exist): $e');
          print('Proceeding with hardcoded junior moderator access (bypassing Supabase auth)');
          skipEmailVerificationCheck = true;
          isHardcodedJuniorModeratorWithoutSupabase = true;
          // Note: Some features may not work without a Supabase session
        }
      }
      
      // For hardcoded reviewer, try to authenticate but bypass email verification
      if (isHardcodedReviewer && signInResponse == null) {
        try {
          signInResponse = await _authService.signIn(email: hardcodedReviewerEmail, password: hardcodedReviewerPassword);
          skipEmailVerificationCheck = true;
          print('Hardcoded reviewer authenticated successfully with Supabase');
        } catch (e) {
          print('Hardcoded reviewer - Supabase auth failed (account may not exist): $e');
          print('Proceeding with hardcoded reviewer access (bypassing Supabase auth)');
          skipEmailVerificationCheck = true;
          isHardcodedReviewerWithoutSupabase = true;
        }
      }
      
      // If not hardcoded admin/moderator/junior moderator/reviewer, try normal auth
      if (signInResponse == null && !isHardcodedAdmin && !isHardcodedModerator && !isHardcodedJuniorModerator && !isHardcodedReviewer) {
        signInResponse = await _authService.signIn(email: email, password: password);
      }
      
      // If hardcoded admin but no Supabase session, show warning but allow access
      if (isHardcodedAdminWithoutSupabase) {
        if (mounted) {
          PalToast.show(
            context,
            message: 'Admin access granted. Note: Some features may require Supabase account.',
            isError: false,
          );
        }
      }
      
      // If hardcoded moderator but no Supabase session, show warning but allow access
      if (isHardcodedModeratorWithoutSupabase) {
        if (mounted) {
          PalToast.show(
            context,
            message: 'Moderator access granted. Note: Some features may require Supabase account.',
            isError: false,
          );
        }
      }
      
      // If hardcoded junior moderator but no Supabase session, show warning but allow access
      if (isHardcodedJuniorModeratorWithoutSupabase) {
        if (mounted) {
          PalToast.show(
            context,
            message: 'Junior Moderator access granted. Note: Some features may require Supabase account.',
            isError: false,
          );
        }
      }
      
      // If hardcoded reviewer but no Supabase session, show warning but allow access
      if (isHardcodedReviewerWithoutSupabase) {
        if (mounted) {
          PalToast.show(
            context,
            message: 'Reviewer access granted. Note: Some features may require Supabase account.',
            isError: false,
          );
        }
      }
      
      print('=== LOGIN - RESPONSE FROM SIGN IN ===');
      if (signInResponse != null) {
        print('Has session: ${signInResponse.session != null}');
        print('Has user: ${signInResponse.user != null}');
        if (signInResponse.user != null) {
          print('User ID: ${signInResponse.user!.id}');
          print('User email: ${signInResponse.user!.email}');
          print('Email verified: ${signInResponse.user!.emailConfirmedAt != null}');
          print('Email confirmed at: ${signInResponse.user!.emailConfirmedAt}');
        }
      } else if (isHardcodedAdmin) {
        print('Hardcoded admin - no Supabase session (will proceed anyway)');
      } else if (isHardcodedModerator) {
        print('Hardcoded moderator - no Supabase session (will proceed anyway)');
      } else if (isHardcodedJuniorModerator) {
        print('Hardcoded junior moderator - no Supabase session (will proceed anyway)');
      } else if (isHardcodedReviewer) {
        print('Hardcoded reviewer - no Supabase session (will proceed anyway)');
      }
      print('====================================');

      if (!mounted) return;

      // Check if email is verified via OTP (skip for hardcoded admin/moderator)
      if (!skipEmailVerificationCheck && 
          signInResponse?.user?.emailConfirmedAt == null) {
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

      // Determine admin/moderator/junior moderator/reviewer status from backend role (not email).
      // Keep hardcoded access for dev/testing accounts.
      bool isAdmin = isHardcodedAdmin || isHardcodedAdminWithoutSupabase;
      bool isModerator =
          isHardcodedModerator || isHardcodedModeratorWithoutSupabase;
      bool isJuniorModerator =
          isHardcodedJuniorModerator || isHardcodedJuniorModeratorWithoutSupabase;
      bool isReviewer =
          isHardcodedReviewer || isHardcodedReviewerWithoutSupabase;

      if (!isHardcodedAdminWithoutSupabase && !isHardcodedModeratorWithoutSupabase && !isHardcodedJuniorModeratorWithoutSupabase && !isHardcodedReviewerWithoutSupabase) {
        try {
          final roleResp = await _userRoleService.getUserRole();
          final role = roleResp['role']?.toString().trim();
          if (role != null && role.isNotEmpty) {
            isAdmin = isAdmin || role == 'admin';
            isModerator = isModerator ||
                role == 'moderator';
            isJuniorModerator = isJuniorModerator || role == 'junior_moderator';
            isReviewer = isReviewer || role == 'reviewer';
          }
        } catch (e) {
          // Fallback: read current user's role directly from own profile (RLS should allow).
          try {
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              final profile = await Supabase.instance.client
                  .from('profiles')
                  .select('role')
                  .eq('id', userId)
                  .maybeSingle();
              final role = (profile as Map?)?['role']?.toString();
              if (role != null && role.isNotEmpty) {
                isAdmin = isAdmin || role == 'admin';
                isModerator = isModerator ||
                    role == 'moderator';
                isJuniorModerator = isJuniorModerator || role == 'junior_moderator';
                isReviewer = isReviewer || role == 'reviewer';
              }
            }
          } catch (_) {
            // If both role lookups fail, leave flags as hardcoded-only.
          }
        }
      }

      await _adminService.setAdminStatus(isAdmin);
      await _moderatorService.setModeratorStatus(isModerator);
      await _juniorModeratorService.setJuniorModeratorStatus(isJuniorModerator);
      await _reviewerService.setReviewerStatus(isReviewer);

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
      // logged-in users that have 0 or 1 posts see the onboarding UI.
      // Skip profile fetch for hardcoded admin/moderator/junior moderator/reviewer without Supabase session
      bool shouldShowWelcome = false;
      if (!isHardcodedAdminWithoutSupabase && !isHardcodedModeratorWithoutSupabase && !isHardcodedJuniorModeratorWithoutSupabase && !isHardcodedReviewerWithoutSupabase) {
        try {
          final postService = PostService();
          // Kick off feed prefetch in parallel with the profile fetch so the
          // feed screen's first load finds data already in cache.
          postService.prefetchFeed();
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
          shouldShowWelcome = postCount <= 1;
        } catch (e) {
          // On error, default to not showing the modal. Preserve safe behaviour.
          shouldShowWelcome = false;
        }
      } else {
        // Hardcoded admin/moderator without Supabase session - don't show welcome modal
        shouldShowWelcome = false;
      }

      // Initialize notification count manager on successful login
      try {
        await NotificationCountManager.instance.initialize();
        debugPrint('[LoginScreen] Notification count manager initialized');
      } catch (e) {
        // Notification count manager failure shouldn't block login
        debugPrint('[LoginScreen] Notification count manager initialization failed: $e');
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {
          'showWelcomeModal': shouldShowWelcome,
          'showFirstPostCard': shouldShowWelcome,
        },
      );

      // In-app notification banners are shown from FeedHomeScreen.initState
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final errorStr = e.toString().toLowerCase();
      // Check if it's a network error
      if (errorStr.contains('network') || 
          errorStr.contains('connection') || 
          errorStr.contains('xmlhttprequest') ||
          errorStr.contains('socket') ||
          errorStr.contains('timeout') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('network is unreachable')) {
        // Show network error dialog
        await showErrorDialogFromTechnical(
          context,
          errorMessage: e.message,
          onTryAgain: () {
            Navigator.of(context).pop();
            _handleLogin();
          },
        );
        return;
      }

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
      });

      final errorStr = e.toString().toLowerCase();
      // Check if it's a network error
      if (errorStr.contains('network') || 
          errorStr.contains('connection') || 
          errorStr.contains('xmlhttprequest') ||
          errorStr.contains('socket') ||
          errorStr.contains('timeout') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('network is unreachable') ||
          errorStr.contains('http') && (errorStr.contains('error') || errorStr.contains('failed'))) {
        // Show network error dialog
        await showErrorDialogFromTechnical(
          context,
          errorMessage: e.toString(),
          onTryAgain: () {
            Navigator.of(context).pop();
            _handleLogin();
          },
        );
        return;
      }

      // For non-network errors, show generic error
      setState(() {
        _emailError = 'An unexpected error occurred. Please try again.';
      });
    }
  }
}
