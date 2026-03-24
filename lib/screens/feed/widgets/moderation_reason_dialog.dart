import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result model for moderation reason dialog
class ModerationReasonResult {
  const ModerationReasonResult({required this.reason, this.details});

  final String reason;
  final String? details;
}

/// A reusable dialog for moderation actions that require a reason selection.
/// Used by warn, mute, hide, escalate, and flag actions.
class ModerationReasonDialog extends StatefulWidget {
  const ModerationReasonDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.actionColor = const Color(0xFFE7000B),
    this.showReasonPicker = true,
    this.showDetailsField = true,
    this.reasonRequired = true,
    this.detailsHint = 'Add additional details (optional)',
    this.detailsRequired = false,
    this.detailsLabel = 'Details',
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final Color actionColor;
  final bool showReasonPicker;
  final bool showDetailsField;
  final bool reasonRequired;
  final String detailsHint;
  final bool detailsRequired;
  final String detailsLabel;

  @override
  State<ModerationReasonDialog> createState() =>
      _ModerationReasonDialogState();
}

class _ModerationReasonDialogState extends State<ModerationReasonDialog> {
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedReason;

  static const _reasons = [
    _ReasonItem('Harassment', 'harassment'),
    _ReasonItem('Spam', 'spam'),
    _ReasonItem('Hate speech', 'hate_speech'),
    _ReasonItem('Violence', 'violence'),
    _ReasonItem('Inappropriate content', 'inappropriate_content'),
    _ReasonItem('Misinformation', 'misinformation'),
    _ReasonItem('Copyright violation', 'copyright_violation'),
    _ReasonItem('Scam', 'scam'),
    _ReasonItem('Other', 'other'),
  ];

  bool get _canSubmit {
    if (widget.showReasonPicker && widget.reasonRequired && _selectedReason == null) {
      return false;
    }
    if (widget.detailsRequired && _detailsController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172B),
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF62748E),
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Reason picker
              if (widget.showReasonPicker) ...[
                const Text(
                  'Select a reason',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF314158),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reasons.map((reason) {
                    final isSelected = _selectedReason == reason.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedReason = reason.value;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFEF2F2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFC9C9)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          reason.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFFE7000B)
                                : const Color(0xFF45556C),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Details field
              if (widget.showDetailsField) ...[
                Text(
                  widget.detailsLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF314158),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  maxLength: 500,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(500),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: widget.detailsHint,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFA2A2B3),
                      fontFamily: 'Inter',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F3F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172B),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF314158),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Submit button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSubmit
                          ? () {
                              Navigator.of(context).pop(
                                ModerationReasonResult(
                                  reason: _selectedReason ?? 'other',
                                  details: _detailsController.text
                                          .trim()
                                          .isNotEmpty
                                      ? _detailsController.text.trim()
                                      : null,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.actionColor,
                        disabledBackgroundColor:
                            widget.actionColor.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.actionLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonItem {
  const _ReasonItem(this.label, this.value);

  final String label;
  final String value;
}
