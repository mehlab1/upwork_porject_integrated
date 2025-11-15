import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

import 'your_posts_screen.dart';
import 'community_guidelines_screen.dart';
import 'package:pal_app/widgets/pal_bottom_nav_bar.dart';
import 'package:pal_app/widgets/pal_loading_widgets.dart';
import 'package:pal_app/widgets/pal_refresh_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _isPageLoading = false;
      });
    });
  }

  Future<void> _showDeactivateAccountDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _DeactivateAccountDialog(
            reasonController: controller,
            onDeactivate: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
    controller.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account deactivated. You can reactivate by logging in again.',
          ),
        ),
      );
    }
  }

  Future<void> _showEditUsernameDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _EditUsernameDialog(
            controller: controller,
            onUpdate: (value) {
              Navigator.of(dialogContext).pop(true);
            },
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
    controller.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username updated')));
    }
  }

  Future<void> _showEditBirthdayDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _EditBirthdayDialog(
            controller: controller,
            onUpdate: (value) {
              Navigator.of(dialogContext).pop(true);
            },
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
    controller.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Birthday updated')));
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _ChangePasswordDialog(
            currentController: currentController,
            newController: newController,
            confirmController: confirmController,
            onSendCode: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password reset code sent')));
    }
  }

  Future<void> _showShareFeedbackDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _ShareFeedbackDialog(
            onSubmit: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for sharing your feedback!')),
      );
    }
  }

  Future<void> _showUpdateProfilePhotoDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _UpdateProfilePhotoDialog(
            onUpdate: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _LogoutDialog(
            onConfirm: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been logged out.')),
      );
    }
  }

  Future<void> _refreshSettings() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _SettingsHeader(),
            Expanded(
              child: PalRefreshIndicator(
                onRefresh: _refreshSettings,
                child: Container(
                  color: const Color(0xFFF7FBFF),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 24, 15, 120),
                    child: Column(
                      children: [
                        _ProfileOverviewCard(
                          onUpdateProfilePhoto: () =>
                              _showUpdateProfilePhotoDialog(context),
                        ),
                        const SizedBox(height: 32),
                        _SettingsSection(
                          title: 'Account',
                          tiles: [
                            _SettingsTileData(
                              title: 'Edit Username',
                              subtitle: 'Last changed 45 days ago',
                              iconAsset: 'assets/settings/username.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              onTap: () => _showEditUsernameDialog(context),
                            ),
                            _SettingsTileData(
                              title: 'Update Birthday',
                              subtitle: 'Optional information',
                              iconAsset: 'assets/settings/dateofbirth.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              onTap: () => _showEditBirthdayDialog(context),
                            ),
                            _SettingsTileData(
                              title: 'Posts You Upvoted',
                              subtitle: 'View your liked posts',
                              iconAsset: 'assets/settings/upvotedPost.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              isDisabled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _SettingsSection(
                          title: 'Security & Privacy',
                          tiles: [
                            _SettingsTileData(
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              iconAsset: 'assets/settings/changePassword.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              onTap: () => _showChangePasswordDialog(context),
                            ),
                            _SettingsTileData(
                              title: 'Push Notifications',
                              subtitle: 'Get notified about activity',
                              iconAsset: 'assets/settings/pushNotification.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              trailingBuilder: (context) => Switch(
                                value: _pushNotificationsEnabled,
                                activeColor: Colors.white,
                                activeTrackColor: const Color(
                                  0xFF155DFC,
                                ).withOpacity(0.7),
                                inactiveTrackColor: const Color(
                                  0xFF155DFC,
                                ).withOpacity(0.2),
                                onChanged: (value) {
                                  setState(() {
                                    _pushNotificationsEnabled = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _SettingsSection(
                          title: 'Community',
                          tiles: [
                            _SettingsTileData(
                              title: 'Community Guidelines',
                              subtitle: 'Read our rules',
                              iconAsset:
                                  'assets/settings/communityGuidelines.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CommunityGuidelinesScreen(),
                                  ),
                                );
                              },
                            ),
                            _SettingsTileData(
                              title: 'Invite Friends',
                              subtitle: 'Copy your invite link',
                              iconAsset: 'assets/settings/inviteFriends.svg',
                              iconBackground: const Color(0xFFF0FDF4),
                              iconTint: const Color(0xFF089E6B),
                              trailingBuilder: (context) => IconButton(
                                onPressed: () {},
                                icon: svg.SvgPicture.asset(
                                  'assets/settings/copyIcon.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF155DFC),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            _SettingsTileData(
                              title: 'Share Feedback',
                              subtitle: 'Help us improve',
                              iconAsset: 'assets/settings/shareFeedback.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              onTap: () => _showShareFeedbackDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _SettingsSection(
                          title: 'Danger Zone',
                          tiles: [
                            _SettingsTileData(
                              title: 'Deactivate Account',
                              subtitle: 'Temporarily disable your account',
                              iconAsset:
                                  'assets/settings/deactivateAccount.svg',
                              iconBackground: const Color(0xFFFEE2E2),
                              iconTint: const Color(0xFFE7000B),
                              titleColor: const Color(0xFFE7000B),
                              onTap: () =>
                                  _showDeactivateAccountDialog(context),
                            ),
                            _SettingsTileData(
                              title: 'Logout',
                              subtitle: 'Sign out of your account',
                              iconAsset: 'assets/settings/logout.svg',
                              iconBackground: const Color(0xFFF1F5F9),
                              iconTint: const Color(0xFF314158),
                              onTap: () => _showLogoutDialog(context),
                            ),
                          ],
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
        showNotificationDot: true,
      ),
    );
    return Stack(
      children: [scaffold, if (_isPageLoading) const PalLoadingOverlay()],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  static const _titleColor = Color(0xFF0F172B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: _titleColor,
                letterSpacing: 0.07,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.onUpdateProfilePhoto});

  static const _borderColor = Color(0x1A000000);
  static const _titleColor = Color(0xFF0F172B);
  static const _subtitleColor = Color(0xFF45556C);

  final VoidCallback onUpdateProfilePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onUpdateProfilePhoto,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: const Color(0xFF314158),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.asset(
                          'assets/feedPage/profile.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF314158),
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '@lagosian_pro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ever since January',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _subtitleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '2024',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _subtitleColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Posts',
                  value: '0',
                  iconAsset: 'assets/settings/posts.svg',
                  iconTint: const Color(0xFF45556C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Upvotes',
                  value: '0',
                  iconAsset: 'assets/settings/upvote.svg',
                  iconTint: const Color(0xFF45556C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, YourPostsScreen.routeName);
              },
              icon: svg.SvgPicture.asset(
                'assets/settings/posts.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0F172B),
                  BlendMode.srcIn,
                ),
              ),
              label: const Text('View All Posts'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                foregroundColor: Colors.black87,
                disabledForegroundColor: Colors.black54,
                disabledBackgroundColor: Colors.white,
                side: const BorderSide(color: _borderColor, width: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.iconAsset,
    this.iconTint,
  });

  final String label;
  final String value;
  final String iconAsset;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              svg.SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
                colorFilter: iconTint == null
                    ? null
                    : ColorFilter.mode(iconTint!, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF45556C),
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172B),
              letterSpacing: -0.45,
            ),
          ),
        ],
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
                color: data.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: svg.SvgPicture.asset(
                  data.iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: data.iconTint == null
                      ? null
                      : ColorFilter.mode(data.iconTint!, BlendMode.srcIn),
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
              height: 24,
              width: 24,
              child: data.trailingBuilder != null
                  ? data.trailingBuilder!(context)
                  : Center(
                      child: svg.SvgPicture.asset(
                        data.iconAsset == 'assets/settings/inviteFriends.svg'
                            ? 'assets/settings/copyIcon.svg'
                            : 'assets/settings/dropDownIcon.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          data.iconAsset == 'assets/settings/inviteFriends.svg'
                              ? const Color(0xFF155DFC)
                              : isDisabled
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

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({required this.onConfirm, required this.onCancel});

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x4D0F172B), width: 0.756),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14101828),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF4B4B4B),
                letterSpacing: -0.15,
                height: 22 / 16,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 200,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
                ),
              ),
              padding: const EdgeInsets.only(top: 12.75),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF0F172B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A0A0A),
                        side: const BorderSide(
                          color: Color(0x1A000000),
                          width: 0.756,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                        ),
                      ),
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

class _UpdateProfilePhotoDialog extends StatefulWidget {
  const _UpdateProfilePhotoDialog({
    required this.onUpdate,
    required this.onCancel,
  });

  final VoidCallback onUpdate;
  final VoidCallback onCancel;

  @override
  State<_UpdateProfilePhotoDialog> createState() =>
      _UpdateProfilePhotoDialogState();
}

class _UpdateProfilePhotoDialogState extends State<_UpdateProfilePhotoDialog> {
  bool _hasSelectedNewImage = false;

  void _handleSelectImage() {
    setState(() {
      _hasSelectedNewImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.76),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A101828),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Update Profile Picture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172B),
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload a new photo that represents you best. Max file size: 5MB.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF717182),
                      letterSpacing: -0.15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(128),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 3,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(120),
                                  child: Image.asset(
                                    'assets/feedPage/profile.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF314158),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        246,
                                        247,
                                        248,
                                      ),
                                      width: 3.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '@lagosian_pro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172B),
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Current profile picture',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF62748E),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _handleSelectImage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFCAD5E2),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              Icons.file_upload_outlined,
                              size: 32,
                              color: Color(0xFF314158),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Click to upload new image',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172B),
                              letterSpacing: -0.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PNG, JPG, or GIF up to 5MB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF62748E),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _hasSelectedNewImage ? widget.onUpdate : null,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Update Picture',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                        ),
                      ),
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.resolveWith((
                          states,
                        ) {
                          final base = const Color(0xFF00A63E);
                          if (states.contains(MaterialState.disabled)) {
                            return base.withOpacity(0.5);
                          }
                          return base;
                        }),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.white,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172B),
                        side: const BorderSide(
                          color: Color(0x19000000),
                          width: 0.76,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeactivateAccountDialog extends StatelessWidget {
  const _DeactivateAccountDialog({
    required this.reasonController,
    required this.onDeactivate,
    required this.onCancel,
  });

  final TextEditingController reasonController;
  final VoidCallback onDeactivate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE7000B),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Deactivate Your Account?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172B),
                        letterSpacing: -0.45,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This will temporarily disable your account. You can reactivate it anytime by logging back in.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF717182),
                        letterSpacing: -0.15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Why are you leaving? (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reasonController,
            minLines: 3,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Tell us why you're deactivating...",
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF717182),
                letterSpacing: -0.3,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onDeactivate,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE7000B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Deactivate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black.withOpacity(0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172B),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditUsernameDialog extends StatelessWidget {
  const _EditUsernameDialog({
    required this.controller,
    required this.onUpdate,
    required this.onCancel,
  });

  final TextEditingController controller;
  final ValueChanged<String> onUpdate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _SettingsDialogShell(
      title: 'Update Username',
      description: 'You can change your username once every 30 days.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Username',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 8),
          _DialogTextField(
            controller: controller,
            hintText: 'Enter new username',
          ),
        ],
      ),
      primaryLabel: 'Update',
      onPrimary: () => onUpdate(controller.text),
      secondaryLabel: 'Cancel',
      onSecondary: onCancel,
    );
  }
}

