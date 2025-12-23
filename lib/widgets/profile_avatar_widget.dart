import 'package:flutter/material.dart';

/// Widget for displaying user profile picture with initials fallback
/// Shows network image if URL is provided, otherwise shows initials
class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 68,
    this.borderWidth = 2,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  /// Profile picture URL (network image)
  final String? imageUrl;

  /// Initials to display if no image (e.g., "JD" for John Doe)
  final String? initials;

  /// Size of the avatar (width and height)
  final double size;

  /// Border width
  final double borderWidth;

  /// Border color
  final Color? borderColor;

  /// Background color for initials (defaults to primary color)
  final Color? backgroundColor;

  /// Text color for initials (defaults to white)
  final Color? textColor;

  /// Font size for initials (defaults to size * 0.4)
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = borderColor ?? const Color(0xFF314158);
    final defaultBgColor = backgroundColor ?? const Color(0xFF155DFC);
    final defaultTextColor = textColor ?? Colors.white;
    final defaultFontSize = fontSize ?? (size * 0.4);

    // Determine what to show
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final displayInitials = initials ?? 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: defaultBorderColor,
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildInitialsPlaceholder(
                    displayInitials,
                    defaultBgColor,
                    defaultTextColor,
                    defaultFontSize,
                  );
                },
                errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(
                  displayInitials,
                  defaultBgColor,
                  defaultTextColor,
                  defaultFontSize,
                ),
              )
            : _buildInitialsPlaceholder(
                displayInitials,
                defaultBgColor,
                defaultTextColor,
                defaultFontSize,
              ),
      ),
    );
  }

  Widget _buildInitialsPlaceholder(
    String initials,
    Color bgColor,
    Color textColor,
    double fontSize,
  ) {
    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

