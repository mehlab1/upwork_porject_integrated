import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';
import 'package:pal/widgets/pal_push_notification.dart';

import '../../services/post_service.dart';
import 'create_post_screen.dart';
import 'widgets/post_card.dart';

class Variables {
  static const Color stateLayersErrorContainerOpacity16 = Color(0x29F9DEDC);
}

class FeedHomeScreen extends StatefulWidget {
  const FeedHomeScreen({super.key, this.showWelcomeModal = false, this.showFirstPostCard = false});

  final bool showWelcomeModal;
  final bool showFirstPostCard;

  @override
  State<FeedHomeScreen> createState() => _FeedHomeScreenState();
}

class _FeedHomeScreenState extends State<FeedHomeScreen> {
  String _selectedFilter = 'New'; // Hot, New, Top
  String? _selectedLocation;
  String? _selectedCategory;
  bool _isLocationDropdownOpen = false;
  bool _isCategoryDropdownOpen = false;
  bool _isTrendingDropdownOpen = false;
  _TrendingOption? _selectedTrending;
  late final ScrollController _scrollController;
  static const int _pageSize = 6;
  static const double _estimatedPostHeight = 520;
  static const double _loadMoreTriggerOffset = 200;
  bool _hasInitializedVisibleLimit = false;
  bool _isLoadingMore = false;
  int _visiblePostLimit = _pageSize;
  int _initialVisiblePostCapacity = _pageSize;

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _activeTabBackground = Color(0xFF0F172B);
  static const Color _darkBlue = Color(0xFF0A1864);
  static const Color _blue100 = Color(0xFFDAE9F8);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _hotTabColor = Color(0xFFFF8904);
  static const Color _newTabColor = Color(0xFF45556C);
  static const Color _topTabColor = Color(0xFF206FE2);
  static const Color _stateLayerShadow = Color(0x40000000);
  static const Color _selectionHighlight = Color(0xFFF8FAFC);
  static const Color _optionTextColor = Color(0xFF0F172B);

  static const List<String> _locationOptions = [
    'All Areas',
    'Victoria Island (VI)',
    'Ikoyi',
    'Lekki',
    'Lekki Phase 1',
    'Ajah',
    'Yaba',
    'Surulere',
    'Ikeja',
    'Mainland',
    'Festac',
    'Isolo',
    'Oshodi',
    'Maryland',
    'Gbagada',
    'Apapa',
    'Other',
  ];

  static const List<String> _categoryOptions = ['Gist', 'Ask', 'Discussion'];

  static const Map<String, String> _categoryOptionIcons = {
    'All Categories': 'assets/feedPage/categoryFilter.svg',
    'Gist': 'assets/images/gistIcon.svg',
    'Ask': 'assets/images/askIcon.svg',
    'Discussion': 'assets/images/discussionIcon.svg',
  };
  static const Map<String, Color?> _categoryOptionIconColors = {
    'Gist': null,
    'Ask': Color(0xFF008236),
    'Discussion': Color(0xFFBB4D00),
  };

  static const List<CommentData> _hotComments = [
    CommentData(
      author: '@lagosian_boy',
      timeAgo: '1h ago',
      body:
          "You NEED to try the one at Yellow Chilli! Best I've ever had, hands down.",
      upvotes: 45,
      downvotes: 0,
      initials: 'LB', id: '',
    ),
    CommentData(
      author: '@naija_gourmet',
      timeAgo: '30m ago',
      body:
          "Party jollof is undefeated! There's something about that smoky flavor from the firewood.",
      upvotes: 38,
      downvotes: 0,
      avatarAsset: 'assets/images/profile.svg', id: '',
    ),
    CommentData(
      author: '@anonymous',
      timeAgo: 'just now',
      body: 'checking',
      upvotes: 1,
      downvotes: 0,
      initials: 'AN', id: '',
    ),
  ];

  bool _shouldShowWelcomeModal = false;
  bool _shouldShowFirstPostCard = false;
  bool _isPageLoading = true;
  bool _isInitialPostsLoading = true;
  final PostService _postService = PostService();
  late final List<PostCardData> _seedPosts = _buildSeedPosts().take(3).toList();
  final List<PostCardData> _remotePosts = [];
  bool _isFeedFetching = false;
  bool _hasMoreRemotePosts = true;
  int _remoteOffset = 0;
  
  // Category and location mappings (name -> id)
  Map<String, String> _categoryMap = {};
  Map<String, String> _locationMap = {};

  // Monthly Spotlight state
  bool _isLoadingSpotlightStatus = false;
  Map<String, dynamic>? _spotlightStatus;
  List<PostCardData> _spotlightPosts = [];
  bool _isLoadingSpotlightPosts = false;
  bool _isShowingSpotlightPosts = false;

  static const PostCardData _pinnedAdminPost = PostCardData(
    variant: PostCardVariant.newPost,
    username: 'Pal Admin',
    timeAgo: 'Pinned · 1h ago',
    location: '',
    category: '',
    title: 'Community announcement: December safety tips',
    body:
        "Stay vigilant when attending Detty December events. Keep your valuables secure, move with trusted pals, and share updates in the community if you notice anything unusual.",
    commentsCount: 6,
    votes: 128,
    avatarAsset: 'assets/feedPage/profile.png',
    comments: null,
  );

  List<PostCardData> get _allPosts => [..._seedPosts, ..._remotePosts];

  List<PostCardData> get _filteredPosts => _postsForFilter(_selectedFilter);


  List<PostCardData> get _visiblePosts {
    // If showing spotlight posts, return those instead
    if (_isShowingSpotlightPosts) {
      if (_spotlightPosts.isEmpty) return const <PostCardData>[];
      final limit = math.min(_visiblePostLimit, _spotlightPosts.length);
      return _spotlightPosts.take(limit).toList();
    }
    
    // Otherwise, return regular filtered posts
    final posts = _filteredPosts;
    if (posts.isEmpty) return const <PostCardData>[];
    final limit = math.min(_visiblePostLimit, posts.length);
    return posts.take(limit).toList();
  }

