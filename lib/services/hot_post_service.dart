import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HotPostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the full envelope: { hottest_post, comparison, ... }
  Future<Map<String, dynamic>> getHotPostData() async {
    final response = await _supabase.functions.invoke(
      'get-hottest-post',
      body: {
        'timeframe': 'today',
        'include_comparison': true,
      },
    );

    debugPrint('[HotPost] raw: ${response.data}');

    if (response.data == null) return {};

    final raw = response.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  Future<Map<String, dynamic>?> getHotPost() async {
    final data = await getHotPostData();
    final post = data['hottest_post'];
    if (post is Map && post.isNotEmpty) {
      return Map<String, dynamic>.from(post);
    }
    return null;
  }
}