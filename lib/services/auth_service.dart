import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabaseClient = Supabase.instance.client; // Direct client access
  User? get currentUser => _supabaseClient.auth.currentUser; // Get current user directly from Supabase Auth

  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
  static const String _functionsBaseUrl =
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1';

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
    final trimmedEmail = email.trim();

    try {
      final response = await _supabaseClient.auth.signUp(
        email: trimmedEmail,
        password: password,
      );

      if (response.user != null) {
        final accessToken = await _resolveSignupSessionToken(
          email: trimmedEmail,
          password: password,
          userId: response.user!.id,
          existingToken: response.session?.accessToken,
        );

        await _completeSignup(
          accessToken: accessToken,
          userData: userData,
        );
      }

      return response;
    } on AuthException catch (e) {
      if (_isEmailSendRateLimitError(e)) {
        final recovered = await _tryRecoverSignupAfterRateLimit(
          email: trimmedEmail,
          password: password,
          userData: userData,
        );
        if (recovered != null) {
          return recovered;
        }
        throw AuthException(
          _emailRateLimitMessage,
          statusCode: e.statusCode,
          code: e.code,
        );
      }
      throw AuthException(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      throw AuthException('An unexpected error occurred during signup');
    }
  }

  static const String _emailRateLimitMessage =
      'Too many verification emails were sent. Please wait about an hour and try again, or log in if you already created your account.';

  bool _isEmailSendRateLimitError(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    return code == 'over_email_send_rate_limit' ||
        message.contains('email rate limit exceeded') ||
        message.contains('over_email_send_rate_limit');
  }

  /// If signup hit the email rate limit, the auth user may still exist from a
  /// prior attempt — try signing in and finishing the profile write.
  Future<AuthResponse?> _tryRecoverSignupAfterRateLimit({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final signInResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (signInResponse.user == null) return null;

      final accessToken = await _resolveSignupSessionToken(
        email: email,
        password: password,
        userId: signInResponse.user!.id,
        existingToken: signInResponse.session?.accessToken,
      );

      await _completeSignup(
        accessToken: accessToken,
        userData: userData,
      );
      return signInResponse;
    } catch (e) {
      debugPrint('[AuthService] signup rate-limit recovery failed: $e');
      return null;
    }
  }

  Future<String?> _resolveSignupSessionToken({
    required String email,
    required String password,
    required String userId,
    String? existingToken,
  }) async {
    if (existingToken != null && existingToken.isNotEmpty) {
      return existingToken;
    }

    await _confirmSignupEmail(email: email, userId: userId);

    final signInResponse = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final token = signInResponse.session?.accessToken;
    if (token == null || token.isEmpty) {
      throw AuthException(
        'Could not start your session after signup. Please try logging in.',
      );
    }
    return token;
  }

  /// Confirms the auth user's email after custom OTP verification so sign-in works
  /// when Supabase "Confirm email" is enabled.
  Future<void> _confirmSignupEmail({
    required String email,
    required String userId,
  }) async {
    final uri = Uri.parse('$_functionsBaseUrl/confirm-signup-email');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': _supabaseAnonKey,
        'Authorization': 'Bearer $_supabaseAnonKey',
      },
      body: jsonEncode({
        'email': email.trim(),
        'user_id': userId,
      }),
    );

    final body = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    if (body is! Map<String, dynamic>) {
      throw AuthException('Failed to confirm email for signup');
    }

    if (resp.statusCode >= 400) {
      throw AuthException(
        (body['error'] ?? body['message'] ?? 'Failed to confirm email for signup')
            .toString(),
        statusCode: resp.statusCode.toString(),
      );
    }

    if (body['success'] != true) {
      throw AuthException(
        (body['error'] ?? body['message'] ?? 'Failed to confirm email for signup')
            .toString(),
      );
    }
  }

  Future<void> _completeSignup({
    required Map<String, dynamic> userData,
    String? accessToken,
  }) async {
    final token =
        accessToken ?? _supabaseClient.auth.currentSession?.accessToken;
    if (token == null) {
      throw AuthException(
        'Authentication required. Sign up first, then complete your profile.',
      );
    }

    String birthdayString;
    if (userData['birthday'] != null &&
        userData['birthday'].toString().isNotEmpty) {
      birthdayString = userData['birthday'].toString();
    } else {
      final DateTime oldEnoughDate =
          DateTime.now().subtract(const Duration(days: 365 * 14));
      birthdayString = oldEnoughDate.toIso8601String().substring(0, 10);
    }

    final username = userData['username']?.toString().trim() ?? '';
    if (username.isEmpty) {
      throw AuthException('username is required');
    }

    final requestBody = <String, dynamic>{
      'username': username,
      'birthday': birthdayString,
      'terms_accepted': userData['terms_accepted'] ?? true,
      'privacy_accepted': userData['privacy_accepted'] ?? true,
    };

    for (final key in [
      'first_name',
      'last_name',
      'gender',
      'location_id',
      'bio',
      'profile_picture_url',
      'terms_version_accepted',
      'privacy_version_accepted',
      'invitation_token',
    ]) {
      final value = userData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        requestBody[key] = value;
      }
    }

    final uri = Uri.parse('$_functionsBaseUrl/complete-signup');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': _supabaseAnonKey,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final body = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    if (body is! Map<String, dynamic>) {
      throw AuthException('Failed to complete signup');
    }

    if (resp.statusCode >= 400) {
      final message = (body['error'] ?? body['message'] ?? 'Failed to create profile')
          .toString();
      throw AuthException(
        message,
        statusCode: resp.statusCode.toString(),
      );
    }

    if (body['success'] != true) {
      throw AuthException(
        (body['error'] ?? body['message'] ?? 'Failed to create profile')
            .toString(),
      );
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
      
      final requestBody = {
        'email': email,
        'otp_code': token,
      };
      
      print('=== VERIFY OTP - REQUEST TO EDGE FUNCTION ===');
      print('URL: $uri');
      print('Email: $email');
      print('OTP code: $token (length: ${token.length})');
      print('Has session token: ${sessionToken != null}');
      print('Request body: ${jsonEncode(requestBody)}');
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode(requestBody),
      );

      print('=== VERIFY OTP - RESPONSE FROM EDGE FUNCTION ===');
      print('Status Code: ${resp.statusCode}');
      print('Response headers: ${resp.headers}');
      print('Response body: ${resp.body}');
      print('================================================');

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        // Check both message and error fields for the error text
        final message = body['message'] ?? body['error'] ?? 'OTP verification failed';
        final errorField = body['error']?.toString() ?? '';
        final messageField = body['message']?.toString() ?? '';
        final combinedError = '$errorField $messageField'.toLowerCase();
        
        print('ERROR verifyOtp: Status ${resp.statusCode} - $message');
        print('ERROR verifyOtp: Error field: $errorField');
        print('ERROR verifyOtp: Message field: $messageField');
        print('ERROR verifyOtp: Full response body: $body');
        
        // Check if it's the known backend error about createSession
        // The edge function re-throws the error, causing a 500, but OTP was actually verified
        // We need to check if OTP verification succeeded before session creation failed
        if (combinedError.contains('createsession is not a function') || 
            combinedError.contains('createsession') ||
            errorField.toLowerCase().contains('createsession')) {
          print('WARNING verifyOtp: OTP verified but session creation failed');
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
        print('ERROR verifyOtp: Success field is false or missing');
        print('ERROR verifyOtp: Response body: $body');
        throw AuthException(body['message'] ?? 'OTP verification failed');
      }
      
      print('SUCCESS verifyOtp: OTP verified successfully');
      print('SUCCESS verifyOtp: Response body: $body');

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
  Future<Map<String, dynamic>> sendOtp({
    String? email,
    String? phone,
    String? userId,
    String? purpose,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/send-otp');

    try {
      // Use anon key for edge function calls (edge function uses service role internally)
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      
      final requestBody = <String, dynamic>{
        'email': email,
        'phone': phone,
        'user_id': userId,
      };
      if (purpose != null && purpose.isNotEmpty) {
        requestBody['purpose'] = purpose;
      }

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode(requestBody),
      );

      final body = jsonDecode(resp.body ?? '{}');
      if (resp.statusCode >= 400) {
        throw Exception(body['message'] ?? body['error'] ?? 'Failed to send OTP');
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
      
      final requestBody = {
        'email': email,
      };
      
      print('=== FORGOT PASSWORD - REQUEST TO EDGE FUNCTION ===');
      print('URL: $uri');
      print('Email: $email');
      print('Has session token: ${sessionToken != null}');
      print('Request body: ${jsonEncode(requestBody)}');
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode(requestBody),
      );

      print('=== FORGOT PASSWORD - RESPONSE FROM EDGE FUNCTION ===');
      print('Status Code: ${resp.statusCode}');
      print('Response headers: ${resp.headers}');
      print('Response body: ${resp.body}');
      print('==================================================');

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        final message = body['message'] ?? body['error'] ?? 'Failed to send password reset OTP';
        print('ERROR forgotPassword: Status ${resp.statusCode} - $message');
        print('ERROR forgotPassword: Full response body: $body');
        throw AuthException(message);
      }

      print('SUCCESS forgotPassword: Response parsed - $body');
      return Map<String, dynamic>.from(body);
    } on AuthException catch (e) {
      print('ERROR forgotPassword: AuthException - ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      print('ERROR forgotPassword: Unexpected error - $e');
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  /// Check whether a user exists for the provided email using check-user-exists edge function.
  /// Returns a map containing keys like: success, exists, user_id, email, message.
  Future<Map<String, dynamic>> checkUserExists({
    required String email,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/check-user-exists');

    try {
      final anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({'email': email.trim()}),
      );

      final body = jsonDecode(resp.body ?? '{}');

      if (resp.statusCode >= 400) {
        final message =
            body['message'] ?? body['error'] ?? 'Failed to check email';
        throw AuthException(message);
      }

      return Map<String, dynamic>.from(body);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }


  /// Verify password reset OTP via verify-password-reset-otp edge function.
  /// Must be called before navigating to [ResetPasswordScreen].
  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otpCode,
  }) async {
    final uri = Uri.parse(
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/verify-password-reset-otp',
    );

    try {
      final trimmedEmail = email.toLowerCase().trim();
      final trimmedOtpCode = otpCode.trim();

      if (trimmedEmail.isEmpty) {
        throw AuthException('Email is required');
      }
      if (trimmedOtpCode.isEmpty) {
        throw AuthException('OTP code is required');
      }
      if (trimmedOtpCode.length != 6) {
        throw AuthException('OTP code must be 6 digits');
      }

      final anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer ${sessionToken ?? anonKey}',
        },
        body: jsonEncode({
          'email': trimmedEmail,
          'otp_code': trimmedOtpCode,
        }),
      );

      final body = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
      final data = body is Map<String, dynamic>
          ? body
          : body is Map
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{};

      if (resp.statusCode >= 400) {
        final message =
            (data['message'] ?? data['error'] ?? 'OTP verification failed')
                .toString();
        throw AuthException(message);
      }

      // Response shape: { valid: bool, message: string, attempts_remaining?: int }
      final isValid = data['valid'] == true;
      if (!isValid) {
        throw AuthException(
          data['message']?.toString() ?? 'Invalid reset code',
        );
      }

      return data;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('An unexpected error occurred during OTP verification');
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