import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';
import 'package:pal/widgets/pal_toast.dart';
import 'package:pal/widgets/profile_avatar_widget.dart';
import 'package:pal/widgets/pal_app_header.dart';
import 'package:pal/services/post_service.dart';
import 'package:pal/services/profile_service.dart';

import 'jm_create_post_screen.dart';
import 'widgets/jm_post_card.dart';

class Variables {
  static const Color stateLayersErrorContainerOpacity16 = Color(0x29F9DEDC);
}

class JmFeedHomeScreen extends StatefulWidget {
  const JmFeedHomeScreen({
    super.key, 
    this.showWelcomeModal = false,
    this.showFirstPostCard = false,
  });

  final bool showWelcomeModal;
  final bool showFirstPostCard;

  @override
  State<JmFeedHomeScreen> createState() => _JmFeedHomeScreenState();
}

class _JmFeedHomeScreenState extends State<JmFeedHomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state when widget is off-screen

  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  
  String _selectedFilter = 'New'; // Hot, New, Top
  String? _selectedLocation;
  String? _selectedCategory;
  String? _selectedLocationId;
  String? _selectedCategoryId;
  bool _isLocationDropdownOpen = false;
  bool _isCategoryDropdownOpen = false;
  bool _isTrendingDropdownOpen = false;
  _TrendingOption? _selectedTrending;
  late final ScrollController _scrollController;
  final GlobalKey _trendingDropdownKey = GlobalKey();
  final LayerLink _trendingDropdownLayerLink = LayerLink();
  OverlayEntry? _trendingDropdownOverlay;
  static const int _pageSize = 20;
  static const double _estimatedPostHeight = 520;
  static const double _loadMoreTriggerOffset = 200;
  bool _hasInitializedVisibleLimit = false;
  bool _isLoadingMore = false;
  int _visiblePostLimit = _pageSize;
  int _initialVisiblePostCapacity = _pageSize;
  int _currentOffset = 0;
  bool _hasMorePosts = true;
  
  // Seed posts + Remote posts pattern
  late final List<JmPostCardData> _seedPosts = _buildSeedPosts().take(3).toList();
  final List<JmPostCardData> _remotePosts = [];
  bool _isFeedFetching = false;
  
  // API data
  Map<String, String> _categoryMap = {}; // name -> id
  Map<String, String> _locationMap = {}; // name -> id
  List<String> _categoryOptions = ['All Categories'];
  List<String> _locationOptions = ['All Areas'];
  String? _errorMessage;
  
  // Profile and badge caching
  final Map<String, ProfileData> _profileCache = {};
  final Map<String, List<String>> _badgeCache = {};
  
  // Current user profile for welcome section
  ProfileData? _currentUserProfile;
  bool _isLoadingCurrentUserProfile = false;
  
  // Monthly Spotlight state
  bool _isLoadingSpotlightStatus = false;
  Map<String, dynamic>? _spotlightStatus;
  List<JmPostCardData> _spotlightPosts = [];
  bool _isLoadingSpotlightPosts = false;
  bool _isShowingSpotlightPosts = false;
  int _spotlightOffset = 0;
  bool _hasMoreSpotlightPosts = true;
  static const int _spotlightPageSize = 20;
  
  // Loading and UI state
  bool _shouldShowWelcomeModal = false;
  bool _shouldShowFirstPostCard = false;
  bool _isPageLoading = true;
  bool _isInitialPostsLoading = true;
  bool _isFirstLoad = true;
  bool _showWelcomeSection = true;

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

  // Category and location options will be loaded from API

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

  // Location and category options getters
  List<String> get _locationOptionsList {
    final List<String> options = ['All Areas'];
    final locationNames = _locationMap.keys.toList()..sort();
    options.addAll(locationNames);
    return options;
  }

  List<String> get _categoryOptionsList {
    final categoryNames = _categoryMap.keys.toList()..sort();
    return ['All Categories', ...categoryNames];
  }

  static const JmPostCardData _pinnedAdminPost = JmPostCardData(
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

  List<JmPostCardData> get _allPosts => [..._seedPosts, ..._remotePosts];

  List<JmPostCardData> get _filteredPosts => _postsForFilter(_selectedFilter);

  List<JmPostCardData> get _visiblePosts {
    // If showing spotlight posts, return those instead
    if (_isShowingSpotlightPosts) {
      if (_spotlightPosts.isEmpty) return const <JmPostCardData>[];
      final limit = math.min(_visiblePostLimit, _spotlightPosts.length);
      return _spotlightPosts.take(limit).toList();
    }

    // Otherwise, return regular filtered posts
    final posts = _filteredPosts;
    if (posts.isEmpty) return const <JmPostCardData>[];
    final limit = math.min(_visiblePostLimit, posts.length);
    return posts.take(limit).toList();
  }

  List<JmPostCardData> _postsForFilter(String filter) {
    switch (filter) {
      case 'Hot':
        // Hot filter: only remote posts (no seed posts), includes both hot and newPost variants
        return _remotePosts
            .where((post) => post.variant == PostCardVariant.hot || 
                            post.variant == PostCardVariant.newPost)
            .toList();
      case 'Top':
        // Top filter: only remote posts (no seed posts), includes both top and newPost variants
        return _remotePosts
            .where((post) => post.variant == PostCardVariant.top || 
                            post.variant == PostCardVariant.newPost)
            .toList();
      case 'New':
      default:
        // New filter: includes both seed posts and remote posts
        return _allPosts;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Don't set selectedTrending here - wait for API data
    
    // Run all independent operations in parallel for faster initialization
    _initializeData();
    
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVisibleLimit(),
    );
    
    // Fetch feed - loading screen will be hidden when feed loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFeed(reset: true, forceRefresh: false); // Use cache on initial load if available
    });
  }

  /// Initialize all data operations in parallel for faster loading
  Future<void> _initializeData() async {
    // Run all independent operations in parallel
    await Future.wait([
      _checkUserProfile(showFirstPostCard: widget.showFirstPostCard),
      _loadCurrentUserProfile(),
      _fetchSpotlightStatus(),
      _fetchCategoryAndLocationMappings(),
    ]);
  }

  Future<void> _checkUserProfile({bool showFirstPostCard = false}) async {
    // Check if user has any posts by querying Supabase directly
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _shouldShowWelcomeModal = false;
          _shouldShowFirstPostCard = false;
        });
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() {
          _shouldShowWelcomeModal = false;
          _shouldShowFirstPostCard = false;
        });
        return;
      }

      final userId = user.id;
      final response = await Supabase.instance.client
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1);

      if (!mounted) return;

      List<dynamic> postsList;
      if (response is List) {
        postsList = response;
      } else {
        debugPrint('WARNING: Unexpected response type from posts query: ${response.runtimeType}');
        postsList = [];
      }

      final hasPosts = postsList.isNotEmpty;
      debugPrint('User post check: userId=$userId, hasPosts=$hasPosts, postsFound=${postsList.length}');

      final prefs = await SharedPreferences.getInstance();
      final welcomeModalKey = 'welcome_modal_shown_$userId';
      final hasShownWelcomeModal = prefs.getBool(welcomeModalKey) ?? false;

      final shouldShowWelcome = !hasPosts && !hasShownWelcomeModal;

      setState(() {
        _shouldShowWelcomeModal = shouldShowWelcome;
        _shouldShowFirstPostCard = !hasPosts;
      });

      if (_shouldShowWelcomeModal) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showWelcomeModal(),
        );
      }
    } catch (e) {
      debugPrint('ERROR: Failed to check user posts: $e');
      if (!mounted) return;
      setState(() {
        _shouldShowWelcomeModal = false;
        _shouldShowFirstPostCard = false;
      });
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    setState(() {
      _isLoadingCurrentUserProfile = true;
    });

    try {
      final profileData = await _profileService.getProfileData();
      if (!mounted) return;
      setState(() {
        _currentUserProfile = profileData;
        _isLoadingCurrentUserProfile = false;
      });
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCurrentUserProfile = false;
      });
    }
  }

  Future<void> _fetchSpotlightStatus() async {
    if (_isLoadingSpotlightStatus) return;

    setState(() {
      _isLoadingSpotlightStatus = true;
    });

    try {
      final response = await _postService.getMonthlySpotlightStatus();
      if (!mounted) return;

      final success = response['success'] as bool? ?? false;
      if (!success) {
        setState(() {
          _isLoadingSpotlightStatus = false;
          _spotlightStatus = null;
        });
        return;
      }

      setState(() {
        _spotlightStatus = response;
        _isLoadingSpotlightStatus = false;

        final options = _trendingOptions;
        if (options.isNotEmpty && _selectedTrending == null) {
          _selectedTrending = options.first;
        }
      });
    } catch (e) {
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
      debugPrint('DEBUG: Loaded ${categories.length} categories and ${locations.length} locations');
      setState(() {
        _categoryMap = categories;
        _locationMap = locations;
        _categoryOptions = _categoryOptionsList;
        _locationOptions = _locationOptionsList;
      });
    } catch (e) {
      debugPrint('ERROR: Failed to fetch category/location mappings: $e');
    }
  }

  Future<void> _fetchSpotlightPosts({bool reset = false}) async {
    if (_isLoadingSpotlightPosts) return;
    if (!reset && !_hasMoreSpotlightPosts) return;

    setState(() {
      _isLoadingSpotlightPosts = true;
      _isShowingSpotlightPosts = true;
      if (reset) {
        _spotlightOffset = 0;
        _hasMoreSpotlightPosts = true;
      }
    });

    try {
      final nextOffset = reset ? 0 : _spotlightOffset;
      final response = await _postService.getMonthlySpotlightPosts(
        limit: _spotlightPageSize,
        offset: nextOffset,
      );

      if (!mounted) return;

      final success = response['success'] as bool? ?? false;
      if (!success) {
        final errorMessage = response['message'] as String? ?? 'Failed to load spotlight posts';
        throw Exception(errorMessage);
      }

      final respPostsList = (response['posts'] as List?) ?? const [];
      final pagination = response['pagination'] as Map<String, dynamic>?;
      final hasMore = pagination?['has_more'] as bool? ?? false;

      final postsList = respPostsList
          .map((post) {
            if (post is Map<String, dynamic>) return post;
            if (post is Map) return Map<String, dynamic>.from(post);
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      await _fetchProfilesForPosts(postsList);

      final variant = PostCardVariant.newPost;
      final mappedPosts = postsList
          .map((post) => _mapPostToCardData(post, variant))
          .whereType<JmPostCardData>()
          .toList();

      setState(() {
        if (reset) {
          _spotlightPosts = mappedPosts;
        } else {
          _spotlightPosts.addAll(mappedPosts);
        }
        _spotlightOffset = nextOffset + postsList.length;
        _hasMoreSpotlightPosts = hasMore;
        _isLoadingSpotlightPosts = false;

        final totalSpotlight = _spotlightPosts.length;
        if (reset) {
          _visiblePostLimit = math.min(_initialVisiblePostCapacity, totalSpotlight);
        } else {
          _visiblePostLimit = math.min(totalSpotlight, _visiblePostLimit + mappedPosts.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      PalToast.show(
        context,
        message: message.isEmpty ? 'Failed to load spotlight posts.' : message,
        isError: true,
      );
      setState(() {
        _isLoadingSpotlightPosts = false;
        if (reset) {
          _spotlightPosts = [];
        }
      });
    }
  }

  Future<void> _fetchProfilesForPosts(List<Map<String, dynamic>> posts) async {
    final Set<String> profileUserIds = {};
    final Set<String> badgeUserIds = {};

    for (final post in posts) {
      final userId = post['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        if (!_profileCache.containsKey(userId)) {
          profileUserIds.add(userId);
        }
        if (!_badgeCache.containsKey(userId)) {
          badgeUserIds.add(userId);
        }
      }
    }

    if (profileUserIds.isEmpty && badgeUserIds.isEmpty) return;

    final profileFutures = profileUserIds.map((userId) async {
      try {
        final profileData = await _profileService.getProfileDataByUserId(userId);
        return MapEntry(userId, profileData);
      } catch (e) {
        debugPrint('ERROR: Failed to fetch profile for user $userId: $e');
        return MapEntry(userId, null);
      }
    });

    final badgeFutures = badgeUserIds.map((userId) async {
      try {
        final badgeResponse = await _postService.getUserBadges(userId: userId);
        if (badgeResponse['success'] == true) {
          final badges = (badgeResponse['badges'] as List<dynamic>?)
                  ?.map((b) => b.toString())
                  .where((b) => b.isNotEmpty)
                  .toList() ??
              [];
          return MapEntry(userId, badges);
        }
        return MapEntry(userId, <String>[]);
      } catch (e) {
        debugPrint('ERROR: Failed to fetch badges for user $userId: $e');
        return MapEntry(userId, <String>[]);
      }
    });

    final profileResults = await Future.wait(profileFutures);
    final badgeResults = await Future.wait(badgeFutures);

    if (!mounted) return;

    setState(() {
      for (final entry in profileResults) {
        if (entry.value != null) {
          _profileCache[entry.key] = entry.value!;
        }
      }
      for (final entry in badgeResults) {
        _badgeCache[entry.key] = entry.value;
      }
    });
  }

  @override
  void didUpdateWidget(covariant JmFeedHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Show welcome modal if SQL logic determined user has 0 posts
    if (_shouldShowWelcomeModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
    }
    // Also handle widget.showWelcomeModal changes
    if (widget.showWelcomeModal &&
        !oldWidget.showWelcomeModal &&
        !_shouldShowWelcomeModal) {
      _shouldShowWelcomeModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _removeTrendingDropdownOverlay();
    super.dispose();
  }

  void _removeTrendingDropdownOverlay() {
    _trendingDropdownOverlay?.remove();
    _trendingDropdownOverlay = null;
    if (_isTrendingDropdownOpen) {
      setState(() {
        _isTrendingDropdownOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // neutral-50
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header section - Sticky
            PalAppHeader(
              showPostButton: true,
              onPostTap: () {
                showCreatePostModal(context).then((postCreated) {
                  if (postCreated == true && mounted) {
                    _refreshFeed();
                    _scrollToTop();
                  }
                });
              },
            ),

            // Filters and content
            Expanded(
              child: PalRefreshIndicator(
                onRefresh: _refreshFeed,
                child: Container(
                  color: const Color(0xFFFFFFFF), // #FFFFFF
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section - appears only at top, not sticky
                        if (_showWelcomeSection) _buildWelcomeSection(),
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

    // Seed posts are always available, so we always have content to show
    final hasContent = _seedPosts.isNotEmpty || _remotePosts.isNotEmpty;
    // Only show full loading overlay on very first page load, not when switching filters
    final shouldShowFullLoading =
        _isPageLoading &&
        _isFirstLoad &&
        !hasContent;

    if (shouldShowFullLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: PalLoadingOverlay(),
      );
    }

    // Only show overlay on very first page load, not when switching filters or refreshing
    // Filter switching and pull-to-refresh will show skeleton loading in the content area
    if (_isPageLoading && _isFirstLoad) {
      return Stack(children: [scaffold, const PalLoadingOverlay()]);
    }

    return scaffold;
  }

  Future<void> _showWelcomeModal() async {
    if (!_shouldShowWelcomeModal || !mounted) return;
    _shouldShowWelcomeModal = false;

    // Save flag to SharedPreferences that welcome modal has been shown
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final welcomeModalKey = 'welcome_modal_shown_${user.id}';
      await prefs.setBool(welcomeModalKey, true);
    }

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
      showCreatePostModal(context).then((postCreated) {
        if (postCreated == true && mounted) {
          _refreshFeed();
          _scrollToTop();
        }
      });
    }
  }

  List<JmPostCardData> _buildSeedPosts() {
    return [
      JmPostCardData(
        variant: PostCardVariant.top,
        username: '@pal_explorer',
        timeAgo: '2h ago',
        location: 'Victoria Island (VI)',
        category: 'Ask',
        title: 'Where should we host our next product meetup?',
        body: 'Looking for a cozy, semi-outdoor space around VI that can host about 30 people. Prefer somewhere with good WiFi and accessible parking.',
        commentsCount: 3,
        votes: 186,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      JmPostCardData(
        variant: PostCardVariant.hot,
        username: '@naija_foodie',
        timeAgo: '45m ago',
        location: 'Lekki Phase 1',
        category: 'Gist',
        title: 'Tasting tour: who has the best party jollof?',
        body: "Yellow Chilli? Ofada Boy? Share your undefeated jollof spots so we can plan a weekend tasting crawl.",
        commentsCount: 54,
        votes: 124,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
      JmPostCardData(
        variant: PostCardVariant.newPost,
        username: '@tech_sis',
        timeAgo: '10m ago',
        location: 'Yaba',
        category: 'Discussion',
        title: 'Coworking spaces with reliable power? ',
        body: 'Need recommendations for coworking spots on the mainland that stay powered through late nights. Bonus points for ergonomic chairs.',
        commentsCount: 12,
        votes: 8,
        avatarAsset: 'assets/feedPage/profile.png',
      ),
    ];
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

  Future<void> _fetchFeed({bool reset = false, bool forceRefresh = false}) async {
    if (_isFeedFetching) return;
    if (!_hasMorePosts && !reset && _selectedFilter != 'Hot' && _selectedFilter != 'Top') return;

    final locationOptions = _locationOptionsList;
    final hasLocationFilter = _selectedLocation != null &&
        locationOptions.isNotEmpty &&
        _selectedLocation != locationOptions.first &&
        _locationMap.containsKey(_selectedLocation);
    
    final categoryOptionsList = _categoryOptionsList;
    final hasCategoryFilter = _selectedCategory != null &&
        categoryOptionsList.isNotEmpty &&
        _selectedCategory != categoryOptionsList.first &&
        _categoryMap.containsKey(_selectedCategory);

    final sortParam = _sortParamForFilter(_selectedFilter);
    final nextOffset = reset ? 0 : _currentOffset;

    setState(() {
      _isFeedFetching = true;
      if (reset) {
        // Only clear posts if forcing refresh, otherwise keep cached data
        if (forceRefresh) {
          _remotePosts.clear();
        }
        _currentOffset = 0;
        _hasMorePosts = true;
        _isLoadingMore = false;
      } else {
        // Set loading more flag when fetching additional posts (not reset)
        _isLoadingMore = true;
      }
    });

    try {
      String? categoryId;
      String? locationId;

      if (hasCategoryFilter && _selectedCategory != null) {
        categoryId = _categoryMap[_selectedCategory];
      }

      if (hasLocationFilter && _selectedLocation != null) {
        locationId = _locationMap[_selectedLocation];
      }

      // Set timeFilter to "all_time" for Hot and Top filters
      final timeFilter = (_selectedFilter == 'Hot' || _selectedFilter == 'Top') 
          ? 'all_time' 
          : null;

      final response = await _postService.getFeed(
        sort: sortParam,
        limit: _pageSize,
        offset: nextOffset,
        categoryId: categoryId,
        locationId: locationId,
        timeFilter: timeFilter,
        forceRefresh: forceRefresh || reset, // Use forceRefresh parameter or reset flag
      );

      final success = response['success'] as bool? ?? true;
      if (!success) {
        final errorMessage = response['error'] as String? ??
            response['message'] as String? ??
            'Failed to load feed';
        throw Exception(errorMessage);
      }

      final pagination = response['pagination'] as Map<String, dynamic>?;
      final posts = (response['posts'] as List?) ?? const [];

      final postsList = posts
          .map((post) {
            if (post is Map<String, dynamic>) return post;
            if (post is Map) return Map<String, dynamic>.from(post);
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      await _fetchProfilesForPosts(postsList);

      // For Hot and Top filters: first post in initial fetch gets special variant, rest get newPost variant
      // When loading more (reset=false), all posts get newPost variant
      // For New filter: all posts get newPost variant
      final mappedPosts = <JmPostCardData>[];
      if ((_selectedFilter == 'Hot' || _selectedFilter == 'Top') && reset) {
        // Initial fetch: first post gets special variant, rest get newPost variant
        final specialVariant = _selectedFilter == 'Hot' 
            ? PostCardVariant.hot 
            : PostCardVariant.top;
        
        for (int i = 0; i < postsList.length; i++) {
          final variant = i == 0 ? specialVariant : PostCardVariant.newPost;
          final mappedPost = _mapPostToCardData(postsList[i], variant);
          if (mappedPost != null) {
            mappedPosts.add(mappedPost);
          }
        }
      } else {
        // New filter or loading more Hot/Top posts: all posts get newPost variant
        final mapped = postsList
            .map((post) => _mapPostToCardData(post, PostCardVariant.newPost))
            .whereType<JmPostCardData>()
            .toList();
        mappedPosts.addAll(mapped);
      }

      final hasMore = pagination?['has_more'] as bool? ?? false;
      final updatedOffset = pagination?['next_offset'] as int? ?? (nextOffset + posts.length);

      if (!mounted) return;
      setState(() {
        _remotePosts.addAll(mappedPosts);
        _currentOffset = updatedOffset;
        _hasMorePosts = hasMore;
        final filteredLength = _postsForFilter(_selectedFilter).length;
        if (reset) {
          _visiblePostLimit = math.min(_initialVisiblePostCapacity, filteredLength);
        } else {
          _visiblePostLimit = math.min(filteredLength, _visiblePostLimit + mappedPosts.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      PalToast.show(
        context,
        message: message.isEmpty ? 'Failed to load feed.' : message,
        isError: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isFeedFetching = false;
        _isInitialPostsLoading = false;
        _isLoadingMore = false;
        // Hide page loading screen after feed has loaded
        if (_isPageLoading) {
          _isPageLoading = false;
          _isFirstLoad = false;
        }
      });
    }
  }

  JmPostCardData? _mapPostToCardData(
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

    final username = (post['username'] ?? profile?['username'] ?? '@pal_user').toString();
    final category = (post['category_name'] ?? categoryMap?['name'] ?? '').toString();
    final location = (post['location_name'] ?? locationMap?['name'] ?? '').toString();

    final userId = post['user_id']?.toString();

    String? profilePictureUrl;
    String? initials;
    List<String>? badges;

    if (userId != null && _profileCache.containsKey(userId)) {
      final cachedProfile = _profileCache[userId]!;
      profilePictureUrl = cachedProfile.pictureUrl;
      initials = cachedProfile.initials;
    }

    if (userId != null && _badgeCache.containsKey(userId)) {
      badges = _badgeCache[userId]!;
    } else if (userId != null) {
      badges = [];
    }

    if (profilePictureUrl == null || profilePictureUrl.isEmpty) {
      profilePictureUrl = (post['profile_picture_url'] ??
              profile?['profile_picture_url'] ??
              post['avatar_url'] ??
              profile?['avatar_url'])
          ?.toString();
    }

    if (initials == null || initials.isEmpty) {
      String generateInitials(String name) {
        final cleanName = name.replaceAll('@', '').trim();
        if (cleanName.isEmpty) return 'U';
        final parts = cleanName.split(RegExp(r'[\s_]+'));
        if (parts.length >= 2) {
          return (parts.first[0] + parts.last[0]).toUpperCase();
        } else if (cleanName.length >= 2) {
          return cleanName.substring(0, 2).toUpperCase();
        } else {
          return cleanName[0].toUpperCase();
        }
      }
      initials = generateInitials(username);
    }

    final createdAt = DateTime.tryParse(post['created_at']?.toString() ?? '');

    final commentsCount = _parseInt(
      post['comments_count'] ?? post['comment_count'] ?? post['replies_count'],
    );
    final votes = _parseInt(
      post['votes'] ??
          post['upvote_count'] ??
          post['engagement_score'] ??
          post['net_score'],
    );

    return JmPostCardData(
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
      // Don't set avatarAsset for dynamic posts - let JmPostCard use profilePictureUrl/initials
      profilePictureUrl: profilePictureUrl,
      initials: initials,
      badges: badges,
      userId: userId,
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

  void _initializeVisibleLimit() {
    if (!mounted || _hasInitializedVisibleLimit) return;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.vertical;
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
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    if (!_isLoadingMore &&
        position.pixels >= position.maxScrollExtent - _loadMoreTriggerOffset) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    if (_isLoadingMore) return;

    if (_isShowingSpotlightPosts) {
      final totalSpotlight = _spotlightPosts.length;
      if (_visiblePostLimit >= totalSpotlight) {
        if (_hasMoreSpotlightPosts && !_isLoadingSpotlightPosts) {
          _fetchSpotlightPosts();
        }
        return;
      }
      final nextLimit = math.min(_visiblePostLimit + _spotlightPageSize, totalSpotlight);
      setState(() {
        _visiblePostLimit = nextLimit;
      });
      return;
    }

    final totalPosts = _filteredPosts.length;
    if (_visiblePostLimit >= totalPosts) {
      // If all posts are fetched and user scrolled to end, loop back to beginning
      if (!_hasMorePosts && !_isFeedFetching) {
        // Reset and fetch from beginning (offset 0) to get any new posts
        _fetchFeed(reset: true, forceRefresh: false); // Use cache when looping
        return;
      }
      // If there are more posts to fetch, continue fetching
      if (_hasMorePosts && !_isFeedFetching) {
        _fetchFeed();
      }
      return;
    }

    final nextLimit = math.min(_visiblePostLimit + _pageSize, totalPosts);
    setState(() {
      _visiblePostLimit = nextLimit;
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
    // Hide welcome section immediately when refresh starts
    if (_showWelcomeSection) {
      setState(() {
        _showWelcomeSection = false;
      });
      await Future.microtask(() {});
    }

    setState(() {
      _isInitialPostsLoading = true;

      // Reset all filters on pull to refresh
      _selectedFilter = 'New';
      _selectedLocation = null;
      _selectedCategory = null;
      _selectedLocationId = null;
      _selectedCategoryId = null;
      _selectedTrending = null;
      _isShowingSpotlightPosts = false;
      _spotlightPosts = [];
      _isLoadingSpotlightPosts = false;
      _spotlightOffset = 0;
      _hasMoreSpotlightPosts = true;
      _isLocationDropdownOpen = false;
      _isCategoryDropdownOpen = false;
      _isTrendingDropdownOpen = false;

      // Reset feed state
      _remotePosts.clear();
      _currentOffset = 0;
      _hasMorePosts = true;
      _isLoadingMore = false;
    });

    _resetVisibleLimitForFilter(_selectedFilter);

    await _fetchCategoryAndLocationMappings();
    await _fetchFeed(reset: true, forceRefresh: true); // Force refresh on pull-to-refresh
    await _fetchSpotlightStatus();

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isInitialPostsLoading = false;
    });
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
              // Clear posts when switching filters - different filters have different data
              // PostService cache will still provide fast response if available
              _remotePosts.clear();
              _currentOffset = 0;
              _hasMorePosts = true;
              _isShowingSpotlightPosts = false;
              _isInitialPostsLoading = true; // Show skeleton when switching filters
              _resetVisibleLimitForFilter(label);
            });
            // Show toast message for feed type change
            String toastMessage;
            switch (label) {
              case 'Hot':
                toastMessage = 'You are in hot feed';
                break;
              case 'Top':
                toastMessage = 'You are in top feed';
                break;
              case 'New':
              default:
                toastMessage = 'You are in new feed';
                break;
            }
            PalToast.show(context, message: toastMessage);
            // Use cache when switching filters (don't force refresh) - PostService will use cache if available
            _fetchFeed(reset: true, forceRefresh: false);
            _scrollToTop();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: isSelected ? _activeTabBackground : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
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
    final locationOptions = _locationOptionsList;
    final selectedLocation = _selectedLocation ??
        (locationOptions.isNotEmpty ? locationOptions.first : 'All Areas');
    final locationOptionsList = locationOptions
        .map((label) => _DropdownOption(label))
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
            leadingIcon: const Icon(Icons.location_on_outlined, size: 16),
            options: locationOptionsList,
            selectedValue: selectedLocation,
            highlightColor: _selectionHighlight,
            optionTextColor: _optionTextColor,
            borderColor: _slate200,
            showHeader: false,
            onSelected: (value) {
              final isAllAreas = locationOptions.isNotEmpty && value == locationOptions.first;
              debugPrint('DEBUG: Location selected: "$value" (isAllAreas: $isAllAreas)');
              setState(() {
                _selectedLocation = isAllAreas ? null : value;
                _selectedLocationId = isAllAreas ? null : _locationMap[value];
                _isLocationDropdownOpen = false;
                _remotePosts.clear();
                _currentOffset = 0;
                _hasMorePosts = true;
                _isLoadingMore = false;
                _isInitialPostsLoading = true; // Show skeleton when changing location filter
              });
              _fetchFeed(reset: true, forceRefresh: false); // Use cache when changing location
            },
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categoryOptionsList = _categoryOptionsList;

    if (categoryOptionsList.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _slate200, width: 1.513),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                'Loading categories...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _optionTextColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedCategory = _selectedCategory ??
        (categoryOptionsList.isNotEmpty
            ? categoryOptionsList.first
            : 'All Categories');
    final categoryOptions = categoryOptionsList
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
                              child:
                                  _categoryOptionIcons[selectedCategory] != null
                                  ? SvgPicture.asset(
                                      _categoryOptionIcons[selectedCategory]!,
                                      width: 16,
                                      height: 16,
                                    )
                                  : Icon(Icons.grid_view_rounded, size: 16),
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
                _selectedCategory = (categoryOptionsList.isNotEmpty &&
                        value == categoryOptionsList.first)
                    ? null
                    : value;
                _selectedCategoryId = (_selectedCategory == null) ? null : _categoryMap[_selectedCategory];
                _isCategoryDropdownOpen = false;
                _remotePosts.clear();
                _currentOffset = 0;
                _hasMorePosts = true;
                _isLoadingMore = false;
                _isInitialPostsLoading = true; // Show skeleton when changing category filter
              });
              _fetchFeed(reset: true, forceRefresh: false); // Use cache when changing category
            },
          ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      color: const Color(0xFFF7FBFF),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryColor, width: 2),
              ),
              child: _isLoadingCurrentUserProfile
                  ? Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : ProfileAvatarWidget(
                      imageUrl: _currentUserProfile?.pictureUrl,
                      initials: _currentUserProfile?.initials ?? 'P',
                      size: 60,
                      borderWidth: 0,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back, Pal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _primary900,
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover whats trending in your community',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF717182),
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWodCard() {
    final options = _trendingOptions;
    _TrendingOption? trending;

    String topicTitle = 'Detty December';
    String topicDescription = 'Share parties, owambe, concerts & nightlife vibes';
    int postCountValue = 1;
    String tagLabel = 'MONTHLY SPOTLIGHT';
    String iconAsset = 'assets/images/dettyIcon.svg';

    bool isSelected = false;
    if (options.isNotEmpty && _selectedTrending != null) {
      trending = _selectedTrending!;
      topicTitle = trending.label;
      topicDescription = trending.description;
      postCountValue = trending.postCount ?? 0;
      tagLabel = (trending.tag ?? 'Trending Topic').toUpperCase();
      iconAsset = trending.iconAsset;
      isSelected = true;

      if (trending.tag == 'Monthly Spotlight' && _spotlightStatus != null) {
        final hotTopicTitle = _spotlightStatus!['hot_topic_title'] as String?;
        final stats = _spotlightStatus!['stats'] as Map<String, dynamic>?;

        if (hotTopicTitle != null && hotTopicTitle.isNotEmpty) {
          topicTitle = hotTopicTitle;
        }

        if (stats != null) {
          final spotlightPostsRaw = stats['spotlight_posts'] ??
              stats['monthly_spotlight_posts'] ??
              stats['total_posts'];
          if (spotlightPostsRaw != null) {
            postCountValue = _parseInt(spotlightPostsRaw);
          }
        }

        if (_spotlightPosts.isNotEmpty && postCountValue == 0) {
          postCountValue = _spotlightPosts.length;
        }
      }
    }

    final postsLabel = '$postCountValue post${postCountValue == 1 ? '' : 's'}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CompositedTransformTarget(
          link: _trendingDropdownLayerLink,
          child: GestureDetector(
            key: _trendingDropdownKey,
            onTap: () {
              setState(() {
                _isLocationDropdownOpen = false;
                _isCategoryDropdownOpen = false;
                _isTrendingDropdownOpen = !_isTrendingDropdownOpen;
              });
              if (_isTrendingDropdownOpen) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showTrendingDropdownOverlay();
                });
              } else {
                _removeTrendingDropdownOverlay();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC6D2FF), width: 1),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 27.996,
                    height: 27.996,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAE9F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        iconAsset,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tagLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF4F39F6)
                                    : const Color(0xFF45556C),
                                fontFamily: 'Inter',
                                letterSpacing: isSelected ? 0.392 : 0.3672,
                                height: 15 / 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFCAD5E2),
                                fontFamily: 'Inter',
                                letterSpacing: -0.3125,
                                height: 24 / 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              postsLabel,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF62748E),
                                fontFamily: 'Inter',
                                letterSpacing: 0.167,
                                height: 13.5 / 9,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topicTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172B),
                            fontFamily: 'Inter',
                            letterSpacing: -0.0762,
                            height: 19.5 / 13,
                          ),
                        ),
                        const SizedBox(height: 0.51),
                        Text(
                          topicDescription,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF62748E),
                            fontFamily: 'Inter',
                            letterSpacing: 0.0645,
                            height: 16.5 / 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7.989),
                  _isTrendingDropdownOpen
                      ? Icon(
                          Icons.keyboard_arrow_up,
                          size: 16,
                          color: const Color(0xFF90A1B9),
                        )
                      : (isSelected
                          ? Container(
                              height: 18.991,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.99,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF432DD7),
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.1172,
                                    height: 15 / 10,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: const Color(0xFF90A1B9),
                            )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTrendingDropdownOverlay() {
    if (_trendingDropdownOverlay != null) {
      _removeTrendingDropdownOverlay();
      return;
    }

    final buttonContext = _trendingDropdownKey.currentContext;
    if (buttonContext == null || !buttonContext.mounted) {
      return;
    }

    final renderBox = buttonContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return;
    }

    final size = renderBox.size;
    final dropdownHeight = (_trendingOptions.length * 90.0).clamp(0.0, 400.0);

    _trendingDropdownOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenHeight = MediaQuery.of(overlayContext).size.height;

        final buttonContext = _trendingDropdownKey.currentContext;
        if (buttonContext == null || !buttonContext.mounted) {
          return const SizedBox.shrink();
        }

        final renderBox = buttonContext.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.attached) {
          return const SizedBox.shrink();
        }

        final offset = renderBox.localToGlobal(Offset.zero);
        final spaceBelow = screenHeight - offset.dy - size.height;
        final spaceAbove = offset.dy;
        final showBelow = spaceBelow >= dropdownHeight || spaceBelow >= spaceAbove;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification ||
                notification is ScrollUpdateNotification ||
                notification is ScrollEndNotification) {
              _removeTrendingDropdownOverlay();
            }
            return false;
          },
          child: Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeTrendingDropdownOverlay,
              child: Stack(
                children: [
                  CompositedTransformFollower(
                    link: _trendingDropdownLayerLink,
                    showWhenUnlinked: false,
                    offset: showBelow
                        ? Offset(0, size.height)
                        : Offset(0, -dropdownHeight),
                    child: Material(
                      elevation: 24,
                      color: Colors.transparent,
                      shadowColor: Colors.black.withOpacity(0.2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: size.width,
                          constraints: BoxConstraints(
                            maxHeight: dropdownHeight,
                          ),
                          child: _buildTrendingDropdownPanel(
                            _selectedTrending ??
                                (_trendingOptions.isNotEmpty
                                    ? _trendingOptions.first
                                    : _TrendingOption(
                                        tag: 'Monthly Spotlight',
                                        label: 'Detty December',
                                        description: 'Share parties, owambe, concerts & nightlife vibes',
                                        iconAsset: 'assets/images/dettyIcon.svg',
                                        iconColor: const Color.fromRGBO(79, 57, 246, 1),
                                        postCount: 1,
                                        isActive: true,
                                      )),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(buttonContext, rootOverlay: true).insert(_trendingDropdownOverlay!);
  }

  Widget _buildTrendingDropdownPanel(_TrendingOption currentSelection) {
    final options = _trendingOptions;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 1),
      constraints: const BoxConstraints(
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC6D2FF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: options.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    _removeTrendingDropdownOverlay();
    setState(() {
      _selectedTrending = option;
      _isTrendingDropdownOpen = false;
    });

    _fetchSpotlightPosts(reset: true);
    _scrollToTop();
  }

  List<_TrendingOption> get _trendingOptions {
    final List<_TrendingOption> options = [];

    if (_spotlightStatus != null) {
      final isAvailable = _spotlightStatus!['is_available'] as bool? ?? false;
      if (isAvailable) {
        final hotTopicTitle = _spotlightStatus!['hot_topic_title'] as String? ??
            'Monthly Spotlight';
        final stats = _spotlightStatus!['stats'] as Map<String, dynamic>?;
        final postCount = stats != null
            ? _parseInt(
                stats['spotlight_posts'] ??
                    stats['monthly_spotlight_posts'] ??
                    stats['total_posts'] ??
                    0,
              )
            : 0;

        options.add(
          _TrendingOption(
            tag: 'Monthly Spotlight',
            label: hotTopicTitle,
            description: 'Share posts related to the monthly spotlight topic',
            iconAsset: 'assets/images/dettyIcon.svg',
            iconColor: const Color.fromRGBO(79, 57, 246, 1),
            postCount: postCount,
            isActive: true,
          ),
        );
      }
    }

    if (options.isEmpty) {
      options.add(
        _TrendingOption(
          tag: 'Monthly Spotlight',
          label: 'Detty December',
          description: 'Share parties, owambe, concerts & nightlife vibes',
          iconAsset: 'assets/images/dettyIcon.svg',
          iconColor: const Color.fromRGBO(79, 57, 246, 1),
          postCount: 1,
          isActive: true,
        ),
      );
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
              showCreatePostModal(context).then((postCreated) {
                if (postCreated == true && mounted) {
                  _refreshFeed();
                  _scrollToTop();
                }
              });
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

  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final trending = _selectedTrending ??
        (_trendingOptions.isNotEmpty ? _trendingOptions.first : null);
    final postsToShow = _visiblePosts;
    
    if (_errorMessage != null && _allPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load posts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _optionTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchFeed(reset: true, forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationFilter(),
          const SizedBox(height: 12),
          _buildCategoryDropdown(),
          const SizedBox(height: 12),
          _buildWodCard(),
          const SizedBox(height: 24),
          // Show skeleton loading when initial loading OR when feed is fetching and no posts yet
          if (_isInitialPostsLoading || (_isFeedFetching && _remotePosts.isEmpty && !_isLoadingSpotlightPosts))
            ...List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LoadingPostSkeleton(),
              ),
            )
          else ...[
            if (_shouldShowFirstPostCard) ...[
              _buildFirstPostCard(),
              const SizedBox(height: 24),
            ],
            // Show WOD post as top pinned post for "New" filter
            if (_selectedFilter == 'New' && !_isShowingSpotlightPosts) ...[
              JmPostCard(
                data: const JmPostCardData(
                  variant: PostCardVariant.wod,
                  username: '@moderator',
                  timeAgo: '2h ago',
                  location: '',
                  category: '',
                  title: 'Problem for who dey government university',
                  body: 'ASUU has declared a nationwide university shutdown starting Friday, Nov 21, citing FG\'s failure to fully implement agreements on salaries & funding. This follows their Oct suspension of a warning strike and a one-month ultimatum that expired without resolution.',
                  commentsCount: 2,
                  votes: 235,
                  initials: 'MO',
                ),
                isPinnedAdmin: true,
              ),
              const SizedBox(height: 24),
              JmPostCard(data: _pinnedAdminPost, isPinnedAdmin: true),
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
              ...postsToShow.map((post) {
                try {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: JmPostCard(data: post),
                  );
                } catch (e, stackTrace) {
                  debugPrint('ERROR: Failed to render post ${post.id}: $e');
                  debugPrint('ERROR: Stack trace: $stackTrace');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Error loading post',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }
              }).toList(),
            if (_isLoadingMore)
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LoadingPostSkeleton(),
                ),
              ),
            // Only show "Scroll for more posts" if there are more posts to show locally
            // Don't show it when looping (when _hasMorePosts is false, it will loop automatically)
            if (!_isLoadingMore && 
                postsToShow.length < _filteredPosts.length && 
                _hasMorePosts)
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (option.tag ?? 'Trending Topic').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F39F6),
                              fontFamily: 'Inter',
                              letterSpacing: 0.392,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCAD5E2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$optionPostCount post${optionPostCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 10,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Inter',
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF62748E),
                        fontFamily: 'Inter',
                        letterSpacing: 0.05,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (option.isActive) ...[
                const SizedBox(width: 8),
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
                            colorFilter: option.iconColor == null ||
                                    option.iconAsset ==
                                        'assets/feedPage/categoryFilter.svg'
                                ? null
                                : ColorFilter.mode(option.iconColor!, BlendMode.srcIn),
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
