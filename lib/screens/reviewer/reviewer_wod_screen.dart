import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_cache.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import 'reviewer_settings_screen.dart';
import '../feed/widgets/post_card.dart';

class ReviewerWodScreen extends StatefulWidget {
  const ReviewerWodScreen({super.key});

  @override
  State<ReviewerWodScreen> createState() => _ReviewerWodScreenState();
}

class _ReviewerWodScreenState extends State<ReviewerWodScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _pinnedWod;
  List<Map<String, dynamic>> _nominatedWod = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWodDashboard();
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';
    if (raw is num) {
      final seconds = raw.toInt();
      if (seconds < 60) return 'just now';
      if (seconds < 3600) return '${seconds ~/ 60}m ago';
      if (seconds < 86400) return '${seconds ~/ 3600}h ago';
      return '${seconds ~/ 86400}d ago';
    }
    if (raw is String) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inSeconds < 60) return 'just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      }
      return raw;
    }
    final seconds = int.tryParse(raw.toString()) ?? 0;
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return '${seconds ~/ 60}m ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ago';
    return '${seconds ~/ 86400}d ago';
  }

  Future<void> _fetchWodDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getWodDashboard();
      debugPrint('[ReviewerWOD] raw: $data');

      Map<String, dynamic>? pinned;
      List<Map<String, dynamic>> nominated = [];

      if (data.isNotEmpty) {
        final pinnedRaw = data['pinned_wod'];
        if (pinnedRaw is Map && pinnedRaw.isNotEmpty) {
          pinned = Map<String, dynamic>.from(pinnedRaw);
        }

        final nominatedRaw = data['nominated_wod'];
        if (nominatedRaw is List) {
          nominated = List<Map<String, dynamic>>.from(
            nominatedRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      debugPrint('[ReviewerWOD] pinned: $pinned');
      debugPrint('[ReviewerWOD] nominated count: ${nominated.length}');

      setState(() {
        _pinnedWod = pinned;
        _nominatedWod = nominated;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ReviewerWOD] error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(
                        3.14159,
                      ), // Flip horizontally
                      child: SvgPicture.asset(
                        'assets/adminIcons/adminSettings/Icon-2.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Wahala of the day (WOD)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 36 / 20, // line-height: 36px
                        letterSpacing: 0.07,
                        color: Color(0xFF0F172B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFF62748E)),
                              const SizedBox(height: 12),
                              const Text(
                                'Failed to load WOD',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF62748E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _fetchWodDashboard,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(15, 28, 15, 120),
                          child: _buildPostsContent(),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PalBottomNavigationBar(
        active: PalNavDestination.settings,
        onHomeTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context).pushReplacementNamed('/home');
        },
        onNotificationsTap: () {
          Navigator.pushNamed(context, '/notifications');
        },
        onSettingsTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ReviewerSettingsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildPostsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxWidth = 600.0;
        final cardWidth = availableWidth.clamp(360.0, maxWidth);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned WOD Section
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'PINNED WOD',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                      height: 16 / 14, // line-height: 16px
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_pinnedWod != null)
              _buildPostCardFromData(_pinnedWod!, variant: PostCardVariant.wod)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No WOD post available',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            // Nominated WOD Posts Section
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'NOMINATED WOD POSTS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                      height: 16 / 14, // line-height: 16px
                      letterSpacing: 0.6,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_nominatedWod.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No nominated posts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              )
            else
              ..._nominatedWod.asMap().entries.map((entry) {
                final idx = entry.key;
                final nom = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: idx < _nominatedWod.length - 1 ? 24 : 0),
                  child: _buildNominatedPostCard(nom),
                );
              }),

          ],
        );
      },
    );
  }

  /// Build card from pinned_wod data
  Widget _buildPostCardFromData(Map<String, dynamic> post, {PostCardVariant variant = PostCardVariant.wod}) {
    final author = post['author'];
    final username = author is Map
        ? (author['username'] ?? '').toString()
        : (post['username'] ?? '').toString();
    final initials = username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : (username.isNotEmpty ? username[0].toUpperCase() : 'U');

    final location = post['location'] is Map
        ? (post['location']['display_name'] ?? '')
        : (post['location_name'] ?? post['location']?.toString() ?? '');
    final category = post['category'] is Map
        ? (post['category']['display_name'] ?? '')
        : (post['category_name'] ?? post['category']?.toString() ?? '');

    final title = (post['title'] ?? post['post_title'] ?? '').toString();
    final content = (post['content'] ?? post['post_content'] ?? '').toString();

    return _buildPostCard(
      username: username.startsWith('@') ? username : '@$username',
      timeAgo: _formatTimeAgo(post['time_ago'] ?? post['wod_date'] ?? post['created_at']),
      initials: initials,
      location: location,
      topic: category,
      title: title.isNotEmpty ? title : content,
      body: title.isNotEmpty ? content : '',
      voteCount: (post['net_score'] as num?)?.toInt() ?? (post['post_upvote_count'] as num?)?.toInt() ?? 0,
      commentCount: (post['comment_count'] as num?)?.toInt() ?? 0,
      variant: variant,
    );
  }

  /// Build card from nominated_wod item
  Widget _buildNominatedPostCard(Map<String, dynamic> nom) {
    // Use post author info (not nominator)
    final username = (nom['post_author_username'] ?? nom['username'] ?? '').toString();
    final profilePictureUrl = (nom['post_author_avatar'] ?? '').toString();
    final initials = username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : (username.isNotEmpty ? username[0].toUpperCase() : 'U');

    final title = (nom['post_title'] ?? '').toString();
    final content = (nom['post_content'] ?? '').toString();

    // Extract category and location from nested objects
    final category = nom['category'] is Map
        ? (nom['category']['name'] ?? '').toString()
        : (nom['category_name'] ?? nom['category']?.toString() ?? '');
    final location = nom['location'] is Map
        ? (nom['location']['name'] ?? '').toString()
        : (nom['location_name'] ?? nom['location']?.toString() ?? '');

    return _buildPostCard(
      username: username.startsWith('@') ? username : '@$username',
      timeAgo: _formatTimeAgo(nom['post_created_at'] ?? nom['nominated_at'] ?? nom['created_at']),
      initials: initials,
      profilePictureUrl: profilePictureUrl.isNotEmpty ? profilePictureUrl : null,
      location: location,
      topic: category,
      title: title.isNotEmpty ? title : content,
      body: title.isNotEmpty ? content : '',
      voteCount: (nom['post_upvote_count'] as num?)?.toInt() ?? 0,
      commentCount: (nom['post_comment_count'] as num?)?.toInt() ?? 0,
      variant: PostCardVariant.newPost,
    );
  }

  Widget _buildPostCard({
    required String username,
    required String timeAgo,
    required String initials,
    required String location,
    required String topic,
    required String title,
    required String body,
    required int voteCount,
    required int commentCount,
    String? profilePictureUrl,
    PostCardVariant variant = PostCardVariant.moderator,
  }) {
    // Determine initials based on variant
    final String displayInitials = variant == PostCardVariant.moderator
        ? 'MO'
        : variant == PostCardVariant.admin
            ? 'AD'
            : initials;

    final postData = PostCardData(
      variant: variant,
      username: username,
      timeAgo: timeAgo,
      location: location,
      category: topic,
      title: title,
      body: body,
      commentsCount: commentCount,
      votes: voteCount,
      initials: displayInitials,
      profilePictureUrl: profilePictureUrl,
    );

    return PostCard(
      data: postData,
      showOverflowMenu: variant != PostCardVariant.admin, // Hide three dots for admin variant
    );
  }

}
