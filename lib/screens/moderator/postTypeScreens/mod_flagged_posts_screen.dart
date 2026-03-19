import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mod_hidden_card.dart';

class ModFlaggedPostsScreen extends StatelessWidget {
  const ModFlaggedPostsScreen({super.key});

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
           ModHiddenCard(
            username: "@suspicious_user",
            timeAgo: "30m ago",
            location: "Unknown",
            category: "Marketplace",
            title: "Free iPhones!",
            body: "Click this link to claim your free iPhone now! 100% legit.",
            voteCount: 0,
            commentCount: 0,
            initials: "SU",
            profileColor: Color(0xFFFFEDD5),
            type: ModeratorPostType.flagged,
          ),
           ModHiddenCard(
            username: "@political_debate",
            timeAgo: "1h ago",
            location: "Washington, DC",
            category: "Politics",
            title: "Controversial Opinion",
            body: "Here is a highly controversial opinion that might be misinformation.",
            voteCount: 10,
            commentCount: 100,
            initials: "PD",
            profileColor: Color(0xFFE0E7FF),
            type: ModeratorPostType.flagged,
          ),
        ],
      ),
    );
  }
}
