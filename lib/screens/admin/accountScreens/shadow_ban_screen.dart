import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/admin_user_card.dart';

class ShadowBanScreen extends StatelessWidget {
  const ShadowBanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Shadow Banned Account',
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
          AdminUserCard(
            username: "@quiet_troll",
            initials: "QT",
            profileColor: Color(0xFFF3E8FF),
            actionLabel: "Shadow Ban",
            actionColor: Color(0xFF0F172B),
          ),
          AdminUserCard(
            username: "@invisible_spammer",
            initials: "IS",
            profileColor: Color(0xFFE0E7FF),
            actionLabel: "Shadow Ban",
            actionColor: Color(0xFF0F172B),
          ),
        ],
      ),
    );
  }
}
