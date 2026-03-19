import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _dividerColor = Color(0xFFE2E8F0);
const _primaryTextColor = Color(0xFF314158);
const _deleteTextColor = Color(0xFFE7000B);

const _mergeIconAsset = 'assets/Mod_Icons/merge-post.svg';
const _deleteIconAsset = 'assets/Mod_Icons/delete-icon-mod.svg';

enum ModeratorPostAction { merge, delete }

class ModPostActionsSheet extends StatelessWidget {
  const ModPostActionsSheet({super.key});

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
              label: 'Merge Post',
              textColor: _primaryTextColor,
              iconAsset: _mergeIconAsset,
              onTap: () =>
                  Navigator.of(context).pop(ModeratorPostAction.merge),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: _dividerColor,
            ),
            _ActionButton(
              label: 'Delete Post',
              textColor: _deleteTextColor,
              iconAsset: _deleteIconAsset,
              onTap: () =>
                  Navigator.of(context).pop(ModeratorPostAction.delete),
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
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final String iconAsset;
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
              SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
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

