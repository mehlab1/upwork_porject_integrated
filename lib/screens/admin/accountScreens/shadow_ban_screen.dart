// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/admin_user_card.dart';

// class ShadowBanScreen extends StatelessWidget {
//   const ShadowBanScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Text(
//           'Shadow Banned Account',
//           style: GoogleFonts.inter(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: const Color(0xFF0F172B),
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         iconTheme: const IconThemeData(color: Color(0xFF0F172B)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172B)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             color: const Color(0xFFF1F5F9),
//             height: 1,
//           ),
//         ),
//       ),
//       body: ListView(
//         padding: EdgeInsets.zero,
//         children: const [
//           AdminUserCard(
//             username: "@quiet_troll",
//             initials: "QT",
//             profileColor: Color(0xFFF3E8FF),
//             actionLabel: "Shadow Ban",
//             actionColor: Color(0xFF0F172B),
//           ),
//           AdminUserCard(
//             username: "@invisible_spammer",
//             initials: "IS",
//             profileColor: Color(0xFFE0E7FF),
//             actionLabel: "Shadow Ban",
//             actionColor: Color(0xFF0F172B),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/app_cache.dart';
import '../widgets/admin_user_card.dart';

class ShadowBanScreen extends StatefulWidget {
  const ShadowBanScreen({super.key});

  @override
  State<ShadowBanScreen> createState() => _ShadowBanScreenState();
}

class _ShadowBanScreenState extends State<ShadowBanScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchShadowBannedUsers();
  }

  /// Safely extract a list from edge-function response data.
  List<dynamic> _extractList(dynamic data, String key) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'] ?? data;
      if (inner is Map && inner.containsKey(key)) {
        return (inner[key] as List?) ?? [];
      }
      return (data[key] as List?) ?? [];
    }
    return [];
  }

  Future<void> _fetchShadowBannedUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_supabase.auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Use AppCache — returns immediately if prefetched, or awaits in-flight
      final data = await AppCache().getShadowBanUsers();
      final users = _extractList(data, 'users');
      debugPrint('[ShadowBan] parsed count: ${users.length}');

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Shadow Banned Account',
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
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];

                    final username = user['username'] ?? 'unknown';
                    final initials = username.isNotEmpty
                        ? username[0].toUpperCase()
                        : 'U';

                    return AdminUserCard(
                      username: '@$username',
                      initials: initials,
                      profileColor: const Color(0xFFE0E7FF),
                      actionLabel: "Shadow Ban",
                      actionColor: const Color(0xFF0F172B),
                    );
                  },
                ),
    );
  }
}