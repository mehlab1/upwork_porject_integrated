// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/mod_hidden_card.dart';

// class ModWarnedPostsScreen extends StatelessWidget {
//   const ModWarnedPostsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Text(
//           'Warned Posts',
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
//            ModHiddenCard(
//             username: "@tech_enthusiast",
//             timeAgo: "2h ago",
//             location: "San Francisco, CA",
//             category: "Tech Talk",
//             title: "Future of AI",
//             body: "The rapid advancement of AI is both exciting and terrifying. We need to be careful about regulations. #AI #Tech",
//             voteCount: 156,
//             commentCount: 23,
//             initials: "TE",
//             profileColor: Color(0xFFE0F2FE),
//             type: ModeratorPostType.warned,
//           ),
//            ModHiddenCard(
//             username: "@crypto_king",
//             timeAgo: "5h ago",
//             location: "New York, NY",
//             category: "Finance",
//             title: "Bitcoin to the moon! 🚀",
//             body: "Don't miss out on this opportunity! Buy now before it's too late. Not financial advice but... you know.",
//             voteCount: 89,
//             commentCount: 45,
//             initials: "CK",
//             profileColor: Color(0xFFFEF3C7),
//             type: ModeratorPostType.warned,
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/app_cache.dart';
import '../widgets/mod_hidden_card.dart';

class ModWarnedPostsScreen extends StatefulWidget {
  const ModWarnedPostsScreen({super.key});

  @override
  State<ModWarnedPostsScreen> createState() => _ModWarnedPostsScreenState();
}

class _ModWarnedPostsScreenState extends State<ModWarnedPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _warnedPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWarnedPosts();
  }

  /// Safely extract a list from edge-function response data.
  List<dynamic> _extractList(dynamic data, String key) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'] ?? data;
      if (inner is Map && inner.containsKey(key)) {
        return (inner[key] as List?) ?? [];
      }
      return (data[key] as List?) ?? [];
    }
    return [];
  }

  Future<void> _fetchWarnedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getWarnedPosts();
      final posts = _extractList(data, 'posts');
      debugPrint('[WarnedPosts] parsed count: ${posts.length}');

      setState(() {
        _warnedPosts = posts;
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Color(0xFF0F172B)),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFF62748E)),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load warned posts',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF62748E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _fetchWarnedPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _warnedPosts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          'No warned posts',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF62748E),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _warnedPosts.length,
                  itemBuilder: (context, index) {
                    final post = _warnedPosts[index];

                    final author = post['user'] ?? post['author'] ?? {};
                    final location = post['location'] ?? {};
                    final category = post['category'] ?? {};

                    final username = author['username'] ?? 'unknown';
                    final initials = username.isNotEmpty
                        ? username[0].toUpperCase()
                        : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ModHiddenCard(
                        username: '@$username',
                        initials: initials,
                        timeAgo:
                            post['warning_action']?['time_ago'] ?? '',
                        location:
                            location['display_name'] ?? '',
                        category:
                            category['display_name'] ?? '',
                        title: post['title'] ?? '',
                        body: post['content'] ?? '',
                        voteCount: post['net_votes'] ?? 0,
                        commentCount:
                            post['comment_count'] ?? 0,
                        profileColor: const Color(0xFFE0F2FE),
                        type: ModeratorPostType.warned,
                      ),
                    );
                  },
                ),
    );
  }
}
