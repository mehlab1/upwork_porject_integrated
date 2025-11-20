/// Utility functions for formatting timestamps
class TimeFormatter {
  /// Formats an ISO timestamp string to a relative time string
  /// 
  /// Examples:
  /// - "just now" (less than 2 seconds)
  /// - "5s ago" (5 seconds)
  /// - "2m ago" (2 minutes)
  /// - "1h ago" (1 hour)
  /// - "3d ago" (3 days)
  /// - "2mo ago" (2 months)
  /// - "1y ago" (1 year)
  /// 
  /// Parameters:
  /// - [isoTimestamp]: ISO 8601 timestamp string (e.g., "2024-01-15T10:30:00Z")
  /// 
  /// Returns: Formatted relative time string
  static String formatTimeAgo(String isoTimestamp) {
    try {
      final now = DateTime.now().toUtc();
      final timestamp = DateTime.parse(isoTimestamp).toUtc();
      final difference = now.difference(timestamp);
      
      final seconds = difference.inSeconds;
      
      // Less than 60 seconds
      if (seconds < 60) {
        return seconds <= 1 ? "just now" : "${seconds}s ago";
      }
      
      // Less than 60 minutes
      final minutes = difference.inMinutes;
      if (minutes < 60) {
        return minutes == 1 ? "1m ago" : "${minutes}m ago";
      }
      
      // Less than 24 hours
      final hours = difference.inHours;
      if (hours < 24) {
        return hours == 1 ? "1h ago" : "${hours}h ago";
      }
      
      // Less than 30 days
      final days = difference.inDays;
      if (days < 30) {
        return days == 1 ? "1d ago" : "${days}d ago";
      }
      
      // Less than 12 months
      final months = (days / 30).floor();
      if (months < 12) {
        return months == 1 ? "1mo ago" : "${months}mo ago";
      }
      
      // Years
      final years = (months / 12).floor();
      return years == 1 ? "1y ago" : "${years}y ago";
    } catch (e) {
      // If parsing fails, return a fallback
      return "recently";
    }
  }
  
  /// Formats an ISO timestamp string to a relative time string with longer format
  /// 
  /// Examples:
  /// - "just now"
  /// - "5 seconds ago"
  /// - "2 minutes ago"
  /// - "1 hour ago"
  /// - "3 days ago"
  /// - "2 months ago"
  /// - "1 year ago"
  /// 
  /// Parameters:
  /// - [isoTimestamp]: ISO 8601 timestamp string
  /// 
  /// Returns: Formatted relative time string with full words
  static String formatTimeAgoLong(String isoTimestamp) {
    try {
      final now = DateTime.now().toUtc();
      final timestamp = DateTime.parse(isoTimestamp).toUtc();
      final difference = now.difference(timestamp);
      
      final seconds = difference.inSeconds;
      
      // Less than 60 seconds
      if (seconds < 60) {
        return seconds <= 1 ? "just now" : "$seconds seconds ago";
      }
      
      // Less than 60 minutes
      final minutes = difference.inMinutes;
      if (minutes < 60) {
        return minutes == 1 ? "1 minute ago" : "$minutes minutes ago";
      }
      
      // Less than 24 hours
      final hours = difference.inHours;
      if (hours < 24) {
        return hours == 1 ? "1 hour ago" : "$hours hours ago";
      }
      
      // Less than 30 days
      final days = difference.inDays;
      if (days < 30) {
        return days == 1 ? "1 day ago" : "$days days ago";
      }
      
      // Less than 12 months
      final months = (days / 30).floor();
      if (months < 12) {
        return months == 1 ? "1 month ago" : "$months months ago";
      }
      
      // Years
      final years = (months / 12).floor();
      return years == 1 ? "1 year ago" : "$years years ago";
    } catch (e) {
      // If parsing fails, return a fallback
      return "recently";
    }
  }
}

