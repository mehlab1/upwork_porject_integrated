import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _postFailedToSubmitIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11.9958 21.9905C17.5163 21.9905 21.9915 17.5153 21.9915 11.9948C21.9915 6.47428 17.5163 1.99902 11.9958 1.99902C6.47525 1.99902 2 6.47428 2 11.9948C2 17.5153 6.47525 21.9905 11.9958 21.9905Z" stroke="#E7000B" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M14.9935 8.99609L8.99609 14.9935" stroke="#E7000B" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M8.99609 8.99609L14.9935 14.9935" stroke="#E7000B" stroke-width="1.99915" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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
const _errorColor = Color(0xFFE7000B);

class PostFailedSubmitResult {
  const PostFailedSubmitResult({required this.saveAsDraft});

  final bool saveAsDraft;
}

class PostFailedSubmitDialog extends StatelessWidget {
  const PostFailedSubmitDialog({super.key});

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
                      child: SvgPicture.string(
                        _postFailedToSubmitIconSvg,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Post Failed to Submit',
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
                          'Upload error',
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
              const Text(
                'Your post couldn\'t be published. This might be due to a connection issue or server error.',
                style: TextStyle(
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
                  text: const TextSpan(
                    text: 'Don\'t worry! ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _warningTextPrimary,
                      fontFamily: 'Inter',
                      letterSpacing: -0.1504,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Your post has been saved as a draft and you can try again.',
                        style: TextStyle(fontWeight: FontWeight.w400),
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
                          .pop(const PostFailedSubmitResult(saveAsDraft: true)),
                      child: const Text(
                        'Save as Draft',
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
                        backgroundColor: _titleColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context)
                          .pop(const PostFailedSubmitResult(saveAsDraft: false)),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.1504,
                        ),
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

Future<PostFailedSubmitResult?> showPostFailedSubmitDialog(BuildContext context) {
  return showDialog<PostFailedSubmitResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PostFailedSubmitDialog(),
  );
}
