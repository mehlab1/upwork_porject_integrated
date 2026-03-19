import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/profile_service.dart';
import '../../widgets/pal_loading_widgets.dart';
import '../../widgets/pal_bottom_nav_bar.dart';
import 'jm_settings_screen.dart';

class JmUserProfileScreen extends StatefulWidget {
  const JmUserProfileScreen({
    super.key,
    required this.userId,
    this.username,
    this.profilePictureUrl,
    this.initials,
  });

  final String userId;
  final String? username;
  final String? profilePictureUrl;
  final String? initials;

  @override
  State<JmUserProfileScreen> createState() => _JmUserProfileScreenState();
}

class _JmUserProfileScreenState extends State<JmUserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileData? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  // Violation counts - TODO: Get from API when available
  int _warnedPostCount = 0;
  int _mutedPostCount = 0;
  int _hiddenPostCount = 0;
  int _shadowBanningCount = 0;
  int _suspensionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileData = await _profileService.getProfileDataByUserId(
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _profileData = profileData;
        _isLoading = false;
      });

      // TODO: Load violation counts from API when available
      // For now, using placeholder values
      _loadViolationCounts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load user profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _formatDate(date);
    } catch (e) {
      return dateString; // Return as-is if parsing fails
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${month} ${date.day}, ${date.year} – $hour:$minute $amPm';
  }

  Future<void> _loadViolationCounts() async {
    // TODO: Replace with actual API call when available
    if (!mounted) return;
    setState(() {
      _warnedPostCount = 0;
      _mutedPostCount = 0;
      _hiddenPostCount = 0;
      _shadowBanningCount = 0;
      _suspensionCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const PalLoadingOverlay()
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFE7000B)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 26),
                    _buildProfilePicture(),
                    const SizedBox(height: 26),
                    _buildUserInformationSection(),
                    const SizedBox(height: 26),
                    _buildDeviceAndLocationSection(),
                    const SizedBox(height: 26),
                    _buildViolationsSection(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _isLoading
          ? null
          : PalBottomNavigationBar(
              active: PalNavDestination.home,
              onHomeTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('/home');
              },
              onNotificationsTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
              onSettingsTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const JmSettingsScreen(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.756),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Transform.rotate(
              angle: 3.14159, // 180 degrees to face left
              child: SvgPicture.asset(
                'assets/settings/dropDownIcon.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0F172B),
                  BlendMode.srcIn,
                ),
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'User Profile ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172B),
                letterSpacing: 0.0703,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    final profilePictureUrl =
        _profileData?.pictureUrl ?? widget.profilePictureUrl;
    final initials = _profileData?.initials ?? widget.initials ?? 'U';

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0F172B), width: 3),
      ),
      child: ClipOval(
        child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
            ? Image.network(
                profilePictureUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialsPlaceholder(initials),
              )
            : _buildInitialsPlaceholder(initials),
      ),
    );
  }

  Widget _buildInitialsPlaceholder(String initials) {
    return Container(
      color: const Color(0xFF155DFC),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildUserInformationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'USER INFORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF62748E),
              letterSpacing: 0.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard([
            _InfoRow(label: 'Name ', value: _profileData?.displayName ?? 'N/A'),
            _InfoRow(
              label: 'Username',
              value:
                  _profileData?.formattedUsername ?? (widget.username != null ? (widget.username!.startsWith('@') ? widget.username! : '@${widget.username!}') : 'N/A'),
            ),
            _InfoRow(
              label: 'Date of birth',
              value: _profileData?.birthday != null
                  ? _formatDateString(_profileData!.birthday!)
                  : 'N/A',
            ),
            _InfoRow(
              label: 'Date Joined',
              value: _formatDate(
                _profileData?.joinedDate ?? _profileData?.createdAt,
              ),
            ),
            _InfoRow(label: 'Trust Score', value: '0%', showTrustScore: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildDeviceAndLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE AND LOCATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF62748E),
              letterSpacing: 0.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard([
            _InfoRow(
              label: 'Device type ',
              value: 'iPhone 14', // TODO: Get from API when available
            ),
            _InfoRow(
              label: 'Operating system',
              value: 'iOS 17.2', // TODO: Get from API when available
            ),
            _InfoRow(
              label: 'Last active',
              value: _formatDateTime(
                _profileData?.createdAt,
              ), // TODO: Get last_seen from API
            ),
            _InfoRow(
              label: 'location',
              value: 'Lagos, Nigeria', // TODO: Get from API when available
            ),
            _InfoRow(
              label: 'IP Address',
              value: '123.45.67.89', // TODO: Get from API when available
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildViolationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIOLATIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF62748E),
              letterSpacing: 0.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard([
            _InfoRow(label: 'Warned Post', value: '$_warnedPostCount'),
            _InfoRow(label: 'Muted Post', value: '$_mutedPostCount'),
            _InfoRow(label: 'Hidden Post', value: '$_hiddenPostCount'),
            _InfoRow(label: 'Shadow banning', value: '$_shadowBanningCount'),
            _InfoRow(label: 'Suspension', value: '$_suspensionCount'),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A000000), width: 0.756),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildInfoRow(rows[i]),
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                thickness: 0.756,
                color: Color(0xFFF1F5F9),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172B),
              fontFamily: 'Inter',
              letterSpacing: -0.1504,
            ),
          ),
          if (row.showTrustScore)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: 0.0,
                    strokeWidth: 3,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF155DFC),
                    ),
                  ),
                ),
                const Text(
                  '0%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0F172B),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            )
          else
            Flexible(
              child: Text(
                row.value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF62748E),
                  fontFamily: 'Inter',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showTrustScore = false,
  });

  final String label;
  final String value;
  final bool showTrustScore;
}
