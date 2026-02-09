import 'package:flutter/material.dart';
import '../feed/feed_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showWelcomeModal = false, this.showFirstPostCard = false});

  final bool showWelcomeModal;
  final bool showFirstPostCard;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return FeedHomeScreen(
      key: const ValueKey('feed_home'), // Stable key to preserve state
      showWelcomeModal: widget.showWelcomeModal,
      showFirstPostCard: widget.showFirstPostCard,
    );
  }
}


