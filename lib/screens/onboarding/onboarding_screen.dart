import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
late AnimationController _kobiPalSlideAnimationController;

late Animation<Color?> _palColorAnimation;
late Animation<double> _kobiFadeAnimation;
late Animation<Color?> _dotColorAnimation;
late Animation<Color?> _buttonColorAnimation;
late Animation<double> _kobiPalSlideYAnimation;
late Animation<double> _kobiPalSlideXAnimation;

// Bright blue color used for buttons when pressed
static const Color _brightBlue = Color(0xFF155DFC);
// Dark color for "pal" text (final state: #0F172B)
static const Color _darkPalColor = Color(0xFF0F172B);

@override
  void initState() {
    super.initState();

    // 1. Logo fade in (standard)
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeOut),
    );

    // 2. Text fade out
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeInOut),
    );

    // 3. Pal Color Animation
    _palColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _palColorAnimation = ColorTween(begin: const Color(0xFFD4D4D4), end: _darkPalColor).animate(
      CurvedAnimation(
        parent: _palColorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 4. Kobi Fade In
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

    // 5. Dot Color
    _dotColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dotColorAnimation = ColorTween(begin: const Color(0xFFD4D4D4), end: _brightBlue).animate(
      CurvedAnimation(
        parent: _dotColorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 6. Button Color
    _buttonColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonColorAnimation = ColorTween(begin: Colors.white, end: _brightBlue).animate(
      CurvedAnimation(
        parent: _buttonColorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 7. Slide Animation
    _kobiPalSlideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _kobiPalSlideYAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _kobiPalSlideAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _kobiPalSlideXAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _kobiPalSlideAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Listeners for Color Updates
    _palColorAnimation.addListener(() {
      if (mounted) setState(() => _palTextColor = _palColorAnimation.value ?? const Color(0xFFD4D4D4));
    });

    _dotColorAnimation.addListener(() {
      if (mounted) setState(() => _dotColor = _dotColorAnimation.value ?? const Color(0xFFD4D4D4));
    });

    _buttonColorAnimation.addListener(() {
      if (mounted) setState(() => _loginButtonColor = _buttonColorAnimation.value ?? Colors.white);
    });

    // --- INSERT THIS NEW CODE ---

    // Sequence Orchestration: Wait for text to fully fade out
    _textAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showText = true; // Physically remove old text
          _showLogo = true;
          _showKobi = true; 
        });
        
        // Trigger all "Enter" animations together cleanly
        _kobiPalSlideAnimationController.forward();
        _logoAnimationController.forward();
        _kobiFadeAnimationController.forward();
        _dotColorAnimationController.forward();
        _buttonColorAnimationController.forward();
      }
    });

// ----------------------------

    // --- TIMING SEQUENCE ---

    // T=800ms: Start "pal" color change
    Timer(const Duration(milliseconds: 800), () {
      if (mounted && _showText) {
        _palColorAnimationController.forward();
      }
    });

    // T=1100ms: PREPARE KOBI
    // We show it immediately so it rests at the "Initial Position" (bottom)
    // before sliding. This prevents the "starts from bottom" jump.
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

    // T=1700ms: TRANSITION
    // Only trigger the first step of the chain. 
    // The rest is handled by the StatusListener above.
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
  _kobiPalSlideAnimationController.dispose();
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
          return ConstrainedBox(
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
                            // Logo section - centered (shows icon, animated text slides next to it)
                            if (_showLogo)
                              Center(
                                child: FadeTransition(
                                  opacity: _logoFadeAnimation,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center, // CRITICAL: Center alignment
                                    children: [
                                      // Left icon container - FIXED SIZE, always centered
                                      Container(
                                        width: 65, // FIXED ratio
                                        height: 65, // FIXED ratio
                                        transform: Matrix4.translationValues(0, 90, 0), // Use transform to move visually without affecting layout flow
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF155DFC),
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              offset: const Offset(0, 4),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Center( // FIXED: Ensures icon is centered in container
                                          child: SvgPicture.asset(
                                            'assets/images/icon.svg',
                                            width: 45,
                                            height: 45,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Placeholder for text that slides in (text is animated separately)
                                      SizedBox(
                                        width: Responsive.widthPercent(
                                          context,
                                          45,
                                        ).clamp(120.0, 160.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Text content section - center-left aligned
                            Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // "kobi pal" text - visible from start in gray, then animates upward to logo position
                                AnimatedBuilder(
                                  animation: _kobiPalSlideAnimationController,
                                  builder: (context, child) {
                                    // Start from the on-screen position (no offset) to match the initial gray layout
                                    final double startY = isSmallDevice ? 56 : 64 + 100;

                                    // Final position near the logo
                                    final endY = -55.0;

                                    // Interpolate between original position and target
                                    final currentY = startY + (endY - startY) * _kobiPalSlideYAnimation.value;

                                    // Horizontal: start where text is displayed; slide towards logo target
                                    final containerWidth = Responsive.widthPercent(context, 90).clamp(300.0, 400.0);
                                    final paddingLeft = Responsive.scaledPadding(context, 40).clamp(24.0, 60.0);

                                    final startX = -paddingLeft * 1.2;

                                    final screenWidth = MediaQuery.of(context).size.width;
                                    final endX = (screenWidth / 2) - (containerWidth / 2) + paddingLeft + 55 + 12 - 85;
                                    final currentX = startX + (endX - startX) * _kobiPalSlideXAnimation.value;

                                    return Transform.translate(
                                      offset: Offset(currentX, currentY),
                                      child: SizedBox(
                                        width: Responsive.widthPercent(
                                          context,
                                          45,
                                        ).clamp(120.0, 160.0),
                                        child: Stack(
                                          alignment: Alignment.centerLeft,
                                          clipBehavior: Clip.none,
                                          children: [
                                            SizedBox(
width: Responsive.widthPercent(context, 45).clamp(120.0, 160.0),
child: Stack(
  clipBehavior: Clip.none,
  alignment: Alignment.centerLeft,
  children: [
    // BASE TEXT: "pal."
    Transform.translate(
offset: Offset(0, isSmallDevice ? -6 : -10), // ⬆️ moves ONLY pal up
child: Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text(
      'pal',
      style: GoogleFonts.inter(
        fontSize: isSmallDevice ? 42 : 70.5,
        fontWeight: FontWeight.w700,
        color: _palTextColor,
        letterSpacing: -1.273,
        height: 1.0,
      ),
    ),
    Text(
      '.',
      style: GoogleFonts.inter(
        fontSize: isSmallDevice ? 42 : 70.5,
        fontWeight: FontWeight.w700,
        color: _dotColor,
        letterSpacing: -1.273,
        height: 1.0,
      ),
    ),
  ],
),
),


    // OVERLAY TEXT: "kobi"
    Positioned(
      top: isSmallDevice ? -8 : -10, // RESPONSIVE OVERLAY OFFSET
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
            height: 1.0,
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
                                      );
                                    },
                                  ),
                                // "Your Every Day" text - fades out
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
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
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
            );
        },
      ),
    ),
  );
}

}