import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/responsive/responsive.dart';
import '../services/notification_count_manager.dart';

enum PalNavDestination { home, notifications, settings }

class PalBottomNavigationBar extends StatelessWidget {
  const PalBottomNavigationBar({
    super.key,
    required this.active,
    required this.onHomeTap,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  static const _primaryColor = Color(0xFF155DFC);
  static const _navBackground = Color(0xFFF7FBFF);
  static const _inactiveIconColor = Color(0xFF111827);
  static const _inactiveCircleBorder = Color(0xFFEFF6FF);

  final PalNavDestination active;
  final VoidCallback onHomeTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;

  bool get _notificationsActive => active == PalNavDestination.notifications;
  bool get _homeActive => active == PalNavDestination.home;
  bool get _settingsActive => active == PalNavDestination.settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: Responsive.responsivePadding(
          context,
          left: 24,
          right: 24,
          top: 12,
          bottom: 20,
        ),
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: Responsive.scaledPadding(context, 62),
          decoration: BoxDecoration(
            color: _navBackground,
            borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 38)),
            border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.2)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Notification icon centered with slight right offset
              Transform.translate(
                offset: Offset(Responsive.scaledPadding(context, 8), 0),
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationCountManager.instance.notifier,
                  builder: (context, unreadCount, _) {
                    return _NotificationSegment(
                      active: _notificationsActive,
                      onTap: onNotificationsTap,
                      unreadCount: unreadCount > 0 && !_notificationsActive ? unreadCount : 0,
                    );
                  },
                ),
              ),
              // Home and Settings positioned at edges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HomeSegment(active: _homeActive, onTap: onHomeTap),
                  Padding(
                    padding: Responsive.responsivePadding(
                      context,
                      right: 16,
                    ),
                    child: _SettingsSegment(
                      active: _settingsActive,
                      onTap: onSettingsTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSegment extends StatelessWidget {
  const _HomeSegment({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: Responsive.widthPercent(context, 30).clamp(80.0, 140.0),
          height: double.infinity,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: active ? PalBottomNavigationBar._primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 38)),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/navbar/homeIcon.svg',
                width: Responsive.scaledIcon(context, 24),
                height: Responsive.scaledIcon(context, 24),
                colorFilter: ColorFilter.mode(
                  active ? Colors.white : PalBottomNavigationBar._inactiveIconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationSegment extends StatelessWidget {
  const _NotificationSegment({
    required this.active,
    required this.onTap,
    required this.unreadCount,
  });

  final bool active;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.scaledPadding(context, 50),
      height: Responsive.scaledPadding(context, 50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 25)),
        child: Container(
          decoration: BoxDecoration(
            color: active ? PalBottomNavigationBar._primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 25)),
            border: active
                ? null
                : Border.all(
                    color: PalBottomNavigationBar._inactiveCircleBorder,
                  ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                'assets/navbar/notification.svg',
                width: Responsive.scaledIcon(context, 24),
                height: Responsive.scaledIcon(context, 24),
                colorFilter: ColorFilter.mode(
                  active
                      ? Colors.white
                      : PalBottomNavigationBar._inactiveIconColor,
                  BlendMode.srcIn,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: Responsive.scaledPadding(context, 8),
                  right: Responsive.scaledPadding(context, 8),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: Responsive.scaledPadding(context, 18),
                      minHeight: Responsive.scaledPadding(context, 18),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: unreadCount > 9 
                          ? Responsive.scaledPadding(context, 6)
                          : Responsive.scaledPadding(context, 4),
                      vertical: Responsive.scaledPadding(context, 2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7000B),
                      borderRadius: BorderRadius.circular(
                        Responsive.scaledPadding(context, 9),
                      ),
                      border: const Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: TextStyle(
                          fontSize: Responsive.scaledFont(context, 10),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSegment extends StatelessWidget {
  const _SettingsSegment({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.scaledPadding(context, 50),
      height: Responsive.scaledPadding(context, 50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 25)),
        child: Container(
          decoration: BoxDecoration(
            color: active ? PalBottomNavigationBar._primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(Responsive.responsiveRadius(context, 25)),
            border: active
                ? null
                : Border.all(
                    color: PalBottomNavigationBar._inactiveCircleBorder,
                  ),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/navbar/settings.svg',
            width: Responsive.scaledIcon(context, 24),
            height: Responsive.scaledIcon(context, 24),
            colorFilter: ColorFilter.mode(
              active ? Colors.white : PalBottomNavigationBar._inactiveIconColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
