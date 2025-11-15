import 'package:flutter/material.dart';
import '../feed/feed_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.showWelcomeModal = false, this.showFirstPostCard = false});

  final bool showWelcomeModal;
  final bool showFirstPostCard;

  @override
  Widget build(BuildContext context) {
    return FeedHomeScreen(showWelcomeModal: showWelcomeModal, showFirstPostCard: showFirstPostCard);
  }
}


