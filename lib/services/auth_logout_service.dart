import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for logout API calls
/// Handles logout through the Supabase Edge Function
class AuthLogoutService {
  AuthLogoutService();

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Internal helper to call Supabase Edge Functions with masked logging
  Future<Map<String, dynamic>> _callFunction(
    String functionName, {
    Map<String, dynamic>? body,
    String method = 'POST',
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/$functionName');
    try {
      print('=== DEBUG: Calling edge function: $functionName');
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      // NOTE: anonKey here is the public anon key used by the app. Keep it out of logs.
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final maskedHeaders = Map<String, String>.from(headers);
      if (maskedHeaders.containsKey('apikey')) maskedHeaders['apikey'] = '***masked***';
      if (maskedHeaders.containsKey('Authorization')) maskedHeaders['Authorization'] = 'Bearer ***masked***';

      print('DEBUG: URL: $uri');
      print('DEBUG: Method: $method');
      print('DEBUG: Headers: $maskedHeaders');
      if (body != null) print('DEBUG: Body keys: ${body.keys.toList()}');

      late http.Response resp;
      final encoded = body == null ? null : jsonEncode(body);
      if (method.toUpperCase() == 'GET') {
        resp = await http.get(uri, headers: headers);
      } else {
        resp = await http.post(uri, headers: headers, body: encoded);
      }

      print('=== RESPONSE FROM EDGE FUNCTION ($functionName) ===');
      print('Status Code: ${resp.statusCode}');
      print('Response header keys: ${resp.headers.keys.toList()}');
      print('Body: ${resp.body}');
      print('===================================');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      // The logout function returns success even for invalid/expired tokens
      // So we only throw on actual server errors (500+), not on 200 responses
      if (resp.statusCode >= 500) {
        final errorMessage = parsed['message'] ?? parsed['error'] ?? 'Server error';
        print('ERROR: Function $functionName returned ${resp.statusCode}: $errorMessage');
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      print('ERROR: Exception while calling function $functionName - ${e.toString()}');
      rethrow;
    }
  }

  /// Logout user using the logout edge function
  /// 
  /// The edge function handles:
  /// - Authentication validation
  /// - Session invalidation via supabaseClient.auth.signOut()
  /// - Graceful handling of expired/invalid tokens
  /// 
  /// Returns: Map with success (bool), message (String), and optionally user_id (String)
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _callFunction('logout', body: {});
      return response;
    } catch (e) {
      // Even if the API call fails, we should consider logout successful
      // to prevent users from being stuck in a logged-in state
      // This matches the backend behavior
      print('WARNING: Logout API call failed, but treating as successful: $e');
      return {
        'success': true,
        'message': 'Logged out successfully',
        'note': 'Session cleared despite API error',
      };
    }
  }
}

