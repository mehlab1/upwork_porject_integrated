import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/suspended_users_service.dart';
import '../widgets/admin_user_card.dart';

class SuspendedAccountScreen extends StatefulWidget {
  const SuspendedAccountScreen({super.key});

  @override
  State<SuspendedAccountScreen> createState() => _SuspendedAccountScreenState();
}

class _SuspendedAccountScreenState extends State<SuspendedAccountScreen> {
  final SuspendedUsersService _service = SuspendedUsersService();
  List<_SuspendedUserRow> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await _service.getSuspendedUsers(limit: 50, offset: 0);
      if (!mounted) return;

      // Preserve the original color feel by cycling through the existing palette.
      const palette = <Color>[
        Color(0xFFE0F2FE),
        Color(0xFFFEF3C7),
        Color(0xFFF1F5F9),
      ];

      final mapped = <_SuspendedUserRow>[];
      for (var i = 0; i < users.length; i++) {
        final u = users[i];
        final username = (u['username'] ?? '').toString();
        if (username.isEmpty) continue;
        mapped.add(
          _SuspendedUserRow(
            username.startsWith('@') ? username : '@$username',
            _initialsFromUsername(username),
            palette[i % palette.length],
          ),
        );
      }

      setState(() {
        _rows = mapped;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _initialsFromUsername(String username) {
    final clean = username.replaceAll('@', '').trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'[\s_.-]+'));
    if (parts.length >= 2) {
      return '${parts.first.isNotEmpty ? parts.first[0] : ''}${parts.last.isNotEmpty ? parts.last[0] : ''}'
          .toUpperCase();
    }
    if (clean.length >= 2) return clean.substring(0, 2).toUpperCase();
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Suspended Account',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172B)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Color(0xFF0F172B)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(
                  child: Text(
                    'No suspended accounts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                )
              : ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final row in _rows)
            AdminUserCard(
              username: row.username,
              initials: row.initials,
              profileColor: row.profileColor,
              actionLabel: "Suspended",
              actionColor: const Color(0xFF94292F),
            ),
        ],
      ),
    );
  }
}

class _SuspendedUserRow {
  const _SuspendedUserRow(this.username, this.initials, this.profileColor);

  final String username;
  final String initials;
  final Color profileColor;
}
