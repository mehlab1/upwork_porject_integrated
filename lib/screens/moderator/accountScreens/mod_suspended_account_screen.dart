import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/moderator_user_card.dart';

class ModSuspendedAccountScreen extends StatelessWidget {
  const ModSuspendedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Suspended Account',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172B)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172B)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: const [
          ModeratorUserCard(
            username: "@foodie_naija",
            initials: "FN",
            profileColor: Color(0xFFE0F2FE),
            actionLabel: "Suspended",
            actionColor: Color(0xFF94292F),
          ),
          ModeratorUserCard(
            username: "@tech_bro_lagos",
            initials: "TB",
            profileColor: Color(0xFFFEF3C7),
            actionLabel: "Suspended",
            actionColor: Color(0xFF94292F),
          ),
          ModeratorUserCard(
            username: "@unknown_user",
            initials: "UU",
            profileColor: Color(0xFFF1F5F9),
            actionLabel: "Suspended",
            actionColor: Color(0xFF94292F),
          ),
        ],
      ),
    );
  }
}
