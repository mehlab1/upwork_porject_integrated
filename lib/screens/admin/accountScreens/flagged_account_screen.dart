import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hidden_card.dart';

class FlaggedAccountScreen extends StatelessWidget {
  const FlaggedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Flagged Posts',
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
        padding: const EdgeInsets.all(16),
        children: const [
           HiddenCard(
            username: "@troll_account",
            timeAgo: "4h ago",
            location: "Nowhere",
            category: "General",
            body: "This is offensive content that violates community guidelines.",
            voteCount: -42,
            commentCount: 12,
            initials: "TA",
            profileColor: Color(0xFFFEE2E2),
            type: AdminPostType.flagged,
          ),
           HiddenCard(
            username: "@hater_123",
            timeAgo: "6h ago",
            location: "Basement",
            category: "Rant",
            body: "I hate everything about this app and everyone on it.",
            voteCount: -15,
            commentCount: 5,
            initials: "HA",
            profileColor: Color(0xFFF1F5F9),
            type: AdminPostType.flagged,
          ),
        ],
      ),
    );
  }
}
