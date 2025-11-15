import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../forgot_password/forgot_password_email_screen.dart';
import '../otp/otp_verification_screen.dart';
import 'interest_selection_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedGender;
  String? _selectedAccountType;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  String? _termsError;

  // Password strength (0-4 segments)
  int _passwordStrength = 0;

  // Validation errors
  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _stateError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _genderError;
  String? _accountTypeError;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey400 = Color(0xFF8A8D9E);
  static const Color _grey700 = Color(0xFF717182);
  static const Color _blue500 = Color(0xFF45556C);
  static const Color _greenSuccess = Color(0xFF00A63E);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _stateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    bool obscureText = false,
    Widget? suffixIcon,
    String? prefixText,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: errorText != null ? Colors.red : _primaryColor,
              width: 0.758,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              // Icon
              Icon(icon, color: _grey400, size: 20),
              if (prefixText != null) ...[
                const SizedBox(width: 16),
                Text(
                  prefixText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _grey400,
                  ),
                ),
              ],
              const SizedBox(width: 16),
              // Input field
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: 16,
                    color: _primary900,
                    fontFamily: 'Inter',
                    letterSpacing: -0.3125,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: _grey700,
                      fontFamily: 'Inter',
                      letterSpacing: -0.3125,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                const SizedBox(width: 12),
                suffixIcon,
                const SizedBox(width: 12),
              ] else
                const SizedBox(width: 12),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Calculate password strength (0-4)
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;

    return strength > 4 ? 4 : strength;
  }

  // Build password strength indicator
  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        SizedBox(
          width: 342,
          height: 4,
          child: Row(
            children: List.generate(4, (index) {
              final isFilled = index < _passwordStrength;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 3.5 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? _primaryColor
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        if (_passwordStrength >= 3)
          Text(
            'Strong password',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: _greenSuccess,
              fontFamily: 'Inter',
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PasswordHint(text: '• Use at least 6 characters'),
        SizedBox(height: 4),
        _PasswordHint(text: '• Add at least one special character'),
        SizedBox(height: 4),
        _PasswordHint(text: '• Mix upper and lower case letters'),
      ],
    );
  }

  // Helper to build a green tick icon
  Widget _buildGreenTick() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _greenSuccess, width: 1),
      ),
      child: Icon(Icons.check, color: _greenSuccess, size: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 64),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: _primary900, size: 20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title - "Create Account"
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500, // Rubik Medium
                  color: _primary900,
                  letterSpacing: 0,
                  fontFamily: 'Rubik',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 52),

              // Form fields container - width 342px, centered
              SizedBox(
                width: 342,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name
                    _buildInputField(
                      hintText: 'First Name',
                      icon: Icons.person_outline,
                      controller: _firstNameController,
                      errorText: _firstNameError,
                      onChanged: (value) {
                        setState(() {
                          _firstNameError = null;
                        });
                      },
                      suffixIcon:
                          _firstNameController.text.isNotEmpty &&
                              _firstNameError == null
                          ? _buildGreenTick()
                          : null,
                    ),

                    const SizedBox(height: 10),

                    // Last Name
                    _buildInputField(
                      hintText: 'Last name',
                      icon: Icons.person_outline,
                      controller: _lastNameController,
                      errorText: _lastNameError,
                      onChanged: (value) {
                        setState(() {
                          _lastNameError = null;
                        });
                      },
                      suffixIcon:
                          _lastNameController.text.isNotEmpty &&
                              _lastNameError == null
                          ? _buildGreenTick()
                          : null,
                    ),

                    const SizedBox(height: 10),

                    // Username
                    _buildInputField(
                      hintText: 'Username',
                      icon: Icons.alternate_email,
                      controller: _usernameController,
                      errorText: _usernameError,
                      onChanged: (value) {
                        setState(() {
                          _usernameError = null;
                        });
                      },
                      suffixIcon:
                          _usernameController.text.isNotEmpty &&
                              _usernameError == null &&
                              _usernameController.text.length >= 3
                          ? _buildGreenTick()
                          : null,
                    ),

                    const SizedBox(height: 10),

                    // Email
                    _buildInputField(
                      hintText: 'Email',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      errorText: _emailError,
                      onChanged: (value) {
                        setState(() {
                          _emailError = null;
                        });
                      },
                      suffixIcon:
                          _emailController.text.isNotEmpty &&
                              _emailError == null &&
                              _isValidEmail(_emailController.text)
                          ? _buildGreenTick()
                          : null,
                    ),

                    const SizedBox(height: 10),

                    // State
                    _buildInputField(
                      hintText: 'State',
                      icon: Icons.location_on_outlined,
                      controller: _stateController,
                      errorText: _stateError,
                      onChanged: (value) {
                        setState(() {
                          _stateError = null;
                        });
                      },
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_stateController.text.isNotEmpty &&
                              _stateError == null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildGreenTick(),
                            ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: _grey400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Gender selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.748),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: _genderError != null
                                  ? Colors.red
                                  : _primaryColor,
                              width: 0.758,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _blue500,
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.1504,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildGenderOption('Male'),
                                  const SizedBox(width: 16),
                                  _buildGenderOption('Female'),
                                  const SizedBox(width: 16),
                                  _buildGenderOption('Other'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_genderError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              _genderError!,
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          errorText: _passwordError,
                          onChanged: (value) {
                            setState(() {
                              _passwordError = null;
                              _passwordStrength = _calculatePasswordStrength(
                                value,
                              );
                            });
                          },
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_passwordController.text.isNotEmpty &&
                                  _passwordError == null &&
                                  _passwordStrength >= 3)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildGreenTick(),
                                ),
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _grey400,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        _buildPasswordStrengthIndicator(),
                        const SizedBox(height: 8),
                        _buildPasswordRecommendations(),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Confirm Password
                    _buildInputField(
                      hintText: 'Confirm Password',
                      icon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      errorText: _confirmPasswordError,
                      onChanged: (value) {
                        setState(() {
                          _confirmPasswordError = null;
                        });
                      },
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_confirmPasswordController.text.isNotEmpty &&
                              _confirmPasswordError == null &&
                              _passwordController.text ==
                                  _confirmPasswordController.text)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildGreenTick(),
                            ),
                          IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _grey400,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Account type dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: _accountTypeError != null
                                  ? Colors.red
                                  : _primaryColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: Show dropdown
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Select Account Type'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: Text('Individual user'),
                                          onTap: () {
                                            setState(() {
                                              _selectedAccountType =
                                                  'Individual user';
                                              _accountTypeError = null;
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                        ListTile(
                                          title: Text('Business Owner'),
                                          onTap: () {
                                            setState(() {
                                              _selectedAccountType =
                                                  'Business Owner';
                                              _accountTypeError = null;
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedAccountType ??
                                            'What will you most likely be using this account for',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: _selectedAccountType != null
                                              ? _primary900
                                              : _grey700,
                                          fontFamily: 'Roboto',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: _grey400,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_accountTypeError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              _accountTypeError!,
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Terms and conditions checkbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 33),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        width: 24.476,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: _primaryColor, width: 1),
                          borderRadius: BorderRadius.circular(6),
                          color: _agreeToTerms ? _primaryColor : Colors.white,
                        ),
                        child: _agreeToTerms
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal, // Rubik Regular
                            color: _primary900,
                            letterSpacing: 0.2,
                            fontFamily: 'Rubik',
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  "By signing up I agree that I'm 13 years of age\nor older, to the ",
                            ),
                            TextSpan(
                              text: 'Terms of Use',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_termsError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 45, right: 33, top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _termsError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Sign up button
              Container(
                width: 338,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      _isLoading ? _primaryColor.withOpacity(0.7) : _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () async {
                            if (_validateSignUp()) {
                              await _handleSignUp();
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
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500, // Poppins Medium
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordEmailScreen(),
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
                    fontWeight: FontWeight.normal,
                    color: _grey400,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Divider
              SizedBox(
                width: 338,
                height: 22,
                child: Row(
                  children: [
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

              const SizedBox(height: 30),

              // Footer text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal, // Rubik Regular
                    color: _grey400,
                    fontFamily: 'Rubik',
                  ),
                  children: [
                    const TextSpan(text: "Already have account? "),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 16,
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
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
          _genderError = null;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15.991,
            height: 15.991,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 0.758),
              color: isSelected ? _primaryColor : Colors.transparent,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            gender,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _primary900,
              fontFamily: 'Inter',
              letterSpacing: -0.1504,
            ),
          ),
        ],
      ),
    );
  }

  bool _validateSignUp() {
    bool isValid = true;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final state = _stateController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate First Name
    if (firstName.isEmpty) {
      setState(() {
        _firstNameError = 'First name is required';
      });
      isValid = false;
    } else {
      setState(() {
        _firstNameError = null;
      });
    }

    // Validate Last Name
    if (lastName.isEmpty) {
      setState(() {
        _lastNameError = 'Last name is required';
      });
      isValid = false;
    } else {
      setState(() {
        _lastNameError = null;
      });
    }

    // Validate Username
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username is required';
      });
      isValid = false;
    } else if (username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
      });
      isValid = false;
    } else {
      setState(() {
        _usernameError = null;
      });
    }

    // Validate Email
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

    // Validate State
    if (state.isEmpty) {
      setState(() {
        _stateError = 'State is required';
      });
      isValid = false;
    } else {
      setState(() {
        _stateError = null;
      });
    }

    // Validate Gender
    if (_selectedGender == null) {
      setState(() {
        _genderError = 'Please select a gender';
      });
      isValid = false;
    } else {
      setState(() {
        _genderError = null;
      });
    }

    // Validate Password
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

    // Validate Confirm Password
    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Please confirm your password';
      });
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      isValid = false;
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }

    // Validate Account Type
    if (_selectedAccountType == null) {
      setState(() {
        _accountTypeError = 'Please select an account type';
      });
      isValid = false;
    } else {
      setState(() {
        _accountTypeError = null;
      });
    }

    // Validate Terms Agreement
    if (!_agreeToTerms) {
      setState(() {
        _termsError = 'Please agree to the Terms of Use and Privacy Policy';
      });
      isValid = false;
    } else {
      setState(() {
        _termsError = null;
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

  Future<void> _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final gender = _selectedGender?.toLowerCase();

    setState(() {
      _isLoading = true;
      _firstNameError = null;
      _lastNameError = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _genderError = null;
    });

    try {
      final birthday =
          DateTime.now().subtract(const Duration(days: 365 * 14));
      final birthdayString = birthday.toIso8601String().substring(0, 10);

      String? genderValue;
      if (gender == 'male') {
        genderValue = 'male';
      } else if (gender == 'female') {
        genderValue = 'female';
      } else if (gender == 'other') {
        genderValue = 'other';
      } else {
        genderValue = 'prefer_not_to_say';
      }

      final userData = {
        'username': username,
        'gender': genderValue,
        'birthday': birthdayString,
        'terms_accepted': _agreeToTerms,
        'privacy_accepted': _agreeToTerms,
        'role': 'user',
        'account_status': 'active',
      };

      final response = await _authService.signUp(
        email: email,
        password: password,
        userData: userData,
      );

      if (!mounted) return;

      if (response.user == null) {
        setState(() {
          _isLoading = false;
          _emailError = 'Failed to create account. Please try again.';
        });
        return;
      }

      try {
        await _authService.sendOtp(
          email: email,
          userId: response.user!.id,
        );
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InterestSelectionScreen(email: email),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('email') ||
          errorMessage.contains('already registered')) {
        setState(() {
          _emailError = 'This email is already registered';
        });
      } else if (errorMessage.contains('username') ||
          errorMessage.contains('duplicate')) {
        setState(() {
          _usernameError = 'This username is already taken';
        });
      } else if (errorMessage.contains('password')) {
        setState(() {
          _passwordError = e.message;
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

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF717182),
        height: 1.4,
        fontFamily: 'Inter',
      ),
    );
  }
}