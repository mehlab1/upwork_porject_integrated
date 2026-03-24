import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/responsive/responsive.dart';

const _headerIconAsset = 'assets/feedPage/reportIcon.svg';

const _cardBorderColor = Color(0xFFFFC9C9);
const _selectedOptionBackground = Color.fromRGBO(254, 242, 242, 0.5);
const _selectedOptionBorder = Color(0xFFFFC9C9);
const _optionBorder = Color(0xFFE2E8F0);
const _titleColor = Color(0xFF0F172B);
const _subtitleColor = Color(0xFF45556C);
const _detailsFieldBackground = Color(0xFFF3F3F5);
const _detailsHintColor = Color(0xFFA2A2B3);
const _infoHeadingColor = Color(0xFF1C398E);
const _infoBodyColor = Color(0xFF1447E6);
const _cancelBorder = Color.fromRGBO(0, 0, 0, 0.1);
const _submitColor = Color(0xFFE7000B);
const _successBorder = Color(0xFFE2E8F0);
const _successAccent = Color(0xFF0F172B);
const _successSecondary = Color(0xFF62748E);
const _successBody = Color(0xFF45556C);
const _successInfoBackground = Color(0xFFF8FAFC);
const _successInfoBorder = Color(0xFFE2E8F0);
const _successInfoText = Color(0xFF314158);

enum ReportSubject { post, comment }

class JmReportPostSheet extends StatefulWidget {
  const JmReportPostSheet({super.key, this.subject = ReportSubject.post});

  final ReportSubject? subject;

  @override
  State<JmReportPostSheet> createState() => _JmReportPostSheetState();
}

class _JmReportPostSheetState extends State<JmReportPostSheet> {
  final TextEditingController _detailsController = TextEditingController();
  final _reportOptions = const [
    _ReportOption(
      title: 'Spam or misleading',
      description: 'Repetitive or deceptive content',
    ),
    _ReportOption(
      title: 'Harassment or hate speech',
      description: 'Bullying, threats, or discriminatory language',
    ),
    _ReportOption(
      title: 'Inappropriate content',
      description: 'Explicit, violent, or offensive material',
    ),
    _ReportOption(
      title: 'False information',
      description: 'Deliberately spreading misinformation',
    ),
    _ReportOption(
      title: 'Other',
      description: 'Another reason not listed above',
    ),
  ];

  late String _selectedReason = _reportOptions.first.title;
  bool _isOverCharacterLimit = false;

  @override
  void initState() {
    super.initState();
    _detailsController.addListener(_onDetailsChanged);
  }

  void _onDetailsChanged() {
    const maxLength = 500;
    final isOverLimit = _detailsController.text.length > maxLength;
    if (isOverLimit != _isOverCharacterLimit) {
      setState(() {
        _isOverCharacterLimit = isOverLimit;
      });
    }
  }

