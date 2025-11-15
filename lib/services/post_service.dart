import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for post-related API calls
class PostService {
  PostService();

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

  // Exposed getter used by UI to check authentication state
  String? get currentSessionToken => _supabaseClient.auth.currentSession?.accessToken;

  /// Basic profile fetch (wrapper) — keeps signature used by UI
  Future<Map<String, dynamic>> getProfile() async {
    return await _callFunction('get-profile', body: {});
  }

  /// Fetch feed with pagination and sorting
  Future<Map<String, dynamic>> getFeed({
    String? sort,
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String? locationId,
  }) async {
    final body = <String, dynamic>{'limit': limit, 'offset': offset};
    if (sort != null) body['sort'] = sort;
    if (categoryId != null) body['category_id'] = categoryId;
    if (locationId != null) body['location_id'] = locationId;
    return await _callFunction('get-feed', body: body);
  }

  Future<Map<String, dynamic>> getHottestPost({String timeframe = 'daily'}) async {
    return await _callFunction('get-hottest-posts', body: {'timeframe': timeframe});
  }

  Future<Map<String, dynamic>> getTopPost({String period = 'week'}) async {
    return await _callFunction('get-top-posts', body: {'period': period});
  }

  Future<Map<String, dynamic>> getComments({required String postId, int limit = 50, int offset = 0}) async {
    final body = {'post_id': postId, 'limit': limit, 'offset': offset};
    return await _callFunction('get-comments', body: body);
  }

  Future<Map<String, dynamic>> createComment({required String postId, required String content, String? parentId}) async {
    final body = {'post_id': postId, 'content': content};
    if (parentId != null) body['parent_id'] = parentId;
    return await _callFunction('create-comment', body: body);
  }

  Future<Map<String, dynamic>> votePost({required String postId, required String voteType}) async {
    final body = {'post_id': postId, 'vote_type': voteType};
    return await _callFunction('vote-post', body: body);
  }

  Future<Map<String, dynamic>> voteComment({required String commentId, required String voteType}) async {
    final body = {'comment_id': commentId, 'vote_type': voteType};
    return await _callFunction('vote-comment', body: body);
  }

  Future<Map<String, dynamic>> deletePost({required String postId}) async {
    final body = {'post_id': postId};
    try {
      return await _callFunction('delete-post', body: body);
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      final lower = raw.toLowerCase();
      if (lower.contains('bad request') ||
          lower.contains('not authorized') ||
          lower.contains('forbidden') ||
          lower.contains('permission') ||
          lower.contains('cannot delete') ||
          lower.contains('not owner') ||
          lower.contains('only owner')) {
        throw Exception("You cannot delete another user's post.");
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteComment({required String commentId}) async {
    final body = {'comment_id': commentId};
    try {
      return await _callFunction('delete-comment', body: body);
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      final lower = raw.toLowerCase();
      if (lower.contains('bad request') ||
          lower.contains('not authorized') ||
          lower.contains('forbidden') ||
          lower.contains('permission') ||
          lower.contains('cannot delete') ||
          lower.contains('not owner') ||
          lower.contains('only owner')) {
        throw Exception("You cannot delete another user's comment.");
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reportPost({required String postId, required String reason, String? description}) async {
    final body = {'post_id': postId, 'reason': reason};
    if (description != null) body['description'] = description;
    return await _callFunction('report-post', body: body);
  }

  Future<Map<String, dynamic>> reportComment({required String commentId, required String reason, String? description}) async {
    final body = {'comment_id': commentId, 'reason': reason};
    if (description != null) body['description'] = description;
    return await _callFunction('report-comment', body: body);
  }

  Future<Map<String, String>> getCategories() async {
    final res = await _callFunction('get-categories', body: {});
    // Normalize to Map<name, id> for the UI
    final Map<String, String> map = {};
    final list = res['categories'] as List<dynamic>? ?? res['data'] as List<dynamic>? ?? [];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final name = (item['name'] ?? item['label'] ?? '').toString();
        final id = (item['id'] ?? item['category_id'] ?? '').toString();
        if (name.isNotEmpty && id.isNotEmpty) map[name] = id;
      }
    }
    return map;
  }

  Future<Map<String, String>> getLocations() async {
    final res = await _callFunction('get-locations', body: {});
    final Map<String, String> map = {};
    final list = res['locations'] as List<dynamic>? ?? res['data'] as List<dynamic>? ?? [];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final name = (item['name'] ?? item['label'] ?? '').toString();
        final id = (item['id'] ?? item['location_id'] ?? '').toString();
        if (name.isNotEmpty && id.isNotEmpty) map[name] = id;
      }
    }
    return map;
  }

  Future<Map<String, dynamic>> createPost({required String content, String? categoryId, String? locationId, bool enableMonthlySpotlight = false}) async {
    final body = <String, dynamic>{'content': content, 'enable_monthly_spotlight': enableMonthlySpotlight};
    if (categoryId != null) body['category_id'] = categoryId;
    if (locationId != null) body['location_id'] = locationId;
    return await _callFunction('create-post', body: body);
  }

  /// Get monthly spotlight status using the get-monthly-spotlight-status edge function
  /// 
  /// Returns: Map with success, is_available, hot_topic_id, hot_topic_title, message, and stats
  Future<Map<String, dynamic>> getMonthlySpotlightStatus() async {
    return await _callFunction('get-monthly-spotlight-status', body: {});
  }

  /// Get monthly spotlight posts using the get-monthly-spotlight-posts edge function
  ///
  /// Parameters: limit, offset
  /// Returns: Map with posts and pagination info
  Future<Map<String, dynamic>> getMonthlySpotlightPosts({int limit = 50, int offset = 0}) async {
    return await _callFunction('get-monthly-spotlight-posts', body: {'limit': limit, 'offset': offset});
  }
}