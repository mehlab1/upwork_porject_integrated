import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage moderator status
/// Handles storing and retrieving moderator status for the current user
class ModeratorService {
  static const String _moderatorKey = 'is_moderator';

  /// Check if the current user is a moderator
  Future<bool> isModerator() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_moderatorKey) ?? false;
    } catch (e) {
      print('Error checking moderator status: $e');
      return false;
    }
  }

  /// Set moderator status for the current user
  Future<void> setModeratorStatus(bool isModerator) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_moderatorKey, isModerator);
    } catch (e) {
      print('Error saving moderator status: $e');
    }
  }

  /// Clear moderator status (called on logout)
  Future<void> clearModeratorStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_moderatorKey);
    } catch (e) {
      print('Error clearing moderator status: $e');
    }
  }
}
