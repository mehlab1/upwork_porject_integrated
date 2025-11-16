import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../signup/signup_screen.dart';
import '../forgot_password/forgot_password_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Animation for shifting form to the left
  AnimationController? _shiftAnimationController;
  Animation<double>? _shiftAnimation;
  bool _isFormShifted = false;

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey400 = Color(0xFF8A8D9E);
  static const Color _grey600 = Color(0xFF6F7786);

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _shiftAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shiftAnimation = Tween<double>(begin: 0.0, end: -100.0).animate(
      CurvedAnimation(
        parent: _shiftAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shiftAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button - positioned at left: 26px, top: 70px
            Positioned(
              left: 26,
              top: 70,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 19,
                  height: 12,
                  child: Icon(Icons.arrow_back, color: _primary900, size: 20),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 200),

                  // Login title - centered, 40px, Rubik Medium
                  Text(
                    'Login ',
                    style: TextStyle(
                      fontSize: 40,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF100B3C),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 83), // Space to email field
                  // Animated form section - shifts to left when login button is pressed
                  AnimatedBuilder(
                    animation:
                        _shiftAnimation ?? const AlwaysStoppedAnimation(0.0),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shiftAnimation?.value ?? 0.0, 0),
                        child: Column(
                          children: [
                            // Email field - left: 26px from SafeArea, top: 342px
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 338,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: _emailError != null
                                            ? Colors.red
                                            : _primaryColor,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 20),
                                        // Email icon
                                        Icon(
                                          Icons.email_outlined,
                                          color: _grey400,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        // Email input
                                        Expanded(
                                          child: TextField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            onChanged: (value) {
                                              setState(() {
                                                _emailError = null;
                                              });
                                            },
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _primary900,
                                              fontFamily: 'Rubik',
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'anthoy@mail.com',
                                              hintStyle: TextStyle(
                                                fontSize: 16,
                                                color: _grey400,
                                                fontFamily: 'Rubik',
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 19,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Reserve space for error message to prevent layout shift
                                  SizedBox(
                                    height: _emailError != null ? 20 : 0,
                                    child: _emailError != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              left: 20,
                                              top: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _emailError!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.red,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password field - centered, width 338px
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 338,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: _passwordError != null
                                            ? Colors.red
                                            : _primaryColor,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 20),
                                        // Lock icon
                                        Icon(
                                          Icons.lock_outline,
                                          color: _grey600,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        // Password input
                                        Expanded(
                                          child: TextField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            onChanged: (value) {
                                              setState(() {
                                                _passwordError = null;
                                              });
                                            },
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _primary900,
                                              fontFamily: 'Rubik',
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Password',
                                              hintStyle: TextStyle(
                                                fontSize: 16,
                                                color: _grey600,
                                                fontFamily: 'Rubik',
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        // Password visibility toggle
                                        IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: _grey600,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                    ),
                                  ),
                                  // Reserve space for error message to prevent layout shift
                                  SizedBox(
                                    height: _passwordError != null ? 20 : 0,
                                    child: _passwordError != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              left: 20,
                                              top: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _passwordError!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.red,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Remember me - left: 26px
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
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
                                      width: 24.4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _primaryColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        color: _rememberMe
                                            ? _primaryColor
                                            : Colors.white,
                                      ),
                                      child: _rememberMe
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.normal, // Rubik Regular
                                      color: _primary900,
                                      letterSpacing: 0.2,
                                      fontFamily: 'Rubik',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Sign In button
                            Container(
                              width: 338,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _isLoading
                                    ? _primaryColor.withOpacity(0.7)
                                    : _primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading
                                      ? null
                                      : () async {
                                          if (_validateLogin()) {
                                            if (!_isFormShifted &&
                                                _shiftAnimationController !=
                                                    null) {
                                              setState(() {
                                                _isFormShifted = true;
                                              });
                                              await _shiftAnimationController!
                                                  .forward();
                                            }
                                            if (!mounted) return;
                                            await _handleLogin();
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(
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
                      );
                    },
                  ),

                  const SizedBox(height: 32),

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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal, // Rubik Regular
                        color: _grey400,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider - 338px width, 22px height
                  SizedBox(
                    width: 338,
                    height: 22,
                    child: Row(
                      children: [
                        // Left divider (72.78% of width)
                        Expanded(
                          flex: 7278,
                          child: Container(
                            alignment: Alignment.center,
                            child: Container(
                              height: 1,
                              width: double.infinity,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                        ),
                        // Right divider (27.22% of width)
                        Expanded(
                          flex: 2722,
                          child: Container(
                            alignment: Alignment.center,
                            child: Container(
                              height: 1,
                              width: double.infinity,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal, // Rubik Regular
                        color: _grey400,
                        fontFamily: 'Rubik',
                      ),
                      children: [
                        const TextSpan(text: "Don't have account? "),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500, // Rubik Medium
                                color: _primaryColor,
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ),
                        ),
                      ],
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
    } else if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters';
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
      await _authService.signIn(email: email, password: password);

      if (!mounted) return;

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
        arguments: {'showWelcomeModal': shouldShowWelcome, 'showFirstPostCard': shouldShowWelcome},
      );
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