import 'package:flutter/material.dart';

/// Official kobiPal app icon from [assets/branding/app_icon.png].
class PalAppIcon extends StatelessWidget {
  const PalAppIcon({
    super.key,
    this.size = 48,
    this.borderRadius = 12,
    this.boxShadow,
  });

  final double size;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  static const assetPath = 'assets/branding/app_icon.png';

  @override
  Widget build(BuildContext context) {
    final icon = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (boxShadow == null || boxShadow!.isEmpty) {
      return icon;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: icon,
    );
  }
}
