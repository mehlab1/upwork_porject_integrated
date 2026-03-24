// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/hidden_card.dart';

// class ReportedPostsScreen extends StatelessWidget {
//   const ReportedPostsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Text(
//           'Reported Posts',
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
//             username: "@troll_account",
//             timeAgo: "4h ago",
//             location: "Nowhere",
//             category: "General",
//             body: "This is offensive content that violates community guidelines.",
//             voteCount: -42,
//             commentCount: 12,
//             initials: "TA",
//             profileColor: Color(0xFFFEE2E2),
//             type: AdminPostType.reported,
//           ),
//            HiddenCard(
//             username: "@hater_123",
//             timeAgo: "6h ago",
//             location: "Basement",
//             category: "Rant",
//             body: "I hate everything about this app and everyone on it.",
//             voteCount: -15,
//             commentCount: 5,
//             initials: "HA",
//             profileColor: Color(0xFFF1F5F9),
//             type: AdminPostType.reported,
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/app_cache.dart';
import '../widgets/hidden_card.dart';

class ReportedPostsScreen extends StatefulWidget {
  const ReportedPostsScreen({super.key});

  @override
  State<ReportedPostsScreen> createState() => _ReportedPostsScreenState();
}

class _ReportedPostsScreenState extends State<ReportedPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _reportedPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReportedPosts();
  }

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

  Future<void> _fetchReportedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getReportedPosts();
      final posts = _extractList(data, 'posts');
      debugPrint('[ReportedPosts] parsed count: ${posts.length}');

      setState(() {
        _reportedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _buildReportInfo(Map<String, dynamic> post) {
    final count = post['pending_report_count'] ?? 0;
    return '$count pending report${count == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Reported Posts',
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
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reportedPosts.length,
                  itemBuilder: (context, index) {
                    final post = _reportedPosts[index];

                    final author = post['user'] ?? post['author'] ?? {};
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
                        timeAgo: _buildReportInfo(post),
                        location: location['display_name'] ?? '',
                        category: category['display_name'] ?? '',
                        title: post['title'] ?? '',
                        body: post['content'] ?? '',
                        voteCount: post['net_votes'] ?? 0,
                        commentCount: post['comment_count'] ?? 0,
                        profileColor: const Color(0xFFFEE2E2),
                        type: AdminPostType.reported,
                      ),
                    );
                  },
                ),
    );
  }
}

