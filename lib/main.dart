import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/otp/otp_verification_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          return HomeScreen(showWelcomeModal: showWelcomeModal);
        },
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/otp': (context) {
          final email =
              ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      },
    );
  }
}
