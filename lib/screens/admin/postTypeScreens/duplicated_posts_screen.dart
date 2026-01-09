import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hidden_card.dart';

class DuplicatedPostsScreen extends StatelessWidget {
  const DuplicatedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Duplicated Posts',
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
            username: "@news_aggregator",
            timeAgo: "10m ago",
            location: "Global",
            category: "News",
            title: "Breaking News: Major Event",
            body: "Details about the major event happening right now...",
            voteCount: 2,
            commentCount: 0,
            initials: "NA",
            profileColor: Color(0xFFDBEAFE),
            type: AdminPostType.duplicated,
          ),
           HiddenCard(
            username: "@reposter_101",
            timeAgo: "15m ago",
            location: "Global",
            category: "News",
            title: "Breaking News: Major Event",
            body: "Details about the major event happening right now...",
            voteCount: 1,
            commentCount: 1,
            initials: "RP",
            profileColor: Color(0xFFF1F5F9),
            type: AdminPostType.duplicated,
          ),
        ],
      ),
    );
  }
}
