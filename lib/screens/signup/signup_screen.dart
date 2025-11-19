import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../otp/otp_verification_screen.dart';
import 'interest_selection_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ============================================================================
  // STATE MANAGEMENT & VARIABLES
  // ============================================================================
  
  // Text Controllers for form inputs
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Form state variables
  String? _selectedGender;
  String? _selectedAccountType;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  // Dropdown open state for Account Type field
  bool _isAccountTypeDropdownOpen = false;

  // Error messages
  String? _termsError;
  String? _dobError;
  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _stateError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _genderError;
  String? _accountTypeError;

  // UI state
  int _passwordStrength = 0; // Password strength (0-4 segments)
  bool _isLoading = false;
  
  // Username checking state
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _usernameCheckTimer;

  // ============================================================================
  // BACKEND LOGIC - Service Instances
  // ============================================================================
  final AuthService _authService = AuthService();

  // ============================================================================
  // UI CONSTANTS - Colors from Figma
  // ============================================================================
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey400 = Color(0xFF8A8D9E);
  static const Color _grey700 = Color(0xFF717182);
  static const Color _blue500 = Color(0xFF45556C);
  static const Color _greenSuccess = Color(0xFF00A63E);

  // ============================================================================
  // UI CONSTANTS - Nigeria States List
  // ============================================================================
  static const List<String> _nigeriaStates = [
    'Abia',
    'Abuja (FCT)',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
  ];

  // ============================================================================
  // BACKEND LOGIC - Username Availability Check
  // ============================================================================
  
  /// Checks username availability using Supabase edge function
  /// Uses debouncing to avoid excessive API calls
  Future<void> _checkUsernameAvailability(String username) async {
    // Cancel previous timer
    _usernameCheckTimer?.cancel();
    
    // Reset state
    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = null;
      _usernameError = null;
    });
    
    // Validate format first
    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
      });
      return;
    }
    
    if (_hasSpaces(username)) {
      setState(() {
        _usernameError = 'no spaces allowed';
        _isUsernameAvailable = false;
      });
      return;
    }
    
    if (!_isValidUsername(username)) {
      setState(() {
        _usernameError = 'Use Alphanumeric or underscore only';
        _isUsernameAvailable = false;
      });
      return;
    }
    
    // Debounce: wait 500ms before checking
    _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() {
        _isCheckingUsername = true;
        _usernameError = null;
      });
      
      try {
        final result = await _authService.checkUsernameAvailability(
          username: username,
        );
        
        if (!mounted) return;
        
        final available = result['available'] as bool? ?? false;
        final message = result['message'] as String?;
        
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
          
          if (!available) {
            _usernameError = message ?? 'This username is already taken';
          } else {
            _usernameError = null;
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = null;
          // Don't set error on network failure - let user try again
        });
      }
    });
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================
  
  /// Validates name format (3+ characters, letters and spaces only)
  bool _isValidName(String value) {
    if (value.trim().length < 3) return false;
    final nameRegex = RegExp(r'^[A-Za-z ]+');
    return nameRegex.hasMatch(value.trim());
  }

  /// Checks if value contains special characters (non-letter, non-space)
  bool _hasSpecialCharacters(String value) {
    return RegExp(r'[^A-Za-z ]').hasMatch(value);
  }

  /// Validates username format (3-20 characters, alphanumeric and underscore only)
  bool _isValidUsername(String value) {
    final usernameRegex = RegExp(r'^[A-Za-z0-9_]{3,20}$');
    return usernameRegex.hasMatch(value);
  }

  /// Checks if value contains spaces
  bool _hasSpaces(String value) {
    return RegExp(r'\s').hasMatch(value);
  }

  /// Calculates age from date of birth string (YYYY-MM-DD format)
  int? _calculateAgeFromDob(String dobText) {
    try {
      final parts = dobText.split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final dob = DateTime(year, month, day);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================
  @override
  void initState() {
    super.initState();
    // Ensure dropdown state is always initialized
    _isAccountTypeDropdownOpen = false;
  }

  @override
  void dispose() {
    _usernameCheckTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _stateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // ============================================================================
  // UI COMPONENTS - Widget Builders
  // ============================================================================
  
  /// Builds a reusable input field with icon, error handling, and validation
  Widget _buildInputField({
    required String hintText,
    IconData? icon,
    String? iconAsset,
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
              if (iconAsset != null) ...[
                SvgPicture.asset(iconAsset, width: 20, height: 20),
                const SizedBox(width: 16),
              ] else if (icon != null) ...[
                Icon(icon, color: _grey400, size: 20),
                const SizedBox(width: 16),
              ],
              if (prefixText != null) ...[
                Text(
                  prefixText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _grey400,
                  ),
                ),
                const SizedBox(width: 16),
              ],
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

  /// Calculates password strength based on length and character types (returns 0-4)
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

  /// Builds password strength indicator with color coding (red/orange/green)
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
              // Determine a single color for the current strength level.
              // 1 => red, 2 => orange, 3 or 4 => green
              final int s = _passwordStrength;
              final Color activeColor = s <= 1
                  ? const Color(0xFFDC2626) // red
                  : (s == 2
                        ? const Color(0xFFF59E0B) // orange
                        : const Color(0xFF16A34A)); // green
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 3.5 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? activeColor
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }


  /// Helper widget to build a green tick icon for validation success
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

  // ============================================================================
  // UI COMPONENTS - Main Build Method
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 64),

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
              Center(
                child: SizedBox(
                  width: 342,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // First Name
                    _buildInputField(
                      hintText: 'First Name',
                      iconAsset: 'assets/authPages/profile.svg',
                      controller: _firstNameController,
                      errorText: _firstNameError,
                      onChanged: (value) {
                        setState(() {
                          if (_hasSpecialCharacters(value)) {
                            _firstNameError = 'Use Letters and spaces only';
                          } else if (value.trim().length < 3) {
                            _firstNameError = 'Use 3+ letters/spaces only';
                          } else {
                            _firstNameError = null;
                          }
                        });
                      },
                      suffixIcon:
                          _isValidName(_firstNameController.text) &&
                              !_hasSpecialCharacters(_firstNameController.text)
                          ? _buildGreenTick()
                          : null,
                    ),

                    const SizedBox(height: 10),

                    // Last Name
                    _buildInputField(
                      hintText: 'Last name',
                      iconAsset: 'assets/authPages/profile.svg',
                      controller: _lastNameController,
                      errorText: _lastNameError,
                      onChanged: (value) {
                        setState(() {
                          if (_hasSpecialCharacters(value)) {
                            _lastNameError = 'Use Letters and spaces only';
                          } else if (value.trim().length < 3) {
                            _lastNameError = 'Use 3+ letters/spaces only';
                          } else {
                            _lastNameError = null;
                          }
                        });
                      },
                      suffixIcon:
                          _isValidName(_lastNameController.text) &&
                              !_hasSpecialCharacters(_lastNameController.text)
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
                          if (_hasSpaces(value)) {
                            _usernameError = 'no spaces allowed';
                            _isUsernameAvailable = false;
                          } else if (!_isValidUsername(value)) {
                            _usernameError =
                                'Use Alphanumeric or underscore only';
                            _isUsernameAvailable = false;
                          } else {
                            // Clear error and check availability
                            _usernameError = null;
                            _checkUsernameAvailability(value);
                          }
                        });
                      },
                      suffixIcon: _isCheckingUsername
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _primaryColor,
                                ),
                              ),
                            )
                          : (_isValidUsername(_usernameController.text) &&
                                  !_hasSpaces(_usernameController.text) &&
                                  _isUsernameAvailable == true)
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

                    // State (Text Input)
                    _buildInputField(
                      hintText: 'location',
                      controller: _stateController,
                      errorText: _stateError,
                      onChanged: (value) {
                        setState(() {
                          _stateError = null;
                        });
                      },
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

                    // Date of Birth (opens calendar)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: _dobError != null
                                  ? Colors.red
                                  : _primaryColor,
                              width: 0.758,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(
                                  now.year - 18,
                                  now.month,
                                  now.day,
                                ),
                                firstDate: DateTime(1900, 1, 1),
                                lastDate: now,
                              );
                              if (picked != null) {
                                setState(() {
                                  _dobController.text =
                                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  _dobError = null;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                SvgPicture.asset(
                                  'assets/authPages/calender.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _dobController.text.isEmpty
                                        ? 'Date of Birth'
                                        : _dobController.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _dobController.text.isEmpty
                                          ? _grey700
                                          : _primary900,
                                      fontFamily: 'Inter',
                                      letterSpacing: -0.3125,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                        ),
                        if (_dobError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              _dobError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
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
                            borderRadius: BorderRadius.vertical(
                              top: const Radius.circular(10),
                              bottom: Radius.circular(
                                (_isAccountTypeDropdownOpen == true) ? 0 : 10,
                              ),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isAccountTypeDropdownOpen =
                                      !_isAccountTypeDropdownOpen;
                                  _accountTypeError = null;
                                });
                              },
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(10),
                                bottom: Radius.circular(
                                  (_isAccountTypeDropdownOpen == true)
                                      ? 0
                                      : 10,
                                ),
                              ),
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
                                      (_isAccountTypeDropdownOpen == true)
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: _grey400,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_isAccountTypeDropdownOpen == true)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              border: Border(
                                top: BorderSide.none,
                                left: BorderSide(
                                  color: _accountTypeError != null
                                      ? Colors.red
                                      : _primaryColor,
                                  width: 1.513,
                                ),
                                right: BorderSide(
                                  color: _accountTypeError != null
                                      ? Colors.red
                                      : _primaryColor,
                                  width: 1.513,
                                ),
                                bottom: BorderSide(
                                  color: _accountTypeError != null
                                      ? Colors.red
                                      : _primaryColor,
                                  width: 1.513,
                                ),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              itemCount: 2,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final option = index == 0
                                    ? 'Personal User'
                                    : 'Business Owner';
                                final isSelected =
                                    _selectedAccountType == option;
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        _selectedAccountType = option;
                                        _accountTypeError = null;
                                        _isAccountTypeDropdownOpen = false;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF8FAFC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: _primary900,
                                                fontFamily: 'Inter',
                                              ),
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
                        if (_accountTypeError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              _accountTypeError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              ),

              const SizedBox(height: 50),

              // Sign up button - aligned with input forms
              Center(
                child: Container(
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
              ),

              const SizedBox(height: 22),

              // Terms and conditions checkbox - aligned with input forms
              Center(
                child: SizedBox(
                  width: 342,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                border: Border.all(
                                  color: _primaryColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                color: _agreeToTerms
                                    ? _primaryColor
                                    : Colors.white,
                              ),
                              child: _agreeToTerms
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.normal, // Rubik Regular
                                  color: _primary900,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Rubik',
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "By signing up I agree to the ",
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
                      if (_termsError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 36, top: 8),
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
                    ],
                  ),
                ),
              ),

              // Divider
              SizedBox(
                width: 338,
                height: 22,
                child: Row(
                  children: [
                    // Left line (short, on the left)
                    Container(
                      width: 80,
                      height: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    // Empty space in the center
                    const Spacer(),
                    // Right line (short, on the right)
                    Container(
                      width: 80,
                      height: 1,
                      color: Colors.grey.withOpacity(0.2),
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

  /// Builds a gender selection option widget (radio button style)
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

  // ============================================================================
  // VALIDATION LOGIC
  // ============================================================================
  
  /// Validates all form fields and sets error messages
  /// Returns true if all validations pass, false otherwise
  bool _validateSignUp() {
    bool isValid = true;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final state = _stateController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final dobText = _dobController.text.trim();

    // Validate First Name
    if (firstName.isEmpty) {
      setState(() {
        _firstNameError = 'First name is required';
      });
      isValid = false;
    } else if (!_isValidName(firstName)) {
      setState(() {
        _firstNameError = _hasSpecialCharacters(firstName)
            ? 'Letters and spaces only'
            : 'Use 3+ letters or spaces only';
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
    } else if (!_isValidName(lastName)) {
      setState(() {
        _lastNameError = _hasSpecialCharacters(lastName)
            ? 'Letters and spaces only'
            : 'Use 3+ letters/spaces only';
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
    } else if (_hasSpaces(username)) {
      setState(() {
        _usernameError = 'no spaces allowed';
      });
      isValid = false;
    } else if (!_isValidUsername(username)) {
      setState(() {
        _usernameError = 'Use Alphanumeric or underscore only';
      });
      isValid = false;
    } else if (_isCheckingUsername) {
      setState(() {
        _usernameError = 'Please wait while we check username availability';
      });
      isValid = false;
    } else if (_isUsernameAvailable == false) {
      setState(() {
        _usernameError = _usernameError ?? 'This username is already taken';
      });
      isValid = false;
    } else if (_isUsernameAvailable == null) {
      // Username format is valid but availability hasn't been checked yet
      // Trigger check and wait
      setState(() {
        _usernameError = 'Please wait while we check username availability';
      });
      _checkUsernameAvailability(username);
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

    // Validate Date of Birth (13+ years)
    if (dobText.isEmpty) {
      setState(() {
        _dobError = 'Birthday is required';
      });
      isValid = false;
    } else {
      final age = _calculateAgeFromDob(dobText);
      if (age == null) {
        setState(() {
          _dobError = 'Enter a valid date (YYYY-MM-DD)';
        });
        isValid = false;
      } else if (age < 13) {
        setState(() {
          _dobError = 'You must be 13 years or older';
        });
        isValid = false;
      } else {
        setState(() {
          _dobError = null;
        });
      }
    }

    // Validate Password
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

  /// Validates email format using regex pattern
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // ============================================================================
  // BACKEND LOGIC - API Calls & Data Handling
  // ============================================================================
  
  /// Handles the sign-up process:
  /// 1. Prepares user data
  /// 2. Calls AuthService to create account
  /// 3. Sends OTP for email verification
  /// 4. Navigates to InterestSelectionScreen on success
  /// 5. Handles errors and displays appropriate messages
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
      // Prepare user data for backend
      final dobText = _dobController.text.trim();
      final birthdayString = dobText; // Use DOB from controller (YYYY-MM-DD format)

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

      // ========== BACKEND API CALL: Create User Account ==========
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

      // ========== BACKEND API CALL: Send OTP for Email Verification ==========
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

      // Navigate to interest selection screen on successful signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InterestSelectionScreen(email: email),
        ),
      );
    } on AuthException catch (e) {
      // ========== BACKEND ERROR HANDLING ==========
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
