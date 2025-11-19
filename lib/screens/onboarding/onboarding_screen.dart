import 'package:flutter/material.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Color for "pal" text - starts as light gray (neutral-300), animates to black
  Color _palTextColor = const Color(0xFFD4D4D4); // neutral-300 (light gray)
  Color _dotColor = const Color(0xFFD4D4D4); // neutral-300 (light gray)
  bool _isLogInPressed = false;
  bool _isSignUpPressed = false;

  // Logo visibility state
  bool _showLogo = false;
  bool _showText = true;
  bool _showKobi = false; // Controls visibility of "kobi" text

  // Login button background color
  Color _loginButtonColor = Colors.white;

  // Animation controllers
  late AnimationController _logoAnimationController;
  late Animation<double> _logoFadeAnimation;
  late AnimationController _textAnimationController;
  late Animation<double> _textFadeAnimation;
  late AnimationController _palColorAnimationController;
  late AnimationController _kobiFadeAnimationController;
  late AnimationController _dotColorAnimationController;
  late AnimationController _buttonColorAnimationController;

  late Animation<Color?> _palColorAnimation;
  late Animation<double> _kobiFadeAnimation;
  late Animation<Color?> _dotColorAnimation;
  late Animation<Color?> _buttonColorAnimation;

  // Bright blue color used for buttons when pressed
  static const Color _brightBlue = Color(0xFF155DFC);
  // Dark blue color for logo text (from Figma: #0f172b)
  static const Color _logoTextColor = Color(0xFF0F172B);
  // Dark color for "pal" text
  static const Color _darkPalColor = Color(0xFF000000);

  @override
  void initState() {
    super.initState();

    // Logo fade in animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeOut),
    );

    // Text fade out animation
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeIn),
    );

    // "pal" color animation (light gray to dark)
    _palColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _palColorAnimation =
        ColorTween(begin: const Color(0xFFD4D4D4), end: _darkPalColor).animate(
          CurvedAnimation(
            parent: _palColorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // "kobi" fade in animation
    _kobiFadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _kobiFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _kobiFadeAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // Dot color animation (light gray to blue)
    _dotColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _dotColorAnimation =
        ColorTween(begin: const Color(0xFFD4D4D4), end: _brightBlue).animate(
          CurvedAnimation(
            parent: _dotColorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Button color animation (white to blue)
    _buttonColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonColorAnimation = ColorTween(begin: Colors.white, end: _brightBlue)
        .animate(
          CurvedAnimation(
            parent: _buttonColorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Update colors during animations
    _palColorAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _palTextColor = _palColorAnimation.value ?? const Color(0xFFD4D4D4);
        });
      }
    });

    _dotColorAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _dotColor = _dotColorAnimation.value ?? const Color(0xFFD4D4D4);
        });
      }
    });

    _buttonColorAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _loginButtonColor = _buttonColorAnimation.value ?? Colors.white;
        });
      }
    });

    _textAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showText = false;
          _showLogo = true;
        });
        _logoAnimationController.forward();
      }
    });

    // Animation sequence:
    // Step 1: Text appears with light color (already set in initial state)
    // Step 2: After 1.5 seconds, "pal" transitions to dark color
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _showText) {
        _palColorAnimationController.forward();
      }
    });

    // Step 3: After 2.5 seconds, "kobi" appears and dot + button transition to blue
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _showText) {
        setState(() {
          _showKobi = true;
        });
        _kobiFadeAnimationController.forward();
        _dotColorAnimationController.forward();
        _buttonColorAnimationController.forward();
      }
    });

    // Step 4: After 4 seconds, text fades out and transitions to logo
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _textAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _palColorAnimationController.dispose();
    _kobiFadeAnimationController.dispose();
    _dotColorAnimationController.dispose();
    _buttonColorAnimationController.dispose();
    super.dispose();
  }

  void _handleLogIn() {
    setState(() {
      _isLogInPressed = true;
    });
    // Navigate to login page after a brief moment to show the pressed state
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Navigator.pushNamed(context, '/login');
      }
    });
  }

  void _handleSignUp() {
    setState(() {
      _isSignUpPressed = true;
    });
    // Navigate to signup page after a brief moment to show the pressed state
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Navigator.pushNamed(context, '/signup');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Neutral-300 color (light gray) matching Figma design
    const Color neutral300 = Color(0xFFD4D4D4);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // First div: Logo or Text content section - aligned to left
            Expanded(
              child: Stack(
                children: [
                  // Logo section - centered on the page
                  if (_showLogo)
                    Center(
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: 279,
                          height: 171,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Return a placeholder if asset fails to load
                            return Container(
                              width: 279,
                              height: 171,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50),
                            );
                          },
                        ),
                      ),
                    ),

                  // Text content section - appears after logo fades out
                  if (_showText)
                    Positioned(
                      left: 74,
                      top: 210,
                      child: FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // "Your Every Day" text - stacked vertically
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // "Your"
                                Text(
                                  'Your',
                                  style: TextStyle(
                                    fontSize: 65, // Figma: 65px
                                    fontWeight:
                                        FontWeight.bold, // Montserrat Bold
                                    color: neutral300, // neutral-300
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12), // Gap between lines
                                // "Every"
                                Text(
                                  'Every',
                                  style: TextStyle(
                                    fontSize: 65, // Figma: 65px
                                    fontWeight:
                                        FontWeight.bold, // Montserrat Bold
                                    color: neutral300, // neutral-300
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12), // Gap between lines
                                // "Day"
                                Text(
                                  'Day',
                                  style: TextStyle(
                                    fontSize: 65, // Figma: 65px
                                    fontWeight:
                                        FontWeight.bold, // Montserrat Bold
                                    color: neutral300, // neutral-300
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: 160,
                              height: 90,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  if (_showKobi)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: FadeTransition(
                                        opacity: _kobiFadeAnimation,
                                        child: Text(
                                          'kobi',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _logoTextColor,
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'pal',
                                          style: TextStyle(
                                            fontSize: 60,
                                            fontWeight: FontWeight.w700,
                                            color: _palTextColor,
                                            fontFamily: 'Inter',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          '.',
                                          style: TextStyle(
                                            fontSize: 60,
                                            fontWeight: FontWeight.w700,
                                            color: _dotColor,
                                            fontFamily: 'Inter',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Second div: Buttons and link section - centered
            Container(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Log In button
                    SizedBox(
                      width: 338, // Figma: 338px
                      child: Material(
                        color: _isLogInPressed
                            ? _brightBlue
                            : _loginButtonColor, // Use animated color
                        borderRadius: BorderRadius.circular(20), // Figma: 20px
                        elevation:
                            (_isLogInPressed ||
                                _loginButtonColor != Colors.white)
                            ? 0
                            : 4,
                        shadowColor: Colors.black.withOpacity(0.25),
                        child: InkWell(
                          onTap: _handleLogIn,
                          onTapDown: (_) {
                            setState(() {
                              _isLogInPressed = true;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              _isLogInPressed = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 90, // Figma: 90px horizontal padding
                              vertical: 18, // Figma: 18px vertical padding
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Log In',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16, // Figma: 16px
                                fontWeight: FontWeight.w500, // Poppins Medium
                                color:
                                    (_isLogInPressed ||
                                        _loginButtonColor != Colors.white)
                                    ? Colors.white
                                    : const Color(
                                        0xFF000000,
                                      ), // rgba(0, 0, 0, 1)
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign Up button
                    SizedBox(
                      width: 338, // Figma: 338px
                      child: Material(
                        color: _isSignUpPressed ? _brightBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20), // Figma: 20px
                        elevation: _isSignUpPressed ? 0 : 4,
                        shadowColor: Colors.black.withOpacity(0.25),
                        child: InkWell(
                          onTap: _handleSignUp,
                          onTapDown: (_) {
                            setState(() {
                              _isSignUpPressed = true;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              _isSignUpPressed = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 90, // Figma: 90px horizontal padding
                              vertical: 18, // Figma: 18px vertical padding
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Sign Up',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16, // Figma: 16px
                                fontWeight: FontWeight.w500, // Poppins Medium
                                color: _isSignUpPressed
                                    ? Colors.white
                                    : Colors.black, // Figma: black text
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}