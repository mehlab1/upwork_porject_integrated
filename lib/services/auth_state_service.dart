import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_remember_me_service.dart';

/// Service to check authentication state and handle auto-login
/// This service is called on app startup to determine if user should be auto-logged in
class AuthStateService {
  final AuthRememberMeService _rememberMeService = AuthRememberMeService();

  /// Check if user should be auto-logged in based on Remember Me preference
  /// Returns true if user has a valid session and Remember Me was enabled
  /// 
  /// Behavior:
  /// - Remember Me = TRUE: User stays logged in across app restarts (Supabase handles token refresh)
  /// - Remember Me = FALSE: User is signed out on next app open
  Future<bool> shouldAutoLogin() async {
    try {
      // Check if Remember Me was enabled
      final rememberMeEnabled = await _rememberMeService.getRememberMe();
      
      if (!rememberMeEnabled) {
        // User didn't check Remember Me - sign out any existing session
        // This ensures users are logged out when they reopen the app
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          await Supabase.instance.client.auth.signOut();
        }
        return false;
      }

      // Remember Me is enabled - check if we have a valid session
      // Supabase automatically handles token refresh using the refresh token
      // so we don't manually check expiresAt (that's just the access token expiry)
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // No session available, clear Remember Me preference
        await _rememberMeService.clearRememberMe();
        return false;
      }

      // Verify user still exists
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await _rememberMeService.clearRememberMe();
        return false;
      }

      // All checks passed - user has Remember Me enabled and valid session
      return true;
    } catch (e) {
      print('Error checking auth state: $e');
      // On error, don't auto-login for safety
      return false;
    }
  }

  /// Get the current authenticated user if session is valid
  User? getCurrentUser() {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Check if there's a valid session (regardless of Remember Me)
  bool hasValidSession() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      // Check if session is expired
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt < now) {
          return false;
        }
      }

      return Supabase.instance.client.auth.currentUser != null;
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }
}


