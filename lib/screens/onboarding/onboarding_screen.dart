import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/responsive.dart';

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
  // Dark color for "pal" text (final state: #0F172B)
  static const Color _darkPalColor = Color(0xFF0F172B);

  @override
  void initState() {
    super.initState();

    // Logo fade in animation - smooth transition
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeOut),
    );

    // Text fade out animation - smooth transition
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeInOut),
    );

    // "pal" color animation (light gray to dark) - smooth transition
    _palColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _palColorAnimation =
        ColorTween(begin: const Color(0xFFD4D4D4), end: _darkPalColor).animate(
          CurvedAnimation(
            parent: _palColorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // "kobi" fade in animation - smooth transition
    _kobiFadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _kobiFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _kobiFadeAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Dot color animation (light gray to blue) - smooth transition
    _dotColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dotColorAnimation =
        ColorTween(begin: const Color(0xFFD4D4D4), end: _brightBlue).animate(
          CurvedAnimation(
            parent: _dotColorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Button color animation (white to blue) - smooth transition
    _buttonColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    // Animation sequence: Clear visible transitions - each step takes 600ms with distinct delays
    // Step 1: Text appears with light color (already set in initial state)
    // Wait a moment to show step 1 clearly before transitioning
    Timer(const Duration(milliseconds: 800), () {
      if (mounted && _showText) {
        // Step 2: "pal" transitions to dark color (takes 600ms)
        // This transition should be clearly visible
        _palColorAnimationController.forward();
      }
    });

    // Step 3: "kobi" appears and dot + button transition to blue (takes 600ms)
    // Start after "pal" transition is clearly visible (800ms delay + 300ms into pal animation)
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted && _showText) {
        setState(() {
          _showKobi = true;
        });
        _kobiFadeAnimationController.forward();
        _dotColorAnimationController.forward();
        _buttonColorAnimationController.forward();
      }
    });

    // Step 4: Text fades out and transitions to logo (takes 600ms)
    // Start after previous animations complete for clear transition
    Timer(const Duration(milliseconds: 1700), () {
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
    final bool isSmallDevice = Responsive.isSmallDevice(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  // Main div: Centered container
                  child: Container(
                    width: Responsive.widthPercent(
                      context,
                      90,
                    ).clamp(300.0, 400.0),
                    padding: Responsive.responsivePadding(
                      context,
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Upper sub-div: Text content section
                        Container(
                          width: double.infinity,
                          height: Responsive.heightPercent(context, 60),
                          padding: Responsive.responsivePadding(
                            context,
                            left: Responsive.scaledPadding(
                              context,
                              40,
                            ).clamp(24.0, 60.0),
                            bottom: Responsive.scaledPadding(context, 40),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Logo section - centered
                              if (_showLogo)
                                Center(
                                  child: FadeTransition(
                                    opacity: _logoFadeAnimation,
                                    child: Image.asset(
                                      'assets/images/Logo.png',
                                      width: Responsive.widthPercent(
                                        context,
                                        75,
                                      ).clamp(200.0, 279.0),
                                      height: Responsive.heightPercent(
                                        context,
                                        25,
                                      ).clamp(120.0, 171.0),
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: Responsive.widthPercent(
                                                context,
                                                75,
                                              ).clamp(200.0, 279.0),
                                              height: Responsive.heightPercent(
                                                context,
                                                25,
                                              ).clamp(120.0, 171.0),
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.image,
                                                size: Responsive.scaledIcon(
                                                  context,
                                                  50,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),

                              // Text content section - center-left aligned
                              if (_showText)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FadeTransition(
                                    opacity: _textFadeAnimation,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // "Your Every Day" text - stacked vertically
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // "Your"
                                            Text(
                                              'Your',
                                              style: TextStyle(
                                                fontSize: isSmallDevice ? 45 : 65,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFD4D4D4),
                                                fontFamily: 'Montserrat',
                                                height: 1.0,
                                                letterSpacing: 2.5,
                                                textBaseline: TextBaseline.alphabetic,
                                              ),
                                            ),
                                            SizedBox(
                                              height: Responsive.scaledPadding(
                                                context,
                                                12,
                                              ),
                                            ),
                                            // "Every"
                                            Text(
                                              'Every',
                                              style: TextStyle(
                                                fontSize: isSmallDevice ? 45 : 65,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFD4D4D4),
                                                fontFamily: 'Montserrat',
                                                height: 1.0,
                                                letterSpacing: 2.5,
                                                textBaseline: TextBaseline.alphabetic,
                                              ),
                                            ),
                                            SizedBox(
                                              height: Responsive.scaledPadding(
                                                context,
                                                15,
                                              ),
                                            ),
                                            // "Day"
                                            Text(
                                              'Day',
                                              style: TextStyle(
                                                fontSize: isSmallDevice ? 45 : 65,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFD4D4D4),
                                                fontFamily: 'Montserrat',
                                                height: 1.0,
                                                letterSpacing: 2.5,
                                                textBaseline: TextBaseline.alphabetic,
                                              ),
                                            ),
                                          ],
                                        ),
                                            SizedBox(
                                              height: Responsive.scaledPadding(
                                                context,
                                                15,
                                              ),
                                            ),

                                        SizedBox(
                                          width: Responsive.widthPercent(
                                            context,
                                            45,
                                          ).clamp(120.0, 160.0),
                                          child: Stack(
                                            alignment: Alignment.centerLeft,
                                            clipBehavior: Clip.none,
                                            children: [
                                              // "pal" text - always visible as base
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'pal',
                                                    style: GoogleFonts.inter(
                                                      fontSize: isSmallDevice ? 42 : 70.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: _palTextColor,
                                                      letterSpacing: -1.273,
                                                      height: 72 / 70.5, // line-height: 72px / font-size: 70.5px
                                                    ),
                                                  ),
                                                  Text(
                                                    '.',
                                                    style: TextStyle(
                                                      fontSize: isSmallDevice ? 42 : 70.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: _dotColor,
                                                      fontFamily: 'Inter',
                                                      letterSpacing: -1.273,
                                                      height: 72 / 70.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // "kobi" text - positioned at top-left, overlapping pal
                                              if (_showKobi)
                                                Positioned(
                                                  top: -2,
                                                  left: 2,
                                                  child: FadeTransition(
                                                    opacity: _kobiFadeAnimation,
                                                    child: Text(
                                                      'kobi',
                                                      style: GoogleFonts.inter(
                                                        fontSize: Responsive.scaledFont(
                                                          context,
                                                          isSmallDevice ? 10 : 12,
                                                        ),
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF0F172B),
                                                        letterSpacing: 0.3,
                                                      ),
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
                            ],
                          ),
                        ),

                        // Lower sub-div: Buttons section
                        Container(
                          width: double.infinity,
                          height: Responsive.heightPercent(context, 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Log In button
                              SizedBox(
                                width: Responsive.widthPercent(
                                  context,
                                  90,
                                ).clamp(280.0, 400.0),
                                child: Material(
                                  color: _isLogInPressed
                                      ? _brightBlue
                                      : _loginButtonColor, // Use animated color
                                  borderRadius: BorderRadius.circular(
                                    Responsive.responsiveRadius(context, 20),
                                  ),
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
                                    borderRadius: BorderRadius.circular(
                                      Responsive.responsiveRadius(context, 20),
                                    ),
                                    child: Container(
                                      padding: Responsive.responsiveSymmetric(
                                        context,
                                        horizontal: isSmallDevice ? 60 : 90,
                                        vertical: isSmallDevice ? 14 : 18,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.responsiveRadius(
                                            context,
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Log In',
                                        textAlign: TextAlign.center,
                                        style: Responsive.responsiveTextStyle(
                                          context,
                                          fontSize: isSmallDevice ? 14 : 16,
                                          fontWeight:
                                              FontWeight.w500, // Poppins Medium
                                          color:
                                              (_isLogInPressed ||
                                                  _loginButtonColor !=
                                                      Colors.white)
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

                              SizedBox(
                                height: Responsive.scaledPadding(context, 16),
                              ),

                              // Sign Up button
                              SizedBox(
                                width: Responsive.widthPercent(
                                  context,
                                  90,
                                ).clamp(280.0, 400.0),
                                child: Material(
                                  color: _isSignUpPressed
                                      ? _brightBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    Responsive.responsiveRadius(context, 20),
                                  ),
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
                                    borderRadius: BorderRadius.circular(
                                      Responsive.responsiveRadius(context, 20),
                                    ),
                                    child: Container(
                                      padding: Responsive.responsiveSymmetric(
                                        context,
                                        horizontal: isSmallDevice ? 60 : 90,
                                        vertical: isSmallDevice ? 14 : 18,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.responsiveRadius(
                                            context,
                                            20,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: _isSignUpPressed
                                              ? Colors.transparent
                                              : _brightBlue,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        textAlign: TextAlign.center,
                                        style: Responsive.responsiveTextStyle(
                                          context,
                                          fontSize: isSmallDevice ? 14 : 16,
                                          fontWeight:
                                              FontWeight.w500, // Poppins Medium
                                          color: _isSignUpPressed
                                              ? Colors.white
                                              : Colors
                                                    .black, // Figma: black text
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: Responsive.scaledPadding(context, 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
