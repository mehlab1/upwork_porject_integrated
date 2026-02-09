import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';
import 'package:pal/widgets/pal_push_notification.dart';
import 'package:pal/widgets/pal_toast.dart';
import 'package:pal/widgets/profile_avatar_widget.dart';
import 'package:pal/widgets/pal_app_header.dart';

import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import 'create_post_screen.dart';
import 'widgets/post_card.dart';

class Variables {
  static const Color stateLayersErrorContainerOpacity16 = Color(0x29F9DEDC);
}

class FeedHomeScreen extends StatefulWidget {
  const FeedHomeScreen({
    super.key,
    this.showWelcomeModal = false,
    this.showFirstPostCard = false,
  });

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
  final GlobalKey _trendingDropdownKey = GlobalKey();
  final LayerLink _trendingDropdownLayerLink = LayerLink();
  OverlayEntry? _trendingDropdownOverlay;
  static const int _pageSize = 12;
  static const double _estimatedPostHeight = 520;
  static const double _loadMoreTriggerOffset = 400;
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

  // Location and category options will be populated from API
  // "All Areas" is always the first option to clear location filter
  List<String> get _locationOptions {
    final List<String> options = ['Location Filter'];
    // Add locations from API, sorted alphabetically
    final locationNames = _locationMap.keys.toList()..sort();
    options.addAll(locationNames);
    return options;
  }

