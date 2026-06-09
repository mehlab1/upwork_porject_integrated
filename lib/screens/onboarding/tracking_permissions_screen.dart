import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../services/tracking_consent_service.dart';
import '../../widgets/pal_app_icon.dart';

/// Pre-prompt for personalized experience; on iOS, accepting also triggers ATT.
class TrackingPermissionsScreen extends StatefulWidget {
  const TrackingPermissionsScreen({
    super.key,
    this.onFinished,
    this.replacement,
  });

  /// Called after consent is saved and this screen is popped (if not using [replacement]).
  final VoidCallback? onFinished;

  /// If set, replaces the entire stack with this widget (used at cold start → home).
  final Widget? replacement;

  @override
  State<TrackingPermissionsScreen> createState() =>
      _TrackingPermissionsScreenState();
}

class _TrackingPermissionsScreenState extends State<TrackingPermissionsScreen> {
  static const Color _primaryColor = Color(0xFF155DFC);
  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _grey600 = Color(0xFF6F7786);

  final TrackingConsentService _consentService = TrackingConsentService.instance;
  bool _isProcessing = false;

  Future<void> _onAllow() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _consentService.grantPersonalizedExperience();
    _exit();
  }

  Future<void> _onDecline() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _consentService.denyPersonalizedExperience();
    _exit();
  }

  void _exit() {
    if (!mounted) return;
    final replacement = widget.replacement;

    if (replacement != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => replacement),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallDevice(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: Responsive.responsivePadding(
                  context,
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: Responsive.heightPercent(context, 6)),
                        Center(
                          child: const PalAppIcon(
                            size: 80,
                            borderRadius: 20,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                offset: Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Responsive.heightPercent(context, 4)),
                        Text(
                          'Personalized experience',
                          textAlign: TextAlign.center,
                          style: Responsive.responsiveTextStyle(
                            context,
                            fontSize: isSmall ? 26 : 32,
                            fontWeight: FontWeight.w700,
                            color: _primary900,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        SizedBox(height: Responsive.heightPercent(context, 2)),
                        Text(
                          'Pal can tailor your feed and recommendations to what matters in your community.',
                          textAlign: TextAlign.center,
                          style: Responsive.responsiveTextStyle(
                            context,
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.w400,
                            color: _grey600,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: Responsive.heightPercent(context, 4)),
                        _Bullet(
                          icon: Icons.tune_rounded,
                          title: 'Relevant local posts',
                          subtitle:
                              'See more content from your area and interests.',
                        ),
                        SizedBox(height: Responsive.scaledPadding(context, 16)),
                        _Bullet(
                          icon: Icons.insights_outlined,
                          title: 'Smarter suggestions',
                          subtitle:
                              'Discover posts and topics that match how you use Pal.',
                        ),
                        SizedBox(height: Responsive.scaledPadding(context, 16)),
                        _Bullet(
                          icon: Icons.shield_outlined,
                          title: 'You stay in control',
                          subtitle:
                              'Change this anytime in Settings. We never sell your personal data.',
                        ),
                        const Spacer(),
                        if (_isProcessing)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          _PrimaryButton(
                            label: 'Allow personalized experience',
                            onPressed: _onAllow,
                          ),
                          SizedBox(height: Responsive.scaledPadding(context, 16)),
                          _SecondaryButton(
                            label: 'Continue without',
                            onPressed: _onDecline,
                          ),
                        ],
                        SizedBox(height: Responsive.heightPercent(context, 2)),
                        Text(
                          'On iPhone, tapping Allow may show an additional Apple privacy prompt. '
                          'Android users can update this preference in app settings.',
                          textAlign: TextAlign.center,
                          style: Responsive.responsiveTextStyle(
                            context,
                            fontSize: 12,
                            color: _grey600,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: Responsive.heightPercent(context, 2)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF155DFC), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Responsive.responsiveTextStyle(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF100B3C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Responsive.responsiveTextStyle(
                  context,
                  fontSize: 13,
                  color: const Color(0xFF6F7786),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF155DFC),
        borderRadius: BorderRadius.circular(
          Responsive.responsiveRadius(context, 20),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            Responsive.responsiveRadius(context, 20),
          ),
          child: Padding(
            padding: Responsive.responsiveSymmetric(
              context,
              vertical: 14,
              horizontal: 24,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Responsive.responsiveTextStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.responsiveRadius(context, 20),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            Responsive.responsiveRadius(context, 20),
          ),
          child: Container(
            padding: Responsive.responsiveSymmetric(
              context,
              vertical: 14,
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                Responsive.responsiveRadius(context, 20),
              ),
              border: Border.all(color: const Color(0xFF155DFC)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Responsive.responsiveTextStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF155DFC),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
