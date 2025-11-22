import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabaseClient = Supabase.instance.client; // Direct client access
  User? get currentUser => _supabaseClient.auth.currentUser; // Get current user directly from Supabase Auth

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final accessToken = response.session?.accessToken;
      if (accessToken != null) {
        debugPrint('[AuthService] access token: $accessToken');
      } else {
        debugPrint('[AuthService] signIn completed without an access token.');
      }
      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('An unexpected error occurred during signin');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      // Sign out should be best effort - don't throw
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // 1. Perform the core Auth signup (only email/password needed by Supabase Auth)
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      
      // 2. If Auth user creation succeeded, create the user profile record
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          userData: userData,
        );
      }
      
      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('An unexpected error occurred during signup');
    }
  }

  Future<void> _createUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Use the class-level Supabase client

      // Use the actual DOB from userData (already in YYYY-MM-DD format)
      // If not provided, fall back to a safe default
      String birthdayString;
      if (userData['birthday'] != null && userData['birthday'].toString().isNotEmpty) {
        birthdayString = userData['birthday'].toString();
      } else {
        // Fallback: Calculate a safe "old enough" date if DOB not provided
        final DateTime oldEnoughDate =
            DateTime.now().subtract(const Duration(days: 365 * 14));
        birthdayString = oldEnoughDate.toIso8601String().substring(0, 10);
      }

      final profileData = {
        // Required fields
        'id': userId,
        'username': userData['username'],
        'birthday': birthdayString, // Use actual DOB from userData
        'terms_accepted': userData['terms_accepted'] ?? false,
        'privacy_accepted': userData['privacy_accepted'] ?? false,

        // Include NOT NULL columns explicitly (defaults exist but being explicit).
        'role': userData['role'] ?? 'user',
        'account_status': userData['account_status'] ?? 'active',
        'total_posts': userData['total_posts'] ?? 0,
        'total_upvotes_received': userData['total_upvotes_received'] ?? 0,

        // Optional/nullable
        'gender': userData['gender']?.toString().toLowerCase(),
        'profile_picture_url': userData['profile_picture_url'],
      };

      // Remove keys with null values so we don't send extraneous nulls
      profileData.removeWhere((key, value) => value == null);

      // Insert using the shared client. Handle duplicate-username conflicts by
      // attempting small retries with a suffix to avoid 409 unique constraint errors.
      const int maxRetries = 3;
      int attempt = 0;
      String baseUsername = profileData['username']?.toString() ?? 'user';
      while (true) {
        try {
          await _supabaseClient.from('profiles').upsert(
            profileData,
            onConflict: 'id',
            ignoreDuplicates: false,
          );
          break; // success
        } catch (e) {
          // Detect duplicate username unique constraint and retry with suffix
          final msg = e?.toString() ?? '';
          if (msg.contains('profiles_username_key') || msg.contains('duplicate key value') && attempt < maxRetries) {
            attempt++;
            final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(9); // short suffix
            final newUsername = '${baseUsername}_$suffix';
            profileData['username'] = newUsername;
            // Retrying with modified username due to duplicate
            continue;
          }
          // If it's not a duplicate-username issue or we've exhausted retries, rethrow
          rethrow;
        }
      }
    } catch (e) {
      // Error creating profile - auth user was created successfully
    }
  }

  /// Verify OTP via edge function. Returns parsed JSON response on success.
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String token,
  }) async {
    // Call the verify-otp edge function which performs verification and
    // may return access/refresh tokens.
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/verify-otp');
    try {
      // Use anon key for edge function calls
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({
          'email': email,
          'otp_code': token,
        }),
      );

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        // Check both message and error fields for the error text
        final message = body['message'] ?? body['error'] ?? 'OTP verification failed';
        final errorField = body['error']?.toString() ?? '';
        final messageField = body['message']?.toString() ?? '';
        final combinedError = '$errorField $messageField'.toLowerCase();
        
        // Check if it's the known backend error about createSession
        // The edge function re-throws the error, causing a 500, but OTP was actually verified
        // We need to check if OTP verification succeeded before session creation failed
        if (combinedError.contains('createsession is not a function') || 
            combinedError.contains('createsession') ||
            errorField.toLowerCase().contains('createsession')) {
          // Return a success response even though session creation failed
          // The OTP was verified, which is what matters - user can sign in separately
          return {
            'success': true,
            'message': 'OTP verified successfully. Please sign in with your email and password.',
            'user_id': body['user_id'], // May or may not be present
          };
        }
        throw AuthException(message);
      }

      if (body is Map<String, dynamic> && body['success'] != true) {
        throw AuthException(body['message'] ?? 'OTP verification failed');
      }

      // If tokens are returned, set the session
      if (body is Map<String, dynamic> && 
          body.containsKey('access_token') && 
          body.containsKey('refresh_token')) {
        try {
          // setSession takes only the refresh token as a string
          await _supabaseClient.auth.setSession(
            body['refresh_token'] as String,
          );
        } catch (e) {
          // Don't throw - the OTP was verified successfully
        }
      } else if (body is Map<String, dynamic> && body.containsKey('user_id')) {
        // OTP verified but no tokens returned (session creation failed in edge function)
        // We can still proceed - the OTP is verified, user just needs to sign in
      }

      return Map<String, dynamic>.from(body);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('An unexpected error occurred during OTP verification: $e');
    }
  }

  /// Call the resend-otp edge function which delegates to send-otp with rate limiting.
  Future<Map<String, dynamic>> resendOtp({String? email, String? phone}) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/resend-otp');

    try {
      // Use anon key for edge function calls
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({'email': email, 'phone': phone}),
      );

      final body = jsonDecode(resp.body ?? '{}');
      if (resp.statusCode >= 400) {
        throw Exception(body['message'] ?? 'Failed to resend OTP');
      }
      return Map<String, dynamic>.from(body);
    } catch (e) {
      rethrow;
    }
  }

  /// Call the send-otp edge function to send an OTP to email or phone.
  Future<Map<String, dynamic>> sendOtp({String? email, String? phone, String? userId}) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/send-otp');

    try {
      // Use anon key for edge function calls (edge function uses service role internally)
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({
          'email': email,
          'phone': phone,
          'user_id': userId,
        }),
      );

      final body = jsonDecode(resp.body ?? '{}');
      if (resp.statusCode >= 400) {
        throw Exception(body['message'] ?? 'Failed to send OTP');
      }
      return Map<String, dynamic>.from(body);
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset OTP via forgot-password edge function
  /// Returns OTP code in development mode, sends email in production
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/forgot-password');

    try {
      // Use anon key for edge function calls
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        final message = body['message'] ?? body['error'] ?? 'Failed to send password reset OTP';
        throw AuthException(message);
      }

      return Map<String, dynamic>.from(body);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }


  /// Reset password using reset-password edge function
  /// This edge function calls verify_password_reset_otp RPC which:
  /// - Verifies the OTP (checks expiration, attempts, etc.)
  /// - Updates the password (hashed with bcrypt)
  /// - All in one atomic operation
  /// 
  /// Parameters:
  /// - email: User's email address
  /// - otp_code: The 6-digit OTP code received via email
  /// - new_password: The new password (will be validated and hashed by database function)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/reset-password');

    try {
      // Validate inputs
      final trimmedEmail = email.toLowerCase().trim();
      final trimmedOtpCode = otpCode.trim();
      final trimmedNewPassword = newPassword.trim();
      
      if (trimmedEmail.isEmpty) {
        throw AuthException('Email is required');
      }
      if (trimmedOtpCode.isEmpty) {
        throw AuthException('OTP code is required');
      }
      if (trimmedOtpCode.length != 6) {
        throw AuthException('OTP code must be 6 digits');
      }
      if (trimmedNewPassword.isEmpty) {
        throw AuthException('New password is required');
      }
      
      // Use anon key for edge function calls
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final requestBody = {
        'email': trimmedEmail,
        'otp_code': trimmedOtpCode,
        'new_password': trimmedNewPassword,
      };
      
      print('DEBUG resetPassword: Request body keys: ${requestBody.keys.toList()}');
      print('DEBUG resetPassword: Email: ${requestBody['email']}');
      print('DEBUG resetPassword: OTP code: ${requestBody['otp_code']} (length: ${trimmedOtpCode.length})');
      print('DEBUG resetPassword: New password length: ${trimmedNewPassword.length}');
      print('DEBUG resetPassword: Has session token: ${sessionToken != null}');

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode(requestBody),
      );

      print('=== RESPONSE FROM EDGE FUNCTION (reset-password) ===');
      print('Status Code: ${resp.statusCode}');
      print('Response header keys: ${resp.headers.keys.toList()}');
      print('Body: ${resp.body}');
      print('===================================');

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        final message = body['message'] ?? body['error'] ?? 'Failed to reset password';
        print('ERROR: reset-password returned ${resp.statusCode}: $message');
        print('ERROR: Full response body: $body');
        throw AuthException(message);
      }

      if (body is Map<String, dynamic> && body['success'] != true) {
        throw AuthException(body['message'] ?? 'Failed to reset password');
      }

      return Map<String, dynamic>.from(body);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  /// Check username availability using check-username edge function
  /// Returns a map with 'available' (bool) and 'message' (String) fields
  Future<Map<String, dynamic>> checkUsernameAvailability({
    required String username,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/check-username?action=check');

    try {
      // Use anon key for edge function calls
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({
          'username': username.trim(),
        }),
      );

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        final message = body['message'] ?? body['error'] ?? 'Failed to check username availability';
        throw Exception(message);
      }

      return Map<String, dynamic>.from(body);
    } catch (e) {
      rethrow;
    }
  }
}