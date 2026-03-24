import 'package:flutter/material.dart';
import 'reviewer_feed_home_screen.dart';

class ReviewerHomeScreen extends StatefulWidget {
  const ReviewerHomeScreen({super.key, this.showWelcomeModal = false, this.showFirstPostCard = false});

  final bool showWelcomeModal;
  final bool showFirstPostCard;

  @override
  State<ReviewerHomeScreen> createState() => _JmHomeScreenState();
}

class _JmHomeScreenState extends State<ReviewerHomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return ReviewerFeedHomeScreen(
      key: const ValueKey('feed_home'), // Stable key to preserve state
      showWelcomeModal: widget.showWelcomeModal,
      showFirstPostCard: widget.showFirstPostCard,
    );
  }
}


