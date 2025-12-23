import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for logout API calls
/// Handles logout through the Supabase Edge Function
class AuthLogoutService {
  AuthLogoutService();

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Internal helper to call Supabase Edge Functions
  Future<Map<String, dynamic>> _callFunction(
    String functionName, {
    Map<String, dynamic>? body,
    String method = 'POST',
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/$functionName');
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      late http.Response resp;
      final encoded = body == null ? null : jsonEncode(body);
      if (method.toUpperCase() == 'GET') {
        resp = await http.get(uri, headers: headers);
      } else {
        resp = await http.post(uri, headers: headers, body: encoded);
      }

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      // The logout function returns success even for invalid/expired tokens
      // So we only throw on actual server errors (500+), not on 200 responses
      if (resp.statusCode >= 500) {
        final errorMessage = parsed['message'] ?? parsed['error'] ?? 'Server error';
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user using the logout edge function
  /// 
  /// The edge function handles:
  /// - Authentication validation (returns success even if token is invalid/expired)
  /// - Deactivation of push notification device tokens (sets is_active: false)
  /// - Session invalidation via supabaseClient.auth.signOut()
  /// - Graceful error handling (returns success even on errors to prevent stuck state)
  /// 
  /// Returns: Map with success (bool), message (String), and optionally user_id (String) or note (String)
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _callFunction('logout', body: {});
      return response;
    } catch (e) {
      // Even if the API call fails, we should consider logout successful
      // to prevent users from being stuck in a logged-in state
      // This matches the backend behavior
      return {
        'success': true,
        'message': 'Logged out successfully',
        'note': 'Session cleared despite API error',
      };
    }
  }
}

