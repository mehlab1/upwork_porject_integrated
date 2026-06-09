import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedLoginCredentials {
  const SavedLoginCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Service to manage "Remember Me" functionality.
/// Stores login preference, optional saved credentials, and last user id for session checks.
class AuthRememberMeService {
  static const String _rememberMeKey = 'auth_remember_me';
  static const String _lastLoginUserIdKey = 'auth_last_login_user_id';
  static const String _savedEmailKey = 'auth_remember_email';
  static const String _savedPasswordKey = 'auth_remember_password';

  /// Saves Remember Me preference and, when enabled, credentials for login autofill.
  Future<void> setRememberMe(
    bool rememberMe, {
    String? email,
    String? password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);

      if (rememberMe) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await prefs.setString(_lastLoginUserIdKey, user.id);
        }
        if (email != null && email.trim().isNotEmpty) {
          await prefs.setString(_savedEmailKey, email.trim());
        }
        if (password != null && password.isNotEmpty) {
          await prefs.setString(_savedPasswordKey, password);
        }
      } else {
        await prefs.remove(_lastLoginUserIdKey);
        await prefs.remove(_savedEmailKey);
        await prefs.remove(_savedPasswordKey);
      }
    } catch (e) {
      print('Error saving Remember Me preference: $e');
    }
  }

  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Error reading Remember Me preference: $e');
      return false;
    }
  }

  /// Returns saved email/password when Remember Me is enabled.
  Future<SavedLoginCredentials?> getSavedLoginCredentials() async {
    try {
      final rememberMe = await getRememberMe();
      if (!rememberMe) return null;

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_savedEmailKey);
      if (email == null || email.isEmpty) return null;

      return SavedLoginCredentials(
        email: email,
        password: prefs.getString(_savedPasswordKey) ?? '',
      );
    } catch (e) {
      print('Error reading saved login credentials: $e');
      return null;
    }
  }

  Future<bool> shouldAutoLogin() async {
    try {
      final rememberMe = await getRememberMe();
      if (!rememberMe) {
        return false;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastLoginUserId = prefs.getString(_lastLoginUserIdKey);
      if (lastLoginUserId != null && lastLoginUserId != user.id) {
        await clearRememberMe();
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking auto-login: $e');
      return false;
    }
  }

  /// Clears Remember Me preference, saved credentials, and stored user id.
  Future<void> clearRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_lastLoginUserIdKey);
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
    } catch (e) {
      print('Error clearing Remember Me preference: $e');
    }
  }

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
