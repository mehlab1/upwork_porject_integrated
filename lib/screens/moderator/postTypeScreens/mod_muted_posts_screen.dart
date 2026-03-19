// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/mod_hidden_card.dart';

// class ModMutedPostsScreen extends StatelessWidget {
//   const ModMutedPostsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Text(
//           'Muted Posts',
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
//             username: "@noisy_neighbor",
//             timeAgo: "1d ago",
//             location: "Austin, TX",
//             category: "Community",
//             body: "WHY IS EVERYONE SO QUIET TODAY?? JUST CHECKING IN!!",
//             voteCount: -5,
//             commentCount: 2,
//             initials: "NN",
//             profileColor: Color(0xFFFFEDD5),
//             type: ModeratorPostType.muted,
//           ),
//            ModHiddenCard(
//             username: "@spam_bot_9000",
//             timeAgo: "2d ago",
//             location: "Internet",
//             category: "Spam",
//             body: "Great deals on sunglasses! Click here! Click here!",
//             voteCount: -20,
//             commentCount: 0,
//             initials: "SB",
//             profileColor: Color(0xFFF1F5F9),
//             type: ModeratorPostType.muted,
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

class ModMutedPostsScreen extends StatefulWidget {
  const ModMutedPostsScreen({super.key});

  @override
  State<ModMutedPostsScreen> createState() => _ModMutedPostsScreenState();
}

class _ModMutedPostsScreenState extends State<ModMutedPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _mutedPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMutedPosts();
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

  Future<void> _fetchMutedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getMutedPosts();
      final posts = _extractList(data, 'posts');
      debugPrint('[MutedPosts] parsed count: ${posts.length}');

      setState(() {
        _mutedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatMuteTime(Map<String, dynamic>? muteAction) {
    if (muteAction == null) return '';

    final isPermanent = muteAction['is_permanent'] == true;

    if (isPermanent) {
      return 'Permanently muted';
    }

    final expiresAt = muteAction['expires_at'];
    if (expiresAt == null) return '';

    return 'Muted until $expiresAt';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Muted Posts',
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
                        'Failed to load muted posts',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF62748E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _fetchMutedPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _mutedPosts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          'No muted posts',
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
                  itemCount: _mutedPosts.length,
                  itemBuilder: (context, index) {
                    final post = _mutedPosts[index];

                    final author = post['user'] ?? post['author'] ?? {};
                    final location = post['location'] ?? {};
                    final category = post['category'] ?? {};
                    final muteAction = post['mute_action'];

                    final username = author['username'] ?? 'unknown';
                    final initials = username.isNotEmpty
                        ? username[0].toUpperCase()
                        : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ModHiddenCard(
                        username: '@$username',
                        initials: initials,
                        timeAgo: _formatMuteTime(muteAction),
                        location:
                            location['display_name'] ?? '',
                        category:
                            category['display_name'] ?? '',
                        title: post['title'] ?? '',
                        body: post['content'] ?? '',
                        voteCount: post['net_votes'] ?? 0,
                        commentCount:
                            post['comment_count'] ?? 0,
                        profileColor: const Color(0xFFFFEDD5),
                        type: ModeratorPostType.muted,
                      ),
                    );
                  },
                ),
    );
  }
}

