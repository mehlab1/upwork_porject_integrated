import 'package:flutter/material.dart';
import '../feed/feed_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.showWelcomeModal = false});

  final bool showWelcomeModal;

  @override
  Widget build(BuildContext context) {
    return FeedHomeScreen(showWelcomeModal: showWelcomeModal);
  }
}


