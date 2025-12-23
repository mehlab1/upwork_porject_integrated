import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/post_service.dart';
import '../../services/admin_service.dart';
import '../../widgets/pal_toast.dart';
import '../settings/community_guidelines_screen.dart';
import 'widgets/post_card.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    this.postData,
  });

  final PostCardData? postData;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String? _activeCategory;
  bool _spotlightEnabled = true;
  bool _dettyDecemberEnabled = false;
  bool _wodEnabled = false;
  String? _selectedLocation;
  bool _isLocationInlineOpen = false;
  bool _isSubmitting = false;
  final GlobalKey _locationCardKey = GlobalKey();

  // Monthly Spotlight state
  bool _isLoadingSpotlightStatus = false;
  Map<String, dynamic>? _spotlightStatus;

  static const Map<String, Color> _categoryColors = {
    'Gist': Color(0xFFAD46FF),
    'Ask': Color(0xFF00C950),
    'Discussion': Color(0xFFFE9A00),
  };

  static const List<String> _locationOptions = [
    'Victoria Island (VI)',
    'Ikoyi',
    'Lekki',
    'Lekki Phase 1',
    'Ajah',
    'Yaba',
    'Surulere',
    'Ikeja',
    'Mainland',
    'Festac',
    'Isolo',
    'Oshodi',
    'Maryland',
    'Apapa',
    'Other',
  ];

  // Fallback hardcoded ids for locations and categories. These are used when
  // the edge functions that fetch categories/locations fail (backend issue).
  // The UI will continue to show the same labels but the app will send the
  // mapped id to the create-post edge function so posts are created with a
  // location/category id. Replace these ids with real ones if you have them.
  static const Map<String, String> _fallbackLocationIdLookup = {
    'Victoria Island (VI)': '1549afea-3d2d-4a84-ab4c-e781816578bc',
    'Ikoyi': 'd2bab849-c561-4bc1-9a38-9b41acc713d2',
    'Lekki': 'bb6c49e4-0ee1-4fca-83fc-703fc24588de',
    'Lekki Phase 1': '7b634ec2-a209-4e5b-99d7-a4e3fda6bafa',
    'Ajah': 'f530b1ec-765c-4108-bf3d-f1ee5160cb1d',
    'Yaba': 'd854e619-8816-4114-b3b6-cc4667a4c93f',
    'Surulere': 'bc3bd59c-dc8d-40da-b857-8f4aaf5edd9a',
    'Ikeja': 'db730bb8-fe61-4259-818f-2ef073010a7d',
    'Maryland': 'b4f2e110-7f8d-4046-8c48-13b0c3c3571e',
    'Gbagada': '9171d84c-fc1b-4c18-9757-618bffb65ed3',
  };

  static const Map<String, String> _fallbackCategoryIdLookup = {
    'Gist': '920895cb-cb64-47fa-bae4-3d600b174b27',
    'Ask': '4610edf9-33a8-4173-94ed-5da6bfc1869c',
    'Discussion': '923b71e2-e2d8-4ac5-a112-f4c4e2270983',
  };

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  final PostService _postService = PostService();
  final AdminService _adminService = AdminService();
  Map<String, String> _categoryIdLookup = {};
  Map<String, String> _locationIdLookup = {};
  bool _isEditMode = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFormFieldChanged);
    _bodyController.addListener(_onFormFieldChanged);
    _titleController.addListener(_capitalizeTitle);
    _bodyController.addListener(_capitalizeBody);
    _checkSpotlightStatus();
    _checkAdminStatus();
    Future(() async {
      try {
        final fetchedCategories = await _postService.getCategories();
        final fetchedLocations = await _postService.getLocations();
        if (!mounted) return;
        setState(() {
          final usedCategories = fetchedCategories.isNotEmpty
              ? fetchedCategories
              : _fallbackCategoryIdLookup;
          final usedLocations = fetchedLocations.isNotEmpty
              ? fetchedLocations
              : _fallbackLocationIdLookup;
          _categoryIdLookup = usedCategories;
          _locationIdLookup = usedLocations;
        });
        // Log when backend returned empty lists so we can detect fallback usage locally
        if (fetchedCategories.isEmpty || fetchedLocations.isEmpty) {
          // ignore: avoid_print
          print(
            'DEBUG: Using fallback mappings for categories or locations (empty backend result)',
          );
        }
      } catch (_) {
        if (!mounted) return;
        // On error, fall back to hardcoded mappings so the UI remains usable.
        setState(() {
          _categoryIdLookup = _fallbackCategoryIdLookup;
          _locationIdLookup = _fallbackLocationIdLookup;
        });
        // ignore: avoid_print
        print(
          'DEBUG: Failed to fetch categories/locations - using fallback mappings',
        );
      }
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      // Initialize edit mode after admin status is checked
      if (widget.postData != null && isAdmin) {
        _isEditMode = true;
        // Pre-fill title and body
        final postData = widget.postData!;
        _titleController.text = postData.title;
        _bodyController.text = postData.body;
        // Set category
        _activeCategory = postData.category;
        // Set location
        _selectedLocation = postData.location;
      }
    });
  }


  Future<void> _checkSpotlightStatus() async {
    try {
      setState(() {
        _isLoadingSpotlightStatus = true;
      });

      final response = await _postService.getMonthlySpotlightStatus();
      if (!mounted) return;

      setState(() {
        _spotlightStatus = response;
        _isLoadingSpotlightStatus = false;
        // Set spotlight enabled based on availability
        final isAvailable = response['is_available'] as bool? ?? false;
        _spotlightEnabled = isAvailable;
      });
    } catch (e) {
      // Silently handle error - fallback to default
      if (!mounted) return;
      setState(() {
        _isLoadingSpotlightStatus = false;
        _spotlightStatus = null;
        _spotlightEnabled = false; // Disable if status fetch fails
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFormFieldChanged);
    _bodyController.removeListener(_onFormFieldChanged);
    _titleController.removeListener(_capitalizeTitle);
    _bodyController.removeListener(_capitalizeBody);
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  static const _surface = Colors.white;
  static const _overlay = Color(0xFF0B1120);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF475569);
  static const _muted = Color(0xFF94A3B8);
  static const _outline = Color(0xFFE2E8F0);

  bool get _isTitleFilled => _titleController.text.trim().length >= 2;
  bool get _isBodyFilled => _bodyController.text.trim().length >= 2;
  bool get _isTitleOverLimit => _titleController.text.length > 75;
  bool get _isBodyOverLimit => _bodyController.text.length > 500;
  bool get _isLocationSelected => _selectedLocation != null;
  bool get _isOverLimit => _isTitleOverLimit || _isBodyOverLimit;
  bool get _canPost =>
      !_isOverLimit &&
      _isTitleFilled &&
      _isBodyFilled &&
      _isLocationSelected &&
      _activeCategory != null;

  void _onFormFieldChanged() {
    setState(() {});
  }

  void _capitalizeTitle() {
    final text = _titleController.text;
    if (text.isNotEmpty) {
      final firstChar = text[0];
      if (firstChar != firstChar.toUpperCase() &&
          firstChar.toLowerCase() == firstChar) {
        final selection = _titleController.selection;
        _titleController.removeListener(_capitalizeTitle);
        _titleController.value = TextEditingValue(
          text: firstChar.toUpperCase() + text.substring(1),
          selection: selection,
        );
        _titleController.addListener(_capitalizeTitle);
      }
    }
  }

  void _capitalizeBody() {
    final text = _bodyController.text;
    if (text.isNotEmpty) {
      final firstChar = text[0];
      if (firstChar != firstChar.toUpperCase() &&
          firstChar.toLowerCase() == firstChar) {
        final selection = _bodyController.selection;
        _bodyController.removeListener(_capitalizeBody);
        _bodyController.value = TextEditingValue(
          text: firstChar.toUpperCase() + text.substring(1),
          selection: selection,
        );
        _bodyController.addListener(_capitalizeBody);
      }
    }
  }

  String _formStatusMessage() {
    if (_isTitleOverLimit) {
      return 'Title exceeds 75 characters';
    }
    if (_isBodyOverLimit) {
      return 'Content exceeds character limit';
    }
    if (_activeCategory == null) {
      return 'Select a post category';
    }
    if (!_isTitleFilled) {
      return 'Add a title to get started';
    }
    if (!_isBodyFilled) {
      return 'Share some details';
    }
    if (!_isLocationSelected) {
      return 'Select a location';
    }
    return 'Please follow community guidelines';
  }

  String? _statusIconAsset() {
    if (_isTitleOverLimit || _isBodyOverLimit) {
      return 'assets/images/askIcon.svg';
    }
    if (_activeCategory == null) {
      return null; // No icon for category selection
    }
    if (!_isTitleFilled) {
      return 'assets/feedPage/pencilIcon.svg';
    }
    if (!_isBodyFilled) {
      return 'assets/postCreation/shareDetails.svg';
    }
    if (!_isLocationSelected) {
      return 'assets/images/locationIcon.svg';
    }
    return null;
  }

  Color _statusIconColor() {
    if (_isTitleOverLimit || _isBodyOverLimit) {
      return const Color(0xFFE7000B);
    }
    if (_activeCategory == null) {
      return _muted;
    }
    if (!_isTitleFilled || !_isBodyFilled) {
      return _muted;
    }
    if (!_isLocationSelected) {
      return _muted;
    }
    return _muted;
  }

  Color _statusTextColor() {
    if (_isTitleOverLimit || _isBodyOverLimit) {
      return const Color(0xFFE7000B);
    }
    if (_activeCategory == null) {
      return _muted;
    }
    if (!_isTitleFilled || !_isBodyFilled) {
      return _muted;
    }
    if (!_isLocationSelected) {
      return _muted;
    }
    if (_canPost) {
      return const Color(0xFF62748E);
    }
    return _muted;
  }

  Widget _buildStatusPrompt() {
    final iconAsset = _statusIconAsset();
    final message = _formStatusMessage();
    final isActionable = _canPost && !_isOverLimit;

    return TextButton(
      onPressed: () {
        if (_isTitleOverLimit || _isBodyOverLimit) {
          _bodyFocusNode.requestFocus();
          return;
        }
        if (_activeCategory == null) {
          // Focus on category selector - user needs to select a category
          return;
        }
        if (!_isTitleFilled) {
          _titleFocusNode.requestFocus();
          return;
        }
        if (!_isBodyFilled) {
          _bodyFocusNode.requestFocus();
          return;
        }
        if (!_isLocationSelected) {
          _showLocationPicker();
          return;
        }
        _showGuidelinesDialog();
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                _statusIconColor(),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _statusTextColor(),
              fontFamily: 'Inter',
              decoration: isActionable
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _overlay.withOpacity(0.55),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 342,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _overlay.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildCategorySelector(),
                      const SizedBox(height: 24),
                      _buildComposer(),
                      const SizedBox(height: 20),
                      _buildLocationCard(),
                      const SizedBox(height: 12),
                      _buildCharacterLimitIndicator(),
                      const SizedBox(height: 12),
                      _buildDettyDecemberCard(),
                      const SizedBox(height: 12),
                      _buildWodCard(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                _buildFooterActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            'assets/feedPage/newPosticon.svg',
            fit: BoxFit.none,
            alignment: Alignment.center,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Share with your community',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _muted,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, size: 18, color: Color(0xFF45556C)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    const Map<String, String> chipIcons = {
      'Gist': 'assets/images/gistIcon.svg',
      'Ask': 'assets/images/askIcon.svg',
      'Discussion': 'assets/images/discussionIcon.svg',
    };

    return Row(
      children: chipIcons.entries.map((entry) {
        final label = entry.key;
        final iconPath = entry.value;
        final isSelected = label == _activeCategory;
        final selectedColor = _categoryColors[label]!;
        return Padding(
          padding: EdgeInsets.only(right: label == 'Discussion' ? 0 : 8),
          child: GestureDetector(
            onTap: () => setState(() => _activeCategory = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(15.989, 10.511, 15.343, 9.48),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(25378200),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withOpacity(0.32),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                        BoxShadow(
                          color: selectedColor.withOpacity(0.24),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      isSelected ? Colors.white : const Color(0xFF45556C),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF45556C),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getTitleHint() {
    switch (_activeCategory) {
      case 'Ask':
        return "What do you want to know?";
      case 'Discussion':
        return "What's on your mind?";
      case 'Gist':
      default:
        return "What's happening?";
    }
  }

  String _getContentHint() {
    switch (_activeCategory) {
      case 'Ask':
        return "Ask your question. The community is here to help...";
      case 'Discussion':
        return "Start a meaningful discussion. Share your perspective...";
      case 'Gist':
      default:
        return "What's the gist? Share something interesting happening around you...";
    }
  }

  Widget _buildComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('title_${_activeCategory ?? 'default'}'),
          controller: _titleController,
          focusNode: _titleFocusNode,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 75,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          style: const TextStyle(
            fontSize: 16,
            height: 24.75 / 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF0F172B),
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: _getTitleHint(),
            hintStyle: const TextStyle(
              fontSize: 16,
              height: 24.75 / 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF90A1B9),
              fontFamily: 'Inter',
            ),
            border: InputBorder.none,
            counterText: '',
          ),
        ),
        Container(width: 298, height: 0.99268, color: _outline),
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('body_${_activeCategory ?? 'default'}'),
          controller: _bodyController,
          focusNode: _bodyFocusNode,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 5,
          maxLines: null,
          maxLength: null, // Allow typing beyond limit to show validation
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: _isBodyOverLimit
                ? const Color(0xFFE7000B)
                : const Color(0xFF0F172B),
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: _getContentHint(),
            hintStyle: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: Color(0xFF90A1B9),
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
            border: InputBorder.none,
            counterText: '',
          ),
        ),
        Container(width: 298, height: 0.99268, color: _outline),
      ],
    );
  }

  Widget _buildLocationCard() {
    final bool hasLocation = _isLocationSelected;
    
    return Container(
      key: _locationCardKey,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasLocation
            ? const Color(0x99EEF2FF)
            : const Color(0x66EEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 0.756),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showLocationDropdown(context);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 31.99036,
                  height: 31.99036,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 0.75633,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.only(right: 0.01182),
                  child: SvgPicture.asset(
                    'assets/images/locationIcon.svg',
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(
                      hasLocation ? _textPrimary : Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocation ? _selectedLocation! : 'Add location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hasLocation
                            ? 'Tap to select the relevant area'
                            : 'Select your relevant area',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isLocationInlineOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationDropdown(BuildContext context) {
    final RenderBox? renderBox = _locationCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate available space below the card
    final double availableHeight = screenHeight - position.dy - size.height;
    final double maxHeight = availableHeight.clamp(100.0, 200.0);

    setState(() {
      _isLocationInlineOpen = true;
    });

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        screenWidth - position.dx - size.width,
        screenHeight - position.dy - size.height,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      color: Colors.white,
      elevation: 8,
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minWidth: size.width,
      ),
      items: _locationOptions.map((location) {
        final isSelected = location == _selectedLocation;
        return PopupMenuItem<String>(
          padding: EdgeInsets.zero,
          value: location,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedLocation = location;
                    _isLocationInlineOpen = false;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF314158),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: Color(0xFF00A63E),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLocationInlineOpen = false;
        });
      }
    });
  }

  Widget _buildCharacterLimitIndicator() {
    final hasLocation = _isLocationSelected;
    final bodyLength = _bodyController.text.length;
    final isOverLimit = _isBodyOverLimit;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasLocation)
          Text(
            'Location added',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
              fontFamily: 'Inter',
            ),
          )
        else
          const SizedBox.shrink(),
        Text(
          '$bodyLength/500 characters',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isOverLimit
                ? const Color(0xFFFB2C36)
                : _textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildDettyDecemberCard() {
    return Container(
      height: 61,
      decoration: BoxDecoration(
        color: const Color(0x66EEF2FF), // rgba(238,242,255,0.4)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 0.756),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.756, vertical: 0.756),
      child: Row(
        children: [
          Container(
            width: 31.99,
            height: 31.99,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF), // indigo-100
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/dettyIcon.svg',
                width: 15.989,
                height: 15.989,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(_overlay, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 9.998),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Detty December',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                    letterSpacing: -0.1504,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 0.76),
                Text(
                  'Toggle for festive spotlight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _dettyDecemberEnabled = !_dettyDecemberEnabled);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 19,
              decoration: BoxDecoration(
                color: _dettyDecemberEnabled
                    ? const Color.fromRGBO(21, 93, 252, 0.20)
                    : const Color.fromRGBO(21, 93, 252, 0.12),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: Colors.transparent, width: 0.756),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 0.75586,
                vertical: 1.0,
              ),
              child: Align(
                alignment: _dettyDecemberEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightCard() {
    // Check if spotlight is available
    final isAvailable = _spotlightStatus?['is_available'] as bool? ?? false;

    // Hide card if spotlight is not available
    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    // Use dynamic title from API or fallback to hardcoded
    final topicTitle =
        _spotlightStatus?['hot_topic_title'] as String? ?? 'Detty December';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x66EEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 0.756),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(21, 93, 252, 0.20),
              borderRadius: BorderRadius.circular(12),
            ),

            child: SvgPicture.asset(
              'assets/images/dettyIcon.svg',
              fit: BoxFit.scaleDown,
              colorFilter: const ColorFilter.mode(_overlay, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topicTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Toggle for Festive spotlight',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _spotlightEnabled = !_spotlightEnabled);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 19,
              decoration: BoxDecoration(
                color: _spotlightEnabled
                    ? const Color.fromRGBO(21, 93, 252, 0.20)
                    : const Color.fromRGBO(21, 93, 252, 0.12),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: Colors.transparent, width: 0.756),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 0.75586,
                vertical: 1.0,
              ),
              child: Align(
                alignment: _spotlightEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    return Container(
      width: 360,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0x80F8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.75633),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 23.98981),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusPrompt(),
          ElevatedButton(
            onPressed: (_canPost && !_isSubmitting)
                ? () {
                    _handleSubmit();
                  }
                : null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (_activeCategory == null) {
                  return _muted.withOpacity(0.3);
                }
                final selectedColor = _categoryColors[_activeCategory]!;
                if (states.contains(WidgetState.disabled)) {
                  return _muted.withOpacity(0.3);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return _darken(selectedColor, 0.08);
                }
                return selectedColor;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return _muted;
                }
                return Colors.white;
              }),
              elevation: WidgetStateProperty.all(0),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            child: Text(
              _isEditMode ? 'Save' : 'Post',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWodCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x66EEF2FF), // rgba(238,242,255,0.4) - same as Detty December
        border: Border.all(
          color: const Color(0xFFE0E7FF),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 27.996,
            height: 27.996,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Transform.rotate(
                angle: 3.14159, // 180 degrees
                child: Transform.scale(
                  scaleY: -1,
                  child: SvgPicture.asset(
                    'assets/feedPage/Megaphone.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF0B1120),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7.989),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Wahala of the Day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172B),
                    fontFamily: 'Inter',
                    letterSpacing: -0.0762,
                    height: 19.5 / 13,
                  ),
                ),
                const SizedBox(height: 0.51),
                // Description
                Text(
                  'Opt-in for WOD spotlight',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF62748E),
                    fontFamily: 'Inter',
                    letterSpacing: 0.0645,
                    height: 16.5 / 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7.989),
          GestureDetector(
            onTap: () {
              setState(() => _wodEnabled = !_wodEnabled);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 19,
              decoration: BoxDecoration(
                color: _wodEnabled
                    ? const Color.fromRGBO(21, 93, 252, 0.20)
                    : const Color.fromRGBO(21, 93, 252, 0.12),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: Colors.transparent, width: 0.756),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 0.75586,
                vertical: 1.0,
              ),
              child: Align(
                alignment: _wodEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper function to ensure header/title ends with a period
  String _ensureTitleEndsWithPeriod(String title) {
    if (title.isEmpty) return title;
    final trimmed = title.trim();
    if (trimmed.endsWith('.')) {
      return trimmed;
    }
    return '$trimmed.';
  }

  void _handleSubmit() async {
    if (_isSubmitting || !_canPost) {
      return;
    }
    
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    final rawTitle = _titleController.text.trim();
    final title = _ensureTitleEndsWithPeriod(rawTitle);
    final body = _bodyController.text.trim();
    final combinedContent = body.isEmpty ? title : '$title\n\n$body'.trim();
    if (combinedContent.isEmpty) {
      // Wait a bit for keyboard to dismiss before showing toast
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        PalToast.show(context, message: 'Please enter post details.');
      }
      return;
    }
    if (combinedContent.length > 1000) {
      // Wait a bit for keyboard to dismiss before showing toast
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        PalToast.show(context, message: 'Post exceeds 1000 characters.');
      }
      return;
    }
    final categoryId = _categoryIdLookup[_activeCategory];
    final selectedLocationName = _selectedLocation;
    final locationId = selectedLocationName != null
        ? _locationIdLookup[selectedLocationName]
        : null;
    if (locationId == null) {
      // Wait a bit for keyboard to dismiss before showing toast
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        PalToast.show(
          context,
          message: 'Selected location is unavailable right now.',
        );
      }
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      Map<String, dynamic> response;
      if (_isEditMode && widget.postData?.id != null) {
        // TODO: Implement updatePost API when available
        // For now, we'll use createPost as a workaround
        // In a real scenario, you'd call: await _postService.updatePost(...)
        response = await _postService.createPost(
          content: combinedContent,
          categoryId: categoryId,
          locationId: locationId,
          enableMonthlySpotlight: _spotlightEnabled,
        );
      } else {
        response = await _postService.createPost(
          content: combinedContent,
          categoryId: categoryId,
          locationId: locationId,
          enableMonthlySpotlight: _spotlightEnabled,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      // Wait a bit for keyboard to dismiss before showing toast and closing modal
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        PalToast.show(
          context,
          message: _isEditMode
              ? (response['message'] ?? 'Post updated successfully')
              : (response['message'] ?? 'Post created successfully'),
        );
        // Close modal after a short delay to ensure toast is visible
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      // Wait a bit for keyboard to dismiss before showing toast
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        PalToast.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _showLocationPicker() async {}

  void _showGuidelinesDialog() {
    // Navigate to Community Guidelines screen
    // The CreatePostScreen state will be preserved when user returns
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CommunityGuidelinesScreen(),
      ),
    );
  }

  Color _darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class _DropdownOption {
  const _DropdownOption(this.label);

  final String label;
}

class _InlineDropdown extends StatelessWidget {
  const _InlineDropdown({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.optionTextColor,
    required this.highlightColor,
    required this.borderColor,
  });

  final List<_DropdownOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final Color optionTextColor;
  final Color highlightColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          top: BorderSide.none,
          left: BorderSide(color: borderColor, width: 1.513),
          right: BorderSide(color: borderColor, width: 1.513),
          bottom: BorderSide(color: borderColor, width: 1.513),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option.label == selectedValue;
            return Material(
              color: isSelected ? highlightColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onSelected(option.label),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: optionTextColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (option.label == selectedValue)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF22C55E),
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

Future<bool?> showCreatePostModal(
  BuildContext context, {
  PostCardData? postData,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xFF0B1120).withOpacity(0.55),
    builder: (context) => CreatePostScreen(postData: postData),
  );
}