  @override
  void dispose() {
    _detailsController.removeListener(_onDetailsChanged);
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportSubject = widget.subject ?? ReportSubject.post;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isSmallDevice = Responsive.isSmallDevice(context);
    final screenWidth = Responsive.screenWidth(context);
    
    // Responsive max width: smaller on small devices, larger on bigger devices
    final maxWidth = isSmallDevice 
        ? screenWidth * 0.95 
        : (screenWidth * 0.9).clamp(320.0, 360.0);

    return SafeArea(
      child: Padding(
        padding: Responsive.responsivePadding(
          context,
          all: 16,
        ).copyWith(
          bottom: bottomInset > 0 ? bottomInset : Responsive.scaledPadding(context, 16),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              child: _ReportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportHeaderSection(
                      subject: reportSubject,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(height: Responsive.scaledPadding(context, 20)),
                    Padding(
                      padding: Responsive.responsiveSymmetric(
                        context,
                        horizontal: 16,
                      ),
                      child: _ReportOptionsSectionTitle(subject: reportSubject),
                    ),
                    SizedBox(height: Responsive.scaledPadding(context, 12)),
                    Padding(
                      padding: Responsive.responsiveSymmetric(
                        context,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._reportOptions.map((option) {
                            final isSelected = option.title == _selectedReason;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: Responsive.scaledPadding(context, 12),
                              ),
                              child: _ReportOptionTile(
                                option: option,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(
                                    () => _selectedReason = option.title,
                                  );
                                },
                              ),
                            );
                          }),
                          SizedBox(height: Responsive.scaledPadding(context, 8)),
                          const _ReportDetailsSectionTitle(),
                          SizedBox(height: Responsive.scaledPadding(context, 8)),
                          _ReportDetailsField(controller: _detailsController),
                          SizedBox(height: Responsive.scaledPadding(context, 12)),
                          const _ReportInfoCard(),
                        ],
                      ),
                    ),
                    SizedBox(height: Responsive.scaledPadding(context, 24)),
                    _ReportFooter(
                      onCancel: () => Navigator.of(context).pop(),
                      onSubmit: () {
                        Navigator.of(context).pop(
                          ReportResult(
                            reason: _selectedReason,
                            details: _detailsController.text.trim(),
                          ),
                        );
                      },
                      isSubmitDisabled: _isOverCharacterLimit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportResult {
  const ReportResult({required this.reason, required this.details});

  final String reason;
  final String details;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorderColor, width: 1.513),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AFB2C36),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.subject, this.onClose});

  final ReportSubject subject;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bool isComment = subject == ReportSubject.comment;
    final String title = isComment ? 'Report Comment' : 'Report Post';
    final iconSize = Responsive.scaledIcon(context, 22.4);
    final containerSize = iconSize * 1.82; // Maintain ratio
    
    return Row(
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFB2C36), Color(0xFFEC003F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Responsive.scaledPadding(context, 11.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FB2C36),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              _headerIconAsset,
              width: iconSize,
              height: iconSize,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        SizedBox(width: Responsive.scaledPadding(context, 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.scaledFont(context, 18),
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.4492,
                ),
              ),
              SizedBox(height: Responsive.scaledPadding(context, 2)),
              Text(
                'Help us understand the issue',
                style: TextStyle(
                  fontSize: Responsive.scaledFont(context, 12),
                  fontWeight: FontWeight.w400,
                  color: _subtitleColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            icon: Icon(
              Icons.close,
              size: Responsive.scaledIcon(context, 20),
              color: _subtitleColor,
            ),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

class _ReportOptionTile extends StatelessWidget {
  const _ReportOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ReportOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? _selectedOptionBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _selectedOptionBorder : _optionBorder,
          width: 1.513,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReportSelectionIndicator(isSelected: isSelected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                          fontFamily: 'Inter',
                          letterSpacing: -0.1504,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _subtitleColor,
                          fontFamily: 'Inter',
                        ),
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
  }
}

class _ReportSelectionIndicator extends StatelessWidget {
  const _ReportSelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final size = Responsive.scaledIcon(context, 12);
    if (isSelected) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC5D0E0),
          width: Responsive.scaledPadding(context, 1.1),
        ),
      ),
    );
  }
}

class _ReportDetailsField extends StatefulWidget {
  const _ReportDetailsField({required this.controller});

  final TextEditingController controller;

  @override
  State<_ReportDetailsField> createState() => _ReportDetailsFieldState();
}

class _ReportDetailsFieldState extends State<_ReportDetailsField> {
  static const int _maxLength = 500; // RPT-3: Max character limit

