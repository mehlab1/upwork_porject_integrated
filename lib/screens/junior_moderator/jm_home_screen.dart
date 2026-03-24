import 'package:flutter/material.dart';
import 'jm_feed_home_screen.dart';

class JmHomeScreen extends StatefulWidget {
  const JmHomeScreen({super.key, this.showWelcomeModal = false, this.showFirstPostCard = false});

  final bool showWelcomeModal;
  final bool showFirstPostCard;

  @override
  State<JmHomeScreen> createState() => _JmHomeScreenState();
}

class _JmHomeScreenState extends State<JmHomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return JmFeedHomeScreen(
      key: const ValueKey('feed_home'), // Stable key to preserve state
      showWelcomeModal: widget.showWelcomeModal,
      showFirstPostCard: widget.showFirstPostCard,
    );
  }
}


