import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/signup/email_collection_screen.dart';
import 'screens/otp/otp_verification_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/your_posts_screen.dart';
import 'screens/settings/upvoted_posts_screen.dart';
import 'screens/settings/community_guidelines_screen.dart';
import 'screens/feed/post_detail_screen.dart';
import 'services/auth_state_service.dart';
import 'services/admin_service.dart';
import 'services/moderator_service.dart';
import 'services/post_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/notification_count_manager.dart';
import 'services/user_role_service.dart';
import 'widgets/pal_push_notification.dart';

// Conditional import: use stub on web, real implementation on mobile
import 'fcm_setup_stub.dart'
    if (dart.library.io) 'fcm_setup_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // =========================================================================
    // PHASE 1: Firebase Initialization (Required first for mobile FCM)
    // =========================================================================
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        debugPrint('[main] Firebase initialized successfully');
        
        // Set up FCM background handler immediately after Firebase (non-blocking)
        try {
          setupFCMBackgroundHandler();
          debugPrint('[main] FCM background handler set up');
        } catch (e) {
          debugPrint('[main] FCM background handler setup failed: $e');
        }
      } catch (e) {
        debugPrint('[main] Firebase initialization failed: $e');
        // Continue even if Firebase fails - app should still work
      }
    }
    
    // =========================================================================
    // PHASE 2: Parallel Initialization (Supabase + Google Fonts)
    // These are independent operations that can run simultaneously
    // =========================================================================
    await Future.wait([
      // Supabase initialization (critical)
      _initializeSupabase(),
      // Google Fonts preload (non-critical, but improves UX)
      _preloadFonts(),
    ]);

    // =========================================================================
    // PHASE 3: Launch App (no more waiting)
    // =========================================================================
    runApp(const PalApp());

  } catch (e, stackTrace) {
    debugPrint('[main] Critical error during initialization: $e');
    debugPrint('[main] Stack trace: $stackTrace');
    // Show error screen instead of black screen
    runApp(
      MaterialApp(
        title: 'Pal',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Failed to initialize app. Please restart.\n\nError: ${e.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INITIALIZATION HELPER FUNCTIONS (for parallel execution)
// =============================================================================

/// Initialize Supabase client - critical for app functionality
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: 'https://wvkyzhnzwijfxpzsrguj.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('[main] Supabase initialized successfully');
  } catch (e) {
    debugPrint('[main] Supabase initialization failed: $e');
    // Rethrow - Supabase is critical for app functionality
    rethrow;
  }
}

/// Preload Google Fonts - improves text rendering on first display
Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.inter()]);
    debugPrint('[main] Google Fonts preloaded successfully');
  } catch (e) {
    debugPrint('[main] GoogleFonts preload skipped: $e');
    // Don't rethrow - fonts are not critical, app works without preload
  }
}

class PalApp extends StatefulWidget {
  const PalApp({super.key});

  @override
  State<PalApp> createState() => _PalAppState();
}

