import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../widgets/pal_bottom_nav_bar.dart';
import '../widgets/hidden_card.dart';

class HiddenPostsScreen extends StatelessWidget {
  const HiddenPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background from Figma
      appBar: AppBar(
        title: const Text(
          'Hidden Post',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9), // Matching separator color
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Mock Post 1 (Matches Figma)
          HiddenCard(
            username: '@surulere_resident',
            initials: 'SU',
            timeAgo: '5d ago',
            location: 'Surulere',
            category: 'Gist',
            title: 'The power situation in Surulere is getting ridiculous!',
            body: 'NEPA (yes I still call it NEPA) has been taking light every day for the past week. 2 hours on, 6 hours off. My generator is working overtime and fuel prices are crazy.',
            voteCount: 287,
            commentCount: 1,
          ),
          
           // Mock Post 2 (Duplicate to populate list)
          HiddenCard(
            username: '@surulere_resident',
            initials: 'SU',
            timeAgo: '5d ago',
            location: 'Surulere',
            category: 'Gist',
            title: 'The power situation in Surulere is getting ridiculous!',
            body: 'NEPA (yes I still call it NEPA) has been taking light every day for the past week. 2 hours on, 6 hours off. My generator is working overtime and fuel prices are crazy.',
            voteCount: 287,
            commentCount: 1,
          ),

           // Mock Post 3
          HiddenCard(
            username: '@surulere_resident',
            initials: 'SU',
            timeAgo: '5d ago',
            location: 'Surulere',
            category: 'Gist',
            title: 'The power situation in Surulere is getting ridiculous!',
            body: 'NEPA (yes I still call it NEPA) has been taking light every day for the past week. 2 hours on, 6 hours off. My generator is working overtime and fuel prices are crazy.',
            voteCount: 287,
            commentCount: 1,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: PalBottomNavigationBar(
           // Keeping 'settings' active since we are in admin settings flow
          active: PalNavDestination.settings,
          onHomeTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacementNamed('/home');
          },
          onNotificationsTap: () {
             Navigator.pushNamed(context, '/notifications');
          },
          onSettingsTap: () {
             // Already in settings flow
          },
        ),
      ),
    );
  }
}
