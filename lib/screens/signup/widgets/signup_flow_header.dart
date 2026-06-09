import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';

/// Shared header for signup flow steps — matches [SignupScreen] title position.
class SignupFlowHeader extends StatelessWidget {
  const SignupFlowHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  static const Color _titleColor = Color(0xFF100B3C);

  @override
  Widget build(BuildContext context) {
    final titleSize = Responsive.scaledFont(context, 32);

    return Column(
      children: [
        SizedBox(height: Responsive.scaledPadding(context, 64)),
        SizedBox(
          height: titleSize * 1.25,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: _titleColor,
                    size: 32,
                  ),
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                    color: _titleColor,
                    letterSpacing: 0,
                    fontFamily: 'Rubik',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
