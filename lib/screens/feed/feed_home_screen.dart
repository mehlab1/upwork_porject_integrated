import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pal_app/widgets/pal_bottom_nav_bar.dart';
import 'package:pal_app/widgets/pal_loading_widgets.dart';
import 'package:pal_app/widgets/pal_refresh_indicator.dart';
import 'package:pal_app/widgets/pal_push_notification.dart';

import 'create_post_screen.dart';
import 'widgets/post_card.dart';

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

  static const List<String> _categoryOptions = [
    'All Categories',
    'Gist',
    'Ask',
    'Discussion',
  ];

  static const Map<String, String> _categoryOptionIcons = {
    'All Categories': 'assets/feedPage/categoryFilter.svg',
    'Gist': 'assets/images/gistIcon.svg',
    'Ask': 'assets/images/askIcon.svg',
    'Discussion': 'assets/images/discussionIcon.svg',
  };
  static const Map<String, Color?> _categoryOptionIconColors = {
    'Gist': null,
    'Ask': null,
    'Discussion': null,
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
  bool _isPageLoading = true;
  bool _isInitialPostsLoading = true;
  late final List<PostCardData> _posts = _buildSeedPosts();

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

  List<PostCardData> get _filteredPosts => _postsForFilter(_selectedFilter);

  List<PostCardData> get _visiblePosts {
    final posts = _filteredPosts;
    if (posts.isEmpty) return const <PostCardData>[];
    final limit = math.min(_visiblePostLimit, posts.length);
    return posts.take(limit).toList();
  }

  List<PostCardData> _postsForFilter(String filter) {
    switch (filter) {
      case 'Hot':
        return _posts
            .where((post) => post.variant == PostCardVariant.hot)
            .toList();
      case 'Top':
        return _posts
            .where((post) => post.variant == PostCardVariant.top)
            .toList();
      case 'New':
      default:
        return _posts;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _selectedTrending = _trendingOptions.first;
    // Only show welcome modal when explicitly requested (e.g., after signup)
    _shouldShowWelcomeModal = widget.showWelcomeModal;
    if (_shouldShowWelcomeModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
    }
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
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/icon.svg',
                            width: 28,
                            height: 28,
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
                              top: 3,
                              left: 0,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'pal',
                                    style: TextStyle(
                                      fontSize: 37,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                      fontFamily: 'Inter',
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    '.',
                                    style: TextStyle(
                                      fontSize: 37,
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
      showCreatePostModal(context);
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
    if (_isLoadingMore || _visiblePostLimit >= totalPosts) {
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
    });
    _resetVisibleLimitForFilter(_selectedFilter);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isInitialPostsLoading = false;
    });
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
              _resetVisibleLimitForFilter(label);
            });
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
            leadingIcon: const Icon(Icons.location_on_outlined, size: 16),
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
                _selectedCategory = value;
                _isCategoryDropdownOpen = false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildMonthlySpotlight() {
    final trending = _selectedTrending ?? _trendingOptions.first;
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
                    width: 12,
                    height: 12,
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
        itemCount: _trendingOptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final option = _trendingOptions[index];
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
    final trending = _selectedTrending ?? _trendingOptions.first;
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
          if (_isTrendingDropdownOpen) ...[
            const SizedBox(height: 8),
            _buildTrendingDropdownPanel(trending),
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
            _buildFirstPostCard(),
            const SizedBox(height: 24),
            PostCard(data: _pinnedAdminPost, isPinnedAdmin: true),
            const SizedBox(height: 24),
            ...postsToShow
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PostCard(data: post),
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