  @override
  Widget build(BuildContext context) {
    final textLength = widget.controller.text.length;
    final isOverLimit = textLength > _maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 4,
          minLines: 4,
          maxLength: _maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.none, // RPT-3: Allow typing beyond limit for validation
          onChanged: (_) => setState(() {}), // RPT-3: Update state to show error
          decoration: InputDecoration(
            filled: true,
            fillColor: _detailsFieldBackground,
            hintText: 'Provide more context about this report...',
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _detailsHintColor,
              fontFamily: 'Inter',
              letterSpacing: -0.3125,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isOverLimit ? const Color(0xFFE7000B) : _optionBorder, // RPT-3: Red border when over limit
                width: 0.756,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isOverLimit ? const Color(0xFFE7000B) : _selectedOptionBorder, // RPT-3: Red border when over limit
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            counterText: '', // Hide default counter
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isOverLimit ? const Color(0xFFE7000B) : _titleColor, // RPT-3: Red text when over limit
            fontFamily: 'Inter',
            height: 1.4,
          ),
        ),
        // RPT-3: Show character count and error
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOverLimit)
                const Text(
                  'Character limit exceeded',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE7000B),
                    fontFamily: 'Inter',
                  ),
                )
              else
                const SizedBox.shrink(),
              Text(
                '$textLength/$_maxLength',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOverLimit ? const Color(0xFFE7000B) : _subtitleColor,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportInfoCard extends StatelessWidget {
  const _ReportInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.756), // Match Figma padding
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF), // Updated to match Figma blue-50
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E2FF), width: 0.756), // Updated to match Figma blue-100
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: _infoHeadingColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _infoHeadingColor,
                    fontFamily: 'Inter',
                    letterSpacing: -0.1504,
                  ),
                ),
                const SizedBox(height: 4),
                // RPT-5: Updated text to match requirement
                const Text(
                  "Our moderation team will review this report as soon as possible. You'll be notified if further action or input is required.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _infoBodyColor,
                    fontFamily: 'Inter',
                    height: 1.625, // 19.5 / 12
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JmReportSuccessDialog extends StatelessWidget {
  const JmReportSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _successBorder, width: 1.513),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(220, 252, 231, 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/checkIcon.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Submitted',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _successAccent,
                            fontFamily: 'Inter',
                            letterSpacing: -0.3125,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thank you for your feedback',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _successSecondary,
                            fontFamily: 'Inter',
                            letterSpacing: -0.1504,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Your report has been submitted successfully. Our moderation team will review it within 24 hours.You’ll be notified if further action or input is required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _successBody,
                  fontFamily: 'Inter',
                  letterSpacing: -0.3125,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _successInfoBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _successInfoBorder, width: 0.756),
                ),
                child: const Text(
                  'We take community safety seriously and appreciate your help in keeping it safe.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _successInfoText,
                    fontFamily: 'Inter',
                    letterSpacing: -0.1504,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _successAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Inter',
                      letterSpacing: -0.1504,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportActionButton extends StatelessWidget {
  const _ReportActionButton({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    this.onPressed,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final disabledBackgroundColor = backgroundColor == _submitColor
        ? const Color(0xFFE2E8F0) // Gray when submit button is disabled
        : backgroundColor;
    final disabledTextColor = backgroundColor == _submitColor
        ? const Color(0xFF94A3B8) // Muted gray text when submit button is disabled
        : textColor;

    return SizedBox(
      height: 40,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDisabled ? disabledBackgroundColor : backgroundColor,
          side: BorderSide(
            color: borderColor,
            width: borderColor.opacity == 0 ? 0 : 0.756,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: isDisabled ? disabledTextColor : textColor,
          disabledBackgroundColor: disabledBackgroundColor,
          disabledForegroundColor: disabledTextColor,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDisabled ? disabledTextColor : textColor,
            fontFamily: 'Inter',
            letterSpacing: -0.1504,
          ),
        ),
      ),
    );
  }
}

class _ReportOption {
  const _ReportOption({required this.title, required this.description});

  final String title;
  final String description;
}

class _ReportHeaderSection extends StatelessWidget {
  const _ReportHeaderSection({required this.subject, this.onClose});

  final ReportSubject subject;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(254, 242, 242, 1),
            Color.fromRGBO(255, 241, 242, 0.3),
            Colors.white,
          ],
          stops: [0, 0.5, 0.65385], // Match Figma stops
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0x80FFE2E2),
            width: 0.756,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20), // RPT-1: Reduced padding
      child: _ReportHeader(subject: subject, onClose: onClose),
    );
  }
}

class _ReportOptionsSectionTitle extends StatelessWidget {
  const _ReportOptionsSectionTitle({required this.subject});

  final ReportSubject subject;

  @override
  Widget build(BuildContext context) {
    final bool isComment = subject == ReportSubject.comment;
    final String title = isComment
        ? 'Why are you reporting this comment?'
        : 'Why are you reporting this post?';
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _titleColor,
        fontFamily: 'Inter',
        letterSpacing: -0.1504,
      ),
    );
  }
}

class _ReportDetailsSectionTitle extends StatelessWidget {
  const _ReportDetailsSectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Additional details (optional)',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _titleColor,
        fontFamily: 'Inter',
        letterSpacing: -0.1504,
      ),
    );
  }
}

class _ReportFooter extends StatelessWidget {
  const _ReportFooter({
    required this.onCancel,
    required this.onSubmit,
    required this.isSubmitDisabled,
  });

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final bool isSubmitDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(248, 250, 252, 1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: _ReportActionButton(
              label: 'Cancel',
              textColor: _titleColor,
              backgroundColor: Colors.white,
              borderColor: _cancelBorder,
              onPressed: onCancel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ReportActionButton(
              label: 'Submit Report',
              textColor: Colors.white,
              backgroundColor: _submitColor,
              borderColor: Colors.transparent,
              onPressed: isSubmitDisabled ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}