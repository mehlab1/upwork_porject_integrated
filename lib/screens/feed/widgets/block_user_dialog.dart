import 'package:flutter/material.dart';

class BlockUserResult {
  const BlockUserResult({required this.confirmed});

  final bool confirmed;
}

class BlockUserDialog extends StatelessWidget {
  const BlockUserDialog({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF0F172B),
              width: 0.76,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Block ${username.startsWith('@') ? username : '@$username'}?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172B),
                      fontFamily: 'Inter',
                      letterSpacing: -0.3125,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to block ${username.startsWith('@') ? username : '@$username'}? They won\'t be able to interact with your posts. You also won\'t see their content. Exception: Platform-pinned posts remain visible to everyone.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF45556C),
                      fontFamily: 'Inter',
                      letterSpacing: -0.15,
                      height: 1.57,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider
              Container(
                height: 0.756,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 12.751),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                          width: 0.756,
                        ),
                        foregroundColor: const Color(0xFF0F172B),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8.756),
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        const BlockUserResult(confirmed: false),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172B),
                          letterSpacing: -0.15,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        const BlockUserResult(confirmed: true),
                      ),
                      child: const Text(
                        'Block',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.15,
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

