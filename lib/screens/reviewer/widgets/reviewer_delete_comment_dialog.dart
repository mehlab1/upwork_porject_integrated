import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _deleteCommentIconAsset = 'assets/feedPage/deleteIcon.svg';

const _dialogBorderColor = Color(0xFFE2E8F0);
const _dialogBackground = Color.fromRGBO(255, 255, 255, 0.95);
const _headerAccentBackground = Color(0xFFFFE2E2);
const _titleColor = Color(0xFF0F172B);
const _subtitleColor = Color(0xFF62748E);
const _bodyColor = Color(0xFF45556C);
const _warningBackground = Color(0xFFFFF4E5);
const _warningBorder = Color(0xFFFEE685);
const _warningTextPrimary = Color(0xFF973C00);
const _cancelBorder = Color.fromRGBO(0, 0, 0, 0.1);
const _deleteColor = Color(0xFFE7000B);

class ReviewerDeleteCommentResult {
  const ReviewerDeleteCommentResult({required this.confirmed});

  final bool confirmed;
}

class ReviewerDeleteCommentDialog extends StatelessWidget {
  const ReviewerDeleteCommentDialog({super.key, required this.commentPreview});

  final String commentPreview;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _dialogBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _dialogBorderColor, width: 1.513),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _headerAccentBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        _deleteCommentIconAsset,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          _deleteColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Comment?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _titleColor,
                            fontFamily: 'Inter',
                            letterSpacing: -0.3125,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _subtitleColor,
                            fontFamily: 'Inter',
                            letterSpacing: -0.1504,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Are you sure you want to delete this comment? It will be permanently removed from the thread.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _bodyColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.3125,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _warningBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _warningBorder, width: 0.756),
                ),
                child: RichText(
                  text: TextSpan(
                    text: 'Warning: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _warningTextPrimary,
                      fontFamily: 'Inter',
                      letterSpacing: -0.1504,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'This comment—"$commentPreview"—will be permanently deleted.',
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _cancelBorder, width: 0.756),
                        foregroundColor: _titleColor,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context)
                          .pop(const ReviewerDeleteCommentResult(confirmed: false)),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1504,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deleteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context)
                          .pop(const ReviewerDeleteCommentResult(confirmed: true)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            _deleteCommentIconAsset,
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Delete Comment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: -0.1504,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}