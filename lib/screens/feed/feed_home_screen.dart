import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  static const Color _slate600 = Color(0xFF62748E);
  static const Color _stateLayerShadow = Color(0x40000000);

  bool _shouldShowWelcomeModal = false;
  final List<PostCardData> _posts = [
    PostCardData(
      variant: PostCardVariant.top,
      username: '@foodie_naija',
      timeAgo: '3d ago',
      location: 'Victoria Island (VI)',
      category: 'Ask',
      title: "Best jollof rice spots in Lagos - Drop your recommendations!",
      body:
          "I've been on a mission to find the absolute best jollof rice in Lagos. So far I've tried Mama Put on Allen Avenue and the one at Cubana. What are your go-to spots? Party jollof vs restaurant jollof - which hits different?",
      commentsCount: 33,
      votes: 236,
      avatarAsset: 'assets/images/profile.svg',
    ),
    PostCardData(
      variant: PostCardVariant.hot,
      username: '@foodie_naija',
      timeAgo: '2h ago',
      location: 'Victoria Island (VI)',
      category: 'Ask',
      title: "Best jollof rice spots in Lagos - Drop your recommendations!",
      body:
          "I've been on a mission to find the absolute best jollof rice in Lagos. So far I've tried Mama Put on Allen Avenue and the one at Cubana. What are your go-to spots? Party jollof vs restaurant jollof - which hits different?",
      commentsCount: 28,
      votes: 235,
      avatarAsset: 'assets/images/profile.svg',
    ),
    PostCardData(
      variant: PostCardVariant.newPost,
      username: '@foodie_naija',
      timeAgo: '2h ago',
      location: 'Victoria Island (VI)',
      category: 'Ask',
      title: "Best jollof rice spots in Lagos - Drop your recommendations!",
      body:
          "I've been on a mission to find the absolute best jollof rice in Lagos. So far I've tried Mama Put on Allen Avenue and the one at Cubana. What are your go-to spots? Party jollof vs restaurant jollof - which hits different?",
      commentsCount: 3,
      votes: 236,
      avatarAsset: 'assets/images/profile.svg',
    ),
  ];

  List<PostCardData> get _filteredPosts {
    switch (_selectedFilter) {
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
    // During development we always surface the welcome modal so the team can iterate on the UI.
    _shouldShowWelcomeModal = true;
    if (_shouldShowWelcomeModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeModal());
    }
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

                    for (final post in _filteredPosts) PostCard(data: post),
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

  Widget _buildFilterButton(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    Color labelColor;
    switch (label) {
      case 'Hot':
        labelColor = _hotTabColor;
        break;
      case 'Top':
        labelColor = _topTabColor;
        break;
      case 'New':
      default:
        labelColor = _newTabColor;
    }

    Widget buildLeadingIcon() {
      if (label == 'Hot') {
        return SvgPicture.asset(
          'assets/images/hotIcon.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.white : labelColor,
            BlendMode.srcIn,
          ),
        );
      }
      if (label == 'New') {
        return SvgPicture.asset(
          'assets/images/newIcon.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.white : labelColor,
            BlendMode.srcIn,
          ),
        );
      }
      return Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : labelColor,
      );
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = label;
            });
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
                    color: isSelected ? Colors.white : labelColor,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _slate200, width: 1.513),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Show location filter
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _blue100,
                        border: Border.all(color: _slate200, width: 0.756),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: _primary900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Location Filter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primary900,
                        fontFamily: 'Inter',
                        letterSpacing: -0.1504,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.keyboard_arrow_down, size: 16, color: _primary900),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _slate200, width: 1.513),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Show category dropdown
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _blue100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: _primary900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Categories',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primary900,
                        fontFamily: 'Inter',
                        letterSpacing: -0.1504,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.keyboard_arrow_down, size: 16, color: _primary900),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySpotlight() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _slate200, width: 0.756),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle monthly spotlight filter
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _blue100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star_outline, size: 16, color: _primary900),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY SPOTLIGHT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _newTabColor,
                          fontFamily: 'Inter',
                          letterSpacing: 0.392,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detty December',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primary900,
                          fontFamily: 'Inter',
                          letterSpacing: -0.0762,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share parties, owambe, concerts & nightlife vibes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: _slate600,
                          fontFamily: 'Inter',
                          letterSpacing: 0.0645,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, size: 16, color: _primary900),
              ],
            ),
          ),
        ),
      ),
    );
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
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
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
