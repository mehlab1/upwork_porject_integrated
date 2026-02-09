import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/error_dialog.dart';
import '../widgets/pal_toast.dart';

/// Error handling utility class that converts technical errors to human-readable messages
class ErrorHandler {
  /// Checks if an error is a network/offline error
  static bool isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Check for common network error patterns
    return errorStr.contains('clientexception') ||
        errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('socket failed') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('no internet') ||
        errorStr.contains('network error') ||
        errorStr.contains('xmlhttprequest') ||
        errorStr.contains('httpclientexception') ||
        errorStr.contains('timeout') ||
        error is SocketException ||
        error is HttpException;
  }
  
  /// Gets a user-friendly offline message
  static String getOfflineMessage() {
    return 'No internet connection. Please check your network and try again.';
  }
  
  /// Shows a user-friendly offline toast notification
  static void showOfflineToast(BuildContext context) {
    PalToast.show(
      context,
      message: getOfflineMessage(),
      isError: true,
    );
  }
  /// Maps technical error messages to human-readable formats with 15+ scenarios
  static Future<void> showHumanReadableError(
    BuildContext context, {
    required String technicalError,
    String? customTitle,
    String? customSubtitle,
    VoidCallback? onCancel,
    VoidCallback? onTryAgain,
  }) {
    final errorLower = technicalError.toLowerCase();
    
    String title, subtitle, message;
    
    // 1. Network/Connection Issues
    if (errorLower.contains('network') || 
        errorLower.contains('connection') || 
        errorLower.contains('xmlhttprequest') ||
        errorLower.contains('socketexception') ||
        errorLower.contains('failed host lookup') ||
        errorLower.contains('connection refused') ||
        errorLower.contains('network is unreachable')) {
      title = customTitle ?? 'No Network';
      subtitle = customSubtitle ?? 'Connection issue';
      message = 'No Network, check your internet connection';
    }
    // 2. Timeout Errors
    else if (errorLower.contains('timeout')) {
      title = customTitle ?? 'No Network';
      subtitle = customSubtitle ?? 'Connection issue';
      message = 'No Network, check your internet connection';
    }
    // 3. Authentication/Session Errors
    else if (errorLower.contains('unauthorized') ||
             errorLower.contains('401') ||
             errorLower.contains('must be logged in') ||
             errorLower.contains('session expired')) {
      title = customTitle ?? 'Session Expired';
      subtitle = customSubtitle ?? 'Please log in again';
      message = 'Your session has expired or is invalid. Please log in again to continue.';
    }
    // 4. Server Errors (500 series)
    else if (errorLower.contains('500') ||
             errorLower.contains('internal server error') ||
             errorLower.contains('server error')) {
      title = customTitle ?? 'Server Error';
      subtitle = customSubtitle ?? 'Something went wrong';
      message = 'We encountered an issue on our servers. Please try again in a few moments.';
    }
    // 5. Not Found Errors (404)
    else if (errorLower.contains('404') ||
             errorLower.contains('not found')) {
      title = customTitle ?? 'Not Found';
      subtitle = customSubtitle ?? 'Resource unavailable';
      message = 'The requested resource could not be found. It may have been removed or is temporarily unavailable.';
    }
    // 6. Bad Request Errors (400 series)
    else if (errorLower.contains('400') ||
             errorLower.contains('bad request') ||
             errorLower.contains('validation failed')) {
      title = customTitle ?? 'Invalid Request';
      subtitle = customSubtitle ?? 'Please check your input';
      message = 'Your request could not be processed due to invalid data. Please check your input and try again.';
    }
    // 7. Permission/Access Denied Errors
    else if (errorLower.contains('403') ||
             errorLower.contains('forbidden') ||
             errorLower.contains('access denied') ||
             errorLower.contains('permission')) {
      title = customTitle ?? 'Access Denied';
      subtitle = customSubtitle ?? 'Insufficient permissions';
      message = 'You don\'t have permission to perform this action. Please contact support if you believe this is an error.';
    }
    // 8. Account Inactive Errors
    else if (errorLower.contains('account is not active') ||
             errorLower.contains('account deactivated')) {
      title = customTitle ?? 'Account Inactive';
      subtitle = customSubtitle ?? 'Account access restricted';
      message = 'Your account is currently inactive. Please contact support for assistance.';
    }
    // 9. Content Validation Errors
    else if (errorLower.contains('content is required') ||
             errorLower.contains('content must be') ||
             errorLower.contains('empty content')) {
      title = customTitle ?? 'Invalid Content';
      subtitle = customSubtitle ?? 'Please check your post';
      if (errorLower.contains('1000 characters')) {
        message = 'Your post content is too long. Please keep it under 1000 characters.';
      } else {
        message = 'Your post content is empty or invalid. Please add some content before posting.';
      }
    }
    // 10. Comment Validation Errors
    else if (errorLower.contains('comment cannot be empty') ||
             errorLower.contains('comment must be') ||
             errorLower.contains('500 characters')) {
      title = customTitle ?? 'Invalid Comment';
      subtitle = customSubtitle ?? 'Please check your comment';
      if (errorLower.contains('500 characters')) {
        message = 'Your comment is too long. Please keep it under 500 characters.';
      } else {
        message = 'Your comment is empty. Please add some content before posting.';
      }
    }
    // 11. Database Function Errors
    else if (errorLower.contains('structure of query does not match function result type') ||
             errorLower.contains('database function')) {
      title = customTitle ?? 'System Error';
      subtitle = customSubtitle ?? 'Database issue';
      message = 'We encountered a technical issue with our database. Our team has been notified and is working on a fix.';
    }
    // 12. Post Not Found Errors
    else if (errorLower.contains('post not found') ||
             errorLower.contains('post does not exist')) {
      title = customTitle ?? 'Post Not Found';
      subtitle = customSubtitle ?? 'No longer available';
      message = 'This post is no longer available. It may have been deleted or is temporarily unavailable.';
    }
    // 13. Rate Limiting Errors
    else if (errorLower.contains('rate limit') ||
             errorLower.contains('too many requests') ||
             errorLower.contains('429')) {
      title = customTitle ?? 'Too Many Requests';
      subtitle = customSubtitle ?? 'Please wait';
      message = 'You\'ve made too many requests in a short period. Please wait a moment and try again.';
    }
    // 14. Profile/Account Errors
    else if (errorLower.contains('profile not found') ||
             errorLower.contains('user not found')) {
      title = customTitle ?? 'Account Error';
      subtitle = customSubtitle ?? 'Profile issue';
      message = 'There was an issue with your account profile. Please try logging out and back in.';
    }
    // 15. Image Upload Errors
    else if (errorLower.contains('image upload') ||
             errorLower.contains('file too large') ||
             errorLower.contains('invalid file type')) {
      title = customTitle ?? 'Upload Error';
      subtitle = customSubtitle ?? 'Image issue';
      if (errorLower.contains('file too large')) {
        message = 'The image file is too large. Please choose a smaller image and try again.';
      } else if (errorLower.contains('invalid file type')) {
        message = 'The selected file is not a valid image type. Please choose a JPG, PNG, or GIF file.';
      } else {
        message = 'There was an issue uploading your image. Please try again.';
      }
    }
    // 16. General Fallback for Unknown Errors
    else {
      title = customTitle ?? 'Something Went Wrong';
      subtitle = customSubtitle ?? 'Unexpected error';
      message = _makeErrorMessageReadable(technicalError);
    }
    
    return showErrorDialog(
      context,
      title: title,
      subtitle: subtitle,
      errorMessage: message,
      onCancel: onCancel,
      onTryAgain: onTryAgain,
    );
  }
  
  /// Converts technical error messages to human-readable format
  static String _makeErrorMessageReadable(String errorMessage) {
    final errorLower = errorMessage.toLowerCase();
    
    // Handle XMLHttpRequest errors specifically
    if (errorLower.contains('xmlhttprequest')) {
      return 'No Network, check your internet connection';
    }
    
    // Handle other HTTP-related technical errors
    if (errorLower.contains('http') && 
        (errorLower.contains('error') || errorLower.contains('failed') || errorLower.contains('exception'))) {
      return 'No Network, check your internet connection';
    }
    
    // Remove common technical prefixes
    String readable = errorMessage
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^Error:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'XMLHttpRequest\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'error\.?\s*$', caseSensitive: false), '')
        .trim();

    // If after cleaning it's still technical, provide a generic message
    if (readable.isEmpty || 
        readable.toLowerCase().contains('xmlhttprequest') ||
        readable.toLowerCase().contains('httpclient') ||
        readable.toLowerCase().startsWith('http')) {
      return 'No Network, check your internet connection';
    }

    // Capitalize first letter
    if (readable.isNotEmpty) {
      readable = readable[0].toUpperCase() + readable.substring(1);
    }

    // Add period if missing
    if (readable.isNotEmpty && !readable.endsWith('.') && !readable.endsWith('!') && !readable.endsWith('?')) {
      readable += '.';
    }

    return readable;
  }
}