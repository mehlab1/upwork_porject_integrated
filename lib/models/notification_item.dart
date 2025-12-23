import 'package:flutter/material.dart';

/// Public notification item model for use across the app
class NotificationItem {
  const NotificationItem({
    required this.headlineParts,
    required this.timestamp,
    this.subtitle,
    this.body,
    this.bodyAsQuote = false,
    this.avatarImageAsset,
    this.avatarIcon,
    this.avatarSvgAsset,
    this.avatarBackground,
    this.avatarGradient,
    this.avatarIconColor,
    this.ctaLabel,
    this.unread = false,
    this.hasAvatarBorder = false,
    this.tileBackgroundColor,
    this.notificationData,
  });

  final List<HeadlinePart> headlineParts;
  final String? subtitle;
  final String? body;
  final bool bodyAsQuote;
  final String timestamp;
  final String? avatarImageAsset;
  final IconData? avatarIcon;
  final String? avatarSvgAsset;
  final Color? avatarBackground;
  final Gradient? avatarGradient;
  final Color? avatarIconColor;
  final String? ctaLabel;
  final bool unread;
  final bool hasAvatarBorder;
  final Color? tileBackgroundColor;
  final Map<String, dynamic>? notificationData; // Store original data for navigation
}

/// Public headline part model
class HeadlinePart {
  const HeadlinePart(this.text, {this.isEmphasized = false});

  final String text;
  final bool isEmphasized;
}

