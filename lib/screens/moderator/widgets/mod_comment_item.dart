import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ModCommentItem extends StatelessWidget {
  const ModCommentItem({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.body,
    required this.voteCount,
    this.initials = 'U',
    this.profileColor = const Color(0xFFF1F5F9),
  });

  final String username;
  final String timeAgo;
  final String body;
  final int voteCount;
  final String initials;
  final Color profileColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with Border
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: profileColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
            ),
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF314158),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Name + Time)
                Row(
                  children: [
                    Text(
                      username.startsWith('@') ? username : '@$username',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.more_horiz, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
                
                const SizedBox(height: 4),

                // Body Text
                _buildBodyText(context, body),

                const SizedBox(height: 8),

                // Footer: Votes
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFF45556C)),
                    const SizedBox(width: 6),
                    Text(
                      '$voteCount',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF314158),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF45556C)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyText(BuildContext context, String text) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r"(@\w+)|(\s+)|([^\s@]+)");
    final matches = exp.allMatches(text);

    for (final m in matches) {
      final String word = m.group(0)!;
      if (word.startsWith('@')) {
        spans.add(
          TextSpan(
            text: word,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563EB),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showMentionPopup(context, word);
              },
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF334155),
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _showMentionPopup(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEFF6FF),
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mentioned User',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                username,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF334155),
                  elevation: 0,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
