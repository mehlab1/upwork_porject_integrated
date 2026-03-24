import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage junior moderator status
/// Handles storing and retrieving junior moderator status for the current user
class JuniorModeratorService {
  static const String _juniorModeratorKey = 'is_junior_moderator';

  /// Check if the current user is a junior moderator
  Future<bool> isJuniorModerator() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_juniorModeratorKey) ?? false;
    } catch (e) {
      print('Error checking junior moderator status: $e');
      return false;
    }
  }

  /// Set junior moderator status for the current user
  Future<void> setJuniorModeratorStatus(bool isJuniorModerator) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_juniorModeratorKey, isJuniorModerator);
    } catch (e) {
      print('Error saving junior moderator status: $e');
    }
  }

  /// Clear junior moderator status (called on logout)
  Future<void> clearJuniorModeratorStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_juniorModeratorKey);
    } catch (e) {
      print('Error clearing junior moderator status: $e');
    }
  }
}
