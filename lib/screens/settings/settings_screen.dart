import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

import 'your_posts_screen.dart';
import 'community_guidelines_screen.dart';
import 'package:pal/widgets/pal_bottom_nav_bar.dart';
import 'package:pal/screens/login/login_screen.dart';
import 'package:pal/widgets/pal_loading_widgets.dart';
import 'package:pal/widgets/pal_refresh_indicator.dart';
import 'package:pal/widgets/pal_toast.dart';
import 'package:pal/services/auth_logout_service.dart';
import 'package:pal/services/auth_remember_me_service.dart';
import 'package:pal/services/auth_deactivate_service.dart';
import 'package:pal/services/fcm_service.dart';
import 'package:pal/services/profile_service.dart';
import 'package:pal/services/profile_picture_service.dart';
import 'package:pal/services/post_service.dart';
import 'package:pal/services/auth_service.dart';
import 'package:pal/widgets/profile_avatar_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upvoted_posts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _isPageLoading = true;
  final AuthLogoutService _logoutService = AuthLogoutService();
  final AuthRememberMeService _rememberMeService = AuthRememberMeService();
  final AuthDeactivateService _deactivateService = AuthDeactivateService();
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  ProfileData? _profileData;
  bool _isLoadingProfile = false;
  bool _hasUpvotedPosts = false;
  bool _isCheckingUpvotedPosts = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _checkUpvotedPosts();
    Future.microtask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _isPageLoading = false;
      });
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
    
    final reasonText = controller.text.trim();
    controller.dispose();
    
    if (result == true && mounted) {
      // Show loading indicator while deactivating
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Determine reason type based on text provided
        // Since UI only has text field, we'll use "other" as default
        // If text is provided and is 10+ chars, use it as reason_text
        // If text is less than 10 chars, don't send it (API requires 10+ chars if provided)
        String reasonType = 'other';
        String? reasonTextForApi;

        if (reasonText.isNotEmpty) {
          if (reasonText.length >= 10) {
            // Text is valid (10+ chars), use it as reason_text
            reasonTextForApi = reasonText;
          } else {
            // Text is too short - don't send it to API
            // API requires reason_text to be 10+ chars if provided
            // We'll proceed with just reason_type
            reasonTextForApi = null;
          }
        }

        // Call the deactivate account edge function
        final deactivateResponse = await _deactivateService.deactivateAccount(
          reasonType: reasonType,
          reasonText: reasonTextForApi,
        );

        if (!mounted) return;

        // Close loading dialog
        Navigator.of(context).pop();

        // Clear Remember Me preference on deactivation
        await _rememberMeService.clearRememberMe();

        // Also clear local session (edge function already signs out, but ensure local cleanup)
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          // Ignore local signOut errors - server deactivation is more important
          print('Note: Local signOut had an issue (non-critical): $e');
        }

        // Show success message
        final message = deactivateResponse['message'] as String? ?? 
                       deactivateResponse['note'] as String? ??
                       'Account deactivated. You can reactivate by logging in again.';
        
        PalToast.show(
          context,
          message: message,
        );

        // Navigate to login screen after a short delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;

        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        PalToast.show(
          context,
          message: errorMessage.isNotEmpty 
              ? errorMessage 
              : 'Failed to deactivate account. Please try again.',
        );
      }
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
    
    if (result == true && mounted) {
      final username = controller.text.trim();
      if (username.isEmpty) {
        controller.dispose();
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final response = await _profileService.updateUsername(username);
        
        if (!mounted) {
          controller.dispose();
          return;
        }

        // Close loading dialog
        Navigator.of(context).pop();

        if (response['success'] == true) {
          // Reload profile data to get updated username
          await _loadProfileData();
          
          PalToast.show(context, message: response['message'] ?? 'Username updated successfully');
        } else {
          final errorMessage = response['error'] ?? 'Failed to update username';
          PalToast.show(context, message: errorMessage);
        }
      } catch (e) {
        if (!mounted) {
          controller.dispose();
          return;
        }

        // Close loading dialog
        Navigator.of(context).pop();

        // Handle specific error cases
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        String displayMessage = errorMessage;
        
        // Check for specific error messages from the API
        final lowerError = errorMessage.toLowerCase();
        if (lowerError.contains('30') || lowerError.contains('cooldown') || lowerError.contains('days')) {
          displayMessage = 'You can only change your username once every 30 days. Please try again later.';
        } else if (lowerError.contains('already taken') || lowerError.contains('taken')) {
          displayMessage = 'This username is already taken. Please choose another one.';
        } else if (lowerError.contains('between 3 and 50') || lowerError.contains('3 and 50')) {
          displayMessage = 'Username must be between 3 and 50 characters.';
        } else if (lowerError.contains('letters, numbers') || lowerError.contains('alphanumeric')) {
          displayMessage = 'Username can only contain letters, numbers, and underscores.';
        } else if (lowerError.contains('missing') || lowerError.contains('required')) {
          displayMessage = 'Please enter a username.';
        }

        PalToast.show(context, message: displayMessage);
      }
    }
    
    controller.dispose();
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
    
    if (result == true && mounted) {
      final birthday = controller.text.trim();
      if (birthday.isEmpty) {
        controller.dispose();
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final response = await _profileService.updateBirthday(birthday);
        
        if (!mounted) {
          controller.dispose();
          return;
        }

        // Close loading dialog
        Navigator.of(context).pop();

        if (response['success'] == true) {
          // Reload profile data to get updated birthday
          await _loadProfileData();
          
          PalToast.show(context, message: response['message'] ?? 'Birthday updated successfully');
        } else {
          final errorMessage = response['error'] ?? 'Failed to update birthday';
          PalToast.show(context, message: errorMessage);
        }
      } catch (e) {
        if (!mounted) {
          controller.dispose();
          return;
        }

        // Close loading dialog
        Navigator.of(context).pop();

        // Handle specific error cases
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        String displayMessage = errorMessage;
        
        // Check for specific error messages from the API
        final lowerError = errorMessage.toLowerCase();
        if (lowerError.contains('yyyy-mm-dd') || lowerError.contains('format')) {
          displayMessage = 'Birthday must be in YYYY-MM-DD format.';
        } else if (lowerError.contains('future')) {
          displayMessage = 'Birthday cannot be in the future.';
        } else if (lowerError.contains('13 years') || lowerError.contains('at least 13')) {
          displayMessage = 'You must be at least 13 years old.';
        } else if (lowerError.contains('120 years') || lowerError.contains('120')) {
          displayMessage = 'Birthday must be within the last 120 years.';
        } else if (lowerError.contains('missing') || lowerError.contains('required')) {
          displayMessage = 'Please select a birthday.';
        }

        PalToast.show(context, message: displayMessage);
      }
    }
    
    controller.dispose();
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
    
    if (result == true && mounted) {
      final currentPassword = currentController.text.trim();
      final newPassword = newController.text.trim();
      final confirmPassword = confirmController.text.trim();

      // Validate passwords
      if (currentPassword.isEmpty) {
        PalToast.show(context, message: 'Please enter your current password');
        currentController.dispose();
        newController.dispose();
        confirmController.dispose();
        return;
      }

      if (newPassword.isEmpty) {
        PalToast.show(context, message: 'Please enter a new password');
        currentController.dispose();
        newController.dispose();
        confirmController.dispose();
        return;
      }

      if (newPassword != confirmPassword) {
        PalToast.show(context, message: 'New passwords do not match');
        currentController.dispose();
        newController.dispose();
        confirmController.dispose();
        return;
      }

      // Get current user's email
      final currentUser = _authService.currentUser;
      if (currentUser?.email == null) {
        PalToast.show(context, message: 'Unable to get user email. Please try again.');
        currentController.dispose();
        newController.dispose();
        confirmController.dispose();
        return;
      }

      final userEmail = currentUser!.email!;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Verify current password by attempting sign-in
        // This ensures the user knows their current password
        final signInResponse = await _authService.signIn(email: userEmail, password: currentPassword);
        
        // Ensure we have a valid session after sign-in
        if (signInResponse.session == null) {
          PalToast.show(context, message: 'Failed to verify current password. Please try again.');
          Navigator.of(context).pop(); // Close loading
          currentController.dispose();
          newController.dispose();
          confirmController.dispose();
          return;
        }
        
        // Small delay to ensure session is fully established
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Send OTP to user's email
        await _authService.forgotPassword(email: userEmail);
        
        if (!mounted) {
          currentController.dispose();
          newController.dispose();
          confirmController.dispose();
          return;
        }

        // Close loading dialog
        Navigator.of(context).pop();

        // Show OTP input dialog
        final otpResult = await _showOtpInputDialog(context, userEmail, newPassword);
        
        if (otpResult == true && mounted) {
          PalToast.show(context, message: 'Password reset successfully');
        }
      } catch (e) {
        if (!mounted) {
          currentController.dispose();
          newController.dispose();
          confirmController.dispose();
          return;
        }

        // Close loading dialog
        Navigator.of(context).pop();

        final errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
        PalToast.show(context, message: errorMessage.isNotEmpty ? errorMessage : 'Failed to send password reset code');
      }
    }
    
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<bool?> _showOtpInputDialog(BuildContext context, String email, String newPassword) async {
    final otpController = TextEditingController();
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _OtpInputDialog(
            controller: otpController,
            onConfirm: () async {
              final otpCode = otpController.text.trim();
              if (otpCode.isEmpty || otpCode.length != 6) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid 6-digit OTP code')),
                  );
                }
                return;
              }

              // Show loading
              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await _authService.resetPassword(
                  email: email,
                  otpCode: otpCode,
                  newPassword: newPassword,
                );

                if (!dialogContext.mounted) return;

                // Close loading and OTP dialog
                Navigator.of(dialogContext).pop(); // Close loading
                Navigator.of(dialogContext).pop(true); // Close OTP dialog with success
              } catch (e) {
                if (!dialogContext.mounted) return;

                // Close loading
                Navigator.of(dialogContext).pop();

                final errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage.isNotEmpty ? errorMessage : 'Failed to reset password'),
                  ),
                );
              }
            },
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
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
      PalToast.show(context, message: 'Thanks for sharing your feedback!');
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
      // Reload profile data after successful update
      _loadProfileData();
      PalToast.show(context, message: 'Profile picture updated');
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
      // Show loading indicator while logging out
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Call the logout edge function to invalidate session on server
        final logoutResponse = await _logoutService.logout();
        
        // Clear Remember Me preference on logout
        await _rememberMeService.clearRememberMe();
        
        // Unregister FCM device token
        try {
          await FCMService().unregisterDevice();
        } catch (e) {
          // FCM unregister failure shouldn't block logout
          print('Note: FCM unregister had an issue (non-critical): $e');
        }
        
        // Also clear local session to ensure complete logout
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          // Ignore local signOut errors - server logout is more important
          print('Note: Local signOut had an issue (non-critical): $e');
        }
        
        if (!mounted) return;
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Check if logout was successful
        final success = logoutResponse['success'] as bool? ?? true;
        final message = logoutResponse['message'] as String? ?? 'Logged out successfully';
        
        // Navigate to login and clear navigation stack
        // Always navigate even if API returned failure, to prevent stuck state
        // This matches the backend's graceful error handling
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        
        // Clear Remember Me preference even if logout API failed
        await _rememberMeService.clearRememberMe();
        
        // Unregister FCM device token even if logout API failed
        try {
          await FCMService().unregisterDevice();
        } catch (e) {
          print('Note: FCM unregister had an issue (non-critical): $e');
        }
        
        // Try to clear local session even if API call failed
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (localError) {
          // Ignore local signOut errors
          print('Note: Local signOut had an issue (non-critical): $localError');
        }
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Even on error, navigate to login to prevent users from being stuck
        // This matches the backend's behavior of treating logout as successful even on errors
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _checkUpvotedPosts() async {
    setState(() {
      _isCheckingUpvotedPosts = true;
    });

    try {
      final response = await _postService.getUpvotedPosts(limit: 1, offset: 0);
      if (!mounted) return;
      
      final posts = response['posts'] as List<dynamic>? ?? [];
      final totalUpvoted = response['total_upvoted_posts'] as int? ?? 0;
      
      setState(() {
        _hasUpvotedPosts = totalUpvoted > 0 || posts.isNotEmpty;
        _isCheckingUpvotedPosts = false;
      });
    } catch (e) {
      print('Error checking upvoted posts: $e');
      if (!mounted) return;
      setState(() {
        _hasUpvotedPosts = false;
        _isCheckingUpvotedPosts = false;
      });
    }
  }

  Future<void> _refreshSettings() async {
    // Reload profile data on refresh to get latest values
    await Future.wait([
      _loadProfileData(),
      _checkUpvotedPosts(),
    ]);
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
                          profileData: _profileData,
                          isLoading: _isLoadingProfile,
                          onUpdateProfilePhoto: () {
                            _showUpdateProfilePhotoDialog(context);
                            // Reload profile after photo update
                            _loadProfileData();
                          },
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
                              iconTint: _hasUpvotedPosts
                                  ? const Color(0xFF314158)
                                  : const Color(0xFF94A3B8),
                              isDisabled: !_hasUpvotedPosts,
                              onTap: _hasUpvotedPosts
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        UpvotedPostsScreen.routeName,
                                      );
                                    }
                                  : null,
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
  const _ProfileOverviewCard({
    this.profileData,
    this.isLoading = false,
    required this.onUpdateProfilePhoto,
  });

  static const _borderColor = Color(0x1A000000);
  static const _titleColor = Color(0xFF0F172B);
  static const _subtitleColor = Color(0xFF45556C);

  final ProfileData? profileData;
  final bool isLoading;
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
                    if (isLoading)
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
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      ProfileAvatarWidget(
                        imageUrl: profileData?.pictureUrl,
                        initials: profileData?.initials ?? 'U',
                        size: 68,
                        borderWidth: 2,
                        borderColor: const Color(0xFF314158),
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
                  children: [
                    if (isLoading)
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                          letterSpacing: -0.3,
                        ),
                      )
                    else
                      Text(
                        profileData?.formattedUsername ?? '@user',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (!isLoading && profileData != null) ...[
                      Text(
                        profileData!.formattedJoinedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _subtitleColor,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ] else if (!isLoading) ...[
                      const Text(
                        'Recently',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _subtitleColor,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ],
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
                  value: isLoading 
                      ? '...' 
                      : (profileData?.postCount.toString() ?? '0'),
                  iconAsset: 'assets/settings/posts.svg',
                  iconTint: const Color(0xFF45556C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Upvotes',
                  value: isLoading 
                      ? '...' 
                      : (profileData?.totalUpvotesReceived.toString() ?? '0'),
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
                color: isDisabled
                    ? const Color(0xFFF1F5F9)
                    : data.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: svg.SvgPicture.asset(
                  data.iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: data.iconTint == null
                      ? (isDisabled
                          ? const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)
                          : null)
                      : ColorFilter.mode(
                          isDisabled ? const Color(0xFF94A3B8) : data.iconTint!,
                          BlendMode.srcIn),
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
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final ProfileService _profileService = ProfileService();
  ProfileData? _currentProfile;
  bool _isLoadingProfile = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final profileData = await _profileService.getProfileData();
      if (mounted) {
        setState(() {
          _currentProfile = profileData;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading current profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _handleSelectImage() async {
    // Show bottom sheet with options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageSourceBottomSheet(),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Read the image bytes directly from XFile
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (_selectedImageFile == null || _selectedImageBytes == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await _profilePictureService.uploadProfilePictureFromBytes(
        _selectedImageBytes!,
        _selectedImageFile!.name,
        mimeType: _selectedImageFile!.mimeType,
      );
      
      if (!mounted) return;

      // Close dialog and trigger callback
      widget.onUpdate();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload profile picture: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
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
                                  child: _selectedImageBytes != null
                                      ? Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : _isLoadingProfile
                                          ? const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            )
                                          : _currentProfile != null &&
                                                  _currentProfile!.hasPicture
                                              ? Image.network(
                                                  _currentProfile!.pictureUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      ProfileAvatarWidget(
                                                    imageUrl: null,
                                                    initials: _currentProfile!.initials,
                                                    size: 128,
                                                  ),
                                                )
                                              : ProfileAvatarWidget(
                                                  imageUrl: null,
                                                  initials: _currentProfile?.initials ?? 'U',
                                                  size: 128,
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
                        Text(
                          _currentProfile?.formattedUsername ?? '@user',
                          style: const TextStyle(
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
                      onPressed: (_selectedImageBytes != null && !_isUploading) 
                          ? _handleUpdate 
                          : null,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isUploading ? 'Uploading...' : 'Update Picture',
                        style: const TextStyle(
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
                      onPressed: _isUploading ? null : widget.onCancel,
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

class _OtpInputDialog extends StatelessWidget {
  const _OtpInputDialog({
    required this.controller,
    required this.onConfirm,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _SettingsDialogShell(
      title: 'Enter OTP Code',
      description: 'Please enter the 6-digit code sent to your email.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'OTP Code',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
        ],
      ),
      primaryLabel: 'Confirm',
      onPrimary: onConfirm,
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
