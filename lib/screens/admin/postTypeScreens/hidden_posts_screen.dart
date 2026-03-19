// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../../widgets/pal_bottom_nav_bar.dart';
// import '../widgets/hidden_card.dart';

// class HiddenPostsScreen extends StatelessWidget {
//   const HiddenPostsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC), // Light gray background from Figma
//       appBar: AppBar(
//         title: const Text(
//           'Hidden Post',
//           style: TextStyle(
//             color: Color(0xFF0F172A),
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: false,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172A)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             color: const Color(0xFFF1F5F9), // Matching separator color
//             height: 1,
//           ),
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: const [
//           // Mock Post 1 (Matches Figma)
//           HiddenCard(
//             username: '@surulere_resident',
//             initials: 'SU',
//             timeAgo: '5d ago',
//             location: 'Surulere',
//             category: 'Gist',
//             title: 'The power situation in Surulere is getting ridiculous!',
//             body: 'NEPA (yes I still call it NEPA) has been taking light every day for the past week. 2 hours on, 6 hours off. My generator is working overtime and fuel prices are crazy.',
//             voteCount: 287,
//             commentCount: 1,
//           ),
          
//            // Mock Post 2 (Duplicate to populate list)
//           HiddenCard(
//             username: '@surulere_resident',
//             initials: 'SU',
//             timeAgo: '5d ago',
//             location: 'Surulere',
//             category: 'Gist',
//             title: 'The power situation in Surulere is getting ridiculous!',
//             body: 'NEPA (yes I still call it NEPA) has been taking light every day for the past week. 2 hours on, 6 hours off. My generator is working overtime and fuel prices are crazy.',
//             voteCount: 287,
//             commentCount: 1,
//           ),

//            // Mock Post 3
//           HiddenCard(
//             username: '@surulere_resident',
//             initials: 'SU',
//             timeAgo: '5d ago',
//             location: 'Surulere',
//             category: 'Gist',
//             title: 'The power situation in Surulere is getting ridiculous!',
//             body: 'NEPA (yes I still call it NEPA) has been taking light every day for the past week. 2 hours on, 6 hours off. My generator is working overtime and fuel prices are crazy.',
//             voteCount: 287,
//             commentCount: 1,
//           ),
//         ],
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//         child: PalBottomNavigationBar(
//            // Keeping 'settings' active since we are in admin settings flow
//           active: PalNavDestination.settings,
//           onHomeTap: () {
//             Navigator.of(context).popUntil((route) => route.isFirst);
//             Navigator.of(context).pushReplacementNamed('/home');
//           },
//           onNotificationsTap: () {
//              Navigator.pushNamed(context, '/notifications');
//           },
//           onSettingsTap: () {
//              // Already in settings flow
//           },
//         ),
//       ),
//     );
//   }
// }
// Dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/app_cache.dart';
import '../../../widgets/pal_bottom_nav_bar.dart';
import '../widgets/hidden_card.dart';

class HiddenPostsScreen extends StatefulWidget {
  const HiddenPostsScreen({super.key});

  @override
  State<HiddenPostsScreen> createState() => _HiddenPostsScreenState();
}

class _HiddenPostsScreenState extends State<HiddenPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _hiddenPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHiddenPosts();
  }

  /// Safely extract a list from edge-function response data.
  /// Handles: { success, data: { posts: [...] } }  OR  { posts: [...] }  OR  [...]
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

  Future<void> _fetchHiddenPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getHiddenPosts();
      final posts = _extractList(data, 'posts');
      debugPrint('[HiddenPosts] parsed count: ${posts.length}');

      setState(() {
        _hiddenPosts = posts;
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
          'Hidden Post',
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
                  itemCount: _hiddenPosts.length,
                  itemBuilder: (context, index) {
                    final post = _hiddenPosts[index];

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
                        timeAgo:
                            post['hide_action']?['time_ago'] ?? '',
                        location:
                            location['display_name'] ?? '',
                        category:
                            category['display_name'] ?? '',
                        title: post['title'] ?? '',
                        body: post['content'] ?? '',
                        voteCount: post['net_votes'] ?? 0,
                        commentCount:
                            post['comment_count'] ?? 0,
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: PalBottomNavigationBar(
          active: PalNavDestination.settings,
          onHomeTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacementNamed('/home');
          },
          onNotificationsTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
          onSettingsTap: () {},
        ),
      ),
    );
  }
}