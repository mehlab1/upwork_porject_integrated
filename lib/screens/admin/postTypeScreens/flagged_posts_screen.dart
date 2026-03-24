// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/hidden_card.dart';

// class FlaggedPostsScreen extends StatelessWidget {
//   const FlaggedPostsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Text(
//           'Flagged Posts',
//           style: GoogleFonts.inter(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: const Color(0xFF0F172B),
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         iconTheme: const IconThemeData(color: Color(0xFF0F172B)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172B)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             color: const Color(0xFFF1F5F9),
//             height: 1,
//           ),
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: const [
//            HiddenCard(
//             username: "@suspicious_user",
//             timeAgo: "30m ago",
//             location: "Unknown",
//             category: "Marketplace",
//             title: "Free iPhones!",
//             body: "Click this link to claim your free iPhone now! 100% legit.",
//             voteCount: 0,
//             commentCount: 0,
//             initials: "SU",
//             profileColor: Color(0xFFFFEDD5),
//             type: AdminPostType.flagged,
//           ),
//            HiddenCard(
//             username: "@political_debate",
//             timeAgo: "1h ago",
//             location: "Washington, DC",
//             category: "Politics",
//             title: "Controversial Opinion",
//             body: "Here is a highly controversial opinion that might be misinformation.",
//             voteCount: 10,
//             commentCount: 100,
//             initials: "PD",
//             profileColor: Color(0xFFE0E7FF),
//             type: AdminPostType.flagged,
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/app_cache.dart';
import '../widgets/hidden_card.dart';

class FlaggedPostsScreen extends StatefulWidget {
  const FlaggedPostsScreen({super.key});

  @override
  State<FlaggedPostsScreen> createState() => _FlaggedPostsScreenState();
}

class _FlaggedPostsScreenState extends State<FlaggedPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _flaggedPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFlaggedPosts();
  }

  Future<void> _fetchFlaggedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getFlaggedPosts();
      final posts = (data['posts'] as List?) ?? (data.values.whereType<List>().firstOrNull ?? []);
      debugPrint('[FlaggedPosts] parsed count: ${posts.length}');

      setState(() {
        _flaggedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Flagged Posts',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Color(0xFF0F172A)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flaggedPosts.length,
                  itemBuilder: (context, index) {
                    final post = _flaggedPosts[index];

                    final author = post['author'] ?? {};
                    final location = post['location'] ?? {};
                    final category = post['category'] ?? {};

                    final username = author['username'] ?? 'unknown';
                    final initials = username.isNotEmpty
                        ? username[0].toUpperCase()
                        : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: HiddenCard(
                        username: '@$username',
                        initials: initials,
                        timeAgo:
                            post['flag_action']?['time_ago'] ?? '',
                        location:
                            location['display_name'] ?? '',
                        category:
                            category['display_name'] ?? '',
                        title: post['title'] ?? '',
                        body: post['content'] ?? '',
                        voteCount: post['moderation_score'] ?? 0,
                        commentCount: post['comment_count'] ?? 0,
                        type: AdminPostType.flagged,
                      ),
                    );
                  },
                ),
    );
  }
}


