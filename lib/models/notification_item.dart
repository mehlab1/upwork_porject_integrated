import 'package:flutter/material.dart';

/// Public notification item model for use across the app
class NotificationItem {
  const NotificationItem({
    required this.headlineParts,
    required this.timestamp,
    this.subtitle,
    this.body,
    this.bodyAsQuote = false,
    this.avatarNetworkUrl,
    this.avatarInitials,
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
  final String? avatarNetworkUrl;
  final String? avatarInitials;
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

  NotificationItem copyWith({
    List<HeadlinePart>? headlineParts,
    String? subtitle,
    String? body,
    bool? bodyAsQuote,
    String? timestamp,
    String? avatarNetworkUrl,
    String? avatarInitials,
    String? avatarImageAsset,
    IconData? avatarIcon,
    String? avatarSvgAsset,
    Color? avatarBackground,
    Gradient? avatarGradient,
    Color? avatarIconColor,
    String? ctaLabel,
    bool? unread,
    bool? hasAvatarBorder,
    Color? tileBackgroundColor,
    Map<String, dynamic>? notificationData,
  }) {
    return NotificationItem(
      headlineParts: headlineParts ?? this.headlineParts,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      bodyAsQuote: bodyAsQuote ?? this.bodyAsQuote,
      timestamp: timestamp ?? this.timestamp,
      avatarNetworkUrl: avatarNetworkUrl ?? this.avatarNetworkUrl,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarImageAsset: avatarImageAsset ?? this.avatarImageAsset,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarSvgAsset: avatarSvgAsset ?? this.avatarSvgAsset,
      avatarBackground: avatarBackground ?? this.avatarBackground,
      avatarGradient: avatarGradient ?? this.avatarGradient,
      avatarIconColor: avatarIconColor ?? this.avatarIconColor,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      unread: unread ?? this.unread,
      hasAvatarBorder: hasAvatarBorder ?? this.hasAvatarBorder,
      tileBackgroundColor: tileBackgroundColor ?? this.tileBackgroundColor,
      notificationData: notificationData ?? this.notificationData,
    );
  }
}

/// Public headline part model
class HeadlinePart {
  const HeadlinePart(this.text, {this.isEmphasized = false});

  final String text;
  final bool isEmphasized;
}

