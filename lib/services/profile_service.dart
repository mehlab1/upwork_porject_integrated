import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for user profile operations
/// Handles fetching and managing user profile data
class ProfileService {
  ProfileService();

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

  /// Fetch current user's profile using the get-profile edge function
  /// 
  /// Returns: Map with success (bool) and profile (Map<String, dynamic>)
  /// Profile includes: id, username, profile_picture_url, avatar_url, bio, 
  /// post_count, total_upvotes_received, created_at, joined_date, etc.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _callFunction('get-profile', body: {});
      return response;
    } catch (e) {
      print('ERROR: Failed to fetch profile: $e');
      rethrow;
    }
  }

  /// Fetch a user's profile by user_id using the get-profile edge function
  /// 
  /// Returns: Map with success (bool) and profile (Map<String, dynamic>)
  /// Profile includes: id, username, profile_picture_url, avatar_url, bio, etc.
  Future<Map<String, dynamic>> getProfileByUserId(String userId) async {
    try {
      final response = await _callFunction('get-profile', body: {'user_id': userId});
      return response;
    } catch (e) {
      print('ERROR: Failed to fetch profile for user $userId: $e');
      rethrow;
    }
  }

  /// Get profile data by user_id as a structured object
  /// Returns null if profile fetch fails
  Future<ProfileData?> getProfileDataByUserId(String userId) async {
    try {
      final response = await getProfileByUserId(userId);
      if (response['success'] == true && response['profile'] != null) {
        return ProfileData.fromMap(response['profile'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('ERROR: Failed to get profile data for user $userId: $e');
      return null;
    }
  }

  /// Get profile data as a structured object
  /// Returns null if profile fetch fails
  Future<ProfileData?> getProfileData() async {
    try {
      final response = await getProfile();
      if (response['success'] == true && response['profile'] != null) {
        return ProfileData.fromMap(response['profile'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('ERROR: Failed to get profile data: $e');
      return null;
    }
  }

  /// Update username using the update-username edge function
  /// 
  /// Parameters: username (String) - new username (3-50 chars, alphanumeric and underscore only)
  /// Returns: Map with success (bool), message (String), and username (String)
  /// Throws Exception on error (including 30-day cooldown)
  Future<Map<String, dynamic>> updateUsername(String username) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-username');
    try {
      print('=== DEBUG: Updating username ===');
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final body = jsonEncode({'username': username});
      final resp = await http.post(uri, headers: headers, body: body);

      print('=== RESPONSE FROM EDGE FUNCTION (update-username) ===');
      print('Status Code: ${resp.statusCode}');
      print('Body: ${resp.body}');
      print('===================================');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        print('ERROR: update-username returned ${resp.statusCode}: $errorMessage');
        // Store status code in the parsed response for error handling
        parsed['_statusCode'] = resp.statusCode;
        parsed['_error'] = errorMessage;
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      print('ERROR: Failed to update username: $e');
      rethrow;
    }
  }

  /// Update birthday using the update-birthday edge function
  /// 
  /// Parameters: birthday (String) - birthday in YYYY-MM-DD format
  /// Returns: Map with success (bool), message (String), and birthday (String)
  /// Throws Exception on error
  Future<Map<String, dynamic>> updateBirthday(String birthday) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-birthday');
    try {
      print('=== DEBUG: Updating birthday ===');
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final body = jsonEncode({'birthday': birthday});
      final resp = await http.post(uri, headers: headers, body: body);

      print('=== RESPONSE FROM EDGE FUNCTION (update-birthday) ===');
      print('Status Code: ${resp.statusCode}');
      print('Body: ${resp.body}');
      print('===================================');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        print('ERROR: update-birthday returned ${resp.statusCode}: $errorMessage');
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      print('ERROR: Failed to update birthday: $e');
      rethrow;
    }
  }
}

/// Structured profile data model
class ProfileData {
  final String id;
  final String username;
  final String? profilePictureUrl;
  final String? avatarUrl;
  final String? bio;
  final int postCount;
  final int totalUpvotesReceived;
  final DateTime? createdAt;
  final DateTime? joinedDate;
  final String? displayName;
  final String? gender;
  final String? birthday;

  ProfileData({
    required this.id,
    required this.username,
    this.profilePictureUrl,
    this.avatarUrl,
    this.bio,
    this.postCount = 0,
    this.totalUpvotesReceived = 0,
    this.createdAt,
    this.joinedDate,
    this.displayName,
    this.gender,
    this.birthday,
  });

  /// Get the profile picture URL (prefers profile_picture_url, falls back to avatar_url)
  String? get pictureUrl => profilePictureUrl ?? avatarUrl;

  /// Check if user has a profile picture
  bool get hasPicture => pictureUrl != null && pictureUrl!.isNotEmpty;

  /// Get formatted username with @ prefix
  String get formattedUsername => username.startsWith('@') ? username : '@$username';

  /// Get display name or username
  String get displayNameOrUsername => displayName ?? formattedUsername;

  /// Get initials from username or display name
  String get initials {
    final name = displayName ?? username;
    // Remove @ if present
    final cleanName = name.replaceAll('@', '').trim();
    if (cleanName.isEmpty) return 'U';
    
    // Split by space or underscore
    final parts = cleanName.split(RegExp(r'[\s_]+'));
    if (parts.length >= 2) {
      // First letter of first and last word
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (cleanName.length >= 2) {
      // First two letters
      return cleanName.substring(0, 2).toUpperCase();
    } else {
      // Single letter
      return cleanName[0].toUpperCase();
    }
  }

  /// Format joined date as "Ever since [Month] [Year]"
  String get formattedJoinedDate {
    final date = joinedDate ?? createdAt;
    if (date == null) return 'Recently';
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = monthNames[date.month - 1];
    final year = date.year;
    
    return 'Ever since $month $year';
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ProfileData(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      profilePictureUrl: map['profile_picture_url']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      bio: map['bio']?.toString(),
      postCount: parseInt(map['post_count'] ?? map['total_posts']),
      totalUpvotesReceived: parseInt(map['total_upvotes_received']),
      createdAt: parseDate(map['created_at']),
      joinedDate: parseDate(map['joined_date'] ?? map['created_at']),
      displayName: map['display_name']?.toString(),
      gender: map['gender']?.toString(),
      birthday: map['birthday']?.toString(),
    );
  }
}

