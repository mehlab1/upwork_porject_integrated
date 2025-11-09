import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _activeCategory = 'Gist';
  bool _spotlightEnabled = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  static const _surface = Colors.white;
  static const _overlay = Color(0xFF0B1120);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF475569);
  static const _muted = Color(0xFF94A3B8);
  static const _outline = Color(0xFFE2E8F0);

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
        return Padding(
          padding: EdgeInsets.only(right: label == 'Discussion' ? 0 : 8),
          child: GestureDetector(
            onTap: () => setState(() => _activeCategory = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(15.989, 10.511, 15.343, 9.48),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFAD46FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(25378200),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0xFFE9D4FF),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                        BoxShadow(
                          color: Color(0xFFE9D4FF),
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
          style: const TextStyle(
            fontSize: 16,
            height: 24.75 / 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF90A1B9),
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
          ),
        ),
        Container(width: 298, height: 0.99268, color: _outline),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          maxLines: 4,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF90A1B9),
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
          ),
        ),
        Container(width: 298, height: 0.99268, color: _outline),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x66EEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 0.756),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Add location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Select your neighborhood in Lagos',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          TextButton.icon(
            onPressed: () {
              _titleFocusNode.requestFocus();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: SvgPicture.asset(
              'assets/feedPage/pencilIcon.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(_muted, BlendMode.srcIn),
            ),
            label: const Text(
              'Add a title to get started',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _muted,
                fontFamily: 'Inter',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _handleSubmit();
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return const Color(0xFF155DFC);
                }
                return _outline;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return Colors.white;
                }
                return _muted;
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

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post functionality coming soon.')),
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