class _PalAppState extends State<PalApp> {
  final AuthStateService _authStateService = AuthStateService();
  final AdminService _adminService = AdminService();
  final ModeratorService _moderatorService = ModeratorService();
  final UserRoleService _userRoleService = UserRoleService();
  bool _isCheckingAuth = true;
  Widget? _initialRoute;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandling();
    _checkAuthState();
  }

  /// Set up FCM notification tap handling
  void _setupNotificationHandling() {
    FCMService().setNotificationTapCallback((data) {
      _handleNotificationNavigation(data);
    });

    // Register foreground message callback — shows in-app PalPushNotification banner
    FCMService().setForegroundMessageCallback((title, body, data) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        PalPushNotification.show(context, title: title, message: body);
      }
      // Also refresh the badge count
      NotificationCountManager.instance.refreshCount();
    });

    // Check for pending navigation data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingData = FCMService().getPendingNavigationData();
      if (pendingData != null) {
        _handleNotificationNavigation(pendingData);
      }
    });
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (!mounted) return;

    final notificationType = data['notification_type']?.toString() ?? '';
    final postId = data['post_id']?.toString();
    final commentId = data['comment_id']?.toString();

    debugPrint('[PalApp] Handling notification navigation: type=$notificationType, postId=$postId, commentId=$commentId');

    // Navigate based on notification type
    switch (notificationType) {
      case 'new_comment':
      case 'reply_to_comment':
      case 'post_upvote':
      case 'post_hot':
      case 'post_top':
      case 'post_trending':
        if (postId != null) {
          // Navigate directly to the post detail screen
          navigatorKey.currentState?.pushNamed(
            PostDetailScreen.routeName,
            arguments: {'postId': postId},
          );
        }
        break;
      case 'comment_upvote':
        if (postId != null) {
          navigatorKey.currentState?.pushNamed(
            PostDetailScreen.routeName,
            arguments: {
              'postId': postId,
              'commentId': commentId,
            },
          );
        }
        break;
      case 'mention_in_comment':
      case 'mention_in_post':
        if (postId != null) {
          navigatorKey.currentState?.pushNamed(
            PostDetailScreen.routeName,
            arguments: {
              'postId': postId,
              'commentId': commentId,
            },
          );
        }
        break;
      case 'report_under_review':
      case 'report_resolved':
        // Navigate to notifications screen
        navigatorKey.currentState?.pushNamed('/notifications');
        break;
      case 'account_suspended':
      case 'account_warning':
        // Navigate to settings
        navigatorKey.currentState?.pushNamed('/settings');
        break;
      default:
        // Default: navigate to notifications screen
        navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if user should be auto-logged in
      final shouldAutoLogin = await _authStateService.shouldAutoLogin();
      
      if (shouldAutoLogin) {
        // Refresh admin/moderator flags based on backend role.
        try {
          final roleResp = await _userRoleService.getUserRole();
          final role = roleResp['role']?.toString().trim();
          final isAdmin = role == 'admin';
          final isModerator = role == 'moderator' ||
              role == 'junior_moderator' ||
              role == 'reviewer';
          await _adminService.setAdminStatus(isAdmin);
          await _moderatorService.setModeratorStatus(isModerator);
        } catch (_) {
          // Non-blocking: keep previous stored values if role fetch fails.
        }

        // Kick off feed prefetch immediately — runs in parallel with everything below
        // so the feed screen's first load finds data already in cache.
        PostService().prefetchFeed();

        // Initialize FCM for logged-in user
        try {
          await FCMService().initialize();
        } catch (e) {
          // FCM initialization failure shouldn't block app startup
          debugPrint('[PalApp] FCM initialization failed: $e');
        }
        
        // Initialize notification count manager
        try {
          await NotificationCountManager.instance.initialize();
          debugPrint('[PalApp] Notification count manager initialized');
        } catch (e) {
          // Notification count manager failure shouldn't block app startup
          debugPrint('[PalApp] Notification count manager initialization failed: $e');
        }
        
        // User has valid session and Remember Me is enabled
        // Fetch profile to determine if welcome modal should be shown
        bool shouldShowWelcome = false;
        try {
          final postService = PostService();
          final profileResp = await postService.getProfile();
          final profile = profileResp['profile'] as Map<String, dynamic>?;
          int postCount = 0;
          if (profile != null) {
            final pc = profile['post_count'];
            if (pc is int) {
              postCount = pc;
            } else {
              postCount = int.tryParse(pc?.toString() ?? '') ?? 0;
            }
          }
          shouldShowWelcome = postCount <= 1;
        } catch (e) {
          // On error, default to not showing the modal
          shouldShowWelcome = false;
        }

        // Navigate to home with appropriate arguments
        if (mounted) {
          setState(() {
            _initialRoute = HomeScreen(
              showWelcomeModal: shouldShowWelcome,
              showFirstPostCard: shouldShowWelcome,
            );
            _isCheckingAuth = false;
          });
          // Note: unread notifications will be shown by FeedHomeScreen.initState
        }
      } else {
        // No valid session or Remember Me not enabled, show onboarding
        if (mounted) {
          setState(() {
            _initialRoute = const OnboardingScreen();
            _isCheckingAuth = false;
          });
        }
      }
    } catch (e) {
      // On error, default to onboarding screen
      if (mounted) {
        setState(() {
          _initialRoute = const OnboardingScreen();
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth state
    if (_isCheckingAuth) {
      return MaterialApp(
        title: 'Pal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Pal',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _initialRoute ?? const OnboardingScreen(),
      routes: {
        '/home': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final showWelcomeModal = args?['showWelcomeModal'] == true;
          final showFirstPostCard = args?['showFirstPostCard'] == true;
          return HomeScreen(showWelcomeModal: showWelcomeModal, showFirstPostCard: showFirstPostCard);
        },
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const EmailCollectionScreen(),
        '/otp': (context) {
          final email =
              ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const SettingsScreen(),
        PostDetailScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final postId = args?['postId']?.toString() ?? '';
          final commentId = args?['commentId']?.toString();
          return PostDetailScreen(
            postId: postId,
            commentId: commentId,
          );
        },
        YourPostsScreen.routeName: (context) => const YourPostsScreen(),
        UpvotedPostsScreen.routeName: (context) => const UpvotedPostsScreen(),
        CommunityGuidelinesScreen.routeName: (context) =>
            const CommunityGuidelinesScreen(),
      },
    );
  }
}
