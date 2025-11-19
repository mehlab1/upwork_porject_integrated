import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pal/widgets/pal_toast.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String? _activeCategory;
  bool _spotlightEnabled = true;
  String? _selectedLocation;
  bool _isLocationInlineOpen = false;

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
    'Maryland',
    'Gbagada',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFormFieldChanged);
    _bodyController.addListener(_onFormFieldChanged);
    _titleController.addListener(_capitalizeTitle);
    _bodyController.addListener(_capitalizeBody);
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
      return 'Content exceeds 500 characters';
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
                      const SizedBox(height: 16),
                      _buildSpotlightCard(),
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

  Widget _buildComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
          decoration: const InputDecoration(
            hintText: "What's happening?",
            hintStyle: TextStyle(
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
          controller: _bodyController,
          focusNode: _bodyFocusNode,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 5,
          maxLines: null,
          maxLength: 500,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
          decoration: const InputDecoration(
            hintText:
                "What’s the gist? Share something interesting happening around you...",
            hintStyle: TextStyle(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: hasLocation
                ? const Color(0x99EEF2FF)
                : const Color(0x66EEF2FF),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: Radius.circular(_isLocationInlineOpen ? 0 : 14),
            ),
            border: Border.all(color: const Color(0xFFE0E7FF), width: 0.756),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isLocationInlineOpen = !_isLocationInlineOpen;
                });
              },
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(_isLocationInlineOpen ? 0 : 14),
              ),
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
                                ? 'Tap to change your neighborhood'
                                : 'Select your neighborhood',
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
        ),
        if (_isLocationInlineOpen)
          _InlineDropdown(
            options: _locationOptions
                .map((label) => _DropdownOption(label))
                .toList(),
            selectedValue: _selectedLocation ?? 'Select your neighborhood',
            onSelected: (value) {
              setState(() {
                _selectedLocation = value;
                _isLocationInlineOpen = false;
              });
            },
            optionTextColor: const Color(0xFF314158),
            highlightColor: const Color(0xFFF8FAFC),
            borderColor: const Color(0xFFE0E7FF),
          ),
      ],
    );
  }

  Widget _buildCharacterLimitIndicator() {
    final hasLocation = _isLocationSelected;
    if (!hasLocation) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Location added',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlightCard() {
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
              children: const [
                Text(
                  'Detty December',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 2),
                Text(
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
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.transparent, width: 0.756),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 2.2,
                vertical: 2.5,
              ),
              child: Align(
                alignment: _spotlightEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/newPost.svg',
                    width: 10,
                    height: 10,
                    fit: BoxFit.scaleDown,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4F39F6),
                      BlendMode.srcIn,
                    ),
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
            onPressed: (_canPost)
                ? () {
                    _handleSubmit();
                    Navigator.of(context).pop();
                    PalToast.show(
                      context,
                      message: 'Post created successfully',
                    );
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
            child: const Text(
              'Post',
              style: TextStyle(
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

  void _handleSubmit() {}

  Future<void> _showLocationPicker() async {}

  void _showGuidelinesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Community Guidelines'),
          content: const Text(
            'Be respectful and ensure your post aligns with our community standards. Avoid spam, harassment, or misinformation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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

Future<void> showCreatePostModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xFF0B1120).withOpacity(0.55),
    builder: (context) => const CreatePostScreen(),
  );
}