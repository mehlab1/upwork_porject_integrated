import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for account deactivation API calls
/// Handles deactivation through the Supabase Edge Function
class AuthDeactivateService {
  AuthDeactivateService();

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

      if (resp.statusCode >= 400) {
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

  /// Deactivate user account using the deactivate-account edge function
  /// 
  /// Parameters:
  /// - reasonType: Required. Must be one of: privacy_concerns, not_useful, 
  ///   too_many_notifications, found_alternative, too_much_time, 
  ///   harassment_issues, technical_problems, other
  /// - reasonText: Optional. If provided, must be 10-500 characters
  /// 
  /// The edge function will:
  /// - Validate authentication
  /// - Validate input parameters
  /// - Call the deactivate_user_account database function
  /// - Sign out the user
  /// 
  /// Returns: Map with success (bool), message (String), and optionally note (String)
  Future<Map<String, dynamic>> deactivateAccount({
    required String reasonType,
    String? reasonText,
  }) async {
    // Validate reason type
    const validReasons = [
      'privacy_concerns',
      'not_useful',
      'too_many_notifications',
      'found_alternative',
      'too_much_time',
      'harassment_issues',
      'technical_problems',
      'other',
    ];

    if (!validReasons.contains(reasonType)) {
      throw Exception('Invalid deactivation reason type');
    }

    // Validate reason text if provided
    if (reasonText != null) {
      final trimmedText = reasonText.trim();
      if (trimmedText.isEmpty) {
        reasonText = null; // Treat empty string as null
      } else if (trimmedText.length < 10) {
        throw Exception('Reason text must be at least 10 characters');
      } else if (trimmedText.length > 500) {
        throw Exception('Reason text must be 500 characters or less');
      }
    }

    final body = <String, dynamic>{
      'reason_type': reasonType,
      'confirm': true, // Required by API
    };

    if (reasonText != null && reasonText.trim().isNotEmpty) {
      body['reason_text'] = reasonText.trim();
    }

    try {
      final response = await _callFunction('deactivate-account', body: body);
      return response;
    } catch (e) {
      // Re-throw with user-friendly message
      final errorString = e.toString().replaceFirst('Exception: ', '');
      throw Exception(errorString);
    }
  }
}

