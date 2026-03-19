import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/moderator_user_card.dart';

class ModBannedAccountScreen extends StatelessWidget {
  const ModBannedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Banned Account',
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
            username: "@spammer_bot_1",
            initials: "SB",
            profileColor: Color(0xFFFFEDD5),
            actionLabel: "Banned",
            actionColor: Color(0xFFE7000B),
          ),
          ModeratorUserCard(
            username: "@malicious_actor",
            initials: "MA",
            profileColor: Color(0xFFFEE2E2),
            actionLabel: "Banned",
            actionColor: Color(0xFFE7000B),
          ),
        ],
      ),
    );
  }
}
