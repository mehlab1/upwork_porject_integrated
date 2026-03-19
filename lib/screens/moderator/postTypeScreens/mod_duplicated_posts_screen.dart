// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/mod_hidden_card.dart';

// class ModDuplicatedPostsScreen extends StatelessWidget {
//   const ModDuplicatedPostsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Text(
//           'Duplicated Posts',
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
//             username: "@news_aggregator",
//             timeAgo: "10m ago",
//             location: "Global",
//             category: "News",
//             title: "Breaking News: Major Event",
//             body: "Details about the major event happening right now...",
//             voteCount: 2,
//             commentCount: 0,
//             initials: "NA",
//             profileColor: Color(0xFFDBEAFE),
//             type: ModeratorPostType.duplicated,
//           ),
//            ModHiddenCard(
//             username: "@reposter_101",
//             timeAgo: "15m ago",
//             location: "Global",
//             category: "News",
//             title: "Breaking News: Major Event",
//             body: "Details about the major event happening right now...",
//             voteCount: 1,
//             commentCount: 1,
//             initials: "RP",
//             profileColor: Color(0xFFF1F5F9),
//             type: ModeratorPostType.duplicated,
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

class ModDuplicatedPostsScreen extends StatefulWidget {
  const ModDuplicatedPostsScreen({super.key});

  @override
  State<ModDuplicatedPostsScreen> createState() => _ModDuplicatedPostsScreenState();
}

class _ModDuplicatedPostsScreenState extends State<ModDuplicatedPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _duplicatedPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDuplicatedPosts();
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

  Future<void> _fetchDuplicatedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getDuplicatedPosts();
      final posts = _extractList(data, 'posts');
      debugPrint('[DuplicatedPosts] parsed count: ${posts.length}');

      setState(() {
        _duplicatedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _buildDuplicateInfo(Map<String, dynamic>? originalPost) {
    if (originalPost == null) return '';

    final originalTitle = originalPost['title'] ?? '';
    return 'Duplicate of: $originalTitle';
  }

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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load duplicated posts',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchDuplicatedPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _duplicatedPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.content_copy_outlined, color: Color(0xFF94A3B8), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No duplicated posts',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _duplicatedPosts.length,
                  itemBuilder: (context, index) {
                    final post = _duplicatedPosts[index];

                    final author = post['user'] ?? post['author'] ?? {};
                    final location = post['location'] ?? {};
                    final category = post['category'] ?? {};
                    final originalPost = post['original_post'];

                    final username = author['username'] ?? 'unknown';
                    final initials = username.isNotEmpty
                        ? username[0].toUpperCase()
                        : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ModHiddenCard(
                        username: '@$username',
                        initials: initials,
                        timeAgo: _buildDuplicateInfo(originalPost),
                        location: location['display_name'] ?? '',
                        category: category['display_name'] ?? '',
                        title: post['title'] ?? '',
                        body: post['content'] ?? '',
                        voteCount: post['net_votes'] ?? 0,
                        commentCount: post['comment_count'] ?? 0,
                        profileColor: const Color(0xFFDBEAFE),
                        type: ModeratorPostType.duplicated,
                      ),
                    );
                  },
                ),
    );
  }
}

