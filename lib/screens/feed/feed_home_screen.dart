import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'create_post_screen.dart';
import 'widgets/post_card.dart';
import '../../services/post_service.dart';
import '../../utils/time_formatter.dart';

class Variables {
  static const Color stateLayersErrorContainerOpacity16 = Color(0x29F9DEDC);
}

class FeedHomeScreen extends StatefulWidget {
  const FeedHomeScreen({super.key, this.showWelcomeModal = false});

  final bool showWelcomeModal;

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
  
  // API integration state
  final PostService _postService = PostService();
  List<PostCardData> _apiPosts = [];
  bool _isLoadingPosts = false;
  Map<String, dynamic>? _pagination;
  String? _errorMessage;
  Map<String, String> _categoryMap = {}; // category name -> id
  Map<String, String> _locationMap = {}; // location name -> id
  bool _isLoadingHotTopic = false;
  _TrendingOption? _currentHotTopic;
  List<_TrendingOption> _trendingOptionsFromApi = [];

  // Colors from Figma
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _activeTabBackground = Color(0xFF0F172B);
  static const Color _darkBlue = Color(0xFF0A1864);
  static const Color _grey50 = Color(0xFFF7FBFF);
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
      initials: 'LB',
    ),
    CommentData(
      author: '@naija_gourmet',
      timeAgo: '30m ago',
      body:
          "Party jollof is undefeated! There's something about that smoky flavor from the firewood.",
      upvotes: 38,
      downvotes: 0,
      avatarAsset: 'assets/images/profile.svg',
    ),
    CommentData(
      author: '@anonymous',
      timeAgo: 'just now',
      body: 'checking',
      upvotes: 1,
      downvotes: 0,
      initials: 'AN',
    ),
  ];

  bool _shouldShowWelcomeModal = false;
  
  // Preserve hardcoded posts
  late final List<PostCardData> _hardcodedPosts = _buildSeedPosts();
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
    id: null,
    avatarAsset: 'assets/feedPage/profile.png',
    comments: null,
  );

  // Combined posts: pinned admin + first 2 hardcoded + API posts
  List<PostCardData> get _allPosts {
    // First 2 hardcoded posts (preserve them)
    final firstTwoHardcoded = _hardcodedPosts.take(2).toList();
    // Combine: pinned admin + first 2 hardcoded + API posts
    return [_pinnedAdminPost, ...firstTwoHardcoded, ..._apiPosts];
  }
  
  List<PostCardData> get _filteredPosts => _postsForFilter(_selectedFilter);

  List<PostCardData> get _visiblePosts {
    final posts = _filteredPosts;
    if (posts.isEmpty) return const <PostCardData>[];
    
    // Remove hardcoded posts from visible posts (they're displayed separately)
    final apiPostsOnly = posts.where((post) => 
      post != _pinnedAdminPost && 
      !_hardcodedPosts.take(2).contains(post)
    ).toList();
    
    final limit = math.min(_visiblePostLimit, apiPostsOnly.length);
    return apiPostsOnly.take(limit).toList();
  }

  List<PostCardData> _postsForFilter(String filter) {
    final allPosts = _allPosts;
    switch (filter) {
      case 'Hot':
        return allPosts
            .where((post) => post.variant == PostCardVariant.hot)
            .toList();
      case 'Top':
        return allPosts
            .where((post) => post.variant == PostCardVariant.top)
            .toList();
      case 'New':
      default:
        return allPosts;
    }
  }

  // ============================================
  // Data Mapping Functions
  // ============================================

  /// Maps API post response to PostCardData
  PostCardData _mapApiPostToPostCardData(Map<String, dynamic> apiPost, String sortFilter) {
    // Determine variant based on sort filter and post metadata
    PostCardVariant variant;
    if (sortFilter == 'Hot' || apiPost['is_trending'] == true) {
      variant = PostCardVariant.hot;
    } else if (sortFilter == 'Top' || apiPost['is_monthly_spotlight'] == true) {
      variant = PostCardVariant.top;
    } else {
      variant = PostCardVariant.newPost;
    }

    // Extract username - try different possible field names
    final username = apiPost['username'] as String? ?? 
                    apiPost['user_username'] as String? ?? 
                    '@user';

    // Format time ago
    final createdAt = apiPost['created_at'] as String? ?? 
                     apiPost['created_at_iso'] as String?;
    final timeAgo = createdAt != null 
        ? TimeFormatter.formatTimeAgo(createdAt)
        : 'recently';

    // Extract location and category names
    final location = apiPost['location_name'] as String? ?? 
                    apiPost['location'] as String? ?? 
                    '';
    final category = apiPost['category_name'] as String? ?? 
                    apiPost['category'] as String? ?? 
                    '';

    // Extract content and split into title (first sentence) and body
    final content = apiPost['content'] as String? ?? '';
    
    // Split content into first sentence (title) and remaining (body)
    final parts = _splitContentIntoTitleAndBody(content);
    final title = parts['title'] ?? '';
    final body = parts['body'] ?? '';

    // Extract counts
    final commentsCount = (apiPost['comment_count'] as num?)?.toInt() ?? 0;
    final upvotes = (apiPost['upvote_count'] as num?)?.toInt() ?? 0;
    final downvotes = (apiPost['downvote_count'] as num?)?.toInt() ?? 0;
    final votes = upvotes - downvotes;

    // Extract avatar
    final avatarAsset = apiPost['profile_picture_url'] as String? ?? 
                       apiPost['avatar_url'] as String? ?? 
                       'assets/feedPage/profile.png';

    return PostCardData(
      variant: variant,
      username: username,
      timeAgo: timeAgo,
      location: location,
      category: category,
      title: title,
      body: body,
      commentsCount: commentsCount,
      votes: votes,
      id: apiPost['id'] as String?,
      avatarAsset: avatarAsset,
      comments: null, // Comments loaded on demand
    );
  }

  /// Splits content into title (first sentence) and body (remaining content)
  Map<String, String> _splitContentIntoTitleAndBody(String content) {
    if (content.isEmpty) {
      return {'title': '', 'body': ''};
    }

    // Find the first sentence ending (period, exclamation mark, or question mark)
    final sentenceEndings = RegExp(r'[.!?]');
    final match = sentenceEndings.firstMatch(content);
    
    if (match != null) {
      final firstSentenceEnd = match.end;
      // Extract title without trailing punctuation and body without leading space
      final title = content.substring(0, match.start).trim();
      final body = content.substring(firstSentenceEnd).trim();
      return {'title': title, 'body': body};
    } else {
      // If no sentence ending found, use first 100 characters as title
      final title = content.length > 100 ? content.substring(0, 100).trim() : content.trim();
      final body = content.length > 100 ? content.substring(100).trim() : '';
      return {'title': title, 'body': body};
    }
  }

  /// Maps API comment response to CommentData
  CommentData _mapApiCommentToCommentData(Map<String, dynamic> apiComment) {
    // Extract author
    final author = apiComment['username'] as String? ?? 
                  apiComment['user_username'] as String? ?? 
                  '@user';

    // Format time ago
    final createdAt = apiComment['created_at'] as String? ?? 
                     apiComment['created_at_iso'] as String?;
    final timeAgo = createdAt != null 
        ? TimeFormatter.formatTimeAgo(createdAt)
        : 'recently';

    // Extract content
    final body = apiComment['content'] as String? ?? '';

    // Extract votes
    final upvotes = (apiComment['upvote_count'] as num?)?.toInt() ?? 0;
    final downvotes = (apiComment['downvote_count'] as num?)?.toInt() ?? 0;

    // Extract avatar
    final avatarAsset = apiComment['profile_picture_url'] as String? ?? 
                       apiComment['avatar_url'] as String?;

    // Generate initials from username if no avatar
    final initials = avatarAsset == null && author.isNotEmpty
        ? author.replaceAll('@', '').substring(0, math.min(2, author.length)).toUpperCase()
        : null;

    return CommentData(
      author: author,
      timeAgo: timeAgo,
      body: body,
      upvotes: upvotes,
      downvotes: downvotes,
      avatarAsset: avatarAsset,
      initials: initials,
    );
  }

  /// Maps API hot topic response to _TrendingOption
  _TrendingOption _mapApiHotTopicToTrendingOption(Map<String, dynamic> apiHotTopic) {
    final title = apiHotTopic['title'] as String? ?? 'Trending Topic';
    final description = apiHotTopic['description'] as String? ?? '';
    final postCount = (apiHotTopic['post_count'] as num?)?.toInt() ?? 0;
    final isActive = apiHotTopic['is_active'] as bool? ?? false;

    // Use default icon and color for now
    // Can be customized based on hot topic data if needed
    return _TrendingOption(
      tag: 'Monthly Spotlight',
      label: title,
      description: description,
      iconAsset: 'assets/images/dettyIcon.svg',
      iconColor: const Color.fromRGBO(79, 57, 246, 1),
      postCount: postCount,
      isActive: isActive,
    );
  }

  // ============================================
  // API Integration Methods
  // ============================================

  /// Loads initial data: categories, locations, hot topic, and feed
  Future<void> _loadInitialData() async {
    try {
      // Load categories and locations in parallel
      final categoriesFuture = _postService.getCategories();
      final locationsFuture = _postService.getLocations();
      
      // Load hot topic
      _loadHotTopic();
      
      // Load categories and locations
      _categoryMap = await categoriesFuture;
      _locationMap = await locationsFuture;
      
      // Load feed posts
      await _loadFeedPosts();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    }
  }

  /// Loads hot topic for Monthly Spotlight
  Future<void> _loadHotTopic() async {
    if (_isLoadingHotTopic) return;
    
    setState(() {
      _isLoadingHotTopic = true;
    });

    try {
      final response = await _postService.getHotTopic(includePosts: false);
      
      if (response['success'] == true && response['hot_topic'] != null) {
        final hotTopic = _mapApiHotTopicToTrendingOption(response['hot_topic'] as Map<String, dynamic>);
        
        if (mounted) {
          setState(() {
            _currentHotTopic = hotTopic;
            _trendingOptionsFromApi = [hotTopic];
            _selectedTrending = hotTopic;
            _isLoadingHotTopic = false;
          });
        }
      } else {
        // Fallback to hardcoded trending options if API fails
        if (mounted) {
          setState(() {
            _isLoadingHotTopic = false;
          });
        }
      }
    } catch (e) {
      // Fallback to hardcoded trending options on error
      if (mounted) {
        setState(() {
          _isLoadingHotTopic = false;
        });
      }
    }
  }

  /// Loads feed posts from API
  Future<void> _loadFeedPosts({bool loadMore = false}) async {
    if (_isLoadingPosts && !loadMore) return;
    if (_isLoadingMore && loadMore) return;

    if (mounted) {
      setState(() {
        if (loadMore) {
          _isLoadingMore = true;
        } else {
          _isLoadingPosts = true;
          _errorMessage = null;
        }
      });
    }

    try {
      // Map filter to sort parameter
      String sort;
      String timeFilter = 'all'; // Default time filter
      switch (_selectedFilter) {
        case 'Hot':
          sort = 'hot';
          break;
        case 'Top':
          sort = 'top';
          // For top posts, we might want to add UI for time filter selection
          // For now, using 'all' as default
          break;
        case 'New':
        default:
          sort = 'latest';
          break;
      }

      // Get category and location IDs
      String? categoryId;
      if (_selectedCategory != null && _selectedCategory != _categoryOptions.first) {
        categoryId = _categoryMap[_selectedCategory];
      }

      String? locationId;
      if (_selectedLocation != null && _selectedLocation != _locationOptions.first) {
        locationId = _locationMap[_selectedLocation];
      }

      // Calculate offset
      final offset = loadMore ? (_apiPosts.length) : 0;

      // Call API
      final response = await _postService.getFeed(
        sort: sort,
        limit: _pageSize,
        offset: offset,
        categoryId: categoryId,
        locationId: locationId,
        timeFilter: timeFilter, // Add timeFilter parameter
      );

      if (response['success'] == true) {
        final posts = response['posts'] as List<dynamic>? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>?;

        // Map posts to PostCardData
        final mappedPosts = posts
            .map((post) => _mapApiPostToPostCardData(
                  post as Map<String, dynamic>,
                  _selectedFilter,
                ))
            .toList();

        if (mounted) {
          setState(() {
            if (loadMore) {
              _apiPosts.addAll(mappedPosts);
            } else {
              _apiPosts = mappedPosts;
            }
            _pagination = pagination;
            _isLoadingPosts = false;
            _isLoadingMore = false;
            _errorMessage = null;
          });
        }
      } else {
        throw Exception(response['error'] ?? response['message'] ?? 'Failed to load posts');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to load posts: ${e.toString()}';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Initialize with hardcoded options, will be updated when API loads
    _selectedTrending = _trendingOptions.first;
    // During development we always surface the welcome modal so the team can iterate on the UI.
    _shouldShowWelcomeModal = true;
    if (_shouldShowWelcomeModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVisibleLimit(),
    );
    // Load initial data from API
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadInitialData(),
    );
  }

  @override
  void didUpdateWidget(covariant FeedHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Filter buttons (Hot, New, Top)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _slate200, width: 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFilterButton(
                            'Hot',
                            Icons.local_fire_department,
                          ),
                          _buildFilterButton('New', Icons.new_releases),
                          _buildFilterButton('Top', Icons.trending_up),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Location Filter dropdown
                    _buildLocationFilter(),

                    const SizedBox(height: 12),

                    // Category dropdown
                    _buildCategoryDropdown(),

                    const SizedBox(height: 12),

                    // Monthly Spotlight card
                    _buildMonthlySpotlight(),

                    const SizedBox(height: 26),

                    // Create Your First Post card
                    _buildFirstPostCard(),

                    const SizedBox(height: 24),

                    PostCard(data: _pinnedAdminPost, isPinnedAdmin: true, postService: _postService),
                    const SizedBox(height: 24),
                    
                    // First 2 hardcoded posts (preserve them)
                    for (final post in _hardcodedPosts.take(2)) PostCard(data: post, postService: _postService),
                    const SizedBox(height: 24),

                    // API posts
                    for (final post in _visiblePosts) PostCard(data: post, postService: _postService),
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
                    if (!_isLoadingMore &&
                        _visiblePosts.length < _filteredPosts.length)
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
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
    // Check if we have more posts from API
    final hasMore = _pagination?['has_more'] == true;
    
    if (_isLoadingMore) return;
    
    // If API has more posts, load them
    if (hasMore) {
      _loadFeedPosts(loadMore: true);
      return;
    }
    
    // Otherwise, use existing pagination logic for visible posts
    final totalPosts = _filteredPosts.length;
    if (_visiblePostLimit >= totalPosts) {
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
        id: null,
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
              _resetVisibleLimitForFilter(label);
            });
            // Reload feed with new filter
            _loadFeedPosts();
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
                _selectedLocation = value;
                _isLocationDropdownOpen = false;
              });
              // Reload feed with new location filter
              _loadFeedPosts();
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
                _selectedCategory = value;
                _isCategoryDropdownOpen = false;
              });
              // Reload feed with new category filter
              _loadFeedPosts();
            },
          ),
      ],
    );
  }

  Widget _buildMonthlySpotlight() {
    // Use API data if available, otherwise fallback to hardcoded
    final availableOptions = _trendingOptionsFromApi.isNotEmpty 
        ? _trendingOptionsFromApi 
        : _trendingOptions;
    final trending = _selectedTrending ?? availableOptions.first;
    final postCountValue = trending.postCount ?? 0;
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
                        trending.label,
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
                        trending.description,
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
                if (trending.isActive)
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
        if (_isTrendingDropdownOpen) _buildTrendingDropdownPanel(trending),
      ],
    );
  }

  Widget _buildTrendingDropdownPanel(_TrendingOption currentSelection) {
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: (_trendingOptionsFromApi.isNotEmpty ? _trendingOptionsFromApi : _trendingOptions).length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final availableOptions = _trendingOptionsFromApi.isNotEmpty 
              ? _trendingOptionsFromApi 
              : _trendingOptions;
          final option = availableOptions[index];
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
  }

  static const List<_TrendingOption> _trendingOptions = [
    _TrendingOption(
      tag: 'Monthly Spotlight',
      label: 'Detty December',
      description: 'Share parties, owambe, concerts & nightlife vibes',
      iconAsset: 'assets/images/dettyIcon.svg',
      iconColor: Color.fromRGBO(79, 57, 246, 1),
      postCount: 1,
      isActive: true,
    ),
    _TrendingOption(
      tag: 'Community Pick',
      label: 'Weekend Brunch',
      description: 'Discover brunch spots & bottomless mimosa deals',
      iconAsset: 'assets/images/dettyIcon.svg',
      iconColor: Color(0xFF2B7FFF),
      postCount: 4,
      isActive: false,
    ),
    _TrendingOption(
      tag: 'City Guides',
      label: 'Island Nightlife',
      description: 'Best clubs, lounges & late-night chill spots',
      iconAsset: 'assets/images/dettyIcon.svg',
      iconColor: Color(0xFFFF6900),
      postCount: 3,
      isActive: false,
    ),
  ];

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

  Widget _buildBottomNavBar() {
    return Container(
      height: 84,
      decoration: BoxDecoration(color: _grey50),
      child: Stack(
        children: [
          Positioned(
            bottom: 11,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 62,
                decoration: BoxDecoration(
                  color: _grey50,
                  border: Border.all(
                    color: Colors.black.withOpacity(0.2),
                    width: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(38),
                ),
                child: Row(
                  children: [
                    // Feed button (active)
                    Container(
                      width: 119,
                      height: 62,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(38),
                      ),
                      child: Icon(Icons.home, color: Colors.white, size: 25),
                    ),
                    // Notifications button
                    Expanded(
                      child: Center(
                        child: Stack(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 25,
                              color: _primary900,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Settings button
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 24,
                        color: _primary900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
