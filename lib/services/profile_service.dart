import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cached profile data with timestamp for expiration checking
class _CachedProfile {
  final ProfileData data;
  final DateTime cachedAt;
  
  _CachedProfile(this.data) : cachedAt = DateTime.now();
  
  bool isValid(Duration maxAge) {
    return DateTime.now().difference(cachedAt) < maxAge;
  }
}

/// Service for user profile operations
/// Handles fetching and managing user profile data with caching support
class ProfileService {
  // Singleton pattern for shared cache across app
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  // Cache configuration
  static const Duration _profileCacheDuration = Duration(minutes: 5);
  
  // Current user profile cache (singleton)
  static ProfileData? _currentUserProfileCache;
  static DateTime? _currentUserProfileCachedAt;
  
  // Other users' profile cache (user_id -> cached profile)
  static final Map<String, _CachedProfile> _userProfileCache = {};

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

      print('=== PROFILE SERVICE - REQUEST TO EDGE FUNCTION ($functionName) ===');
      print('URL: $uri');
      print('Method: $method');
      print('Has session token: ${sessionToken != null}');
      if (body != null) {
        print('Request body: ${jsonEncode(body)}');
      }

      late http.Response resp;
      final encoded = body == null ? null : jsonEncode(body);
      if (method.toUpperCase() == 'GET') {
        resp = await http.get(uri, headers: headers);
      } else {
        resp = await http.post(uri, headers: headers, body: encoded);
      }

