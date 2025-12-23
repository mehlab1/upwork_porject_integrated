import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage admin status
/// Handles storing and retrieving admin status for the current user
class AdminService {
  static const String _adminKey = 'is_admin';

  /// Check if the current user is an admin
  Future<bool> isAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_adminKey) ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Set admin status for the current user
  Future<void> setAdminStatus(bool isAdmin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminKey, isAdmin);
    } catch (e) {
      print('Error saving admin status: $e');
    }
  }

  /// Clear admin status (called on logout)
  Future<void> clearAdminStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminKey);
    } catch (e) {
      print('Error clearing admin status: $e');
    }
  }
}

