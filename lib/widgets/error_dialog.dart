import 'package:flutter/material.dart';

// Color constants matching the design
const _dialogBackground = Colors.white;
const _errorIconBackground = Color(0xFFFFE2E2); // Light red background
const _titleColor = Color(0xFF0F172A); // Dark gray for title
const _subtitleColor = Color(0xFF62748E); // Lighter gray for subtitle
const _bodyColor = Color(0xFF45556C); // Medium gray for body text
const _cancelBorder = Color(0xFFE2E8F0); // Light gray border
const _tryAgainColor = Color(0xFF155DFC); // Dark blue for Try Again button

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.message,
    this.onCancel,
    this.onTryAgain,
  });

  final String title;
  final String subtitle;
  final String message;
  final VoidCallback? onCancel;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _dialogBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                          fontFamily: 'Inter',
                          letterSpacing: -0.3125,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _subtitleColor,
                          fontFamily: 'Inter',
                          letterSpacing: -0.1504,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Error message body
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: _bodyColor,
                fontFamily: 'Inter',
                letterSpacing: -0.3125,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: _cancelBorder,
                        width: 1.0,
                      ),
                      foregroundColor: _titleColor,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        letterSpacing: -0.1504,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tryAgainColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onTryAgain ?? () => Navigator.of(context).pop(),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        letterSpacing: -0.1504,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show error dialog with dynamic content from backend error
/// Converts technical error messages to human-readable format
Future<void> showErrorDialog(
  BuildContext context, {
  required String errorMessage,
  String? title,
  String? subtitle,
  VoidCallback? onCancel,
  VoidCallback? onTryAgain,
}) {
  final errorLower = errorMessage.toLowerCase();
  
  String dialogTitle;
  String dialogSubtitle;
  String dialogMessage;

  // Network/Connection Errors (including XMLHttpRequest and HTTP errors)
  if (errorLower.contains('xmlhttprequest') ||
      errorLower.contains('http') ||
      errorLower.contains('network') ||
      errorLower.contains('connection') ||
      errorLower.contains('timeout') ||
      errorLower.contains('socket') ||
      errorLower.contains('failed host lookup') ||
      errorLower.contains('no internet') ||
      errorLower.contains('connection refused') ||
      errorLower.contains('failed to connect') ||
      errorLower.contains('connection closed') ||
      errorLower.contains('connection reset') ||
      errorLower.contains('network is unreachable') ||
      errorLower.contains('dns') ||
      errorLower.contains('lookup failed')) {
    dialogTitle = title ?? 'Connection Error';
    dialogSubtitle = subtitle ?? 'Unable to connect';
    dialogMessage = 'Your internet connection was lost or is unstable. Please check your connection and try again.';
  }
  // Authentication/Session Errors
  else if (errorLower.contains('unauthorized') ||
      errorLower.contains('authentication') ||
      errorLower.contains('session') ||
      errorLower.contains('token') ||
      errorLower.contains('logged in') ||
      errorLower.contains('must be logged in')) {
    dialogTitle = title ?? 'Session Expired';
    dialogSubtitle = subtitle ?? 'Please log in again';
    dialogMessage = 'Your session has expired or is invalid. Please log in again to continue.';
  }
  // Account Status Errors
  else if (errorLower.contains('account is not active') ||
      errorLower.contains('account not active')) {
    dialogTitle = title ?? 'Account Inactive';
    dialogSubtitle = subtitle ?? 'Account access restricted';
    dialogMessage = 'Your account is currently inactive. Please contact support if you believe this is an error.';
  }
  else if (errorLower.contains('profile not found')) {
    dialogTitle = title ?? 'Account Error';
    dialogSubtitle = subtitle ?? 'Profile not found';
    dialogMessage = 'Your account profile could not be found. Please try logging out and logging back in.';
  }
  // Content Validation Errors
  else if (errorLower.contains('content is required') ||
      errorLower.contains('content must be')) {
    dialogTitle = title ?? 'Invalid Content';
    dialogSubtitle = subtitle ?? 'Please check your post';
    if (errorLower.contains('1000 characters')) {
      dialogMessage = 'Your post content is too long. Please keep it under 1000 characters.';
    } else {
      dialogMessage = 'Your post content is empty or invalid. Please add some content before posting.';
    }
  }
  // Category/Location Validation Errors
  else if (errorLower.contains('invalid category') ||
      errorLower.contains('category selected')) {
    dialogTitle = title ?? 'Invalid Category';
    dialogSubtitle = subtitle ?? 'Category selection error';
    dialogMessage = 'The selected category is invalid. Please select a different category and try again.';
  }
  else if (errorLower.contains('invalid location') ||
      errorLower.contains('location selected')) {
    dialogTitle = title ?? 'Invalid Location';
    dialogSubtitle = subtitle ?? 'Location selection error';
    dialogMessage = 'The selected location is invalid. Please select a different location and try again.';
  }
  // Monthly Spotlight Errors
  else if (errorLower.contains('monthly spotlight') ||
      errorLower.contains('spotlight not available')) {
    dialogTitle = title ?? 'Spotlight Unavailable';
    dialogSubtitle = subtitle ?? 'Monthly spotlight error';
    dialogMessage = 'Monthly spotlight is currently not available. You can still create your post without it.';
  }
  // Server/Backend Errors
  else if (errorLower.contains('internal server error') ||
      errorLower.contains('server error') ||
      errorLower.contains('failed to create') ||
      errorLower.contains('failed to validate')) {
    dialogTitle = title ?? 'Server Error';
    dialogSubtitle = subtitle ?? 'Something went wrong';
    dialogMessage = 'We encountered an issue while processing your request. Please try again in a few moments.';
  }
  // Validation Errors (General)
  else if (errorLower.contains('validation') ||
      errorLower.contains('invalid input') ||
      errorLower.contains('invalid')) {
    dialogTitle = title ?? 'Invalid Input';
    dialogSubtitle = subtitle ?? 'Please check your input';
    dialogMessage = 'Some of the information you provided is invalid. Please review and try again.';
  }
  // Permission/Access Errors
  else if (errorLower.contains('permission') ||
      errorLower.contains('forbidden') ||
      errorLower.contains('access denied')) {
    dialogTitle = title ?? 'Access Denied';
    dialogSubtitle = subtitle ?? 'Insufficient permissions';
    dialogMessage = 'You don\'t have permission to perform this action. Please contact support if you believe this is an error.';
  }
  // Default - Use provided title/subtitle or generic message
  else {
    dialogTitle = title ?? 'Error';
    dialogSubtitle = subtitle ?? 'Something went wrong';
    // Try to make the error message more readable
    dialogMessage = _makeErrorMessageReadable(errorMessage);
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => ErrorDialog(
      title: dialogTitle,
      subtitle: dialogSubtitle,
      message: dialogMessage,
      onCancel: onCancel,
      onTryAgain: onTryAgain,
    ),
  );
}

/// Converts technical error messages to human-readable format
String _makeErrorMessageReadable(String errorMessage) {
  final errorLower = errorMessage.toLowerCase();
  
  // Handle XMLHttpRequest errors specifically
  if (errorLower.contains('xmlhttprequest')) {
    return 'Your internet connection was lost or is unstable. Please check your connection and try again.';
  }
  
  // Handle other HTTP-related technical errors
  if (errorLower.contains('http') && 
      (errorLower.contains('error') || errorLower.contains('failed') || errorLower.contains('exception'))) {
    return 'We couldn\'t connect to the server. Please check your internet connection and try again.';
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
    return 'We encountered a connection issue. Please check your internet connection and try again.';
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

