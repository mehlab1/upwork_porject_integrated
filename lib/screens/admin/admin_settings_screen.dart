import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import '../../widgets/pal_bottom_nav_bar.dart';
import '../../widgets/pal_loading_widgets.dart';
import '../../services/profile_service.dart';
import '../../services/admin_service.dart';
import '../../services/announcements_service.dart';
import '../../services/app_cache.dart';
import '../../services/post_service.dart';
import '../../services/suspended_users_service.dart';
import 'moderator_queue_screen.dart';
import 'junior_moderator_queue_screen.dart';
import 'content_curator_queue_screen.dart';
import 'announcements_screen.dart';
import 'wod_screen.dart';
import 'top_post_screen.dart';
import 'hot_post_screen.dart';
import 'postTypeScreens/hidden_posts_screen.dart';
import 'postTypeScreens/warned_posts_screen.dart';
import 'postTypeScreens/muted_posts_screen.dart';
import 'postTypeScreens/duplicated_posts_screen.dart';
import 'postTypeScreens/reported_posts_screen.dart';
import 'postTypeScreens/flagged_posts_screen.dart';
import 'accountScreens/suspended_account_screen.dart';
import 'accountScreens/banned_account_screen.dart';
import 'accountScreens/shadow_ban_screen.dart';
import 'accountScreens/flagged_account_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isPageLoading = true;
  final ProfileService _profileService = ProfileService();
  final AdminService _adminService = AdminService();
  final PostService _postService = PostService();
  ProfileData? _profileData;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    // Kick off all queue + stats prefetches immediately so data is ready
    // before the user taps any tile.
    AppCache().prefetchModQueuePosts();
    AppCache().prefetchModQueuePostsHistory();
    AppCache().prefetchModQueueCommentsNew();
    AppCache().prefetchModQueueCommentsHistory();
    AppCache().prefetchModQueueUsersNew();
    AppCache().prefetchModQueueUsersHistory();
    AppCache().prefetchJmQueuePosts();
    AppCache().prefetchJmQueuePostsHistory();
    AppCache().prefetchJmQueueCommentsNew();
    AppCache().prefetchJmQueueCommentsHistory();
    AppCache().prefetchCcQueuePosts();
    AppCache().prefetchCcQueueCommentsNew();
    AnnouncementsService().prefetch();
    AppCache().prefetchHiddenPosts();
    AppCache().prefetchWarnedPosts();
    AppCache().prefetchMutedPosts();
    AppCache().prefetchDuplicatedPosts();
    AppCache().prefetchReportedPosts();
    AppCache().prefetchFlaggedPosts();
    AppCache().prefetchShadowBanUsers();
    AppCache().prefetchBannedUsers();
    AppCache().prefetchWod();
    AppCache().prefetchTopPost();
    AppCache().prefetchHotPost();
    _postService.prefetchHotFeed();
    _postService.prefetchTopFeed();
    SuspendedUsersService().prefetch();
    // Remove artificial delay — show content immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() { _isPageLoading = false; });
    });
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final profileData = await _profileService.getProfileData();
      if (!mounted) return;
      setState(() {
        _profileData = profileData;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  String _getAdminSinceDate() {
    return 'Admin since December 2025';
  }


  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Heading
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 16, 15, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF7FBFF),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 120),
                  child: Column(
                    children: [
                      _AdministratorBadgeCard(
                        profileData: _profileData,
                        isLoading: _isLoadingProfile,
                        adminSince: _getAdminSinceDate(),
                      ),
                      const SizedBox(height: 20),
                      _SettingsSection(
                        title: 'COMMUNITY MEMBERS',
                        tiles: [
                          _SettingsTileData(
                            title: 'Moderator Queue',
                            subtitle: 'Keeps the community safe',
                            iconAsset:
                                'assets/adminIcons/adminSettings/shield-tick.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchModQueuePosts();
                              AppCache().prefetchModQueueCommentsNew();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ModeratorQueueScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Junior Moderator Queue',
                            subtitle: 'Helps enforce rules.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/shield.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchJmQueuePosts();
                              AppCache().prefetchJmQueueCommentsNew();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const JuniorModeratorQueueScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Content Curator Queue',
                            subtitle: 'Organizes content.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/medal.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchCcQueuePosts();
                              AppCache().prefetchCcQueueCommentsNew();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ContentCuratorQueueScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SettingsSection(
                        title: 'PINNED POSTS',
                        tiles: [
                          _SettingsTileData(
                            title: 'Announcement',
                            subtitle: 'Important update shared.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/headphone.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              // Pre-fetch immediately so the edge function warms
                              // up during the navigation animation, not after.
                              AnnouncementsService().prefetch();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AnnouncementsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Wahala of the day (WOD)',
                            subtitle: 'Today\'s trending issue.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/Megaphone.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchWod();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WodScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Top Post',
                            subtitle: 'Most notable post.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/Icon-1.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchTopPost();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TopPostScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Hot Post',
                            subtitle: 'Most active post.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/Icon.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchHotPost();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HotPostScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SettingsSection(
                        title: 'POST STATUS',
                        tiles: [
                          _SettingsTileData(
                            title: 'Hidden Conversations',
                            subtitle: 'Post temporarily deleted ',
                            iconAsset:
                                'assets/adminIcons/adminSettings/eye-slash.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchHiddenPosts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HiddenPostsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Warned Conversations',
                            subtitle: 'Warning Posts',
                            iconAsset:
                                'assets/adminIcons/adminSettings/warning-2.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchWarnedPosts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WarnedPostsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Muted Conversations',
                            subtitle: 'Silenced post',
                            iconAsset:
                                'assets/adminIcons/adminSettings/volume-slash.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchMutedPosts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MutedPostsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Duplicated Conversations',
                            subtitle: 'Repeated Post ',
                            iconAsset:
                                'assets/adminIcons/adminSettings/document-copy.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchDuplicatedPosts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DuplicatedPostsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SettingsSection(
                        title: 'DANGER ZONE',
                        tiles: [
                          _SettingsTileData(
                            title: 'Reported Conversations',
                            subtitle: 'Report Section',
                            iconAsset:
                                'assets/adminIcons/adminSettings/flag.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchReportedPosts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ReportedPostsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Flagged Account',
                            subtitle: 'Account  in review',
                            iconAsset:
                                'assets/adminIcons/adminSettings/flag-2.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFFE7000B),
                            titleColor: const Color(0xFFE7000B),
                            onTap: () {
                              AppCache().prefetchFlaggedPosts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FlaggedAccountScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Shadow Ban',
                            subtitle: 'Hides a user\'s activity.',
                            iconAsset:
                                'assets/adminIcons/adminSettings/ghost.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFF314158),
                            onTap: () {
                              AppCache().prefetchShadowBanUsers();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ShadowBanScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Suspended Account',
                            subtitle: 'Temporarily restricted account',
                            iconAsset:
                                'assets/adminIcons/adminSettings/timer-pause.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFFE7000B),
                            titleColor: const Color(0xFFE7000B),
                            onTap: () {
                              SuspendedUsersService().prefetch();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SuspendedAccountScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsTileData(
                            title: 'Banned Account:',
                            subtitle: 'Permanently blocked account',
                            iconAsset:
                                'assets/adminIcons/adminSettings/slash.svg',
                            iconBackground: const Color(0xFFF1F5F9),
                            iconTint: const Color(0xFFE7000B),
                            titleColor: const Color(0xFFE7000B),
                            onTap: () {
                              AppCache().prefetchBannedUsers();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BannedAccountScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: PalBottomNavigationBar(
          active: PalNavDestination.settings,
          onHomeTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          onNotificationsTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
          onSettingsTap: () {},
        ),
      ),
    );
    return Stack(
      children: [scaffold, if (_isPageLoading) const PalLoadingOverlay()],
    );
  }
}

class _AdministratorBadgeCard extends StatelessWidget {
  const _AdministratorBadgeCard({
    this.profileData,
    this.isLoading = false,
    required this.adminSince,
  });

  final ProfileData? profileData;
  final bool isLoading;
  final String adminSince;

  @override
  Widget build(BuildContext context) {
    final initials = profileData?.initials ?? 'AD';
    final profilePictureUrl = profileData?.pictureUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A000000), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Gradient border container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F39F6), Color(0xFF9810FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3), // Border width
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child:
                          profilePictureUrl != null &&
                              profilePictureUrl.isNotEmpty
                          ? Image.network(
                              profilePictureUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildInitialsPlaceholder(initials),
                            )
                          : _buildInitialsPlaceholder(initials),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                    height: 24 / 16, // line-height: 24px
                    letterSpacing: -0.31,
                    color: Color(0xFF0F172B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminSince,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    height: 20 / 14, // line-height: 20px
                    letterSpacing: -0.15,
                    color: Color(0xFF45556C),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F39F6), Color(0xFF9810FA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x334F39F6),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Color(0x334F39F6),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      svg.SvgPicture.asset(
                        'assets/adminIcons/adminSettings/crown.svg',
                        width: 12,
                        height: 12,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Inter',
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
    );
  }

  Widget _buildInitialsPlaceholder(String initials) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF314158),
            fontSize: 32,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.tiles});

  final String title;
  final List<_SettingsTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF62748E),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A000000), width: 0.8),
          ),
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                _SettingsTile(data: tiles[i]),
                if (i != tiles.length - 1)
                  const Divider(
                    height: 0,
                    thickness: 0.75,
                    color: Color(0xFFE2E8F0),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTileData {
  const _SettingsTileData({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.iconBackground,
    this.iconTint,
    this.trailingBuilder,
    this.titleColor,
    this.isDisabled = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final Color iconBackground;
  final Color? iconTint;
  final Color? titleColor;
  final WidgetBuilder? trailingBuilder;
  final bool isDisabled;
  final VoidCallback? onTap;
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data});

  final _SettingsTileData data;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = data.isDisabled;
    final Color titleColor = data.titleColor ?? const Color(0xFF0F172B);
    final Color subtitleColor = isDisabled
        ? const Color(0xFF94A3B8)
        : const Color(0xFF62748E);

    return InkWell(
      onTap: isDisabled ? null : data.onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDisabled
                    ? const Color(0xFFF1F5F9)
                    : data.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: svg.SvgPicture.asset(
                  data.iconAsset,
                  width: 18,
                  height: 18,
                  colorFilter: data.iconTint == null
                      ? (isDisabled
                            ? const ColorFilter.mode(
                                Color(0xFF94A3B8),
                                BlendMode.srcIn,
                              )
                            : null)
                      : ColorFilter.mode(
                          isDisabled ? const Color(0xFF94A3B8) : data.iconTint!,
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
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDisabled ? const Color(0xFF94A3B8) : titleColor,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 18,
              width: 18,
              child: data.trailingBuilder != null
                  ? data.trailingBuilder!(context)
                  : Center(
                      child: svg.SvgPicture.asset(
                        'assets/settings/dropDownIcon.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          isDisabled
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF90A1B9),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

