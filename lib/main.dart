import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

class PalApp extends StatelessWidget {
  const PalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
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
