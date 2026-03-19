import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage reviewer status
/// Handles storing and retrieving reviewer status for the current user
class ReviewerService {
  static const String _reviewerKey = 'is_reviewer';

  /// Check if the current user is a reviewer
  Future<bool> isReviewer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reviewerKey) ?? false;
    } catch (e) {
      print('Error checking reviewer status: $e');
      return false;
    }
  }

  /// Set reviewer status for the current user
  Future<void> setReviewerStatus(bool isReviewer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reviewerKey, isReviewer);
    } catch (e) {
      print('Error saving reviewer status: $e');
    }
  }

  /// Clear reviewer status (called on logout)
  Future<void> clearReviewerStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_reviewerKey);
    } catch (e) {
      print('Error clearing reviewer status: $e');
    }
  }
}