      print('=== PROFILE SERVICE - RESPONSE FROM EDGE FUNCTION ($functionName) ===');
      print('Status Code: ${resp.statusCode}');
      print('Response headers: ${resp.headers}');
      print('Response body: ${resp.body}');
      print('===============================================================');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['message'] ?? parsed['error'] ?? 'Server error';
        print('ERROR _callFunction ($functionName): Status ${resp.statusCode} - $errorMessage');
        print('ERROR _callFunction ($functionName): Full response body: $parsed');
        throw Exception(errorMessage);
      }

      print('SUCCESS _callFunction ($functionName): Response parsed - $parsed');
      return parsed;
    } catch (e) {
      print('ERROR _callFunction ($functionName): Exception - $e');
      rethrow;
    }
  }

  /// Fetch current user's profile using the get-profile edge function
  /// 
  /// Returns: Map with success (bool) and profile (Map<String, dynamic>)
  /// Profile includes: id, username, profile_picture_url, avatar_url, bio, 
  /// post_count, total_upvotes_received, created_at, joined_date, etc.
  Future<Map<String, dynamic>> getProfile() async {
    print('=== DEBUG getProfile: Fetching current user profile ===');
    try {
      final response = await _callFunction('get-profile', body: {});
      print('DEBUG getProfile: Response success: ${response['success']}');
      if (response['profile'] != null) {
        final profile = response['profile'] as Map<String, dynamic>;
        print('DEBUG getProfile: Username: ${profile['username']}');
        print('DEBUG getProfile: post_count: ${profile['post_count']}');
        print('DEBUG getProfile: total_upvotes_received: ${profile['total_upvotes_received']}');
        print('DEBUG getProfile: total_upvotes: ${profile['total_upvotes']}');
        print('DEBUG getProfile: Profile keys: ${profile.keys.toList()}');
      } else {
        print('DEBUG getProfile: No profile in response');
      }
      return response;
    } catch (e) {
      print('ERROR getProfile: Exception - $e');
      rethrow;
    }
  }

  /// Fetch a user's profile by user_id using the get-profile edge function
  /// 
  /// Returns: Map with success (bool) and profile (Map<String, dynamic>)
  /// Profile includes: id, username, profile_picture_url, avatar_url, bio, etc.
  Future<Map<String, dynamic>> getProfileByUserId(String userId) async {
    return await _callFunction('get-profile', body: {'user_id': userId});
  }

  /// Moderator/Admin view of a user's profile via mod-view-profile edge function
  /// 
  /// Returns rich data: profile, post_stats, moderation_summary, role_history, recent_actions
  /// Requires moderator or admin role.
  Future<Map<String, dynamic>> modViewProfile(String targetUserId) async {
    return await _callFunction('mod-view-profile', body: {'target_user_id': targetUserId});
  }

  /// Get profile data by user_id as a structured object with caching
  /// Returns cached data if valid (< 5 minutes old), otherwise fetches fresh
  /// Set forceRefresh to true to bypass cache
  Future<ProfileData?> getProfileDataByUserId(String userId, {bool forceRefresh = false}) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh && _userProfileCache.containsKey(userId)) {
      final cached = _userProfileCache[userId]!;
      if (cached.isValid(_profileCacheDuration)) {
        debugPrint('[ProfileService] Returning cached profile for user: $userId');
        return cached.data;
      }
    }
    
    try {
      final response = await getProfileByUserId(userId);
      if (response['success'] == true && response['profile'] != null) {
        final profileData = ProfileData.fromMap(response['profile'] as Map<String, dynamic>);
        // Cache the profile
        _userProfileCache[userId] = _CachedProfile(profileData);
        return profileData;
      }
      return null;
    } catch (e) {
      // On error, return cached data if available (even if stale)
      if (_userProfileCache.containsKey(userId)) {
        debugPrint('[ProfileService] Returning stale cached profile for user: $userId (fetch failed)');
        return _userProfileCache[userId]!.data;
      }
      return null;
    }
  }

  /// Get current user's profile data as a structured object with caching
  /// Returns cached data if valid (< 5 minutes old), otherwise fetches fresh
  /// Set forceRefresh to true to bypass cache
  Future<ProfileData?> getProfileData({bool forceRefresh = false}) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh && 
        _currentUserProfileCache != null && 
        _currentUserProfileCachedAt != null) {
      final age = DateTime.now().difference(_currentUserProfileCachedAt!);
      if (age < _profileCacheDuration) {
        debugPrint('[ProfileService] Returning cached current user profile (age: ${age.inSeconds}s)');
        return _currentUserProfileCache;
      }
    }
    
    debugPrint('[ProfileService] Fetching fresh current user profile');
    try {
      final response = await getProfile();
      if (response['success'] == true && response['profile'] != null) {
        final profileMap = response['profile'] as Map<String, dynamic>;
        final profileData = ProfileData.fromMap(profileMap);
        
        // Update cache
        _currentUserProfileCache = profileData;
        _currentUserProfileCachedAt = DateTime.now();
        
        return profileData;
      }
      debugPrint('[ProfileService] getProfileData: Returning null - success false or no profile');
      return null;
    } catch (e) {
      debugPrint('[ProfileService] getProfileData error: $e');
      // On error, return cached data if available (even if stale)
      if (_currentUserProfileCache != null) {
        debugPrint('[ProfileService] Returning stale cached profile (fetch failed)');
        return _currentUserProfileCache;
      }
      return null;
    }
  }

  /// Update username using the update-username edge function
  /// 
  /// Parameters: username (String) - new username (3-50 chars, alphanumeric and underscore only)
  /// Returns: Map with success (bool), message (String), and username (String)
  /// Throws Exception on error (including 30-day cooldown)
  Future<Map<String, dynamic>> updateUsername(String username) async {
    print('=== DEBUG updateUsername: Updating username to: $username ===');
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-username');
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      print('DEBUG updateUsername: Has session token: ${sessionToken != null}');
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final body = jsonEncode({'username': username});
      final resp = await http.post(uri, headers: headers, body: body);

      print('DEBUG updateUsername: Status code: ${resp.statusCode}');
      print('DEBUG updateUsername: Response body: ${resp.body}');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        print('ERROR updateUsername: Status ${resp.statusCode} - $errorMessage');
        // Store status code for error handling
        parsed['_statusCode'] = resp.statusCode;
        parsed['_error'] = errorMessage;
        throw Exception(errorMessage);
      }

      print('DEBUG updateUsername: Success - ${parsed['success']}');
      print('DEBUG updateUsername: Message - ${parsed['message']}');
      
      // Invalidate cache since profile was updated
      if (parsed['success'] == true) {
        invalidateCurrentUserCache();
      }
      
      return parsed;
    } catch (e) {
      print('ERROR updateUsername: Exception - $e');
      rethrow;
    }
  }

  /// Update birthday using the update-birthday edge function
  /// 
  /// Parameters: birthday (String) - birthday in YYYY-MM-DD format
  /// Returns: Map with success (bool), message (String), and birthday (String)
  /// Throws Exception on error
  Future<Map<String, dynamic>> updateBirthday(String birthday) async {
    print('=== DEBUG updateBirthday: Updating birthday to: $birthday ===');
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-birthday');
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      print('DEBUG updateBirthday: Has session token: ${sessionToken != null}');
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final body = jsonEncode({'birthday': birthday});
      print('DEBUG updateBirthday: Request body: $body');
      
      final resp = await http.post(uri, headers: headers, body: body);

      print('DEBUG updateBirthday: Status code: ${resp.statusCode}');
      print('DEBUG updateBirthday: Response body: ${resp.body}');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        print('ERROR updateBirthday: Status ${resp.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }

      print('DEBUG updateBirthday: Success - ${parsed['success']}');
      print('DEBUG updateBirthday: Message - ${parsed['message']}');
      print('DEBUG updateBirthday: Birthday in response - ${parsed['birthday']}');
      print('DEBUG updateBirthday: Profile in response - ${parsed['profile']}');
      
      // Invalidate cache since profile was updated
      if (parsed['success'] == true) {
        invalidateCurrentUserCache();
      }
      
      return parsed;
    } catch (e) {
      print('ERROR updateBirthday: Exception - $e');
      rethrow;
    }
  }

  /// Get blocked users using the get-blocked-users edge function
  /// 
  /// Parameters: limit (int, default 20), offset (int, default 0)
  /// Returns: Map with success (bool), blocked_users (List), limit, offset
  Future<Map<String, dynamic>> getBlockedUsers({int limit = 20, int offset = 0}) async {
    print('=== DEBUG getBlockedUsers: Fetching blocked users (limit: $limit, offset: $offset) ===');
    final uri = Uri.parse(
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-blocked-users?limit=$limit&offset=$offset'
    );
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      print('DEBUG getBlockedUsers: Has session token: ${sessionToken != null}');
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final resp = await http.get(uri, headers: headers);
      print('DEBUG getBlockedUsers: Status code: ${resp.statusCode}');
      print('DEBUG getBlockedUsers: Response body: ${resp.body}');
      
      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['message'] ?? parsed['error'] ?? 'Server error';
        print('ERROR getBlockedUsers: Status ${resp.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }

      print('DEBUG getBlockedUsers: Success - ${parsed['success']}');
      final blockedUsers = parsed['blocked_users'] as List<dynamic>? ?? [];
      print('DEBUG getBlockedUsers: Found ${blockedUsers.length} blocked users');
      return parsed;
    } catch (e) {
      print('ERROR getBlockedUsers: Exception - $e');
      rethrow;
    }
  }

  /// Unblock a user using the unblock-user edge function
  /// 
  /// Parameters: blockedUserId (String) - ID of user to unblock
  /// Returns: Map with success (bool), message (String), unblocked_user (String)
  Future<Map<String, dynamic>> unblockUser(String blockedUserId) async {
    print('=== DEBUG unblockUser: Unblocking user: $blockedUserId ===');
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/unblock-user');
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      print('DEBUG unblockUser: Has session token: ${sessionToken != null}');
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final body = jsonEncode({'blocked_user_id': blockedUserId});
      print('DEBUG unblockUser: Request body: $body');
      
      final resp = await http.post(uri, headers: headers, body: body);

      print('DEBUG unblockUser: Status code: ${resp.statusCode}');
      print('DEBUG unblockUser: Response body: ${resp.body}');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['message'] ?? parsed['error'] ?? 'Server error';
        print('ERROR unblockUser: Status ${resp.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }

      print('DEBUG unblockUser: Success - ${parsed['success']}');
      print('DEBUG unblockUser: Message - ${parsed['message']}');
      print('DEBUG unblockUser: Unblocked user - ${parsed['unblocked_user']}');
      return parsed;
    } catch (e) {
      print('ERROR unblockUser: Exception - $e');
      rethrow;
    }
  }

  /// Submit user feedback using the submit-feedback edge function
  /// 
  /// Parameters:
  /// - feedbackType: Must be 'feedback', 'feature_request', or 'bug_report'
  /// - message: Feedback message (10-2000 characters)
  /// 
  /// Returns: Map with success (bool), message (String), feedback_id (String)
  Future<Map<String, dynamic>> submitFeedback({
    required String feedbackType,
    required String message,
  }) async {
    // Validate feedback type
    const validTypes = ['feedback', 'feature_request', 'bug_report'];
    if (!validTypes.contains(feedbackType)) {
      throw Exception('Invalid feedback type');
    }

    // Validate message length
    final trimmedMessage = message.trim();
    if (trimmedMessage.length < 10) {
      throw Exception('Feedback message must be at least 10 characters');
    }
    if (trimmedMessage.length > 2000) {
      throw Exception('Feedback message must be 2000 characters or less');
    }

    try {
      return await _callFunction('submit-feedback', body: {
        'feedback_type': feedbackType,
        'message': trimmedMessage,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update notification preferences using the update-notification-preferences edge function
  /// 
  /// Parameters: Map of preference keys to boolean values
  /// Supported keys: push_notifications_enabled, post_reply_enabled, comment_reply_enabled,
  /// post_vote_enabled, comment_vote_enabled, mention_enabled, post_achievement_enabled,
  /// account_status_enabled
  /// 
  /// Returns: Map with success (bool), preferences (Map), message (String)
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, bool> preferences) async {
    print('=== PROFILE SERVICE - UPDATE NOTIFICATION PREFERENCES ===');
    print('Request payload: $preferences');
    print('Has session token: ${_supabaseClient.auth.currentSession?.accessToken != null}');
    print('User ID: ${_supabaseClient.auth.currentUser?.id}');
    
    try {
      final response = await _callFunction('update-notification-preferences', body: preferences);
      
      print('=== PROFILE SERVICE - RESPONSE ===');
      print('Status: Success');
      print('Response success field: ${response['success']}');
      print('Response message: ${response['message']}');
      print('Response preferences: ${response['preferences']}');
      if (response['preferences'] != null) {
        final prefs = response['preferences'] as Map<String, dynamic>;
        print('Response push_notifications_enabled: ${prefs['push_notifications_enabled']}');
      }
      print('Full response: $response');
      print('======================================================');
      
      return response;
    } catch (e, stackTrace) {
      print('=== PROFILE SERVICE - ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      print('================================');
      rethrow;
    }
  }

  /// Opt in to Wahala of the Day (WOD) eligibility using `wod-opt-in` edge function.
  /// Returns: Map with success (bool), message (String)
  Future<Map<String, dynamic>> wodOptIn() async {
    return await _callFunction('wod-opt-in', body: {});
  }

  /// Opt out of Wahala of the Day (WOD) eligibility using `wod-opt-out` edge function.
  /// Returns: Map with success (bool), message (String)
  Future<Map<String, dynamic>> wodOptOut() async {
    return await _callFunction('wod-opt-out', body: {});
  }

  // ============================================================================
  // CACHE MANAGEMENT METHODS
  // ============================================================================

  /// Clear all profile caches (call on logout or when data needs full refresh)
  void clearAllProfileCaches() {
    _currentUserProfileCache = null;
    _currentUserProfileCachedAt = null;
    _userProfileCache.clear();
    debugPrint('[ProfileService] All profile caches cleared');
  }

  /// Invalidate current user's profile cache (call after profile update)
  void invalidateCurrentUserCache() {
    _currentUserProfileCache = null;
    _currentUserProfileCachedAt = null;
    debugPrint('[ProfileService] Current user profile cache invalidated');
  }

  /// Invalidate a specific user's profile cache
  void invalidateUserCache(String userId) {
    _userProfileCache.remove(userId);
    debugPrint('[ProfileService] Profile cache invalidated for user: $userId');
  }

  /// Check if current user profile is cached and valid
  bool get hasValidCurrentUserCache {
    if (_currentUserProfileCache == null || _currentUserProfileCachedAt == null) {
      return false;
    }
    return DateTime.now().difference(_currentUserProfileCachedAt!) < _profileCacheDuration;
  }

  /// Get cache age for current user profile (for debugging)
  Duration? get currentUserCacheAge {
    if (_currentUserProfileCachedAt == null) return null;
    return DateTime.now().difference(_currentUserProfileCachedAt!);
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
  final DateTime? usernameUpdatedAt;
  final String? firstName;
  final String? lastName;

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
    this.usernameUpdatedAt,
    this.firstName,
    this.lastName,
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

  /// Format joined date as "User since [Month] [Year]"
  String get formattedJoinedDate {
    final date = joinedDate ?? createdAt;
    if (date == null) return 'Recently';
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = monthNames[date.month - 1];
    final year = date.year;
    
    return 'User since $month $year';
  }

  /// Get days since username was last changed
  /// Returns null if username has never been changed
  int? get daysSinceUsernameChange {
    if (usernameUpdatedAt == null) return null;
    return DateTime.now().difference(usernameUpdatedAt!).inDays;
  }

  /// Get formatted string for username last changed
  String get formattedUsernameLastChanged {
    final days = daysSinceUsernameChange;
    if (days == null) return 'Never changed';
    if (days == 0) return 'Changed today';
    if (days == 1) return 'Last changed 1 day ago';
    return 'Last changed $days days ago';
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    print('=== DEBUG ProfileData.fromMap: Parsing profile data ===');
    print('DEBUG ProfileData.fromMap: FULL MAP CONTENTS: $map');
    print('DEBUG ProfileData.fromMap: All keys in map: ${map.keys.toList()}');
    print('DEBUG ProfileData.fromMap: Raw post_count value: ${map['post_count']} (type: ${map['post_count']?.runtimeType})');
    print('DEBUG ProfileData.fromMap: Raw total_posts value: ${map['total_posts']} (type: ${map['total_posts']?.runtimeType})');
    print('DEBUG ProfileData.fromMap: Raw total_upvotes_received value: ${map['total_upvotes_received']} (type: ${map['total_upvotes_received']?.runtimeType})');
    print('DEBUG ProfileData.fromMap: Raw total_upvotes value: ${map['total_upvotes']} (type: ${map['total_upvotes']?.runtimeType})');
    print('DEBUG ProfileData.fromMap: Raw upvotes value: ${map['upvotes']} (type: ${map['upvotes']?.runtimeType})');
    print('DEBUG ProfileData.fromMap: Raw upvote_count value: ${map['upvote_count']} (type: ${map['upvote_count']?.runtimeType})');
    print('DEBUG ProfileData.fromMap: Raw net_upvotes value: ${map['net_upvotes']} (type: ${map['net_upvotes']?.runtimeType})');
    
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
      if (value is double) return value.toInt();
      return 0;
    }

    final postCount = parseInt(map['post_count'] ?? map['total_posts']);
    // Check multiple possible field names for upvotes
    final totalUpvotesReceived = parseInt(
      map['total_upvotes_received'] ?? 
      map['total_upvotes'] ?? 
      map['upvotes'] ?? 
      map['upvote_count'] ??
      map['net_upvotes']
    );
    
    print('DEBUG ProfileData.fromMap: Parsed postCount: $postCount');
    print('DEBUG ProfileData.fromMap: Parsed totalUpvotesReceived: $totalUpvotesReceived');

    return ProfileData(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      profilePictureUrl: map['profile_picture_url']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      bio: map['bio']?.toString(),
      postCount: postCount,
      totalUpvotesReceived: totalUpvotesReceived,
      createdAt: parseDate(map['created_at']),
      joinedDate: parseDate(map['joined_date'] ?? map['created_at']),
      displayName: map['display_name']?.toString(),
      gender: map['gender']?.toString(),
      birthday: map['birthday']?.toString(),
      usernameUpdatedAt: parseDate(map['username_updated_at']),
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
    );
  }
}