  List<PostCardData> _postsForFilter(String filter) {
    switch (filter) {
      case 'Hot':
        return _allPosts
            .where((post) => post.variant == PostCardVariant.hot)
            .toList();
      case 'Top':
        return _allPosts
            .where((post) => post.variant == PostCardVariant.top)
            .toList();
      case 'New':
      default:
        return _allPosts;
    }
  }

  Future<void> _checkUserProfile({bool showFirstPostCard = false}) async {
    // Check if user has any posts by querying Supabase directly
    // This avoids using the get-profile function which has SQL errors
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // User not logged in, don't show welcome modal or first post card
        setState(() {
          _shouldShowWelcomeModal = false;
          _shouldShowFirstPostCard = false;
        });
        return;
      }

      // Check if we have a valid session token
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // No valid session, don't show welcome modal or first post card
        setState(() {
          _shouldShowWelcomeModal = false;
          _shouldShowFirstPostCard = false;
        });
        return;
      }

      // Query Supabase directly to check if user has any posts
      // Note: posts.user_id references profiles.id, which should equal auth.users.id
      // Only fetch the id field and limit to 1 for efficiency
      final userId = user.id;
      
      // Execute query: SELECT id FROM posts WHERE user_id = userId AND status = 'active' LIMIT 1
      final response = await Supabase.instance.client
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1);

      if (!mounted) return;

      // Supabase returns a List<Map<String, dynamic>> or List<dynamic>
      // Convert to List and check if it's empty
      List<dynamic> postsList;
      if (response is List) {
        postsList = response;
      } else {
        // Handle unexpected response format
        debugPrint('WARNING: Unexpected response type from posts query: ${response.runtimeType}');
        postsList = [];
      }

      // If response list is empty, user has no posts
      // If response has data, user has at least one post
      final hasPosts = postsList.isNotEmpty;
      
      debugPrint('User post check: userId=$userId, hasPosts=$hasPosts, postsFound=${postsList.length}');

      // If user has 0 posts, show welcome modal and first post card
      // If user has posts, don't show them
      setState(() {
        _shouldShowWelcomeModal = !hasPosts;
        _shouldShowFirstPostCard = !hasPosts;
      });

      // Show welcome modal if user has 0 posts (based on SQL query result)
      // Use the SQL logic result directly, not widget.showWelcomeModal
      if (_shouldShowWelcomeModal) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
      }
    } catch (e) {
      // Error querying posts (network error, permission error, etc.)
      // Log the error for debugging
      debugPrint('ERROR: Failed to check user posts: $e');
      debugPrint('Error type: ${e.runtimeType}');
      
      // Don't show welcome modal or first post card as a safe default
      // This handles cases where:
      // - Network errors
      // - Permission errors (RLS policies blocking access)
      // - Database errors
      // - User doesn't have a profile record yet (posts.user_id references profiles.id)
      // - Any other errors
      if (!mounted) return;
      setState(() {
        _shouldShowWelcomeModal = false;
        _shouldShowFirstPostCard = false;
      });
      // Silently handle the error - user can still use the app normally
    }
  }

  Future<void> _fetchSpotlightStatus() async {
    try {
      setState(() {
        _isLoadingSpotlightStatus = true;
      });

      final response = await _postService.getMonthlySpotlightStatus();
      if (!mounted) return;

      setState(() {
        _spotlightStatus = response;
        _isLoadingSpotlightStatus = false;
        
        // Set selected trending to first available option after API data loads
        final options = _trendingOptions;
        if (options.isNotEmpty && _selectedTrending == null) {
          _selectedTrending = options.first;
        }
      });
    } catch (e) {
      // Silently handle error - no spotlight options will be shown
      if (!mounted) return;
      setState(() {
        _isLoadingSpotlightStatus = false;
        _spotlightStatus = null;
        _selectedTrending = null;
      });
    }
  }

  Future<void> _fetchCategoryAndLocationMappings() async {
    try {
      final categories = await _postService.getCategories();
      final locations = await _postService.getLocations();
      if (!mounted) return;
      setState(() {
        _categoryMap = categories;
        _locationMap = locations;
      });
    } catch (e) {
      // Silently handle error - filters will work with names if IDs not available
      print('Failed to fetch category/location mappings: $e');
    }
  }

  Future<void> _fetchSpotlightPosts() async {
    if (_isLoadingSpotlightPosts) return;

    setState(() {
      _isLoadingSpotlightPosts = true;
      _isShowingSpotlightPosts = true;
    });

    try {
      print('DEBUG: _fetchSpotlightPosts called. Preparing request with limit=50 offset=0');
      final response = await _postService.getMonthlySpotlightPosts(
        limit: 50, // Fetch more posts for spotlight
        offset: 0,
      );

      print('DEBUG: Received spotlight posts response. Keys: ${response.keys.toList()}');
      final respPostsList = (response['posts'] as List?) ?? const [];
      print('DEBUG: Number of posts returned from spotlight function: ${respPostsList.length}');

      final posts = respPostsList;
      final variant = PostCardVariant.newPost; // Use newPost variant for spotlight posts
      
      final mappedPosts = posts
          .map((post) {
            if (post is Map<String, dynamic>) {
              return _mapPostToCardData(post, variant);
            }
            if (post is Map) {
              return _mapPostToCardData(
                Map<String, dynamic>.from(post as Map),
                variant,
              );
            }
            return null;
          })
          .whereType<PostCardData>()
          .toList();

      if (!mounted) return;
      setState(() {
        _spotlightPosts = mappedPosts;
        _isLoadingSpotlightPosts = false;
        // Update visible limit for spotlight posts
        _visiblePostLimit = math.min(_initialVisiblePostCapacity, mappedPosts.length);
      });
    } catch (e) {
      print('DEBUG: Exception in _fetchSpotlightPosts: ${e.runtimeType} ${e.toString()}');
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? 'Failed to load spotlight posts.' : message)),
      );
      setState(() {
        _isLoadingSpotlightPosts = false;
        _spotlightPosts = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Don't set selectedTrending here - wait for API data
    
    // Check user profile to determine if welcome modal and first post card should be shown
    _checkUserProfile(showFirstPostCard: widget.showFirstPostCard);
    
    // Fetch monthly spotlight status
    _fetchSpotlightStatus();
    
    // Fetch category and location mappings
    _fetchCategoryAndLocationMappings();
    
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVisibleLimit(),
    );
    Future.microtask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _isPageLoading = false;
      });
      // Show a demo push notification once the page finishes initial load (testing only)
      // You can remove this after integrating with real notifications.
      PalPushNotification.show(
        context,
        title: 'New message',
        message: 'Your post received new comments in Lagos community.',
      );
    });
    Future.microtask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _isInitialPostsLoading = false;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFeed(reset: true);
    });
  }

  @override
  void didUpdateWidget(covariant FeedHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Show welcome modal if SQL logic determined user has 0 posts
    // This handles cases where the widget is updated after the SQL query completes
    if (_shouldShowWelcomeModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // neutral-50
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header section
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(color: _slate200, width: 0.755),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/icon.svg',
                            width: 35,
                            height: 35,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: const [
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Text(
                                'kobi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF314158),
                                  fontFamily: 'Inter',
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'pal',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                      fontFamily: 'Inter',
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    '.',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF155DFC),
                                      fontFamily: 'Inter',
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showCreatePostModal(context);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Post',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.1504,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filters and content
            Expanded(
              child: PalRefreshIndicator(
                onRefresh: _refreshFeed,
                child: Container(
                  color: const Color(0xFFF7FBFF),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildFilterPills(),
                        _buildCards(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PalBottomNavigationBar(
        active: PalNavDestination.home,
        onHomeTap: _scrollToTop,
        onNotificationsTap: () {
          Navigator.of(context).pushNamed('/notifications');
        },
        onSettingsTap: () {
          Navigator.pushNamed(context, '/settings');
        },
        showNotificationDot: true,
      ),
    );
    return Stack(
      children: [scaffold, if (_isPageLoading) const PalLoadingOverlay()],
    );
  }

  Future<void> _showWelcomeModal() async {
    if (!_shouldShowWelcomeModal || !mounted) return;
    _shouldShowWelcomeModal = false;

    final shouldCreatePost = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _WelcomeDialogContent(
            onExplore: () => Navigator.of(dialogContext).pop(false),
            onCreatePost: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    );

    if (shouldCreatePost == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );
    }
  }

  void _initializeVisibleLimit() {
    if (!mounted || _hasInitializedVisibleLimit) return;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.vertical;
    final estimatedCapacity = availableHeight > 0
        ? (availableHeight / _estimatedPostHeight).ceil() + 1
        : _pageSize;
    final capacity = math.max(_pageSize, estimatedCapacity);
    final clampedVisible = math.min(capacity, _filteredPosts.length);

    setState(() {
      _initialVisiblePostCapacity = capacity;
      _visiblePostLimit = clampedVisible;
      _hasInitializedVisibleLimit = true;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreTriggerOffset) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    final totalPosts = _filteredPosts.length;
    if (_isLoadingMore) {
      return;
    }
    if (_visiblePostLimit >= totalPosts) {
      if (_hasMoreRemotePosts && !_isFeedFetching) {
        _fetchFeed();
      }
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 350)).then((_) {
      if (!mounted) return;
      final total = _filteredPosts.length;
      final nextLimit = math.min(_visiblePostLimit + _pageSize, total);
      setState(() {
        _visiblePostLimit = nextLimit;
        _isLoadingMore = false;
      });
    });
  }

  void _resetVisibleLimitForFilter(String filter) {
    final filtered = _postsForFilter(filter);
    final nextLimit = math.min(_initialVisiblePostCapacity, filtered.length);
    _visiblePostLimit = nextLimit;
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _isInitialPostsLoading = true;
      
      // Reset all filters on pull to refresh
      _selectedFilter = 'New';
      _selectedLocation = null;
      _selectedCategory = null;
      _selectedTrending = null;
      _isShowingSpotlightPosts = false;
      _spotlightPosts = [];
      _isLoadingSpotlightPosts = false;
      _isLocationDropdownOpen = false;
      _isCategoryDropdownOpen = false;
      _isTrendingDropdownOpen = false;
      
      // Reset feed state
      _remotePosts.clear();
      _remoteOffset = 0;
      _hasMoreRemotePosts = true;
      _isLoadingMore = false;
    });
    
    _resetVisibleLimitForFilter(_selectedFilter);
    
    // Fetch fresh data from backend
    await _fetchFeed(reset: true);
    
    // Refresh spotlight status to get latest options
    await _fetchSpotlightStatus();
    
    // Delay for smooth UI transition (matching provided code pattern)
    // Note: _fetchFeed may also set _isInitialPostsLoading to false, but we ensure
    // it's set after the delay to match the provided UI behavior
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isInitialPostsLoading = false;
    });
  }

  Future<void> _fetchFeed({bool reset = false}) async {
    if (_isFeedFetching) return;
    if (!_hasMoreRemotePosts && !reset && _selectedFilter != 'Hot' && _selectedFilter != 'Top') return;

    // Check if location or category filters are selected
    // Location: "All Areas" (first option) means no filter, so check if not first option
    final hasLocationFilter = _selectedLocation != null && _selectedLocation != _locationOptions.first;
    // Category: null means no filter, any selected value (including first option) is a valid filter
    final hasCategoryFilter = _selectedCategory != null;
    final hasFilters = hasLocationFilter || hasCategoryFilter;

    // Special handling for Hot filter - uses get-hottest-post edge function
    // BUT if location/category filters are selected, use get-feed instead
    if (_selectedFilter == 'Hot' && !hasFilters) {
      setState(() {
        _isFeedFetching = true;
        if (reset) {
          _remotePosts.clear();
          _remoteOffset = 0;
          _hasMoreRemotePosts = false; // Hot filter returns single post, no pagination
        }
      });

      try {
        final response = await _postService.getHottestPost(
          timeframe: 'today',
        );

        final hottestPost = response['hottest_post'] as Map<String, dynamic>?;
        final variant = PostCardVariant.hot;
        
        List<PostCardData> mappedPosts = [];
        if (hottestPost != null) {
          final mappedPost = _mapPostToCardData(hottestPost, variant);
          if (mappedPost != null) {
            mappedPosts = [mappedPost];
          }
        }

        if (!mounted) return;
        setState(() {
          if (reset) {
            _remotePosts.clear();
            _remotePosts.addAll(mappedPosts);
            _hasMoreRemotePosts = false; // Single post, no more to load
          } else {
            // For Hot filter, replace existing posts on reset
            _remotePosts.clear();
            _remotePosts.addAll(mappedPosts);
            _hasMoreRemotePosts = false;
          }
          final filteredLength = _postsForFilter(_selectedFilter).length;
          if (reset) {
            _visiblePostLimit =
                math.min(_initialVisiblePostCapacity, filteredLength);
          } else {
            _visiblePostLimit =
                math.min(filteredLength, _visiblePostLimit + mappedPosts.length);
          }
        });
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isEmpty ? 'Failed to load hottest post.' : message)),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isFeedFetching = false;
          _isInitialPostsLoading = false;
        });
      }
      return;
    }

    // Special handling for Top filter - uses get-top-post edge function
    // BUT if location/category filters are selected, use get-feed instead
    if (_selectedFilter == 'Top' && !hasFilters) {
      setState(() {
        _isFeedFetching = true;
        if (reset) {
          _remotePosts.clear();
          _remoteOffset = 0;
          _hasMoreRemotePosts = false; // Top filter returns single post, no pagination
        }
      });

      try {
        final response = await _postService.getTopPost(
          period: 'all_time',
        );

        final topPost = response['top_post'] as Map<String, dynamic>?;
        final variant = PostCardVariant.top;
        
        List<PostCardData> mappedPosts = [];
        if (topPost != null) {
          final mappedPost = _mapPostToCardData(topPost, variant);
          if (mappedPost != null) {
            mappedPosts = [mappedPost];
          }
        }

        if (!mounted) return;
        setState(() {
          if (reset) {
            _remotePosts.clear();
            _remotePosts.addAll(mappedPosts);
            _hasMoreRemotePosts = false; // Single post, no more to load
          } else {
            // For Top filter, replace existing posts on reset
            _remotePosts.clear();
            _remotePosts.addAll(mappedPosts);
            _hasMoreRemotePosts = false;
          }
          final filteredLength = _postsForFilter(_selectedFilter).length;
          if (reset) {
            _visiblePostLimit =
                math.min(_initialVisiblePostCapacity, filteredLength);
          } else {
            _visiblePostLimit =
                math.min(filteredLength, _visiblePostLimit + mappedPosts.length);
          }
        });
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isEmpty ? 'Failed to load top post.' : message)),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isFeedFetching = false;
          _isInitialPostsLoading = false;
        });
      }
      return;
    }

    // Use get-feed for all filters when location/category filters are selected
    // OR for New filter (always uses get-feed)
    // OR for Hot/Top when filters are selected
    final sortParam = _sortParamForFilter(_selectedFilter);
    final nextOffset = reset ? 0 : _remoteOffset;

    setState(() {
      _isFeedFetching = true;
      if (reset) {
        _remotePosts.clear();
        _remoteOffset = 0;
        _hasMoreRemotePosts = true;
      }
    });

    try {
      // Convert category and location names to IDs
      String? categoryId;
      String? locationId;
      
      // Only filter by category if a specific category is selected (not the first/default)
      if (hasCategoryFilter) {
        categoryId = _categoryMap[_selectedCategory];
        // If categoryId is null, the mapping might not be loaded yet - log for debugging
        if (categoryId == null) {
          debugPrint('WARNING: Category filter selected but ID not found in mapping: $_selectedCategory');
        }
      }
      
      // Only filter by location if a specific location is selected (not "All Areas")
      if (hasLocationFilter) {
        locationId = _locationMap[_selectedLocation];
        // If locationId is null, the mapping might not be loaded yet - log for debugging
        if (locationId == null) {
          debugPrint('WARNING: Location filter selected but ID not found in mapping: $_selectedLocation');
        }
      }
      
      debugPrint('Fetching feed with filters: sort=$sortParam, categoryId=$categoryId, locationId=$locationId');
      
      final response = await _postService.getFeed(
        sort: sortParam,
        limit: _pageSize,
        offset: nextOffset,
        categoryId: categoryId,
        locationId: locationId,
      );

      final posts = (response['posts'] as List?) ?? const [];
      final variant = _variantForFilter(_selectedFilter);
      final mappedPosts = posts
          .map((post) {
            if (post is Map<String, dynamic>) {
              return _mapPostToCardData(post, variant);
            }
            if (post is Map) {
              return _mapPostToCardData(
                Map<String, dynamic>.from(post as Map),
                variant,
              );
            }
            return null;
          })
          .whereType<PostCardData>()
          .toList();

      final pagination = response['pagination'] as Map<String, dynamic>?;
      final hasMore = pagination?['has_more'] as bool? ?? false;
      final updatedOffset = pagination?['next_offset'] as int? ??
          (nextOffset + posts.length);

      if (!mounted) return;
      setState(() {
        _remotePosts.addAll(mappedPosts);
        _remoteOffset = updatedOffset;
        _hasMoreRemotePosts = hasMore;
        final filteredLength = _postsForFilter(_selectedFilter).length;
        if (reset) {
          _visiblePostLimit =
              math.min(_initialVisiblePostCapacity, filteredLength);
        } else {
          _visiblePostLimit =
              math.min(filteredLength, _visiblePostLimit + mappedPosts.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? 'Failed to load feed.' : message)),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isFeedFetching = false;
        _isInitialPostsLoading = false;
      });
    }
  }

  String _sortParamForFilter(String filter) {
    switch (filter) {
      case 'Top':
        return 'top';
      case 'Hot':
        return 'hot';
      case 'New':
      default:
        return 'latest';
    }
  }

  PostCardVariant _variantForFilter(String filter) {
    switch (filter) {
      case 'Top':
        return PostCardVariant.top;
      case 'Hot':
        return PostCardVariant.hot;
      case 'New':
      default:
        return PostCardVariant.newPost;
    }
  }

  PostCardData? _mapPostToCardData(
    Map<String, dynamic> post,
    PostCardVariant variant,
  ) {
    final rawTitle = (post['title'] ?? '').toString().trim();
    final rawBody = (post['body'] ?? '').toString().trim();
    final content = (post['content'] ?? '').toString().trim();
    if (rawTitle.isEmpty && rawBody.isEmpty && content.isEmpty) {
      return null;
    }

    String title = rawTitle;
    String body = rawBody;
    if (title.isEmpty) {
      final segments = content.split('\n\n');
      if (segments.isNotEmpty) {
        title = segments.first.trim();
        if (body.isEmpty && segments.length > 1) {
          body = segments.sublist(1).join('\n\n').trim();
        }
      }
    }
    if (body.isEmpty) {
      body = content.isNotEmpty ? content : title;
    }
    if (title.isEmpty) {
      title = 'Community Post';
    }

    final profile = post['profiles'] as Map<String, dynamic>?;
    final categoryMap = post['categories'] as Map<String, dynamic>?;
    final locationMap = post['locations'] as Map<String, dynamic>?;

    final username = (post['username'] ??
            profile?['username'] ??
            '@pal_user')
        .toString();
    final category =
        (post['category_name'] ?? categoryMap?['name'] ?? '').toString();
    final location =
        (post['location_name'] ?? locationMap?['name'] ?? '').toString();

    final createdAt =
        DateTime.tryParse(post['created_at']?.toString() ?? '');

    final commentsCount = _parseInt(
      post['comments_count'] ?? post['comment_count'] ?? post['replies_count'],
    );
    final votes = _parseInt(
      post['votes'] ??
          post['upvote_count'] ??
          post['engagement_score'] ??
          post['net_score'],
    );

    return PostCardData(
      id: post['id']?.toString(),
      variant: variant,
      username: username.isEmpty ? '@pal_user' : username,
      timeAgo: _formatTimeAgo(createdAt),
      location: location,
      category: category,
      title: title,
      body: body,
      commentsCount: commentsCount,
      votes: votes,
      avatarAsset: 'assets/feedPage/profile.png',
    );
  }

  int _parseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'just now';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(dateTime);
  }

  List<PostCardData> _buildSeedPosts() {
    final hotComments = _hotComments;
    return [
      PostCardData(
        variant: PostCardVariant.top,
        username: '@pal_explorer',
        timeAgo: '2h ago',
        location: 'Victoria Island (VI)',
        category: 'Ask',
        title: 'Where should we host our next product meetup?',
        body:
            'Looking for a cozy, semi-outdoor space around VI that can host about 30 people. Prefer somewhere with good WiFi and accessible parking.',
        commentsCount: hotComments.length,
        votes: 186,
        avatarAsset: 'assets/feedPage/profile.png',
        comments: hotComments,
      ),
      PostCardData(
        variant: PostCardVariant.hot,
        username: '@naija_foodie',
        timeAgo: '45m ago',
        location: 'Lekki Phase 1',
        category: 'Gist',
        title: 'Tasting tour: who has the best party jollof?',
        body:
            "Yellow Chilli? Ofada Boy? Share your undefeated jollof spots so we can plan a weekend tasting crawl.",
        commentsCount: 54,
        votes: 124,
        avatarAsset: 'assets/feedPage/profile.png',
        comments: const <CommentData>[],
      ),
      PostCardData(
        variant: PostCardVariant.newPost,
        username: '@tech_sis',
        timeAgo: '10m ago',
        location: 'Yaba',
        category: 'Discussion',
        title: 'Coworking spaces with reliable power? ',
        body:
            'Need recommendations for coworking spots on the mainland that stay powered through late nights. Bonus points for ergonomic chairs.',
        commentsCount: 12,
        votes: 8,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.newPost,
        username: '@lagos_runner',
        timeAgo: '25m ago',
        location: 'Lekki',
        category: 'Discussion',
        title: 'Looking for 5am running buddies',
        body:
            'Trying to stay consistent with morning runs. Anyone up for a Lekki-Ikate loop twice a week?',
        commentsCount: 6,
        votes: 21,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.hot,
        username: '@owambequeen',
        timeAgo: '1h ago',
        location: 'Ikoyi',
        category: 'Gist',
        title: 'Detty December outfit inspo needed!',
        body:
            'Share your favourite vendors for statement pieces. Looking for something extra for New Year’s Eve.',
        commentsCount: 33,
        votes: 98,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.top,
        username: '@founder_ng',
        timeAgo: '3h ago',
        location: 'Ikeja',
        category: 'Ask',
        title: 'Anyone tried the new startup accelerator in Ikeja?',
        body:
            'Curious about the mentorship quality and if they really provide access to investors as promised in the deck.',
        commentsCount: 18,
        votes: 142,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.newPost,
        username: '@islandmom',
        timeAgo: '5m ago',
        location: 'Ajah',
        category: 'Ask',
        title: 'Kid-friendly brunch ideas',
        body:
            'Planning a Sunday outing with two toddlers. Need spots with playgrounds or activity corners.',
        commentsCount: 4,
        votes: 5,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.hot,
        username: '@nightshift',
        timeAgo: '1h ago',
        location: 'Surulere',
        category: 'Discussion',
        title: 'Late-night coffee spots still open?',
        body:
            'Looking for somewhere quiet past 9pm to get work done. Preferably with outdoor seating.',
        commentsCount: 17,
        votes: 77,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.top,
        username: '@musicjunkie',
        timeAgo: '4h ago',
        location: 'Yaba',
        category: 'Gist',
        title: 'Underground live sets this weekend',
        body:
            'Heard there’s a rooftop jazz session somewhere around Onikan. Anyone got the plug?',
        commentsCount: 29,
        votes: 201,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      PostCardData(
        variant: PostCardVariant.newPost,
        username: '@citycyclist',
        timeAgo: '18m ago',
        location: 'Mainland',
        category: 'Discussion',
        title: 'Cycling-safe routes before sunrise',
        body:
            'Trying to map out 20km loops with minimal traffic. Any cyclist groups open to new members?',
        commentsCount: 9,
        votes: 12,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
    ];
  }

  static const Color _filterInactiveTextColor = Color(0xFF45556C);

  Widget _buildFilterButton(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    Color accentColor;
    switch (label) {
      case 'Hot':
        accentColor = _hotTabColor;
        break;
      case 'Top':
        accentColor = _topTabColor;
        break;
      case 'New':
      default:
        accentColor = _newTabColor;
    }

    final Color textColor = isSelected
        ? Colors.white
        : _filterInactiveTextColor;
    final Color iconColor = isSelected ? Colors.white : accentColor;

    Widget buildLeadingIcon() {
      if (label == 'Hot') {
        return SvgPicture.asset(
          'assets/images/hotIcon.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
        );
      }
      if (label == 'New') {
        return SvgPicture.asset(
          'assets/images/newIcon.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      }
      if (label == 'Top') {
        return SvgPicture.asset(
          'assets/images/topIcon.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
        );
      }
      return Icon(icon, size: 16, color: iconColor);
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_selectedFilter == label) {
              _scrollToTop();
              return;
            }
            setState(() {
              _selectedFilter = label;
              _isLoadingMore = false;
              _remotePosts.clear();
              _remoteOffset = 0;
              _hasMoreRemotePosts = true;
              _isShowingSpotlightPosts = false; // Reset spotlight posts when switching filters
              _resetVisibleLimitForFilter(label);
            });
            _fetchFeed(reset: true);
            _scrollToTop();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: isSelected ? _activeTabBackground : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildLeadingIcon(),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                    fontFamily: 'Inter',
                    letterSpacing: -0.1504,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    final selectedLocation = _selectedLocation ?? _locationOptions.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _slate200, width: 1.513),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: Radius.circular(_isLocationDropdownOpen ? 0 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x140F172A),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isCategoryDropdownOpen = false;
                  _isLocationDropdownOpen = !_isLocationDropdownOpen;
                });
              },
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(_isLocationDropdownOpen ? 0 : 14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _blue100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: _primary900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedLocation,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _optionTextColor,
                                fontFamily: 'Inter',
                                letterSpacing: -0.1504,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isLocationDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: _optionTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLocationDropdownOpen)
          _InlineDropdown(
            title: 'Location Filter',
            leadingIcon: const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: _primary900,
            ),
            options: _locationOptions
                .map((label) => _DropdownOption(label))
                .toList(),
            selectedValue: selectedLocation,
            highlightColor: _selectionHighlight,
            optionTextColor: _optionTextColor,
            borderColor: _slate200,
            showHeader: false,
            onSelected: (value) {
              setState(() {
                // If "All Areas" is selected, set to null to clear filter
                // Otherwise, set the selected location
                _selectedLocation = (value == _locationOptions.first) ? null : value;
                _isLocationDropdownOpen = false;
                // Reset feed state and fetch with new filter
                _remotePosts.clear();
                _remoteOffset = 0;
                _hasMoreRemotePosts = true;
                _isLoadingMore = false;
              });
              _fetchFeed(reset: true);
            },
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final selectedCategory = _selectedCategory ?? _categoryOptions.first;
    final categoryOptions = _categoryOptions
        .map(
          (label) => _DropdownOption(
            label,
            iconAsset: _categoryOptionIcons[label],
            iconColor: _categoryOptionIconColors[label],
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _slate200, width: 1.513),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: Radius.circular(_isCategoryDropdownOpen ? 0 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x140F172A),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isLocationDropdownOpen = false;
                  _isCategoryDropdownOpen = !_isCategoryDropdownOpen;
                });
              },
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(_isCategoryDropdownOpen ? 0 : 14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _blue100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: _optionTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCategory,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _optionTextColor,
                                fontFamily: 'Inter',
                                letterSpacing: -0.1504,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isCategoryDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: _optionTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isCategoryDropdownOpen)
          _InlineDropdown(
            title: 'Category Filter',
            leadingIcon: const Icon(Icons.grid_view_rounded, size: 16),
            options: categoryOptions,
            selectedValue: selectedCategory,
            highlightColor: _selectionHighlight,
            optionTextColor: _optionTextColor,
            borderColor: _slate200,
            showHeader: false,
            onSelected: (value) {
              setState(() {
                // Set the selected category (all category options are valid filters)
                _selectedCategory = value;
                _isCategoryDropdownOpen = false;
                // Reset feed state and fetch with new filter
                _remotePosts.clear();
                _remoteOffset = 0;
                _hasMoreRemotePosts = true;
                _isLoadingMore = false;
              });
              _fetchFeed(reset: true);
            },
          ),
      ],
    );
  }

  Widget _buildMonthlySpotlight() {
    // Only show spotlight if we have options from API
    final options = _trendingOptions;
    if (options.isEmpty || _selectedTrending == null) {
      return const SizedBox.shrink();
    }
    
    final trending = _selectedTrending!;
    
    // Use API data for Monthly Spotlight
    String topicTitle = trending.label;
    String topicDescription = trending.description;
    int postCountValue = trending.postCount ?? 0;
    bool isActive = trending.isActive;
    
    // If this is Monthly Spotlight and we have API data, use it
    if (trending.tag == 'Monthly Spotlight' && _spotlightStatus != null) {
      final isAvailable = _spotlightStatus!['is_available'] as bool? ?? false;
      final hotTopicTitle = _spotlightStatus!['hot_topic_title'] as String?;
      final stats = _spotlightStatus!['stats'] as Map<String, dynamic>?;
      
      if (hotTopicTitle != null && hotTopicTitle.isNotEmpty) {
        topicTitle = hotTopicTitle;
      }
      
      if (stats != null) {
        // Try to get spotlight posts count - check multiple possible field names
        // This should be the count of posts where is_monthly_spotlight = true
        final spotlightPostsRaw = stats['spotlight_posts'] ?? 
                                 stats['monthly_spotlight_posts'] ?? 
                                 stats['total_posts'];
        if (spotlightPostsRaw != null) {
          // Use existing _parseInt helper to handle int, string, or other numeric types
          postCountValue = _parseInt(spotlightPostsRaw);
        }
      }
      
      // Fallback: Use actual count from fetched spotlight posts if available
      // This ensures we show the real count of posts with is_monthly_spotlight = true
      if (_spotlightPosts.isNotEmpty && postCountValue == 0) {
        postCountValue = _spotlightPosts.length;
      }
      
      isActive = isAvailable;
    }
    
    final tagLabel = (trending.tag ?? 'Trending Topic').toUpperCase();
    final postsLabel = '$postCountValue post${postCountValue == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isLocationDropdownOpen = false;
              _isCategoryDropdownOpen = false;
              _isTrendingDropdownOpen = !_isTrendingDropdownOpen;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(238, 242, 255, 0.4),
              border: Border.all(
                color: const Color.fromRGBO(198, 210, 255, 1),
                width: 1,
              ),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(_isTrendingDropdownOpen ? 0 : 14),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(222, 231, 255, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    trending.iconAsset,
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      trending.iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tagLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F39F6),
                              fontFamily: 'Inter',
                              letterSpacing: 0.392,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFCAD5E2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            postsLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF62748E),
                              fontFamily: 'Inter',
                              letterSpacing: 0.16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topicTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Inter',
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topicDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF62748E),
                          fontFamily: 'Inter',
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF432DD7),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  _isTrendingDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: _optionTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingDropdownPanel(_TrendingOption currentSelection) {
    final options = _trendingOptions;
    
    // Don't show dropdown if no options available
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          top: BorderSide.none,
          left: BorderSide(
            color: const Color.fromRGBO(198, 210, 255, 1),
            width: 1,
          ),
          right: BorderSide(
            color: const Color.fromRGBO(198, 210, 255, 1),
            width: 1,
          ),
          bottom: BorderSide(
            color: const Color.fromRGBO(198, 210, 255, 1),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: options.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.label == currentSelection.label;
                return _TrendingDropdownTile(
                  option: option,
                  isSelected: isSelected,
                  onTap: () => _handleTrendingSelect(option),
                );
              },
            ),
    );
  }

  void _handleTrendingSelect(_TrendingOption option) {
    setState(() {
      _selectedTrending = option;
      _isTrendingDropdownOpen = false;
    });
    
    // Monthly Spotlight is the only option, fetch spotlight posts from edge function
    _fetchSpotlightPosts();
    
    // Scroll to top when spotlight is selected
    _scrollToTop();
  }

  // Get available spotlight options from API only
  List<_TrendingOption> get _trendingOptions {
    final List<_TrendingOption> options = [];
    
    // Only add Monthly Spotlight if available from API (only one option ever)
    if (_spotlightStatus != null) {
      final isAvailable = _spotlightStatus!['is_available'] as bool? ?? false;
      if (isAvailable) {
        final hotTopicTitle = _spotlightStatus!['hot_topic_title'] as String? ?? 'Monthly Spotlight';
        final stats = _spotlightStatus!['stats'] as Map<String, dynamic>?;
        // Use existing _parseInt helper to handle int, string, or other numeric types
        // Try to get spotlight posts count - check multiple possible field names
        final postCount = stats != null 
            ? _parseInt(stats['spotlight_posts'] ?? 
                       stats['monthly_spotlight_posts'] ?? 
                       stats['total_posts'] ?? 
                       0)
            : 0;
        
        // Add Monthly Spotlight option (only one option ever, so no duplicates possible)
        options.add(_TrendingOption(
          tag: 'Monthly Spotlight',
          label: hotTopicTitle,
          description: 'Share posts related to the monthly spotlight topic',
          iconAsset: 'assets/images/dettyIcon.svg',
          iconColor: const Color.fromRGBO(79, 57, 246, 1),
          postCount: postCount,
          isActive: true,
        ));
      }
    }
    
    return options;
  }

  Widget _buildFirstPostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: _darkBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start The Conversation',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Your community is waiting. Share what's happening, ask questions, or start meaningful discussions.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Rubik',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildFirstPostButton(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPostButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 201,
          height: 37,
          decoration: BoxDecoration(
            color: Variables.stateLayersErrorContainerOpacity16,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: _stateLayerShadow,
                blurRadius: 1,
                offset: Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create Your First Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/feedPage/profile.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome back, Pal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Catch up with your Lagos community',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _buildFilterButton('Hot', Icons.local_fire_department_outlined),
            const SizedBox(width: 12),
            _buildFilterButton('New', Icons.bolt_outlined),
            const SizedBox(width: 12),
            _buildFilterButton('Top', Icons.trending_up_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final postsToShow = _visiblePosts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationFilter(),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 24),
          _buildMonthlySpotlight(),
          if (_isTrendingDropdownOpen && _selectedTrending != null) ...[
            const SizedBox(height: 8),
            _buildTrendingDropdownPanel(_selectedTrending!),
          ],
          const SizedBox(height: 24),
          if (_isInitialPostsLoading)
            ...List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LoadingPostSkeleton(),
              ),
            )
          else ...[
            // Show first post card conditionally (backend logic preserved)
            if (_shouldShowFirstPostCard) ...[
              _buildFirstPostCard(),
              const SizedBox(height: 24),
            ],
            // Only show admin post for "New" filter and when not showing spotlight posts (backend logic preserved)
            if (_selectedFilter == 'New' && !_isShowingSpotlightPosts) ...[
              PostCard(data: _pinnedAdminPost, isPinnedAdmin: true),
              const SizedBox(height: 24),
            ],
            // Show loading indicator when fetching spotlight posts
            if (_isLoadingSpotlightPosts)
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LoadingPostSkeleton(),
                ),
              )
            else
              ...postsToShow
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PostCard(
                      data: post,
                    ),
                  ),
                )
                .toList(),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            if (!_isLoadingMore && postsToShow.length < _filteredPosts.length)
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 32),
                child: Center(
                  child: Text(
                    'Scroll for more posts',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WelcomeDialogContent extends StatelessWidget {
  const _WelcomeDialogContent({
    required this.onExplore,
    required this.onCreatePost,
  });

  final VoidCallback onExplore;
  final VoidCallback onCreatePost;

  static const Color _titleColor = Color(0xFF111827);
  static const Color _bodyColor = Color(0xFF45556C);
  static const Color _primaryBlue = Color(0xFF155DFC);
  static const Color _primaryNavy = Color(0xFF0F172B);
  static const Color _checklistPanelColor = Color(0xFFF8FAFC);
  static const Color _checklistBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/icon.svg',
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const Icon(
                          Icons.alternate_email,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Pal!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _titleColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Account created successfully',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF314158),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Your account has been created successfully. You can now start engaging with the community!',
                style: TextStyle(
                  fontSize: 16,
                  height: 26 / 16,
                  fontWeight: FontWeight.w400,
                  color: _bodyColor,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 330,
                height: 110,
                padding: const EdgeInsets.fromLTRB(
                  12.75124,
                  12.75122,
                  12.75124,
                  0.75633,
                ),
                decoration: BoxDecoration(
                  color: _checklistPanelColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _checklistBorder, width: 0.75633),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _CheckListTile(label: 'Create and comment on posts'),
                    SizedBox(height: 12),
                    _CheckListTile(label: 'Vote on discussions'),
                    SizedBox(height: 12),
                    _CheckListTile(label: 'Ask Questions'),
                    SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExplore,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Explore Forum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _bodyColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCreatePost,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        backgroundColor: _primaryNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create First Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingOption {
  const _TrendingOption({
    this.tag,
    required this.label,
    required this.description,
    required this.iconAsset,
    required this.iconColor,
    this.postCount,
    this.isActive = false,
  });

  final String? tag;
  final String label;
  final String description;
  final String iconAsset;
  final Color iconColor;
  final int? postCount;
  final bool isActive;
}

class _TrendingDropdownTile extends StatelessWidget {
  const _TrendingDropdownTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _TrendingOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final optionPostCount = option.postCount ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color.fromRGBO(198, 210, 255, 1)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAE9F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    option.iconAsset,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      option.iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          (option.tag ?? 'Trending Topic').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F39F6),
                            fontFamily: 'Inter',
                            letterSpacing: 0.392,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFCAD5E2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$optionPostCount post${optionPostCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF62748E),
                            fontFamily: 'Inter',
                            letterSpacing: 0.16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Inter',
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF62748E),
                        fontFamily: 'Inter',
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
              ),
              if (option.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF432DD7),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckListTile extends StatelessWidget {
  const _CheckListTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/checkIcon.svg',
          width: 16,
          height: 16,
          placeholderBuilder: (context) =>
              const Icon(Icons.check, size: 16, color: Color(0xFF00A63E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF314158),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownOption {
  const _DropdownOption(this.label, {this.iconAsset, this.iconColor});

  final String label;
  final String? iconAsset;
  final Color? iconColor;
}

class _InlineDropdown extends StatelessWidget {
  const _InlineDropdown({
    this.title,
    this.leadingIcon,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.optionTextColor,
    required this.highlightColor,
    required this.borderColor,
    this.showHeader = false,
  });

  final String? title;
  final Widget? leadingIcon;
  final List<_DropdownOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final Color optionTextColor;
  final Color highlightColor;
  final Color borderColor;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          top: BorderSide.none,
          left: BorderSide(color: borderColor, width: 1.513),
          right: BorderSide(color: borderColor, width: 1.513),
          bottom: BorderSide(color: borderColor, width: 1.513),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader && title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: leadingIcon ?? const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: optionTextColor,
                        fontFamily: 'Inter',
                        letterSpacing: -0.1504,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.label == selectedValue;
              final Color? iconColor = option.iconColor;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(option.label),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? highlightColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (option.iconAsset != null) ...[
                          SvgPicture.asset(
                            option.iconAsset!,
                            width: 16,
                            height: 16,
                            colorFilter:
                                iconColor == null ||
                                    option.iconAsset ==
                                        'assets/feedPage/categoryFilter.svg'
                                ? null
                                : ColorFilter.mode(iconColor, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: optionTextColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}