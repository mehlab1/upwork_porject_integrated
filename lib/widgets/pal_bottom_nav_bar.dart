import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PalNavDestination { home, notifications, settings }

class PalBottomNavigationBar extends StatelessWidget {
  const PalBottomNavigationBar({
    super.key,
    required this.active,
    required this.onHomeTap,
    required this.onNotificationsTap,
    required this.onSettingsTap,
    this.showNotificationDot = false,
  });

  static const _primaryColor = Color(0xFF155DFC);
  static const _navBackground = Color(0xFFF7FBFF);
  static const _inactiveIconColor = Color(0xFF111827);
  static const _inactiveCircleBorder = Color(0xFFEFF6FF);

  final PalNavDestination active;
  final VoidCallback onHomeTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;
  final bool showNotificationDot;

  bool get _notificationsActive => active == PalNavDestination.notifications;
  bool get _homeActive => active == PalNavDestination.home;
  bool get _settingsActive => active == PalNavDestination.settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 62,
          decoration: BoxDecoration(
            color: _navBackground,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HomeSegment(active: _homeActive, onTap: onHomeTap),
              Transform.translate(
                offset: const Offset(-12, 0),
                child: _NotificationSegment(
                  active: _notificationsActive,
                  onTap: onNotificationsTap,
                  showDot: showNotificationDot && !_notificationsActive,
                ),
              ),
              _SettingsSegment(active: _settingsActive, onTap: onSettingsTap),
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
    return SizedBox(
      width: 119,
      height: double.infinity,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: active ? PalBottomNavigationBar._primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(38),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/navbar/homeIcon.svg',
            width: 24,
            height: 24,
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

class _NotificationSegment extends StatelessWidget {
  const _NotificationSegment({
    required this.active,
    required this.onTap,
    required this.showDot,
  });

  final bool active;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 50,
        height: 50,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            decoration: BoxDecoration(
              color: active
                  ? PalBottomNavigationBar._primaryColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: active
                  ? null
                  : Border.all(
                      color: PalBottomNavigationBar._inactiveCircleBorder,
                    ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.only(left: 8),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/navbar/notification.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    active
                        ? Colors.white
                        : PalBottomNavigationBar._inactiveIconColor,
                    BlendMode.srcIn,
                  ),
                ),
                if (showDot)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7000B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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
      width: 50,
      height: 50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: active ? PalBottomNavigationBar._primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: active
                ? null
                : Border.all(
                    color: PalBottomNavigationBar._inactiveCircleBorder,
                  ),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/navbar/settings.svg',
            width: 24,
            height: 24,
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
