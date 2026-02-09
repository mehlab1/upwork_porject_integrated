import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../settings/community_guidelines_screen.dart';
import 'interest_selection_screen.dart';
import '../../core/responsive/responsive.dart';
import '../../widgets/error_dialog.dart';

/// Custom painter for checkmark with border (for success messages)
class _CheckmarkPainter extends CustomPainter {
  static const Color _checkmarkColor = Color(0xFF00A63E);
  static const double _borderWidth = 1.17;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _checkmarkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw checkmark path
    final path = Path();
    // Start from bottom-left, curve up and right
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.35, size.height);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  
  // Password validation state
  bool _hasMinLength = false;
  bool _hasCapital = false;
  bool _hasSpecialChar = false;

  // Username checking state
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _usernameCheckTimer;

  // Location search state
  bool _isSearchingLocation = false;
  List<Map<String, String>> _locationResults = [];
  bool _isLocationDropdownOpen = false;
  Timer? _locationSearchTimer;
  final FocusNode _locationFocusNode = FocusNode();

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
  static const Color _checkboxColor = Color(0xFF7265E3);

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
  // BACKEND LOGIC - Location Search API
  // ============================================================================

  /// Searches for locations using Geoapify API
  /// Displays only country and state in results
  Future<void> _searchLocations(String query) async {
    // Cancel previous timer
    _locationSearchTimer?.cancel();

    // Reset state
    setState(() {
      _isSearchingLocation = false;
      _locationResults = [];
      _isLocationDropdownOpen = false;
    });

    // Don't search if query is too short
    if (query.trim().isEmpty || query.trim().length < 2) {
      return;
    }

    // Debounce: wait 500ms before searching
    _locationSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      setState(() {
        _isSearchingLocation = true;
      });

      try {
        const apiKey = 'cfd3c858feac49d98dd804389ae1b5ba';
        final encodedQuery = Uri.encodeComponent(query.trim());
        final url =
            'https://api.geoapify.com/v1/geocode/search?text=$encodedQuery&apiKey=$apiKey&limit=10';

        final response = await http.get(Uri.parse(url));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>? ?? [];

          final List<Map<String, String>> results = [];

          for (var feature in features) {
            final properties = feature['properties'] as Map<String, dynamic>?;
            if (properties != null) {
              final country = properties['country'] as String?;
              final state = properties['state'] as String?;

              // Only add results that have both country and state
              if (country != null && state != null) {
                // Check if this combination already exists
                final locationKey = '$state, $country';
                if (!results.any((r) => r['display'] == locationKey)) {
                  results.add({
                    'country': country,
                    'state': state,
                    'display': locationKey,
                  });
                }
              }
            }
          }

          if (!mounted) return;

          setState(() {
            _isSearchingLocation = false;
            _locationResults = results;
            _isLocationDropdownOpen =
                results.isNotEmpty &&
                _stateController.text.trim().isNotEmpty &&
                _locationFocusNode.hasFocus;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _isSearchingLocation = false;
            _locationResults = [];
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSearchingLocation = false;
          _locationResults = [];
        });
      }
    });
  }

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
        _usernameError = 'Only letters, numbers, and underscores are allowed.';
        _isUsernameAvailable = false;
      });
      return;
    }

    // Validate username format with specific error messages
    final validationError = _validateUsername(username);
    if (validationError != null) {
      setState(() {
        _usernameError = validationError;
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
            _usernameError = message ?? 'That username is already taken.';
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

  /// Validates name format and returns specific error message if invalid
  /// Returns null if name is valid
  /// Rules: Min 3 / Max 20 characters; allowed: letters, spaces, hyphens
  String? _validateName(String value) {
    final trimmed = value.trim();
    
    // Check if empty (handled separately in form validation)
    if (trimmed.isEmpty) return null;
    
    // Check length - too short
    if (trimmed.length < 3) {
      return 'Minimum 3 characters. Letters, spaces, or hyphens only.';
    }
    
    // Check length - too long
    if (trimmed.length > 20) {
      return 'Maximum 20 characters allowed. Letters, spaces, or hyphens only.';
    }
    
    // Only letters, spaces, and hyphens allowed
    if (!RegExp(r'^[A-Za-z -]+$').hasMatch(trimmed)) {
      return 'Minimum 3 characters. Letters, spaces, or hyphens only.';
    }
    
    return null; // Valid name
  }

  /// Validates name format (3-20 characters, letters, spaces, hyphens only)
  bool _isValidName(String value) {
    return _validateName(value) == null;
  }

  /// Checks if value contains invalid characters (non-letter, non-space, non-hyphen)
  bool _hasSpecialCharacters(String value) {
    return RegExp(r'[^A-Za-z -]').hasMatch(value);
  }

   /// Validates username format and returns specific error message if invalid
   /// Returns null if username is valid
   String? _validateUsername(String value) {
    // Check if empty (handled separately in form validation)
    if (value.isEmpty) return null;
    
    // Check length - too short
    if (value.length < 4) {
      return 'Username must be at least 4 characters.';
    }
    
    // Check length - too long
    if (value.length > 15) {
      return 'Username can\'t be longer than 15 characters.';
    }
    
    // Must start with a letter
    if (!RegExp(r'^[A-Za-z]').hasMatch(value)) {
      return 'Username must start with a letter.';
    }
    
    // Can't end with underscore
    if (value.endsWith('_')) {
      return 'Username can\'t end with an underscore.';
    }
    
    // No consecutive underscores
    if (value.contains('__')) {
      return 'No consecutive underscores.';
    }
    
    // Only letters, numbers, and underscores allowed
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores are allowed.';
    }
    
    return null; // Valid username
  }

  /// Helper method for backward compatibility - checks if username is valid
  bool _isValidUsername(String value) {
    return _validateUsername(value) == null;
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
    _isLocationDropdownOpen = false;

    // Handle location focus changes
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus) {
        // Close dropdown when focus is lost
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isLocationDropdownOpen = false;
            });
          }
        });
      } else if (_locationResults.isNotEmpty &&
          _stateController.text.trim().isNotEmpty) {
        // Open dropdown when focused and there are results
        setState(() {
          _isLocationDropdownOpen = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameCheckTimer?.cancel();
    _locationSearchTimer?.cancel();
    _locationFocusNode.dispose();
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
    Color? iconAssetColor,
    TextEditingController? controller,
    bool obscureText = false,
    Widget? suffixIcon,
    String? prefixText,
    String? errorText,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: Responsive.scaledPadding(context, 60).clamp(55.0, 65.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: errorText != null ? Colors.red : _primaryColor,
              width: 0.758,
            ),
            borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 14)),
          ),
          child: Row(
            children: [
              SizedBox(width: Responsive.scaledPadding(context, 20)),
              // Icon
              if (iconAsset != null) ...[
                SvgPicture.asset(
                  iconAsset,
                  width: Responsive.scaledIcon(context, 20),
                  height: Responsive.scaledIcon(context, 20),
                  colorFilter: iconAssetColor != null
                      ? ColorFilter.mode(iconAssetColor, BlendMode.srcIn)
                      : null,
                ),
                SizedBox(width: Responsive.scaledPadding(context, 16)),
              ] else if (icon != null) ...[
                Icon(icon, color: _grey400, size: Responsive.scaledIcon(context, 20)),
                SizedBox(width: Responsive.scaledPadding(context, 16)),
              ],
              if (prefixText != null) ...[
                Text(
                  prefixText,
                  style: TextStyle(
                    fontSize: Responsive.scaledFont(context, 16),
                    fontWeight: FontWeight.w500,
                    color: _grey400,
                  ),
                ),
                SizedBox(width: Responsive.scaledPadding(context, 16)),
              ],
              // Input field
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  onChanged: onChanged,
                  inputFormatters: inputFormatters,
                  style: TextStyle(
                    fontSize: Responsive.scaledFont(context, 16),
                    color: _primary900,
                    fontFamily: 'Inter',
                    letterSpacing: -0.3125,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: Responsive.scaledFont(context, 16),
                      color: _grey700,
                      fontFamily: 'Inter',
                      letterSpacing: -0.3125,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: Responsive.scaledPadding(context, 4)),
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                SizedBox(width: Responsive.scaledPadding(context, 12)),
                suffixIcon,
                SizedBox(width: Responsive.scaledPadding(context, 12)),
              ] else
                SizedBox(width: Responsive.scaledPadding(context, 12)),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.scaledPadding(context, 20),
              top: Responsive.scaledPadding(context, 4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: Responsive.scaledIcon(context, 14), color: Colors.red),
                SizedBox(width: Responsive.scaledPadding(context, 4)),
                Expanded(
                  child: Text(
                    errorText,
                    style: TextStyle(
                      fontSize: Responsive.scaledFont(context, 12),
                      color: Colors.red,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Calculates password strength based on required validation rules (returns 0-4)
  /// Only reaches maximum (4) when ALL required rules are met:
  /// - Length >= 8
  /// - Contains uppercase [A-Z]
  /// - Contains special character
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    // Count how many required validation rules are met
    int rulesMet = 0;
    if (password.length >= 8) rulesMet++;
    if (password.contains(RegExp(r'[A-Z]'))) rulesMet++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) rulesMet++;

    // Strength is based on progress: 0 rules = 0, 1 rule = 1, 2 rules = 2-3, 3 rules = 4
    if (rulesMet == 0) return 0;
    if (rulesMet == 1) return 1;
    if (rulesMet == 2) return 3; // Show 3 bars when 2 rules met
    // Only return 4 when all 3 required rules are met
    if (rulesMet == 3) return 4;
    
    return 0;
  }

  /// Validates password requirements and updates state
  void _validatePasswordRequirements(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasCapital = password.contains(RegExp(r'[A-Z]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  /// Checks if password meets all validation requirements
  bool _isPasswordFullyValid(String password) {
    if (password.isEmpty) return false;
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  }

  /// Gets the current password hint (one at a time, in priority order)
  String? _getPasswordHint() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Use 8+ characters, at least one capital, special character';
    }
    
    // Show hints one at a time in priority order
    if (!_hasMinLength) {
      return 'Password must be at least 8 characters';
    }
    if (!_hasCapital) {
      return 'Password must contain at least one capital letter';
    }
    if (!_hasSpecialChar) {
      return 'Password must contain at least one special character';
    }
    
    // All requirements met
    return null;
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

  /// Helper widget to build a custom checkmark for success messages (no circle)
  Widget _buildSuccessCheckmark() {
    return CustomPaint(
      size: const Size(9.327059745788574, 6.412353992462158),
      painter: _CheckmarkPainter(),
    );
  }

  /// Builds password hint widget showing one requirement at a time
  Widget _buildPasswordHint(BuildContext context) {
    final hint = _getPasswordHint();
    if (hint == null) {
      // All requirements met - hide the hint
      return const SizedBox.shrink();
    }

    // Show current requirement hint
    final isError = _passwordController.text.isNotEmpty && 
                    (_passwordError != null || 
                     (!_hasMinLength && _passwordController.text.length > 0));
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.info_outline,
          size: Responsive.scaledIcon(context, 14),
          color: isError ? Colors.red : _blue500,
        ),
        SizedBox(width: Responsive.scaledPadding(context, 4)),
        Flexible(
          child: Text(
            hint,
            style: TextStyle(
              fontSize: Responsive.scaledFont(context, 12),
              color: isError ? Colors.red : _blue500,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  /// Builds a location search field with autocomplete dropdown
  Widget _buildLocationSearchField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: Responsive.scaledPadding(context, 60).clamp(55.0, 65.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _stateError != null ? Colors.red : _primaryColor,
              width: 0.758,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Responsive.responsiveRadius(context, 14)),
              topRight: Radius.circular(Responsive.responsiveRadius(context, 14)),
              bottomLeft: Radius.circular(
                (_isLocationDropdownOpen && _locationResults.isNotEmpty)
                    ? 0
                    : Responsive.responsiveRadius(context, 14),
              ),
              bottomRight: Radius.circular(
                (_isLocationDropdownOpen && _locationResults.isNotEmpty)
                    ? 0
                    : Responsive.responsiveRadius(context, 14),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: Responsive.scaledPadding(context, 20)),
              SvgPicture.asset(
                'assets/authPages/location.svg',
                width: Responsive.scaledIcon(context, 20),
                height: Responsive.scaledIcon(context, 20),
                colorFilter: ColorFilter.mode(
                  const Color.fromRGBO(144, 161, 185, 1.0),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: Responsive.scaledPadding(context, 16)),
              Expanded(
                child: TextField(
                  controller: _stateController,
                  focusNode: _locationFocusNode,
                  style: TextStyle(
                    fontSize: Responsive.scaledFont(context, 16),
                    color: _primary900,
                    fontFamily: 'Inter',
                    letterSpacing: -0.3125,
                  ),
                  decoration: InputDecoration(
                    hintText: 'State, Country',
                    hintStyle: TextStyle(
                      fontSize: Responsive.scaledFont(context, 16),
                      color: _grey700,
                      fontFamily: 'Inter',
                      letterSpacing: -0.3125,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: Responsive.scaledPadding(context, 4)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _stateError = null;
                      _isLocationDropdownOpen = false;
                      _locationResults = [];
                    });
                    if (value.trim().isNotEmpty) {
                      _searchLocations(value);
                    } else {
                      setState(() {
                        _locationResults = [];
                        _isLocationDropdownOpen = false;
                      });
                    }
                  },
                  onTap: () {
                    if (_locationResults.isNotEmpty &&
                        _stateController.text.trim().isNotEmpty) {
                      setState(() {
                        _isLocationDropdownOpen = true;
                      });
                    }
                  },
                ),
              ),
              if (_isSearchingLocation)
                Padding(
                  padding: EdgeInsets.only(right: Responsive.scaledPadding(context, 12)),
                  child: SizedBox(
                    width: Responsive.scaledIcon(context, 20),
                    height: Responsive.scaledIcon(context, 20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                )
              else if (_stateController.text.isNotEmpty && _stateError == null)
                Padding(
                  padding: EdgeInsets.only(right: Responsive.scaledPadding(context, 12)),
                  child: _buildGreenTick(),
                )
              else
                SizedBox(width: Responsive.scaledPadding(context, 12)),
            ],
          ),
        ),
        if (_isLocationDropdownOpen && _locationResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(
                  color: _stateError != null ? Colors.red : _primaryColor,
                  width: 0.758,
                ),
                right: BorderSide(
                  color: _stateError != null ? Colors.red : _primaryColor,
                  width: 0.758,
                ),
                bottom: BorderSide(
                  color: _stateError != null ? Colors.red : _primaryColor,
                  width: 0.758,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _locationResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = _locationResults[index];
                final displayText = location['display'] ?? '';
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _stateController.text = displayText;
                        _stateError = null;
                        _isLocationDropdownOpen = false;
                        _locationResults = [];
                      });
                      _locationFocusNode.unfocus();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.scaledPadding(context, 20),
                        vertical: Responsive.scaledPadding(context, 12),
                      ),
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: Responsive.scaledFont(context, 16),
                          color: _primary900,
                          fontFamily: 'Inter',
                          letterSpacing: -0.3125,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_stateError != null)
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.scaledPadding(context, 20),
              top: Responsive.scaledPadding(context, 4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: Responsive.scaledIcon(context, 14), color: Colors.red),
                SizedBox(width: Responsive.scaledPadding(context, 4)),
                Expanded(
                  child: Text(
                    _stateError!,
                    style: TextStyle(
                      fontSize: Responsive.scaledFont(context, 12),
                      color: Colors.red,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
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
              SizedBox(height: Responsive.scaledPadding(context, 64)),

              // Title - "Create Account"
              Text(
                'Complete Profile ',
                style: TextStyle(
                  fontSize: Responsive.scaledFont(context, 32),
                  fontWeight: FontWeight.bold,
                  color: _primary900,
                  letterSpacing: 0,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Responsive.scaledPadding(context, 52)),

              // Form fields container - responsive width, centered
              Center(
                child: SizedBox(
                  width: Responsive.widthPercent(context, 90).clamp(300.0, 342.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Name
                      _buildInputField(
                        context: context,
                        hintText: 'First Name',
                        iconAsset: 'assets/authPages/profile.svg',
                        controller: _firstNameController,
                        errorText: _firstNameError,
                        onChanged: (value) {
                          setState(() {
                            final validationError = _validateName(value);
                            if (validationError != null) {
                              _firstNameError = validationError;
                            } else {
                              _firstNameError = null;
                            }
                          });
                        },
                        suffixIcon:
                            _firstNameController.text.isNotEmpty &&
                            _isValidName(_firstNameController.text)
                            ? _buildGreenTick()
                            : null,
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Last Name
                      _buildInputField(
                        context: context,
                        hintText: 'Last Name',
                        iconAsset: 'assets/authPages/profile.svg',
                        controller: _lastNameController,
                        errorText: _lastNameError,
                        onChanged: (value) {
                          setState(() {
                            final validationError = _validateName(value);
                            if (validationError != null) {
                              _lastNameError = validationError;
                            } else {
                              _lastNameError = null;
                            }
                          });
                        },
                        suffixIcon:
                            _lastNameController.text.isNotEmpty &&
                            _isValidName(_lastNameController.text)
                            ? _buildGreenTick()
                            : null,
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Username
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            context: context,
                            hintText: 'Username',
                            icon: Icons.alternate_email,
                            controller: _usernameController,
                            inputFormatters: [
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                return newValue.copyWith(
                                  text: newValue.text.toLowerCase(),
                                );
                              }),
                            ],
                            errorText: _usernameError,
                            onChanged: (value) {
                              setState(() {
                                if (_hasSpaces(value)) {
                                  _usernameError = 'Only letters, numbers, and underscores are allowed.';
                                  _isUsernameAvailable = false;
                                } else {
                                  // Validate username format with specific error messages
                                  final validationError = _validateUsername(value);
                                  if (validationError != null) {
                                    _usernameError = validationError;
                                    _isUsernameAvailable = false;
                                  } else {
                                    // Clear error and check availability
                                    _usernameError = null;
                                    _checkUsernameAvailability(value);
                                  }
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
                          // Success message when username is available
                          if (_isValidUsername(_usernameController.text) &&
                              !_hasSpaces(_usernameController.text) &&
                              _isUsernameAvailable == true &&
                              _usernameError == null)
                            Padding(
                              padding: EdgeInsets.only(
                                left: Responsive.scaledPadding(context, 9),
                                top: Responsive.scaledPadding(context, 4),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildSuccessCheckmark(),
                                  SizedBox(width: Responsive.scaledPadding(context, 8)),
                                  Expanded(
                                    child: Text(
                                      'Username is available',
                                      style: TextStyle(
                                        fontSize: Responsive.scaledFont(context, 12),
                                        color: _greenSuccess,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Email
                      _buildInputField(
                        context: context,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        errorText: _emailError,
                        onChanged: (value) {
                          setState(() {
                            // Real-time validation
                            final trimmedValue = value.trim();
                            if (trimmedValue.isEmpty) {
                              _emailError = null;
                            } else if (!trimmedValue.contains('@')) {
                              _emailError = 'Email must contain @';
                            } else {
                              // Check for incomplete domain/TLD before full validation
                              final parts = trimmedValue.split('@');
                              if (parts.length == 2 && parts[1].contains('.')) {
                                final tld = parts[1].split('.').last;
                                // Check if TLD is incomplete (less than 2 chars)
                                if (tld.isNotEmpty && tld.length < 2) {
                                  _emailError = 'Invalid email format. Domain extension is incomplete (e.g., .com)';
                                } else if (!_isValidEmail(trimmedValue)) {
                                  _emailError = 'Invalid email format. Use format: example@gmail.com';
                                } else {
                                  _emailError = null;
                                }
                              } else if (!_isValidEmail(trimmedValue)) {
                                _emailError = 'Invalid email format. Use format: example@gmail.com';
                              } else {
                                _emailError = null;
                              }
                            }
                          });
                        },
                        suffixIcon:
                            _emailController.text.isNotEmpty &&
                                _emailError == null &&
                                _isValidEmail(_emailController.text.trim())
                            ? _buildGreenTick()
                            : null,
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Location Search Field with Autocomplete
                      _buildLocationSearchField(context),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Gender selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.scaledPadding(context, 16.748)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: _genderError != null
                                    ? Colors.red
                                    : _primaryColor,
                                width: 0.758,
                              ),
                              borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 14)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: TextStyle(
                                    fontSize: Responsive.scaledFont(context, 14),
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF717182),
                                    fontFamily: 'Rubik',
                                    letterSpacing: -0.1504,
                                  ),
                                ),
                                SizedBox(height: Responsive.scaledPadding(context, 12)),
                                Row(
                                  children: [
                                    _buildGenderOption(context, 'Male'),
                                    SizedBox(width: Responsive.scaledPadding(context, 16)),
                                    _buildGenderOption(context, 'Female'),
                                    SizedBox(width: Responsive.scaledPadding(context, 16)),
                                    _buildGenderOption(context, 'Other'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_genderError != null)
                            Padding(
                              padding: EdgeInsets.only(
                                left: Responsive.scaledPadding(context, 20),
                                top: Responsive.scaledPadding(context, 4),
                              ),
                              child: Text(
                                _genderError!,
                                style: TextStyle(
                                  fontSize: Responsive.scaledFont(context, 12),
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Date of Birth (opens calendar)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: Responsive.scaledPadding(context, 60).clamp(55.0, 65.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: _dobError != null
                                    ? Colors.red
                                    : _primaryColor,
                                width: 0.758,
                              ),
                              borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 14)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 14)),
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: DateTime(1900, 1, 1),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  final dobText =
                                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  final age = _calculateAgeFromDob(dobText);

                                  setState(() {
                                    _dobController.text = dobText;
                                    if (age == null) {
                                      _dobError =
                                          'Enter a valid date (YYYY-MM-DD)';
                                    } else if (age < 18) {
                                      _dobError =
                                          'You must be 18 years or older';
                                    } else {
                                      _dobError = null;
                                    }
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  SizedBox(width: Responsive.scaledPadding(context, 20)),
                                  SvgPicture.asset(
                                    'assets/authPages/calender.svg',
                                    width: Responsive.scaledIcon(context, 20),
                                    height: Responsive.scaledIcon(context, 20),
                                  ),
                                  SizedBox(width: Responsive.scaledPadding(context, 16)),
                                  Expanded(
                                    child: Text(
                                      _dobController.text.isEmpty
                                          ? 'Date of Birth'
                                          : _dobController.text,
                                      style: TextStyle(
                                        fontSize: Responsive.scaledFont(context, 16),
                                        color: _dobController.text.isEmpty
                                            ? _grey700
                                            : _primary900,
                                        fontFamily: 'Inter',
                                        letterSpacing: -0.3125,
                                      ),
                                    ),
                                  ),
                                  if (_dobController.text.isNotEmpty &&
                                      _dobError == null) ...[
                                    SizedBox(width: Responsive.scaledPadding(context, 12)),
                                    _buildGreenTick(),
                                  ],
                                  SizedBox(width: Responsive.scaledPadding(context, 12)),
                                ],
                              ),
                            ),
                          ),
                          if (_dobError != null)
                            Padding(
                              padding: EdgeInsets.only(
                                left: Responsive.scaledPadding(context, 20),
                                top: Responsive.scaledPadding(context, 4),
                              ),
                              child: Text(
                                _dobError!,
                                style: TextStyle(
                                  fontSize: Responsive.scaledFont(context, 12),
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            context: context,
                            hintText: 'Password',
                            iconAsset: 'assets/authPages/password.svg',
                            iconAssetColor: const Color(0xFF90A1B9),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            errorText: _passwordError,
                            onChanged: (value) {
                              setState(() {
                                _passwordError = null;
                                _passwordStrength = _calculatePasswordStrength(
                                  value,
                                );
                                _validatePasswordRequirements(value);
                                // Clear confirm password error when password changes
                                if (_confirmPasswordController.text.isNotEmpty) {
                                  if (value == _confirmPasswordController.text) {
                                    _confirmPasswordError = null;
                                  } else {
                                    _confirmPasswordError = 'Passwords do not match';
                                  }
                                }
                              });
                            },
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isPasswordFullyValid(_passwordController.text) &&
                                    _passwordError == null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildGreenTick(),
                                  ),
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
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          _buildPasswordStrengthIndicator(),
                          // Password hints - only show if there's a hint to display
                          if (_passwordController.text.isNotEmpty && _getPasswordHint() != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 20),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildPasswordHint(context),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Confirm Password
                      _buildInputField(
                        context: context,
                        hintText: 'Confirm Password',
                        iconAsset: 'assets/authPages/password.svg',
                        iconAssetColor: const Color(0xFF90A1B9),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        errorText: _confirmPasswordError,
                            onChanged: (value) {
                              setState(() {
                                final password = _passwordController.text;
                                if (value.isEmpty) {
                                  _confirmPasswordError = null;
                                } else if (password != value) {
                                  _confirmPasswordError = 'Passwords do not match';
                                } else {
                                  _confirmPasswordError = null;
                                }
                              });
                            },
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isPasswordFullyValid(_passwordController.text) &&
                                _confirmPasswordController.text.isNotEmpty &&
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
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
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

                      SizedBox(height: Responsive.scaledPadding(context, 10)),

                      // Account type dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: Responsive.scaledPadding(context, 90).clamp(80.0, 100.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: _accountTypeError != null
                                    ? Colors.red
                                    : _primaryColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(Responsive.responsiveRadius(context, 10)),
                                bottom: Radius.circular(
                                  (_isAccountTypeDropdownOpen == true) ? 0 : Responsive.responsiveRadius(context, 10),
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
                                  top: Radius.circular(Responsive.responsiveRadius(context, 10)),
                                  bottom: Radius.circular(
                                    (_isAccountTypeDropdownOpen == true)
                                        ? 0
                                        : Responsive.responsiveRadius(context, 10),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.scaledPadding(context, 14),
                                    vertical: Responsive.scaledPadding(context, 18),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedAccountType ??
                                              'What will you most likely be using this account for',
                                          style: TextStyle(
                                            fontSize: Responsive.scaledFont(context, 14),
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
                                        size: Responsive.scaledIcon(context, 16),
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
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(Responsive.responsiveRadius(context, 10)),
                                  bottomRight: Radius.circular(Responsive.responsiveRadius(context, 10)),
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
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.scaledPadding(context, 8),
                                  horizontal: Responsive.scaledPadding(context, 8),
                                ),
                                itemCount: 2,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: Responsive.scaledPadding(context, 4)),
                                itemBuilder: (context, index) {
                                  final option = index == 0
                                      ? 'Personal'
                                      : 'Business';
                                  final isSelected =
                                      _selectedAccountType == option;
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 12)),
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
                                            Responsive.responsiveRadius(context, 12),
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Responsive.scaledPadding(context, 12),
                                          vertical: Responsive.scaledPadding(context, 12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: Responsive.scaledFont(context, 12),
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
                              padding: EdgeInsets.only(
                                left: Responsive.scaledPadding(context, 20),
                                top: Responsive.scaledPadding(context, 4),
                              ),
                              child: Text(
                                _accountTypeError!,
                                style: TextStyle(
                                  fontSize: Responsive.scaledFont(context, 12),
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

              SizedBox(height: Responsive.scaledPadding(context, 50)),

              // Terms and conditions checkbox - aligned with input forms
              Center(
                child: SizedBox(
                  width: Responsive.widthPercent(context, 90).clamp(300.0, 342.0),
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
                              width: Responsive.scaledPadding(context, 24.476),
                              height: Responsive.scaledPadding(context, 24),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _checkboxColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 6)),
                                color: _agreeToTerms
                                    ? _checkboxColor
                                    : Colors.white,
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
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CommunityGuidelinesScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: Responsive.scaledFont(context, 12),
                                    fontWeight:
                                        FontWeight.normal, // Rubik Regular
                                    color: const Color(0xFF100B3C),
                                    letterSpacing: 0.2,
                                    fontFamily: 'Rubik',
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "By signing up I agree, to the ",
                                    ),
                                    TextSpan(
                                      text: 'Terms of Use',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: const Color(0xFF100B3C),
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: const Color(0xFF100B3C),
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
                      if (_termsError != null)
                        Padding(
                          padding: EdgeInsets.only(
                            left: Responsive.scaledPadding(context, 36),
                            top: Responsive.scaledPadding(context, 8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: Responsive.scaledIcon(context, 16),
                                color: Colors.red,
                              ),
                              SizedBox(width: Responsive.scaledPadding(context, 8)),
                              Expanded(
                                child: Text(
                                  _termsError!,
                                  style: TextStyle(
                                    fontSize: Responsive.scaledFont(context, 13),
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

              SizedBox(height: Responsive.scaledPadding(context, 22)),

              // Sign up button - aligned with input forms
              Center(
                child: Container(
                  width: Responsive.widthPercent(context, 90).clamp(300.0, 338.0),
                  height: Responsive.scaledPadding(context, 56).clamp(50.0, 60.0),
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? _primaryColor.withOpacity(0.7)
                        : _primaryColor,
                    borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 20)),
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
                      borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 20)),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: Responsive.scaledIcon(context, 20),
                                height: Responsive.scaledIcon(context, 20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: Responsive.scaledFont(context, 16),
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

              SizedBox(height: Responsive.scaledPadding(context, 30)),

              // Footer text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: Responsive.scaledFont(context, 16),
                    fontWeight: FontWeight.normal, // Rubik Regular
                    color: _grey400,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    const TextSpan(text: "Already have an account? "),
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
                            fontSize: Responsive.scaledFont(context, 16),
                            fontWeight: FontWeight.w700, // Rubik Medium
                            color: _primaryColor,
                            fontFamily: 'Inter',
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
  Widget _buildGenderOption(BuildContext context, String gender) {
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
            width: Responsive.scaledPadding(context, 15.991),
            height: Responsive.scaledPadding(context, 15.991),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 0.758),
              color: isSelected ? _primaryColor : Colors.transparent,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: Responsive.scaledPadding(context, 6),
                      height: Responsive.scaledPadding(context, 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: Responsive.scaledPadding(context, 8)),
          Text(
            gender,
            style: TextStyle(
              fontSize: Responsive.scaledFont(context, 14),
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

  /// Checks if all form fields are valid without setting error messages
  /// Used to enable/disable the signup button
  bool _areAllFieldsValid() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final state = _stateController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final dobText = _dobController.text.trim();

    // Check First Name
    if (firstName.isEmpty || !_isValidName(firstName)) {
      return false;
    }

    // Check Last Name
    if (lastName.isEmpty || !_isValidName(lastName)) {
      return false;
    }

    // Check Username
    if (username.isEmpty ||
        _hasSpaces(username) ||
        !_isValidUsername(username) ||
        _isCheckingUsername ||
        _isUsernameAvailable != true) {
      return false;
    }

    // Check Email
    if (email.isEmpty || !_isValidEmail(email)) {
      return false;
    }

    // Check State
    if (state.isEmpty) {
      return false;
    }

    // Check Gender
    if (_selectedGender == null) {
      return false;
    }

    // Check Date of Birth
    if (dobText.isEmpty) {
      return false;
    }
    final age = _calculateAgeFromDob(dobText);
    if (age == null || age < 18) {
      return false;
    }

    // Check Password
    if (password.isEmpty || 
        password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return false;
    }

    // Check Confirm Password
    if (confirmPassword.isEmpty || password != confirmPassword) {
      return false;
    }

    // Check Account Type
    if (_selectedAccountType == null) {
      return false;
    }

    // Check Terms Agreement
    if (!_agreeToTerms) {
      return false;
    }

    return true;
  }

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

    // Collect all error messages first, then update state once
    String? newFirstNameError;
    String? newLastNameError;
    String? newUsernameError;
    String? newEmailError;
    String? newStateError;
    String? newGenderError;
    String? newDobError;
    String? newPasswordError;
    String? newConfirmPasswordError;
    String? newAccountTypeError;
    String? newTermsError;

    // Validate First Name
    if (firstName.isEmpty) {
      newFirstNameError = 'First name is required';
      isValid = false;
    } else {
      final validationError = _validateName(firstName);
      if (validationError != null) {
        newFirstNameError = validationError;
        isValid = false;
      } else {
        newFirstNameError = null;
      }
    }

    // Validate Last Name
    if (lastName.isEmpty) {
      newLastNameError = 'Last name is required';
      isValid = false;
    } else {
      final validationError = _validateName(lastName);
      if (validationError != null) {
        newLastNameError = validationError;
        isValid = false;
      } else {
        newLastNameError = null;
      }
    }

    // Validate Username
    if (username.isEmpty) {
      newUsernameError = 'Username is required';
      isValid = false;
    } else if (_hasSpaces(username)) {
      newUsernameError = 'Only letters, numbers, and underscores are allowed.';
      isValid = false;
    } else {
      // Validate username format with specific error messages
      final validationError = _validateUsername(username);
      if (validationError != null) {
        newUsernameError = validationError;
        isValid = false;
      } else if (_isCheckingUsername) {
        newUsernameError = 'Please wait while we check username availability';
        isValid = false;
      } else if (_isUsernameAvailable == false) {
        newUsernameError = _usernameError ?? 'That username is already taken.';
        isValid = false;
      } else if (_isUsernameAvailable == null) {
        // Username format is valid but availability hasn't been checked yet
        // Trigger check and wait
        newUsernameError = 'Please wait while we check username availability';
        _checkUsernameAvailability(username);
        isValid = false;
      } else {
        newUsernameError = null;
      }
    }

    // Validate Email
    if (email.isEmpty) {
      newEmailError = 'Email is required';
      isValid = false;
    } else if (!email.contains('@')) {
      newEmailError = 'Email must contain @';
      isValid = false;
    } else if (!_isValidEmail(email)) {
      newEmailError = 'Invalid email format. Use format: example@gmail.com';
      isValid = false;
    } else {
      newEmailError = null;
    }

    // Validate State
    if (state.isEmpty) {
      newStateError = 'State is required';
      isValid = false;
    } else {
      newStateError = null;
    }

    // Validate Gender
    if (_selectedGender == null) {
      newGenderError = 'Please select a gender';
      isValid = false;
    } else {
      newGenderError = null;
    }

    // Validate Date of Birth (18+ years)
    if (dobText.isEmpty) {
      newDobError = 'Birthday is required';
      isValid = false;
    } else {
      final age = _calculateAgeFromDob(dobText);
      if (age == null) {
        newDobError = 'Enter a valid date (YYYY-MM-DD)';
        isValid = false;
      } else if (age < 18) {
        newDobError = 'You must be 18 years or older';
        isValid = false;
      } else {
        newDobError = null;
      }
    }

    // Validate Password
    if (password.isEmpty) {
      newPasswordError = 'Password is required';
      isValid = false;
    } else if (password.length < 8) {
      newPasswordError = 'Password must be at least 8 characters';
      isValid = false;
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      newPasswordError = 'Password must contain at least one capital letter';
      isValid = false;
    } else if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      newPasswordError = 'Password must contain at least one special character';
      isValid = false;
    } else {
      newPasswordError = null;
    }

    // Validate Confirm Password
    if (confirmPassword.isEmpty) {
      newConfirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (password != confirmPassword) {
      newConfirmPasswordError = 'Passwords do not match';
      isValid = false;
    } else {
      newConfirmPasswordError = null;
    }

    // Validate Account Type
    if (_selectedAccountType == null) {
      newAccountTypeError = 'Please select an account type';
      isValid = false;
    } else {
      newAccountTypeError = null;
    }

    // Validate Terms Agreement
    if (!_agreeToTerms) {
      newTermsError = 'Please agree to the Terms of Use and Privacy Policy';
      isValid = false;
    } else {
      newTermsError = null;
    }

    // Update all errors in a single setState call to prevent duplicate displays
    setState(() {
      _firstNameError = newFirstNameError;
      _lastNameError = newLastNameError;
      _usernameError = newUsernameError;
      _emailError = newEmailError;
      _stateError = newStateError;
      _genderError = newGenderError;
      _dobError = newDobError;
      _passwordError = newPasswordError;
      _confirmPasswordError = newConfirmPasswordError;
      _accountTypeError = newAccountTypeError;
      _termsError = newTermsError;
    });

    return isValid;
  }

  /// Validates email format with comprehensive checks
  /// - Checks for complete TLD (at least 2 characters after dot)
  /// - Validates proper format for @gmail.com and other domains
  /// - Catches incomplete domains like .c, .co (if less than 2 chars)
  bool _isValidEmail(String email) {
    // Basic structure check: must have @ and at least one dot after @
    if (!email.contains('@') || !email.contains('.')) {
      return false;
    }

    // Split email into local and domain parts
    final parts = email.split('@');
    if (parts.length != 2) {
      return false; // Must have exactly one @
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    // Local part must not be empty
    if (localPart.isEmpty) {
      return false;
    }

    // Domain part must contain at least one dot
    if (!domainPart.contains('.')) {
      return false;
    }

    // Split domain into domain name and TLD
    final domainParts = domainPart.split('.');
    if (domainParts.length < 2) {
      return false;
    }

    // Get TLD (last part after last dot)
    final tld = domainParts.last;

    // TLD must be at least 2 characters (catches incomplete .c, .co, etc.)
    if (tld.length < 2) {
      return false;
    }

    // TLD must contain only letters
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
      return false;
    }

    // Full email regex validation
    // Allows letters, numbers, dots, hyphens, underscores in local part
    // Allows letters, numbers, dots, hyphens in domain part
    // Requires TLD with at least 2 letters
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
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
      final birthdayString =
          dobText; // Use DOB from controller (YYYY-MM-DD format)

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
        await _authService.sendOtp(email: email, userId: response.user!.id);
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navigate to interest selection screen on successful signup
      Navigator.push(
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
            _handleSignUp();
          },
        );
        return;
      }

      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('email') ||
          errorMessage.contains('already registered')) {
        setState(() {
          _emailError = 'This email is already registered';
        });
      } else if (errorMessage.contains('username') ||
          errorMessage.contains('duplicate')) {
        setState(() {
          _usernameError = 'That username is already taken.';
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
            _handleSignUp();
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
