import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/widgets/pal_toast.dart';
import 'package:pal/services/profile_service.dart';

class ReviewerBlockedAccountsScreen extends StatefulWidget {
  const ReviewerBlockedAccountsScreen({super.key});

  static const routeName = '/settings/blocked-accounts';

  @override
  State<ReviewerBlockedAccountsScreen> createState() => _JmBlockedAccountsScreenState();
}

class _JmBlockedAccountsScreenState extends State<ReviewerBlockedAccountsScreen> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _unblockingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _profileService.getBlockedUsers();

      if (!mounted) return;

      if (response['success'] == true) {
        final blockedUsers = response['blocked_users'] as List<dynamic>? ?? [];
        setState(() {
          _blockedUsers = blockedUsers.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message']?.toString() ?? 'Failed to load blocked users';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(String userId, String username) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UnblockUserDialog(username: username),
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    // Show loading state for this user
    setState(() {
      _unblockingUsers.add(userId);
    });

    try {
      final response = await _profileService.unblockUser(userId);

      if (!mounted) return;

      if (response['success'] == true) {
        // Remove from local list
        setState(() {
          _blockedUsers.removeWhere(
            (user) => user['id'] == userId || user['blocked_user_id'] == userId,
          );
          _unblockingUsers.remove(userId);
        });

        PalToast.show(
          context,
          message:
              'You\'ve unblocked $username. You\'ll be able to see each other\'s posts and interact again.',
        );
      } else {
        setState(() {
          _unblockingUsers.remove(userId);
        });
        PalToast.show(
          context,
          message: response['message']?.toString() ?? 'Failed to unblock user',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _unblockingUsers.remove(userId);
      });
      PalToast.show(
        context,
        message:
            'Failed to unblock user: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  String _getInitials(String username) {
    final cleanName = username.replaceAll('@', '').trim();
    if (cleanName.isEmpty) return 'U';

    final parts = cleanName.split(RegExp(r'[\s_]+'));
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (cleanName.length >= 2) {
      return cleanName.substring(0, 2).toUpperCase();
    } else {
      return cleanName[0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BlockedAccountsHeader(),
            Expanded(
              child: Container(
                color: const Color(0xFFFAFAFA),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBlockedUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isSmallScreen = screenWidth < 360;
                          final isLargeScreen = screenWidth > 600;

                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              isSmallScreen
                                  ? 12
                                  : isLargeScreen
                                  ? 24
                                  : 16,
                              24,
                              isSmallScreen
                                  ? 12
                                  : isLargeScreen
                                  ? 24
                                  : 16,
                              120,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // About Blocking Card
                                _AboutBlockingCard(
                                  isSmallScreen: isSmallScreen,
                                  isLargeScreen: isLargeScreen,
                                ),
                                SizedBox(
                                  height: isSmallScreen
                                      ? 16
                                      : isLargeScreen
                                      ? 32
                                      : 24,
                                ),
                                // Content: Empty state or blocked users list
                                _blockedUsers.isEmpty
                                    ? _EmptyStateCard(
                                        isSmallScreen: isSmallScreen,
                                        isLargeScreen: isLargeScreen,
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ..._blockedUsers.map((user) {
                                            final userId =
                                                user['blocked_user_id']
                                                    ?.toString() ??
                                                user['id']?.toString() ??
                                                '';
                                            final username =
                                                user['blocked_username']
                                                    ?.toString() ??
                                                user['username']?.toString() ??
                                                '@user';
                                            final profilePictureUrl =
                                                user['blocked_profile_picture_url']
                                                    ?.toString() ??
                                                user['profile_picture_url']
                                                    ?.toString();
                                            final blockedAt = user['blocked_at']
                                                ?.toString();
                                            final initials = _getInitials(
                                              username,
                                            );
                                            final isUnblocking =
                                                _unblockingUsers.contains(
                                                  userId,
                                                );

                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: isSmallScreen ? 10 : 12,
                                              ),
                                              child: _BlockedUserItem(
                                                username:
                                                    username.startsWith('@')
                                                    ? username
                                                    : '@$username',
                                                userId: userId,
                                                profilePictureUrl:
                                                    profilePictureUrl,
                                                initials: initials,
                                                blockedAt: blockedAt,
                                                isUnblocking: isUnblocking,
                                                onUnblock: isUnblocking
                                                    ? null
                                                    : () => _unblockUser(
                                                        userId,
                                                        username,
                                                      ),
                                                isSmallScreen: isSmallScreen,
                                                isLargeScreen: isLargeScreen,
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
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
        onSettingsTap: () {},
      ),
    );
  }
}

class _BlockedAccountsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    final iconSize = isSmallScreen
        ? 14.0
        : isLargeScreen
        ? 18.0
        : 16.0;
    final fontSize = isSmallScreen
        ? 18.0
        : isLargeScreen
        ? 22.0
        : 20.0;
    final horizontalPadding = isSmallScreen
        ? 8.0
        : isLargeScreen
        ? 16.0
        : 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.735),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isSmallScreen ? 14 : 16,
        horizontalPadding,
        isSmallScreen ? 14 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: iconSize,
              height: iconSize,
              alignment: Alignment.centerLeft,
              child: Transform.rotate(
                angle: 3.14159, // 180 degrees rotation to point left
                child: SvgPicture.asset(
                  'assets/settings/dropDownIcon.svg',
                  width: iconSize,
                  height: iconSize,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0A0A0A),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Text(
            'Blocked Accounts',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A0A0A),
              fontFamily: 'Inter',
              letterSpacing: -0.1504,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutBlockingCard extends StatelessWidget {
  final bool isSmallScreen;
  final bool isLargeScreen;

  const _AboutBlockingCard({
    required this.isSmallScreen,
    required this.isLargeScreen,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen
        ? 18.0
        : isLargeScreen
        ? 22.0
        : 20.0;
    final iconContainerSize = isSmallScreen
        ? 36.0
        : isLargeScreen
        ? 44.0
        : 40.0;
    final titleFontSize = isSmallScreen
        ? 15.0
        : isLargeScreen
        ? 17.0
        : 16.0;
    final bodyFontSize = isSmallScreen
        ? 13.0
        : isLargeScreen
        ? 15.0
        : 14.0;
    final cardPadding = isSmallScreen
        ? 12.0
        : isLargeScreen
        ? 20.0
        : 16.0;
    final spacing = isSmallScreen
        ? 12.0
        : isLargeScreen
        ? 18.0
        : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF155DFC), width: 1.471),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Blue left border accent
            Positioned(
              left: -0.47,
              top: -0.17,
              bottom: 0.17,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF155DFC), Color(0xFF3B82F6)],
                  ),
                ),
              ),
            ),
            // Content with gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFEFF6FF).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container with gradient
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: iconContainerSize,
                      height: iconContainerSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF155DFC), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/settings/shieldIcon.svg',
                          width: iconSize,
                          height: iconSize,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'About Blocking',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172B),
                            fontFamily: 'Inter',
                            letterSpacing: -0.3125,
                            height: 24 / titleFontSize,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          'Blocked users cannot see your posts or comment on your content. Exception: Platform-pinned or trending posts remain visible to everyone You can unblock them at any time from this page.',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF45556C),
                            fontFamily: 'Inter',
                            letterSpacing: -0.1504,
                            height: 22.75 / bodyFontSize,
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
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final bool isSmallScreen;
  final bool isLargeScreen;

  const _EmptyStateCard({
    required this.isSmallScreen,
    required this.isLargeScreen,
  });

  @override
  Widget build(BuildContext context) {
    final iconContainerSize = isSmallScreen
        ? 70.0
        : isLargeScreen
        ? 90.0
        : 80.0;
    final iconSize = isSmallScreen
        ? 32.0
        : isLargeScreen
        ? 40.0
        : 36.0;
    final titleFontSize = isSmallScreen
        ? 15.0
        : isLargeScreen
        ? 17.0
        : 16.0;
    final bodyFontSize = isSmallScreen
        ? 13.0
        : isLargeScreen
        ? 15.0
        : 14.0;
    final cardHeight = isSmallScreen
        ? 300.0
        : isLargeScreen
        ? 400.0
        : 352.0;
    final spacing = isSmallScreen
        ? 24.0
        : isLargeScreen
        ? 40.0
        : 32.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.735),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(0.735),
        child: Container(
          height: cardHeight,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large circular icon container
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/settings/noUsersBlocked.svg',
                      width: iconSize,
                      height: iconSize,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF62748E),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Text(
                'No Blocked Users',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172B),
                  fontFamily: 'Inter',
                  letterSpacing: -0.3125,
                  height: 24 / titleFontSize,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Text(
                  'You haven\'t blocked anyone yet. When you block a user, they\'ll appear here and won\'t be able to interact with your content.',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF62748E),
                    fontFamily: 'Inter',
                    letterSpacing: -0.1504,
                    height: 22.75 / bodyFontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedUserItem extends StatelessWidget {
  const _BlockedUserItem({
    required this.username,
    required this.userId,
    required this.onUnblock,
    this.profilePictureUrl,
    this.initials,
    this.blockedAt,
    this.isUnblocking = false,
    this.isSmallScreen = false,
    this.isLargeScreen = false,
  });

  final String username;
  final String userId;
  final VoidCallback? onUnblock;
  final String? profilePictureUrl;
  final String? initials;
  final String? blockedAt;
  final bool isUnblocking;
  final bool isSmallScreen;
  final bool isLargeScreen;

  String _formatBlockedDate(String? blockedAt) {
    if (blockedAt == null || blockedAt.isEmpty) return 'Recently blocked';

    try {
      final dateTime = DateTime.parse(blockedAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Blocked today';
      } else if (difference.inDays == 1) {
        return 'Blocked 1 day ago';
      } else if (difference.inDays < 30) {
        return 'Blocked ${difference.inDays} days ago';
      } else if (difference.inDays < 60) {
        final months = (difference.inDays / 30).floor();
        return months == 1
            ? 'Blocked 1 month ago'
            : 'Blocked $months months ago';
      } else {
        return 'Blocked ${(difference.inDays / 30).floor()} months ago';
      }
    } catch (e) {
      return 'Recently blocked';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = profilePictureUrl != null && profilePictureUrl!.isNotEmpty;
    final avatarSize = isSmallScreen
        ? 42.0
        : isLargeScreen
        ? 52.0
        : 47.0;
    final badgeFontSize = isSmallScreen
        ? 13.0
        : isLargeScreen
        ? 15.0
        : 14.0;
    final dateFontSize = isSmallScreen
        ? 13.0
        : isLargeScreen
        ? 15.0
        : 14.0;
    final buttonFontSize = isSmallScreen
        ? 13.0
        : isLargeScreen
        ? 15.0
        : 14.0;

    // Calculate username font size - use smaller if username is too long
    final displayUsername = username.startsWith('@') ? username : '@$username';
    final isUsernameTooLong = displayUsername.length > 10;
    final usernameFontSize = isUsernameTooLong
        ? (isSmallScreen
              ? 11.0
              : isLargeScreen
              ? 13.0
              : 12.0)
        : badgeFontSize;
    final cardPadding = isSmallScreen
        ? 16.0
        : isLargeScreen
        ? 24.0
        : 20.0;
    final spacing = isSmallScreen
        ? 12.0
        : isLargeScreen
        ? 20.0
        : 16.0;
    final buttonHeight = isSmallScreen
        ? 24.0
        : isLargeScreen
        ? 30.0
        : 26.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.735),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with 3px border
            Container(
              margin: const EdgeInsets.only(right: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(avatarSize / 2),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172B), width: 3),
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? Image.network(
                            profilePictureUrl!,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials ?? 'U',
                                    style: TextStyle(
                                      fontSize: isSmallScreen
                                          ? 14
                                          : isLargeScreen
                                          ? 18
                                          : 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF314158),
                                      fontFamily: 'Inter',
                                      letterSpacing: -0.3125,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials ?? 'U',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 14
                                      : isLargeScreen
                                      ? 18
                                      : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF314158),
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.3125,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(width: spacing),
            // User info with unblock button in same row as badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row with username, badge, and unblock button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayUsername,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172B),
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.3,
                                  height: 21 / 14, // line-height: 21px
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            // Blocked badge
                            Container(
                              margin: const EdgeInsets.only(left: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen
                                        ? 8
                                        : isLargeScreen
                                        ? 11
                                        : 9.47,
                                    vertical: isSmallScreen
                                        ? 2.5
                                        : isLargeScreen
                                        ? 4
                                        : 3.47,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFC9C9),
                                      width: 0.74,
                                    ),
                                  ),
                                  child: Text(
                                    'Blocked',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE7000B),
                                      fontFamily: 'Inter',
                                      height: 18 / 12, // line-height: 18px
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Unblock button - aligned to right side
                      isUnblocking
                          ? SizedBox(
                              width: isSmallScreen
                                  ? 80
                                  : isLargeScreen
                                  ? 95
                                  : 85,
                              height: buttonHeight,
                              child: Center(
                                child: SizedBox(
                                  width: isSmallScreen ? 14 : 16,
                                  height: isSmallScreen ? 14 : 16,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Material(
                                color: const Color(0xFF155DFC),
                                child: InkWell(
                                  onTap: onUnblock,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen
                                          ? 14
                                          : isLargeScreen
                                          ? 22
                                          : 18,
                                    ),
                                    height: buttonHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                          spreadRadius: -1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Unblock',
                                        style: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                          letterSpacing: -0.1504,
                                          height: 1.2,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    _formatBlockedDate(blockedAt),
                    style: TextStyle(
                      fontSize: dateFontSize,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF62748E),
                      fontFamily: 'Inter',
                      height: 16 / dateFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnblockUserDialog extends StatelessWidget {
  const _UnblockUserDialog({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0F172B), width: 0.76),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unblock $username?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172B),
                      fontFamily: 'Inter',
                      letterSpacing: -0.3125,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to unblock $username? They\'ll be able to see your posts and interact with you again.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF45556C),
                      fontFamily: 'Inter',
                      letterSpacing: -0.15,
                      height: 1.57,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider
              Container(height: 0.756, color: const Color(0xFFE2E8F0)),
              const SizedBox(height: 12.751),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                          width: 0.756,
                        ),
                        foregroundColor: const Color(0xFF0F172B),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8.756),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172B),
                          letterSpacing: -0.15,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Unblock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.15,
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
