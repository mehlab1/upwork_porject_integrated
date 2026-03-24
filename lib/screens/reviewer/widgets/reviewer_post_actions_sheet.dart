import 'package:flutter/material.dart';

const _reportIconUrl =
    'http://localhost:3845/assets/cb61929553b7d8f69935bfebd61c3621a68ef1a8.svg';
const _deleteIconUrl =
    'http://localhost:3845/assets/7955eed7a9f56c34af6459c727fa4eca183e4331.svg';

const _dividerColor = Color(0xFFE2E8F0);
const _reportTextColor = Color(0xFF314158);
const _deleteTextColor = Color(0xFFE7000B);

enum PostAction { report, delete }

class ReviewerPostActionsSheet extends StatelessWidget {
  const ReviewerPostActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 30,
              offset: Offset(0, -12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionButton(
              label: 'Report Post',
              textColor: _reportTextColor,
              iconUrl: _reportIconUrl,
              onTap: () => Navigator.of(context).pop(PostAction.report),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: _dividerColor,
            ),
            _ActionButton(
              label: 'Delete Post',
              textColor: _deleteTextColor,
              iconUrl: _deleteIconUrl,
              onTap: () => Navigator.of(context).pop(PostAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.textColor,
    required this.iconUrl,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final String iconUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Image.network(
                iconUrl,
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => Icon(
                  label == 'Delete Post' ? Icons.delete_outline : Icons.flag,
                  size: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.1504,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

