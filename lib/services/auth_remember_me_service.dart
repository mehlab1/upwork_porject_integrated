import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage "Remember Me" functionality
/// Handles storing and retrieving the user's preference to stay logged in
class AuthRememberMeService {
  static const String _rememberMeKey = 'auth_remember_me';
  static const String _lastLoginUserIdKey = 'auth_last_login_user_id';

  /// Save the "Remember Me" preference
  /// If rememberMe is true, also save the current user ID
  /// If rememberMe is false, clear the stored user ID
  Future<void> setRememberMe(bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      
      if (rememberMe) {
        // Save current user ID when Remember Me is enabled
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await prefs.setString(_lastLoginUserIdKey, user.id);
        }
      } else {
        // Clear user ID when Remember Me is disabled
        await prefs.remove(_lastLoginUserIdKey);
      }
    } catch (e) {
      print('Error saving Remember Me preference: $e');
    }
  }

  /// Get the "Remember Me" preference
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Error reading Remember Me preference: $e');
      return false;
    }
  }

  /// Check if user should be auto-logged in
  /// Returns true if:
  /// 1. Remember Me was enabled
  /// 2. There's a valid session
  /// 3. The session user ID matches the stored user ID (if available)
  Future<bool> shouldAutoLogin() async {
    try {
      final rememberMe = await getRememberMe();
      if (!rememberMe) {
        return false;
      }

      // Check if there's a valid session
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        return false;
      }

      // Verify the session is still valid by checking the user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Optionally verify the user ID matches the stored one
      final prefs = await SharedPreferences.getInstance();
      final lastLoginUserId = prefs.getString(_lastLoginUserIdKey);
      if (lastLoginUserId != null && lastLoginUserId != user.id) {
        // User ID changed, clear the preference
        await clearRememberMe();
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking auto-login: $e');
      return false;
    }
  }

  /// Clear the Remember Me preference and stored user ID
  /// Called when user explicitly logs out
  Future<void> clearRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_lastLoginUserIdKey);
    } catch (e) {
      print('Error clearing Remember Me preference: $e');
    }
  }

  /// Get the current user ID if Remember Me is enabled
  Future<String?> getRememberedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoginUserIdKey);
    } catch (e) {
      print('Error reading remembered user ID: $e');
      return null;
    }
  }
}