class _EditBirthdayDialog extends StatelessWidget {
  const _EditBirthdayDialog({
    required this.controller,
    required this.onUpdate,
    required this.onCancel,
  });

  final TextEditingController controller;
  final ValueChanged<String> onUpdate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _SettingsDialogShell(
      title: 'Update Birthday',
      description: "Your birthday is private and won't be shown to others.",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Birthday',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final initialDate = now.subtract(const Duration(days: 365 * 18));
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked != null) {
                controller.text =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              }
            },
            child: AbsorbPointer(
              child: _DialogTextField(controller: controller),
            ),
          ),
        ],
      ),
      primaryLabel: 'Update',
      onPrimary: () => onUpdate(controller.text),
      secondaryLabel: 'Cancel',
      onSecondary: onCancel,
    );
  }
}

class _ChangePasswordDialog extends StatelessWidget {
  const _ChangePasswordDialog({
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.onSendCode,
    required this.onCancel,
  });

  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final VoidCallback onSendCode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _SettingsDialogShell(
      title: 'Change Password',
      description: 'Enter your current password and choose a new one.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DialogLabeledField(
            label: 'Current Password',
            controller: currentController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _DialogLabeledField(
            label: 'New Password',
            controller: newController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _DialogLabeledField(
            label: 'Confirm New Password',
            controller: confirmController,
            obscureText: true,
          ),
        ],
      ),
      primaryLabel: 'Send Code',
      onPrimary: onSendCode,
      secondaryLabel: 'Cancel',
      onSecondary: onCancel,
    );
  }
}

