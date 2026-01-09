import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hidden_card.dart';

class WarnedPostsScreen extends StatelessWidget {
  const WarnedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Warned Posts',
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
            username: "@tech_enthusiast",
            timeAgo: "2h ago",
            location: "San Francisco, CA",
            category: "Tech Talk",
            title: "Future of AI",
            body: "The rapid advancement of AI is both exciting and terrifying. We need to be careful about regulations. #AI #Tech",
            voteCount: 156,
            commentCount: 23,
            initials: "TE",
            profileColor: Color(0xFFE0F2FE),
            type: AdminPostType.warned,
          ),
           HiddenCard(
            username: "@crypto_king",
            timeAgo: "5h ago",
            location: "New York, NY",
            category: "Finance",
            title: "Bitcoin to the moon! 🚀",
            body: "Don't miss out on this opportunity! Buy now before it's too late. Not financial advice but... you know.",
            voteCount: 89,
            commentCount: 45,
            initials: "CK",
            profileColor: Color(0xFFFEF3C7),
            type: AdminPostType.warned,
          ),
        ],
      ),
    );
  }
}
