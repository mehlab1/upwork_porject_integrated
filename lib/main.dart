import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/otp/otp_verification_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/your_posts_screen.dart';
import 'screens/settings/community_guidelines_screen.dart';
import 'services/auth_state_service.dart';
import 'services/post_service.dart';
import 'services/fcm_service.dart';

// Conditional import: use stub on web, real implementation on mobile
import 'fcm_setup_stub.dart'
    if (dart.library.io) 'fcm_setup_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (only on mobile platforms, not web)
  if (!kIsWeb) {
  await Firebase.initializeApp();
  }
  
  // Set up background message handler (only on mobile platforms)
  setupFCMBackgroundHandler();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://wvkyzhnzwijfxpzsrguj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  runApp(const PalApp());
}

class PalApp extends StatefulWidget {
  const PalApp({super.key});

  @override
  State<PalApp> createState() => _PalAppState();
}

class _PalAppState extends State<PalApp> {
  final AuthStateService _authStateService = AuthStateService();
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
          // Navigate to post detail (you may need to create this screen)
          navigatorKey.currentState?.pushNamed('/home', arguments: {
            'highlight_post_id': postId,
          });
        }
        break;
      case 'comment_upvote':
        if (postId != null) {
          navigatorKey.currentState?.pushNamed('/home', arguments: {
            'highlight_post_id': postId,
            'highlight_comment_id': commentId,
          });
        }
        break;
      case 'mention_in_comment':
      case 'mention_in_post':
        if (postId != null) {
          navigatorKey.currentState?.pushNamed('/home', arguments: {
            'highlight_post_id': postId,
            'highlight_comment_id': commentId,
          });
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
        // Initialize FCM for logged-in user
        try {
          await FCMService().initialize();
        } catch (e) {
          // FCM initialization failure shouldn't block app startup
          debugPrint('[PalApp] FCM initialization failed: $e');
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
          shouldShowWelcome = postCount == 0;
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
        '/signup': (context) => const SignUpScreen(),
        '/otp': (context) {
          final email =
              ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const SettingsScreen(),
        YourPostsScreen.routeName: (context) => const YourPostsScreen(),
        CommunityGuidelinesScreen.routeName: (context) =>
            const CommunityGuidelinesScreen(),
      },
    );
  }
}
