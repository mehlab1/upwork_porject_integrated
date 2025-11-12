import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pal_app/services/post_service.dart';
import 'package:pal_app/widgets/error_dialog.dart';

const _headerIconAsset = 'assets/feedPage/reportIcon.svg';
const _selectedIndicatorAsset = 'assets/images/checkIcon.svg';
const _infoIconAsset = 'assets/images/infoIcon.svg';

const _cardBorderColor = Color(0xFFFFC9C9);
const _selectedOptionBackground = Color.fromRGBO(254, 242, 242, 0.5);
const _selectedOptionBorder = Color(0xFFFFC9C9);
const _optionBorder = Color(0xFFE2E8F0);
const _titleColor = Color(0xFF0F172B);
const _subtitleColor = Color(0xFF45556C);
const _detailsFieldBackground = Color(0xFFF3F3F5);
const _detailsHintColor = Color(0xFFA2A2B3);
const _infoBackground = Color(0xFFEFF4FF);
const _infoBorder = Color(0xFFD0E2FF);
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

class ReportPostSheet extends StatefulWidget {
  const ReportPostSheet({super.key, this.postId});

  final String? postId;

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  final TextEditingController _detailsController = TextEditingController();
  final PostService _postService = PostService();
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // Map UI reasons to backend reasons
  String _mapReasonToBackend(String uiReason) {
    switch (uiReason) {
      case 'Spam or misleading':
        return 'spam';
      case 'Harassment or hate speech':
        return 'harassment'; // Could also be 'hate_speech'
      case 'Inappropriate content':
        return 'inappropriate_content';
      case 'False information':
        return 'misinformation';
      case 'Other':
        return 'other';
      default:
        return 'other';
    }
  }

  Future<void> _submitReport() async {
    // If postId is null, this is likely for comment reporting which we're not implementing yet
    if (widget.postId == null) {
      Navigator.of(context).pop(
        ReportResult(
          reason: _selectedReason,
          details: _detailsController.text.trim(),
          success: true,
        ),
      );
      return;
    }

    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final mappedReason = _mapReasonToBackend(_selectedReason);
      final description = _detailsController.text.trim();

      final result = await _postService.reportPost(
        postId: widget.postId!,
        reason: mappedReason,
        description: description.isNotEmpty ? description : null,
      );

      if (result['success'] == true) {
        // Show success dialog
        if (mounted) {
          Navigator.of(context).pop(
            ReportResult(
              reason: _selectedReason,
              details: description,
              success: true,
            ),
          );
        }
      } else {
        // Show error using ErrorDialog
        if (mounted) {
          await showErrorDialog(
            context,
            errorMessage: result['error'] ?? 'Failed to submit report',
          );
        }
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        await showErrorDialog(
          context,
          errorMessage: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomInset > 0 ? bottomInset : 16,
          top: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: _ReportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ReportHeaderSection(),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(left: 30),
                      child: _ReportOptionsSectionTitle(),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(30, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._reportOptions.map((option) {
                            final isSelected = option.title == _selectedReason;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
                          const SizedBox(height: 8),
                          const _ReportDetailsSectionTitle(),
                          const SizedBox(height: 8),
                          _ReportDetailsField(controller: _detailsController),
                          const SizedBox(height: 16),
                          const _ReportInfoCard(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ReportFooter(
                      onCancel: () => Navigator.of(context).pop(),
                      onSubmit: _submitReport,
                      isSubmitting: _isSubmitting,
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
  const ReportResult({required this.reason, required this.details, this.success = false});

  final String reason;
  final String details;
  final bool success;
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3366), Color(0xFFFF1744)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4DFB2C36),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              _headerIconAsset,
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Report Post',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.45,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Help us understand the issue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _subtitleColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                ),
              ),
            ],
          ),
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
    if (isSelected) {
      // Use local asset instead of network URL to avoid connection refused errors
      return SvgPicture.asset(
        _selectedIndicatorAsset,
        width: 12,
        height: 12,
        placeholderBuilder: (_) => Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
        ),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC5D0E0), width: 1.1),
      ),
    );
  }
}

class _ReportDetailsField extends StatelessWidget {
  const _ReportDetailsField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      minLines: 4,
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
          borderSide: const BorderSide(color: _optionBorder, width: 0.756),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _selectedOptionBorder, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _titleColor,
        fontFamily: 'Inter',
        height: 1.4,
      ),
    );
  }
}

class _ReportInfoCard extends StatelessWidget {
  const _ReportInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _infoBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _infoBorder, width: 0.756),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use Flutter's built-in info icon to avoid network requests
          const Icon(
            Icons.info,
            color: _infoHeadingColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _infoHeadingColor,
                    fontFamily: 'Inter',
                    letterSpacing: -0.1504,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Our moderation team will review this report within 24 hours. You'll receive a notification once we've taken action.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _infoBodyColor,
                    fontFamily: 'Inter',
                    height: 1.6,
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

class ReportSuccessDialog extends StatelessWidget {
  const ReportSuccessDialog({super.key});

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
                'Your report has been submitted successfully. Our moderation team will review it within 24 hours.',
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
    required this.onPressed,
    this.isSubmitting = false,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onPressed;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: borderColor,
            width: borderColor.opacity == 0 ? 0 : 0.756,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: textColor,
        ),
        onPressed: isSubmitting ? null : onPressed,
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
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
  const _ReportHeaderSection();

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
          stops: [0, 0.5, 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: const Color(0x80FFE2E2), width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: _ReportHeader(),
    );
  }
}

class _ReportOptionsSectionTitle extends StatelessWidget {
  const _ReportOptionsSectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Why are you reporting this post?',
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
  const _ReportFooter({required this.onCancel, required this.onSubmit, this.isSubmitting = false});

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final bool isSubmitting;

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
              onPressed: onSubmit,
              isSubmitting: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}
