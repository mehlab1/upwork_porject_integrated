import 'package:flutter/material.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Color for "pal" text - starts as light gray (neutral-300), animates to black after 2 seconds
  Color _palTextColor = const Color(0xFFD4D4D4); // neutral-300 (light gray)
  Color _dotColor = const Color(0xFFD4D4D4); // neutral-300 (light gray)
  bool _isLogInPressed = false;
  bool _isSignUpPressed = false;

  // Logo visibility state
  bool _showLogo = false;
  bool _showText = true;

  // Animation controllers
  late AnimationController _logoAnimationController;
  late Animation<double> _logoFadeAnimation;
  late AnimationController _textAnimationController;
  late Animation<double> _textFadeAnimation;

  // Bright blue color used for buttons when pressed
  static const Color _brightBlue = Color(0xFF155DFC);
  // Dark blue color for logo text (from Figma: #0f172b)
  static const Color _logoTextColor = Color(0xFF0F172B);

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

    _textAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showText = false;
          _showLogo = true;
        });
        _logoAnimationController.forward();
      }
    });

    // Text is shown first, then fades out to reveal the logo
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _textAnimationController.forward();
      }
    });

    // Animate "pal" text and dot color to black shortly before it fades away
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _showText) {
        setState(() {
          _palTextColor = Colors.black;
          _dotColor = Colors.black;
        });
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
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
                  // Logo section - positioned at top: 294px, left: 72px (from Figma)
                  if (_showLogo)
                    Positioned(
                      left: 72,
                      top: 294,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo icon (66px from Figma)
                            Image.asset(
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
                            const SizedBox(width: 18), // gap-[18px] from Figma
                            // Logo text section
                          ],
                        ),
                      ),
                    ),

                  // Text content section - appears after logo fades out
                  if (_showText)
                    Positioned(
                      left: 74,
                      top: 180,
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
                                  Positioned(
                                    top: 0,
                                    left: 0,
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
                        color: _isLogInPressed ? _brightBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20), // Figma: 20px
                        elevation: _isLogInPressed ? 0 : 4,
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
                                color: _isLogInPressed
                                    ? Colors.white
                                    : Colors.black, // Figma: black text
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
