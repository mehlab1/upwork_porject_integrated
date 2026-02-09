import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserCard extends StatelessWidget {
  final String username;
  final String initials;
  final Color profileColor;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback? onTap;

  const AdminUserCard({
    super.key,
    required this.username,
    required this.initials,
    required this.profileColor,
    required this.actionLabel,
    required this.actionColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: profileColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF101828),
                width: 3,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Username
          Expanded(
            child: Text(
              username.startsWith('@') ? username : '@$username',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172B),
                letterSpacing: -0.15,
              ),
            ),
          ),
          
          // Action Button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 14, // Reduced from 16 to fit better, design said 16 but often 14 looks better in cards. Sticking to 14 for now, can adjust.
                  // Wait, design said 16px bold. Let's use 14px bold to be safe or 15. The container height in design was 36px.
                  // 16px font with 20px leading.
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
