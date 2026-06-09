import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

/// Delete-account confirmation dialog.
class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({
    super.key,
    required this.reasonController,
    required this.onDelete,
    required this.onCancel,
  });

  final TextEditingController reasonController;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.759),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: svg.SvgPicture.asset(
                    'assets/settings/settingsdelete.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Your Account?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A),
                    fontFamily: 'Inter',
                    letterSpacing: -0.4395,
                    height: 28 / 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'This action will permanently delete your account.\nOnce deleted, your data cannot be recovered.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF717182),
              fontFamily: 'Inter',
              letterSpacing: -0.1504,
              height: 20 / 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          const Text(
            'Why are you leaving? (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A0A0A),
              fontFamily: 'Inter',
              letterSpacing: -0.1504,
              height: 14 / 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reasonController,
            minLines: 3,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: "Tell us why you're deleting...",
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF717182),
                fontFamily: 'Inter',
                letterSpacing: -0.3125,
                height: 24 / 16,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F3F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0),
                  width: 0.759,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0),
                  width: 0.759,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0),
                  width: 0.759,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onDelete,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE7000B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.black.withOpacity(0.1),
                  width: 0.759,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.759,
                  vertical: 8.759,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