class _ShareFeedbackDialog extends StatefulWidget {
  const _ShareFeedbackDialog({required this.onSubmit, required this.onCancel});

  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  State<_ShareFeedbackDialog> createState() => _ShareFeedbackDialogState();
}

class _ShareFeedbackDialogState extends State<_ShareFeedbackDialog> {
  static const List<String> _feedbackTypes = [
    'Feature Request',
    'Bug Report',
    'General Feedback',
  ];

  String _selectedType = _feedbackTypes.first;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsDialogShell(
      title: 'Share Your Thoughts',
      description:
          "We'd love to hear your feedback, feature requests, or bug reports.",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172B),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                items: _feedbackTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Message',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: "Tell us what's on your mind...",
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF717182),
                letterSpacing: -0.3,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      primaryLabel: 'Submit',
      onPrimary: () => widget.onSubmit(),
      secondaryLabel: 'Cancel',
      onSecondary: widget.onCancel,
    );
  }
}

class _SettingsDialogShell extends StatelessWidget {
  const _SettingsDialogShell({
    required this.title,
    required this.description,
    required this.content,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final String description;
  final Widget content;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172B),
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF717182),
                    letterSpacing: -0.15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(child: content),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0F172B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172B),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: onSecondary,
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogLabeledField extends StatelessWidget {
  const _DialogLabeledField({
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.15,
          ),
        ),
        const SizedBox(height: 8),
        _DialogTextField(controller: controller, obscureText: obscureText),
      ],
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    this.hintText,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: 1,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF717182),
          letterSpacing: -0.3,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
