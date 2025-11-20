import 'package:flutter/material.dart';
import 'profile_upload_screen.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key, required this.email});

  final String email;

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  static const Color _primaryBlue = Color(0xFF155DFC);
  static const Color _headingColor = Color(0xFF0F172A);
  static const Color _subheadingColor = Color(0xFF45556C);
  static const Color _countColor = Color(0xFF6B7280);
  static const Color _selectedTextColor = Colors.white;

  final List<String> _interests = const [
    'Lifestyle',
    'Local Updates',
    'Detty December',
    'Food & Dining',
    'Real Estate',
    'Tech & Business',
    'Politics',
    'Sports',
    'Fashion',
  ];

  final Set<String> _selected = <String>{};
  bool _showSelectionError = false;

  void _toggleInterest(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else if (_selected.length < 3) {
        _selected.add(value);
      }
      if (_selected.length >= 2) {
        _showSelectionError = false;
      }
    });
  }

  void _handleContinue() {
    if (_selected.length < 2) {
      setState(() => _showSelectionError = true);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileUploadScreen(email: widget.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = '${_selected.length}/3 selected';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Text(
                'Select your Interest',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _headingColor,
                  fontFamily: 'Rubik',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 54),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Your Interests (Choose 2-3)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _headingColor,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Select topics you'd like to see",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _subheadingColor,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double available = constraints.maxWidth;
                    const double gap = 16;
                    const int columns = 3; // force 3 per row
                    double tileWidth =
                        (available - gap * (columns - 1)) / columns;
                    final double tileHeight = 55.0;
                    return Wrap(
                      alignment: WrapAlignment.start,
                      spacing: gap,
                      runSpacing: gap,
                      children: _interests.map((label) {
                        final isSelected = _selected.contains(label);
                        return GestureDetector(
                          onTap: () => _toggleInterest(label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: tileWidth,
                            height: tileHeight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _primaryBlue,
                                width: 1.522,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? _primaryBlue
                                      : const Color(0xFF6F7786),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: _countColor,
                  fontFamily: 'Inter',
                ),
              ),
              if (_showSelectionError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select at least two interests to continue.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE11D48),
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selected.length >= 2 ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    disabledBackgroundColor: _primaryBlue.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}