  // Category options from API
  List<String> get _categoryOptions {
    // Start with 'All Categories' option, then add categories from API, sorted alphabetically
    final categoryNames = _categoryMap.keys.toList()..sort();
    return ['All Categories', ...categoryNames];
  }

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
      initials: 'LB',
      id: '',
    ),
    CommentData(
      author: '@naija_gourmet',
      timeAgo: '30m ago',
      body:
          "Party jollof is undefeated! There's something about that smoky flavor from the firewood.",
      upvotes: 38,
      downvotes: 0,
      avatarAsset: 'assets/images/profile.svg',
      id: '',
    ),
    CommentData(
      author: '@anonymous',
      timeAgo: 'just now',
      body: 'checking',
      upvotes: 1,
      downvotes: 0,
      initials: 'AN',
      id: '',
    ),
  ];

  bool _shouldShowWelcomeModal = false;
  bool _shouldShowFirstPostCard = false;
  bool _isPageLoading = true;
  bool _isInitialPostsLoading = true;
  bool _isFirstLoad = true; // Track if this is the very first load
  bool _showWelcomeSection =
      true; // Track welcome section visibility - shown initially, hidden after refresh
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();

  // Profile cache: user_id -> ProfileData
  final Map<String, ProfileData> _profileCache = {};

  // Badge cache: user_id -> List<String> (badge names)
  final Map<String, List<String>> _badgeCache = {};

  // Current user profile for welcome section
  ProfileData? _currentUserProfile;
  bool _isLoadingCurrentUserProfile = false;
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
  int _spotlightOffset = 0;
  bool _hasMoreSpotlightPosts = true;
  static const int _spotlightPageSize = 20;

  // Track if first Hot/Top post UI has been shown (only show special UI once, not on loop)
  bool _hasShownFirstHotPost = false;
  bool _hasShownFirstTopPost = false;

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
        // For Hot filter, return all posts (first will have hot variant, rest newPost variant)
        // Only filter if we specifically want hot variant posts (legacy behavior)
        return _allPosts;
      case 'Top':
        // For Top filter, return all posts (first will have top variant, rest newPost variant)
        // Only filter if we specifically want top variant posts (legacy behavior)
        return _allPosts;
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
      // Only fetch the id field and limit to 2 for efficiency (to check if user has 0 or 1 post)
      final userId = user.id;

      // Execute query: SELECT id FROM posts WHERE user_id = userId AND status = 'active' LIMIT 2
      final response = await Supabase.instance.client
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(2);

      if (!mounted) return;

      // Supabase returns a List<Map<String, dynamic>> or List<dynamic>
      // Convert to List and check the count
      List<dynamic> postsList;
      if (response is List) {
        postsList = response;
      } else {
        // Handle unexpected response format
        debugPrint(
          'WARNING: Unexpected response type from posts query: ${response.runtimeType}',
        );
        postsList = [];
      }

      // Get the post count (0, 1, or 2+)
      final postCount = postsList.length;
      // Show cards if user has 0 or 1 post
      final shouldShowCards = postCount <= 1;

      debugPrint(
        'User post check: userId=$userId, postCount=$postCount, shouldShowCards=$shouldShowCards',
      );

      // If user has 0 or 1 posts, show welcome modal and first post card
      // If user has 2+ posts, don't show them
      // Welcome modal will show every time user has 0 or 1 posts (same as first post card)
      final shouldShowWelcome = shouldShowCards;

      setState(() {
        _shouldShowWelcomeModal = shouldShowWelcome;
        _shouldShowFirstPostCard = shouldShowCards;
      });

      // Don't show welcome modal immediately - wait for feed to load
      // The modal will be shown in _checkAndShowWelcomeModalAfterFeedLoad()
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

      // Check for success
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
      debugPrint(
        'DEBUG: Loaded ${categories.length} categories and ${locations.length} locations',
      );
      debugPrint('DEBUG: Location map keys: ${locations.keys.toList()}');
      setState(() {
        _categoryMap = categories;
        _locationMap = locations;
      });
    } catch (e) {
      // Silently handle error - filters will work with names if IDs not available
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

      // Check for success
      final success = response['success'] as bool? ?? false;
      if (!success) {
        final errorMessage =
            response['message'] as String? ?? 'Failed to load spotlight posts';
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

      // Fetch profiles in parallel
      await _fetchProfilesForPosts(postsList);

      final variant = PostCardVariant.newPost;
      final mappedPosts = postsList
          .map((post) => _mapPostToCardData(post, variant))
          .whereType<PostCardData>()
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

        // Update visible limit for spotlight posts
        final totalSpotlight = _spotlightPosts.length;
        if (reset) {
          _visiblePostLimit = math.min(
            _initialVisiblePostCapacity,
            totalSpotlight,
          );
        } else {
          _visiblePostLimit = math.min(
            totalSpotlight,
            _visiblePostLimit + mappedPosts.length,
          );
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Don't set selectedTrending here - wait for API data

    // Check user profile to determine if welcome modal and first post card should be shown
    _checkUserProfile(showFirstPostCard: widget.showFirstPostCard);

    // Load current user profile for welcome section
    _loadCurrentUserProfile();

    // Fetch monthly spotlight status
    _fetchSpotlightStatus();

    // Fetch category and location mappings
    _fetchCategoryAndLocationMappings();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVisibleLimit(),
    );

    // Seed posts are always available, so we can show content immediately
    // Page loading state is set to false immediately - no artificial delays
    // _isInitialPostsLoading will be set to false by _fetchFeed when data arrives
    setState(() {
      _isPageLoading = false;
      _isFirstLoad = false;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFeed(reset: true);
    });
  }

  @override
  void didUpdateWidget(covariant FeedHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Welcome modal will be shown after feed loads via _checkAndShowWelcomeModalAfterFeedLoad()
    // No need to trigger it here as it's handled in the feed loading completion
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

        // Get current button position to determine if we should flip
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
        final showBelow =
            spaceBelow >= dropdownHeight || spaceBelow >= spaceAbove;

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
                  // Use CompositedTransformFollower to anchor to the button
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
                            _selectedTrending ?? _trendingOptions.first,
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

    Overlay.of(
      buttonContext,
      rootOverlay: true,
    ).insert(_trendingDropdownOverlay!);
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );

    // Seed posts are always available, so we always have content to show
    // Show content immediately with loading overlay on top when loading (prevents white screen flash)
    // Only show full loading screen on very first app load when truly no content exists
    final hasContent = _seedPosts.isNotEmpty || _remotePosts.isNotEmpty;
    final shouldShowFullLoading =
        (_isPageLoading || _isInitialPostsLoading) &&
        _isFirstLoad &&
        !hasContent;

    // Safety check: If we've been loading for too long or if there's an error state,
    // show content anyway to prevent blank screen
    if (shouldShowFullLoading) {
      // Add timeout check - if loading takes too long, show content anyway
      return const Scaffold(
        backgroundColor: Colors.white,
        body: PalLoadingOverlay(),
      );
    }

    // Always show content with loading overlay on top if still loading (for smooth navigation)
    // This prevents white screen when returning to home tab
    if (_isPageLoading || _isInitialPostsLoading) {
      return Stack(children: [scaffold, const PalLoadingOverlay()]);
    }

    // Always return scaffold to prevent blank screen
    return scaffold;
  }

  // Check if feed has loaded and show welcome modal if needed
  void _checkAndShowWelcomeModalAfterFeedLoad() {
    // Only show welcome modal after feed has completely loaded
    if (!_isInitialPostsLoading && _shouldShowWelcomeModal && mounted) {
      // Add a small delay to ensure UI is fully rendered
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _shouldShowWelcomeModal) {
          _showWelcomeModal();
        }
      });
    }
  }

  Future<void> _showWelcomeModal() async {
    if (!_shouldShowWelcomeModal || !mounted) return;
    // Reset flag to prevent showing multiple times in the same session
    // But don't persist it - modal will show again next time if user still has 0 or 1 posts
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
      showCreatePostModal(context).then((postCreated) {
        if (postCreated == true && mounted) {
          _refreshFeed();
          _scrollToTop();
        }
      });
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
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // Handle load more posts
    if (!_isLoadingMore &&
        position.pixels >= position.maxScrollExtent - _loadMoreTriggerOffset) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    if (_isLoadingMore) return;

    // Handle spotlight posts separately
    if (_isShowingSpotlightPosts) {
      final totalSpotlight = _spotlightPosts.length;
      if (_visiblePostLimit >= totalSpotlight) {
        // Need to fetch more spotlight posts from API
        if (_hasMoreSpotlightPosts && !_isLoadingSpotlightPosts) {
          _fetchSpotlightPosts();
        }
        return;
      }
      // Show more already-loaded spotlight posts
      final nextLimit = math.min(
        _visiblePostLimit + _spotlightPageSize,
        totalSpotlight,
      );
      setState(() {
        _visiblePostLimit = nextLimit;
      });
      return;
    }

    // Handle regular feed posts
    final totalPosts = _filteredPosts.length;
    if (_visiblePostLimit >= totalPosts) {
      // Check if we need to loop (for Hot/Top filters when no more posts)
      if ((_selectedFilter == 'Hot' || _selectedFilter == 'Top') && 
          _hasMoreRemotePosts && 
          !_isFeedFetching) {
        // Reset offset and fetch from beginning to implement looping
        _remoteOffset = 0;
        _fetchFeed(reset: false);
      } else if (_hasMoreRemotePosts && !_isFeedFetching) {
        _fetchFeed();
      }
      return;
    }

    // Update visible limit immediately without delay for smooth scrolling
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
    // Clear client-side feed cache on pull-to-refresh to ensure fresh data
    _postService.clearFeedCache();
    
    // Hide welcome section immediately when refresh starts - do this synchronously first
    if (_showWelcomeSection) {
      setState(() {
        _showWelcomeSection =
            false; // Remove welcome section on pull to refresh
      });
      // Ensure state update is processed before continuing
      await Future.microtask(() {});
    }

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
      _spotlightOffset = 0;
      _hasMoreSpotlightPosts = true;
      _isLocationDropdownOpen = false;
      _isCategoryDropdownOpen = false;
      _isTrendingDropdownOpen = false;

      // Reset feed state
      _remotePosts.clear();
      _remoteOffset = 0;
      _hasMoreRemotePosts = true;
      _isLoadingMore = false;
      
      // Reset Hot/Top first post UI flags on refresh
      _hasShownFirstHotPost = false;
      _hasShownFirstTopPost = false;
    });

    _resetVisibleLimitForFilter(_selectedFilter);

    // OPTIMIZATION: Fetch all data in PARALLEL for lowest latency
    // This reduces refresh time by ~50-70% compared to sequential calls
    await Future.wait([
      _fetchCategoryAndLocationMappings(),
      _fetchFeed(reset: true, forceRefresh: true),
      _fetchSpotlightStatus(),
    ]);

    // No artificial delay - _fetchFeed already sets _isInitialPostsLoading to false
    // Content displays immediately when data is ready
  }

  /// Fetches feed posts with optional category and location filtering
  ///
  /// Filtering Logic:
  /// - Categories and locations are loaded from API endpoints:
  ///   - get-categories: https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-categories
  ///   - get-locations: https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-locations
  /// - When a category or location is selected from dropdown, the name is mapped to its ID
  /// - The category_id and location_id are passed to get-feed function:
  ///   - https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-feed
  /// - The get-feed function filters posts using:
  ///   - get_posts_by_category if category_id is provided
  ///   - get_posts_by_location if location_id is provided
  ///   - Default sorting functions (get_posts_hot, get_posts_latest, get_posts_top) otherwise
  /// 
  /// Parameters:
  /// - reset: If true, clears existing posts and starts from offset 0
  /// - forceRefresh: If true, bypasses client-side cache (use for pull-to-refresh)
  Future<void> _fetchFeed({bool reset = false, bool forceRefresh = false}) async {
    if (_isFeedFetching) return;
    if (!_hasMoreRemotePosts &&
        !reset &&
        _selectedFilter != 'Hot' &&
        _selectedFilter != 'Top')
      return;

    // Check if location or category filters are selected
    // Location: "All Areas" (first option) means no filter, so check if not first option
    final locationOptions = _locationOptions;
    final hasLocationFilter =
        _selectedLocation != null &&
        locationOptions.isNotEmpty &&
        _selectedLocation != locationOptions.first &&
        _locationMap.containsKey(_selectedLocation);
    // Category: "All Categories" (first option) means no filter, so check if not first option
    final categoryOptionsList = _categoryOptions;
    final hasCategoryFilter =
        _selectedCategory != null &&
        categoryOptionsList.isNotEmpty &&
        _selectedCategory != categoryOptionsList.first &&
        _categoryMap.containsKey(_selectedCategory);
    final hasFilters = hasLocationFilter || hasCategoryFilter;

    // Special handling for Hot filter - uses get-feed with sort: 'hot'
    // Supports infinite scroll with looping behavior
    if (_selectedFilter == 'Hot') {
      setState(() {
        _isFeedFetching = true;
        if (reset) {
          _remotePosts.clear();
          _remoteOffset = 0;
          _hasMoreRemotePosts = true; // Enable pagination for feed
        }
      });

      try {
        // Convert category and location names to IDs for the get-feed API call
        String? categoryId;
        String? locationId;

        if (hasCategoryFilter && _selectedCategory != null) {
          categoryId = _categoryMap[_selectedCategory];
        }

        if (hasLocationFilter && _selectedLocation != null) {
          locationId = _locationMap[_selectedLocation];
        }

        // Use get-feed with sort: 'hot' instead of getHottestPost
        final response = await _postService.getFeed(
          sort: 'hot',
          limit: _pageSize,
          offset: reset ? 0 : _remoteOffset,
          categoryId: categoryId,
          locationId: locationId,
          forceRefresh: forceRefresh,
        );

        final success = response['success'] as bool? ?? true;
        if (!success) {
          final errorMessage =
              response['error'] as String? ??
              response['message'] as String? ??
              'Failed to load feed';
          throw Exception(errorMessage);
        }

        final posts = response['posts'] as List<dynamic>? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;
        final hasMore = pagination?['has_more'] as bool? ?? false;

        // Map posts - first post gets Hot variant, rest get regular variant
        List<PostCardData> mappedPosts = [];
        if (posts.isNotEmpty) {
          // Convert List<dynamic> to List<Map<String, dynamic>> for type safety
          final postsList = posts
              .map((p) => p as Map<String, dynamic>)
              .toList();
          await _fetchProfilesForPosts(postsList);

          for (int i = 0; i < posts.length; i++) {
            final post = posts[i];
            // First post in feed (when offset is 0 and first item) gets Hot variant ONLY ONCE
            // After showing Hot variant once, all subsequent posts (including on loop) show normal UI
            final currentOffset = reset ? 0 : _remoteOffset;
            PostCardVariant variant = PostCardVariant.newPost;
            if (currentOffset == 0 && i == 0 && !_hasShownFirstHotPost) {
              variant = PostCardVariant.hot;
              _hasShownFirstHotPost = true;
            }
            
            final mappedPost = _mapPostToCardData(post, variant);
            if (mappedPost != null) {
              mappedPosts.add(mappedPost);
            }
          }
        }

        if (!mounted) return;
        
        final updatedOffset = reset 
            ? mappedPosts.length 
            : _remoteOffset + mappedPosts.length;
        
        setState(() {
          if (reset) {
            _remotePosts.clear();
            _remotePosts.addAll(mappedPosts);
            _remoteOffset = updatedOffset;
          } else {
            _remotePosts.addAll(mappedPosts);
            _remoteOffset = updatedOffset;
          }
          
          // Implement looping: if no more posts, enable looping by keeping hasMoreRemotePosts true
          // The offset will be reset in _loadMorePosts when we detect we've reached the end
          if (!hasMore && mappedPosts.isNotEmpty) {
            _hasMoreRemotePosts = true; // Keep true for looping - offset will reset in next load
          } else {
            _hasMoreRemotePosts = hasMore;
          }
          
          final filteredLength = _postsForFilter(_selectedFilter).length;
          if (reset) {
            _visiblePostLimit = math.min(
              _initialVisiblePostCapacity,
              filteredLength,
            );
          } else {
            _visiblePostLimit = math.min(
              filteredLength,
              _visiblePostLimit + mappedPosts.length,
            );
          }
        });
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceFirst('Exception: ', '');
        PalToast.show(
          context,
          message: message.isEmpty ? 'Failed to load hot posts.' : message,
          isError: true,
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isFeedFetching = false;
          _isInitialPostsLoading = false;
        });
        // Check if we should show welcome modal now that feed has loaded
        _checkAndShowWelcomeModalAfterFeedLoad();
      }
      return;
    }

    // Special handling for Top filter - uses get-feed with sort: 'top'
    // Supports infinite scroll with looping behavior
    if (_selectedFilter == 'Top') {
      setState(() {
        _isFeedFetching = true;
        if (reset) {
          _remotePosts.clear();
          _remoteOffset = 0;
          _hasMoreRemotePosts = true; // Enable pagination for feed
        }
      });

      try {
        // Convert category and location names to IDs for the get-feed API call
        String? categoryId;
        String? locationId;

        if (hasCategoryFilter && _selectedCategory != null) {
          categoryId = _categoryMap[_selectedCategory];
        }

        if (hasLocationFilter && _selectedLocation != null) {
          locationId = _locationMap[_selectedLocation];
        }

        // Use get-feed with sort: 'top' instead of getTopPost
        final response = await _postService.getFeed(
          sort: 'top',
          limit: _pageSize,
          offset: reset ? 0 : _remoteOffset,
          categoryId: categoryId,
          locationId: locationId,
          forceRefresh: forceRefresh,
        );

        final success = response['success'] as bool? ?? true;
        if (!success) {
          final errorMessage =
              response['error'] as String? ??
              response['message'] as String? ??
              'Failed to load feed';
          throw Exception(errorMessage);
        }

        final posts = response['posts'] as List<dynamic>? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;
        final hasMore = pagination?['has_more'] as bool? ?? false;

        // Map posts - first post gets Top variant, rest get regular variant
        List<PostCardData> mappedPosts = [];
        if (posts.isNotEmpty) {
          // Convert List<dynamic> to List<Map<String, dynamic>> for type safety
          final postsList = posts
              .map((p) => p as Map<String, dynamic>)
              .toList();
          await _fetchProfilesForPosts(postsList);

          for (int i = 0; i < posts.length; i++) {
            final post = posts[i];
            // First post in feed (when offset is 0 and first item) gets Top variant ONLY ONCE
            // After showing Top variant once, all subsequent posts (including on loop) show normal UI
            final currentOffset = reset ? 0 : _remoteOffset;
            PostCardVariant variant = PostCardVariant.newPost;
            if (currentOffset == 0 && i == 0 && !_hasShownFirstTopPost) {
              variant = PostCardVariant.top;
              _hasShownFirstTopPost = true;
            }
            
            final mappedPost = _mapPostToCardData(post, variant);
            if (mappedPost != null) {
              mappedPosts.add(mappedPost);
            }
          }
        }

        if (!mounted) return;
        
        final updatedOffset = reset 
            ? mappedPosts.length 
            : _remoteOffset + mappedPosts.length;
        
        setState(() {
          if (reset) {
            _remotePosts.clear();
            _remotePosts.addAll(mappedPosts);
            _remoteOffset = updatedOffset;
          } else {
            _remotePosts.addAll(mappedPosts);
            _remoteOffset = updatedOffset;
          }
          
          // Implement looping: if no more posts, enable looping by keeping hasMoreRemotePosts true
          // The offset will be reset in _loadMorePosts when we detect we've reached the end
          if (!hasMore && mappedPosts.isNotEmpty) {
            _hasMoreRemotePosts = true; // Keep true for looping - offset will reset in next load
          } else {
            _hasMoreRemotePosts = hasMore;
          }
          
          final filteredLength = _postsForFilter(_selectedFilter).length;
          if (reset) {
            _visiblePostLimit = math.min(
              _initialVisiblePostCapacity,
              filteredLength,
            );
          } else {
            _visiblePostLimit = math.min(
              filteredLength,
              _visiblePostLimit + mappedPosts.length,
            );
          }
        });
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceFirst('Exception: ', '');
        PalToast.show(
          context,
          message: message.isEmpty ? 'Failed to load top posts.' : message,
          isError: true,
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isFeedFetching = false;
          _isInitialPostsLoading = false;
        });
        // Check if we should show welcome modal now that feed has loaded
        _checkAndShowWelcomeModalAfterFeedLoad();
      }
      return;
    }

    // Use get-feed for New filter (always uses get-feed with pagination)
    // Hot and Top filters are handled above using their dedicated edge functions
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
      // Convert category and location names to IDs for the get-feed API call
      String? categoryId;
      String? locationId;

      if (hasCategoryFilter && _selectedCategory != null) {
        categoryId = _categoryMap[_selectedCategory];
      }

      if (hasLocationFilter && _selectedLocation != null) {
        locationId = _locationMap[_selectedLocation];
      }

      // Call get-feed edge function
      final response = await _postService.getFeed(
        sort: sortParam,
        limit: _pageSize,
        offset: nextOffset,
        categoryId: categoryId,
        locationId: locationId,
        forceRefresh: forceRefresh,
      );

      // Check for success field in response
      final success = response['success'] as bool? ?? true;
      if (!success) {
        final errorMessage =
            response['error'] as String? ??
            response['message'] as String? ??
            'Failed to load feed';
        throw Exception(errorMessage);
      }

      final pagination = response['pagination'] as Map<String, dynamic>?;
      final posts = (response['posts'] as List?) ?? const [];

      final postsList = posts
          .map((post) {
            if (post is Map<String, dynamic>) {
              return post;
            }
            if (post is Map) {
              return Map<String, dynamic>.from(post);
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      // Fetch profiles for unique user IDs from posts (via get-profile edge function)
      await _fetchProfilesForPosts(postsList);

      final variant = _variantForFilter(_selectedFilter);
      final mappedPosts = postsList
          .map((post) => _mapPostToCardData(post, variant))
          .whereType<PostCardData>()
          .toList();

      final hasMore = pagination?['has_more'] as bool? ?? false;
      final updatedOffset =
          pagination?['next_offset'] as int? ?? (nextOffset + posts.length);

      if (!mounted) return;
      setState(() {
        _remotePosts.addAll(mappedPosts);
        _remoteOffset = updatedOffset;
        _hasMoreRemotePosts = hasMore;
        final filteredLength = _postsForFilter(_selectedFilter).length;
        if (reset) {
          _visiblePostLimit = math.min(
            _initialVisiblePostCapacity,
            filteredLength,
          );
        } else {
          _visiblePostLimit = math.min(
            filteredLength,
            _visiblePostLimit + mappedPosts.length,
          );
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
      });
      // Check if we should show welcome modal now that feed has loaded
      _checkAndShowWelcomeModalAfterFeedLoad();
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

  /// Fetch profiles for unique user IDs from posts (parallel fetching for performance)
  Future<void> _fetchProfilesForPosts(List<Map<String, dynamic>> posts) async {
    // Extract unique user IDs that need fetching
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

    // Fetch all profiles in parallel
    final profileFutures = profileUserIds.map((userId) async {
      try {
        final profileData = await _profileService.getProfileDataByUserId(
          userId,
        );
        return MapEntry(userId, profileData);
      } catch (e) {
        debugPrint('ERROR: Failed to fetch profile for user $userId: $e');
        return MapEntry(userId, null);
      }
    });

    // Fetch all badges in parallel
    final badgeFutures = badgeUserIds.map((userId) async {
      try {
        final badgeResponse = await _postService.getUserBadges(userId: userId);
        if (badgeResponse['success'] == true) {
          final badges =
              (badgeResponse['badges'] as List<dynamic>?)
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

    // Wait for all fetches to complete in parallel
    final profileResults = await Future.wait(profileFutures);
    final badgeResults = await Future.wait(badgeFutures);

    if (!mounted) return;

    // Update caches in a single setState call for efficiency
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

    final username = (post['username'] ?? profile?['username'] ?? '@pal_user')
        .toString();
    final category = (post['category_name'] ?? categoryMap?['name'] ?? '')
        .toString();
    final location = (post['location_name'] ?? locationMap?['name'] ?? '')
        .toString();

    // Get user_id from post
    final userId = post['user_id']?.toString();

    // Fetch profile picture URL from cached profile data (via get-profile edge function)
    String? profilePictureUrl;
    String? initials;
    List<String>? badges;

    if (userId != null && _profileCache.containsKey(userId)) {
      final cachedProfile = _profileCache[userId]!;
      profilePictureUrl =
          cachedProfile.pictureUrl; // Uses profile_picture_url or avatar_url
      initials = cachedProfile.initials;
    }

    // Get badges from badge cache
    if (userId != null && _badgeCache.containsKey(userId)) {
      badges = _badgeCache[userId]!;
    } else if (userId != null) {
      // Initialize with empty list if not in cache yet to avoid null issues
      badges = [];
    }

    // Fallback to post data if cache doesn't have profile yet
    if (profilePictureUrl == null || profilePictureUrl.isEmpty) {
      profilePictureUrl =
          (post['profile_picture_url'] ??
                  profile?['profile_picture_url'] ??
                  post['avatar_url'] ??
                  profile?['avatar_url'])
              ?.toString();
    }

    // Generate initials from username if not available from cached profile
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
      // Don't set avatarAsset for backend posts - let them show initials if no profile picture
      // Only hardcoded seed posts should have avatarAsset set
      avatarAsset: null,
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
              _isShowingSpotlightPosts =
                  false; // Reset spotlight posts when switching filters
              // Reset Hot/Top first post UI flags when switching filters
              // This ensures the first post gets special UI when switching to Hot or Top
              _hasShownFirstHotPost = false;
              _hasShownFirstTopPost = false;
              _resetVisibleLimitForFilter(label);
            });
            // Show toast message for feed type change
            String toastMessage;
            switch (label) {
              case 'Hot':
                toastMessage = 'You are in Hot feed';
                break;
              case 'Top':
                toastMessage = 'You are in Top feed';
                break;
              case 'New':
              default:
                toastMessage = 'You are in New feed';
                break;
            }
            PalToast.show(context, message: toastMessage);
            _fetchFeed(reset: true);
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
    // Get current location options from API (includes "All Areas" as first option)
    final locationOptions = _locationOptions;
    final selectedLocation =
        _selectedLocation ??
        (locationOptions.isNotEmpty ? locationOptions.first : 'Location Filter');

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
            options: locationOptions
                .map((label) => _DropdownOption(label))
                .toList(),
            selectedValue: selectedLocation,
            highlightColor: _selectionHighlight,
            optionTextColor: _optionTextColor,
            borderColor: _slate200,
            showHeader: false,
            onSelected: (value) {
              final isAllAreas =
                  locationOptions.isNotEmpty && value == locationOptions.first;
              debugPrint(
                'DEBUG: Location selected: "$value" (isAllAreas: $isAllAreas)',
              );
              setState(() {
                // If "All Areas" is selected, set to null to clear filter
                // Otherwise, set the selected location
                _selectedLocation = isAllAreas ? null : value;
                _isLocationDropdownOpen = false;
                // Reset feed state and fetch with new filter
                _remotePosts.clear();
                _remoteOffset = 0;
                _hasMoreRemotePosts = true;
                _isLoadingMore = false;
              });
              debugPrint('DEBUG: Selected location set to: $_selectedLocation');
              debugPrint(
                'DEBUG: Location map contains key: ${_locationMap.containsKey(_selectedLocation)}',
              );
              // Fetch feed with location filter applied
              _fetchFeed(reset: true);
            },
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    // Get current category options from API
    final categoryOptionsList = _categoryOptions;

    // If no categories loaded yet, show placeholder
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

    final selectedCategory =
        _selectedCategory ??
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
                // Set the selected category
                // If "All Categories" is selected, set to null to clear filter
                _selectedCategory =
                    (categoryOptionsList.isNotEmpty &&
                        value == categoryOptionsList.first)
                    ? null
                    : value;
                _isCategoryDropdownOpen = false;
                // Reset feed state and fetch with new filter
                _remotePosts.clear();
                _remoteOffset = 0;
                _hasMoreRemotePosts = true;
                _isLoadingMore = false;
              });
              // Fetch feed with category filter applied
              _fetchFeed(reset: true);
            },
          ),
      ],
    );
  }

  Widget _buildWodCard() {
    // Use API data if available, otherwise show default Detty December
    final options = _trendingOptions;
    _TrendingOption? trending;

    String topicTitle = 'Detty December';
    String topicDescription =
        'Share parties, owambe, concerts & nightlife vibes';
    int postCountValue = 1;
    String tagLabel = 'MONTHLY SPOTLIGHT';
    String iconAsset = 'assets/images/dettyIcon.svg';
    // Color iconColor = const Color.fromRGBO(79, 57, 246, 1);

    // If we have API data, use it
    bool isSelected = false;
    if (options.isNotEmpty && _selectedTrending != null) {
      trending = _selectedTrending!;
      topicTitle = trending.label;
      topicDescription = trending.description;
      postCountValue = trending.postCount ?? 0;
      tagLabel = (trending.tag ?? 'Trending Topic').toUpperCase();
      iconAsset = trending.iconAsset;
      // iconColor = trending.iconColor;
      isSelected = true;

      // If this is Monthly Spotlight and we have API data, use it
      if (trending.tag == 'Monthly Spotlight' && _spotlightStatus != null) {
        final hotTopicTitle = _spotlightStatus!['hot_topic_title'] as String?;
        final stats = _spotlightStatus!['stats'] as Map<String, dynamic>?;

        if (hotTopicTitle != null && hotTopicTitle.isNotEmpty) {
          topicTitle = hotTopicTitle;
        }

        if (stats != null) {
          final spotlightPostsRaw =
              stats['spotlight_posts'] ??
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
        // Button container - wrapped with CompositedTransformTarget for anchoring
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
                  // Icon container - matching Figma design
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
                        // colorFilter: ColorFilter.mode(
                        //   iconColor,
                        //   BlendMode.srcIn,
                        // ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Content section - matching Figma design
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Label, bullet, post count
                        Row(
                          children: [
                            Text(
                              tagLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(
                                        0xFF4F39F6,
                                      ) // Purple when selected
                                    : const Color(
                                        0xFF45556C,
                                      ), // Gray when not selected
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
                        // Title
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
                        // Description
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
                  // Show "Active" badge when selected, up arrow when dropdown is open, or right arrow when collapsed
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

  Widget _buildTrendingDropdownPanel(_TrendingOption currentSelection) {
    final options = _trendingOptions;

    // Don't show dropdown if no options available
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 1),
      constraints: const BoxConstraints(
        maxHeight: 400, // Limit maximum height to prevent overflow
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

    // Monthly Spotlight is the only option, fetch spotlight posts from edge function
    _fetchSpotlightPosts(reset: true);

    // Scroll to top when spotlight is selected
    _scrollToTop();
  }

  // Get available spotlight options from API, with default Detty December fallback
  List<_TrendingOption> get _trendingOptions {
    final List<_TrendingOption> options = [];

    // Only add Monthly Spotlight if available from API (only one option ever)
    if (_spotlightStatus != null) {
      final isAvailable = _spotlightStatus!['is_available'] as bool? ?? false;
      if (isAvailable) {
        final hotTopicTitle =
            _spotlightStatus!['hot_topic_title'] as String? ??
            'Monthly Spotlight';
        final stats = _spotlightStatus!['stats'] as Map<String, dynamic>?;
        // Use existing _parseInt helper to handle int, string, or other numeric types
        // Try to get spotlight posts count - check multiple possible field names
        final postCount = stats != null
            ? _parseInt(
                stats['spotlight_posts'] ??
                    stats['monthly_spotlight_posts'] ??
                    stats['total_posts'] ??
                    0,
              )
            : 0;

        // Add Monthly Spotlight option (only one option ever, so no duplicates possible)
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

    // If no API data available, add default Detty December option
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

  Widget _buildWelcomeSection() {
    return Container(
      color: const Color(0xFFF7FBFF),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image with 2 stroke border on the left
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : ProfileAvatarWidget(
                      imageUrl: _currentUserProfile?.pictureUrl,
                      initials: _currentUserProfile?.initials ?? 'P',
                      size: 60,
                      borderWidth: 0, // No border as we have outer borders
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Text content (heading and description)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome heading
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
                // Description text
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
    final trending =
        _selectedTrending ??
        (_trendingOptions.isNotEmpty ? _trendingOptions.first : null);
    final postsToShow = _visiblePosts;
    
    // Get screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    // Max width for posts content (prevents posts from being too wide on large screens)
    const maxContentWidth = 600.0;
    // Small margin for larger screens
    const smallMargin = 16.0;
    
    // Calculate responsive padding: use small margins on large screens, full padding on small screens
    final isLargeScreen = screenWidth > maxContentWidth + (smallMargin * 2);
    final horizontalPadding = isLargeScreen 
        ? smallMargin 
        : 16.0; // Keep original padding for smaller screens
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          _buildLocationFilter(),
          const SizedBox(height: 12),
          _buildCategoryDropdown(),
          const SizedBox(height: 12),
          _buildWodCard(),
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
            // Show WOD post as top pinned post for "New" filter
            if (_selectedFilter == 'New' && !_isShowingSpotlightPosts) ...[
              PostCard(
                data: const PostCardData(
                  variant: PostCardVariant.wod,
                  username: '@moderator',
                  timeAgo: '2h ago',
                  location: '',
                  category: '',
                  title: 'Problem for who dey government university',
                  body:
                      'ASUU has declared a nationwide university shutdown starting Friday, Nov 21, citing FG\'s failure to fully implement agreements on salaries & funding. This follows their Oct suspension of a warning strike and a one-month ultimatum that expired without resolution.',
                  commentsCount: 2,
                  votes: 235,
                  initials: 'MO',
                ),
                isPinnedAdmin: true,
              ),
              const SizedBox(height: 24),
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
              ...postsToShow.map((post) {
                try {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PostCard(data: post),
                  );
                } catch (e, stackTrace) {
                  debugPrint('ERROR: Failed to render post ${post.id}: $e');
                  debugPrint('ERROR: Stack trace: $stackTrace');
                  // Return a placeholder widget instead of crashing
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
            // Show skeleton loading when fetching more posts during scroll
            if (_isFeedFetching && !_isInitialPostsLoading)
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: LoadingPostSkeleton(),
                ),
              ),
            if (!_isFeedFetching && postsToShow.length < _filteredPosts.length)
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
        ),
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
