import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches the current authenticated user's role via the `get-user-role` edge function.
class UserRoleService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  static const String _baseUrl =
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

  /// Returns the raw edge-function response, typically:
  /// `{ role: "admin|moderator|junior_moderator|reviewer|user", permissions: [...] }`
  Future<Map<String, dynamic>> getUserRole() async {
    final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
    if (sessionToken == null) {
      throw Exception('No active session');
    }

    final uri = Uri.parse('$_baseUrl/get-user-role');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': _anonKey,
      'Authorization': 'Bearer $sessionToken',
    };

    final resp = await http.get(uri, headers: headers);
    final parsed = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);

    if (resp.statusCode >= 400) {
      String message = 'Failed to fetch role';
      if (parsed is Map) {
        message = (parsed['message'] ?? parsed['error'] ?? message).toString();
      }
      debugPrint('[UserRoleService] get-user-role ${resp.statusCode}: $message');
      throw Exception(message);
    }

    if (parsed is Map<String, dynamic>) return parsed;
    if (parsed is Map) return Map<String, dynamic>.from(parsed);
    return <String, dynamic>{'data': parsed};
  }
}

