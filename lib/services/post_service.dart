import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cached feed data with timestamp for expiration checking
class _CachedFeedData {
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  
  _CachedFeedData(this.data) : cachedAt = DateTime.now();
  
  bool isValid(Duration maxAge) {
    return DateTime.now().difference(cachedAt) < maxAge;
  }
}

/// Service for post-related API calls with client-side caching
class PostService {
  // Singleton pattern for shared cache
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  // ============================================================================
  // CLIENT-SIDE FEED CACHE CONFIGURATION
  // ============================================================================
  // Cache durations by filter type (industry best practice)
  // - "New" filter: 2 minutes (increased from 30 seconds for better cache hits)
  // - "Hot"/"Top" filters: 5 minutes (increased from 2 minutes for better cache hits)
  static const Duration _newFilterCacheDuration = Duration(minutes: 2);
  static const Duration _hotTopFilterCacheDuration = Duration(minutes: 5);
  
  // Feed cache storage (cache key -> cached data)
  static final Map<String, _CachedFeedData> _feedCache = {};

  // In-flight dedup — prevents duplicate concurrent requests for the same feed params
  static final Map<String, Future<Map<String, dynamic>>> _inflightFeeds = {};

  // Pinned posts cache (3-minute TTL to avoid cold-start on every New-filter load)
  static const Duration _pinnedPostsCacheDuration = Duration(minutes: 3);
  static List<Map<String, dynamic>>? _pinnedPostsCache;
  static DateTime? _pinnedPostsCacheTime;

  // Upvoted posts cache
  static const Duration _upvotedPostsCacheDuration = Duration(minutes: 3);
  static Map<String, dynamic>? _upvotedPostsCache;
  static DateTime? _upvotedPostsCacheTime;
  static Future<Map<String, dynamic>>? _inflightUpvotedPosts;

  bool get _isUpvotedPostsCacheValid =>
      _upvotedPostsCache != null &&
      _upvotedPostsCacheTime != null &&
      DateTime.now().difference(_upvotedPostsCacheTime!) < _upvotedPostsCacheDuration;

  /// Fire-and-forget prefetch of upvoted posts.
  void prefetchUpvotedPosts() {
    if (_isUpvotedPostsCacheValid) return;
    if (_inflightUpvotedPosts != null) return;
    _inflightUpvotedPosts = getUpvotedPosts(limit: 100, offset: 0)
        .whenComplete(() => _inflightUpvotedPosts = null);
  }

  /// Invalidate upvoted posts cache (call after upvoting/un-upvoting).
  void invalidateUpvotedPostsCache() {
    _upvotedPostsCache = null;
    _upvotedPostsCacheTime = null;
    _inflightUpvotedPosts = null;
  }

  /// Returns true if upvoted posts data is already cached and fresh.
  bool get isUpvotedPostsCached => _isUpvotedPostsCacheValid;

  /// Invalidate pinned posts cache (call after pinning/unpinning a post).
  void invalidatePinnedPostsCache() {
    _pinnedPostsCache = null;
    _pinnedPostsCacheTime = null;
  }

  /// Fire-and-forget prefetch of the default (New) feed.
  /// Safe to call any time — no-ops if data is already fresh or in-flight.
  /// The fetched data populates [_feedCache] so the next [getFeed] call returns instantly.
  void prefetchFeed() {
    const cacheKey = 'feed_latest_20_0___';
    final cached = _feedCache[cacheKey];
    if (cached != null && cached.isValid(_newFilterCacheDuration)) return;
    if (_inflightFeeds.containsKey(cacheKey)) return;
    _inflightFeeds[cacheKey] = getFeed(sort: 'latest', limit: 20, offset: 0)
        .whenComplete(() => _inflightFeeds.remove(cacheKey));
  }

  /// Fire-and-forget prefetch of the Hot feed.
  void prefetchHotFeed() {
    const cacheKey = 'feed_hot_20_0___all_time';
    final cached = _feedCache[cacheKey];
    if (cached != null && cached.isValid(_hotTopFilterCacheDuration)) return;
    if (_inflightFeeds.containsKey(cacheKey)) return;
    _inflightFeeds[cacheKey] = getFeed(sort: 'hot', limit: 20, offset: 0, timeFilter: 'all_time')
        .whenComplete(() => _inflightFeeds.remove(cacheKey));
  }

  /// Fire-and-forget prefetch of the Top feed.
  void prefetchTopFeed() {
    const cacheKey = 'feed_top_20_0___all_time';
    final cached = _feedCache[cacheKey];
    if (cached != null && cached.isValid(_hotTopFilterCacheDuration)) return;
    if (_inflightFeeds.containsKey(cacheKey)) return;
    _inflightFeeds[cacheKey] = getFeed(sort: 'top', limit: 20, offset: 0, timeFilter: 'all_time')
        .whenComplete(() => _inflightFeeds.remove(cacheKey));
  }

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

  /// Block a user using the block-user edge function
  Future<Map<String, dynamic>> blockUser({
    required String blockedUserId,
    String? reason,
  }) async {
    print('=== DEBUG blockUser: Blocking user: $blockedUserId ===');
    final body = <String, dynamic>{
      'blocked_user_id': blockedUserId,
    };
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
      print('DEBUG blockUser: Reason provided: $reason');
    }
    try {
      final response = await _callFunction('block-user', body: body);
      print('DEBUG blockUser: Response success: ${response['success']}');
      print('DEBUG blockUser: Response message: ${response['message']}');
      print('DEBUG blockUser: Full response: $response');
      return response;
    } catch (e) {
      print('ERROR blockUser: Exception - $e');
      rethrow;
    }
  }

  /// Basic profile fetch (wrapper) — keeps signature used by UI
  Future<Map<String, dynamic>> getProfile() async {
    return await _callFunction('get-profile', body: {});
  }

  /// Fetch feed with pagination and sorting
  /// 
  /// Uses the get-feed edge function which supports:
  /// - sort: 'hot', 'top', 'latest' (default: 'hot')
  /// - time_filter: 'all', 'today', 'week', 'month' (default: 'all')
  /// - Filtering by category_id and/or location_id
  /// - Caching via use_cache parameter (backend) and client-side cache
  /// - forceRefresh: bypass client-side cache (for pull-to-refresh)
  /// 
  /// Returns: Map with success, posts (List), pagination (Map), and cached (bool)
  Future<Map<String, dynamic>> getFeed({
    String? sort,
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String? locationId,
    String? timeFilter,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    // Generate cache key based on all parameters
    final cacheKey = 'feed_${sort ?? 'latest'}_${limit}_${offset}_${categoryId ?? ''}_${locationId ?? ''}_${timeFilter ?? ''}';
    
    // Determine cache duration based on sort type
    final sortType = sort ?? 'latest';
    final cacheDuration = (sortType == 'hot' || sortType == 'top') 
        ? _hotTopFilterCacheDuration 
        : _newFilterCacheDuration;
    
    // Check client-side cache first (unless force refresh)
    if (!forceRefresh && _feedCache.containsKey(cacheKey)) {
      final cached = _feedCache[cacheKey]!;
      if (cached.isValid(cacheDuration)) {
        debugPrint('[PostService] Returning client-cached feed (key: $cacheKey, age: ${DateTime.now().difference(cached.cachedAt).inSeconds}s)');
        return {...cached.data, 'client_cached': true};
      } else {
        // Cache expired, remove it
        _feedCache.remove(cacheKey);
      }
    }

    // Join in-flight request if one is already running for this key
    if (!forceRefresh && _inflightFeeds.containsKey(cacheKey)) {
      debugPrint('[PostService] Joining in-flight feed request (key: $cacheKey)');
      return _inflightFeeds[cacheKey]!;
    }
    
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'use_cache': forceRefresh ? false : useCache,
    };
    
    if (sort != null) body['sort'] = sort;
    if (timeFilter != null) body['time_filter'] = timeFilter;
    if (categoryId != null) body['category_id'] = categoryId;
    if (locationId != null) body['location_id'] = locationId;
    
    debugPrint('[PostService] getFeed: sort=$sort, limit=$limit, offset=$offset, category=$categoryId, location=$locationId');
    
    final response = await _callFunction('get-feed', body: body);
    
    debugPrint('[PostService] getFeed: Received ${(response['posts'] as List?)?.length ?? 0} posts, server_cached: ${response['cached']}');
    
    // Cache successful response on client-side
    if (response['success'] == true || response['posts'] != null) {
      _feedCache[cacheKey] = _CachedFeedData(response);
    }
    
    return {...response, 'client_cached': false};
  }
  
  /// Returns true if a valid cached result exists for the given feed parameters.
  /// Used by the feed screen to decide whether to show the skeleton while switching filters.
  bool isFeedCached({
    String? sort,
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String? locationId,
    String? timeFilter,
  }) {
    final cacheKey = 'feed_${sort ?? 'latest'}_${limit}_${offset}_${categoryId ?? ''}_${locationId ?? ''}_${timeFilter ?? ''}';
    final sortType = sort ?? 'latest';
    final cacheDuration = (sortType == 'hot' || sortType == 'top')
        ? _hotTopFilterCacheDuration
        : _newFilterCacheDuration;
    final cached = _feedCache[cacheKey];
    return cached != null && cached.isValid(cacheDuration);
  }

  /// Clear all client-side feed cache (call on pull-to-refresh or logout)
  void clearFeedCache() {
    _feedCache.clear();
    debugPrint('[PostService] Client-side feed cache cleared');
  }
  
  /// Clear cache entries for a specific sort type
  void clearFeedCacheForSort(String sort) {
    _feedCache.removeWhere((key, _) => key.contains('feed_$sort'));
    debugPrint('[PostService] Feed cache cleared for sort: $sort');
  }

  /// Get the hottest post using the get-hottest-post edge function
  /// 
  /// Parameters:
  /// - timeframe: "today" | "week" | "custom" (default: "today")
  /// - customHours: For custom timeframe, specify hours (e.g., 48 for last 48 hours)
  /// - includeComparison: If true, returns comparison of today vs week hottest posts
  /// 
  /// Returns: Map with success, hottest_post (or null), timeframe, and optionally:
  /// - period_hours (for custom timeframe)
  /// - comparison (if includeComparison is true)
  /// - message (e.g., "No posts available in this timeframe")
  Future<Map<String, dynamic>> getHottestPost({
    String timeframe = 'today',
    int? customHours,
    bool includeComparison = false,
  }) async {
    final body = <String, dynamic>{'timeframe': timeframe};
    
    if (timeframe == 'custom' && customHours != null) {
      body['custom_hours'] = customHours;
    }
    if (includeComparison) {
      body['include_comparison'] = true;
    }
    
    print('=== GET HOTTEST POST - REQUEST ===');
    print('Timeframe: $timeframe');
    print('Custom hours: $customHours');
    print('Include comparison: $includeComparison');
    print('Request body: ${jsonEncode(body)}');
    
    final response = await _callFunction('get-hottest-post', body: body);
    
    print('=== GET HOTTEST POST - RESPONSE ===');
    print('Success: ${response['success']}');
    print('Has hottest_post: ${response['hottest_post'] != null}');
    if (response['hottest_post'] != null) {
      final post = response['hottest_post'] as Map<String, dynamic>?;
      print('Post ID: ${post?['id']}');
      print('Post content length: ${post?['content']?.toString().length ?? 0}');
    } else {
      print('Message: ${response['message']}');
    }
    print('Full response: $response');
    print('===================================');
    
    return response;
  }

  /// Get the top post using the get-top-post edge function
  /// 
  /// Parameters:
  /// - period: "all_time" | "week" | "month" | "year" (default: "all_time")
  /// - includeStats: If true, includes additional statistics
  /// 
  /// Returns: Map with success, top_post (or null), period, and optionally:
  /// - stats (if includeStats is true)
  /// - message (e.g., "No posts available yet")
  Future<Map<String, dynamic>> getTopPost({
    String period = 'all_time',
    bool includeStats = false,
  }) async {
    final body = <String, dynamic>{'period': period};
    
    if (includeStats) {
      body['include_stats'] = true;
    }
    
    print('=== GET TOP POST - REQUEST ===');
    print('Period: $period');
    print('Include stats: $includeStats');
    print('Request body: ${jsonEncode(body)}');
    
    final response = await _callFunction('get-top-post', body: body);
    
    print('=== GET TOP POST - RESPONSE ===');
    print('Success: ${response['success']}');
    print('Has top_post: ${response['top_post'] != null}');
    if (response['top_post'] != null) {
      final post = response['top_post'] as Map<String, dynamic>?;
      print('Post ID: ${post?['id']}');
      print('Post content length: ${post?['content']?.toString().length ?? 0}');
    } else {
      print('Message: ${response['message']}');
    }
    print('Full response: $response');
    print('==============================');
    
    return response;
  }

  /// Get the realtime WOD post using the get-wod-post edge function.
  ///
  /// Returns: Map payload from backend; expected to contain one post entry
  /// under keys like `wod_post`, `post`, or `data` depending on backend shape.
  Future<Map<String, dynamic>> getWodPost() async {
    print('=== GET WOD POST - REQUEST ===');
    final response = await _callFunction('get-wod-post', method: 'GET');
    print('=== GET WOD POST - RESPONSE ===');
    print('Success: ${response['success']}');
    print('Response keys: ${response.keys.toList()}');
    print('==============================');
    return response;
  }

  /// Get a single post by ID using the get-post edge function
  /// 
  /// Returns: Map with success (bool) and post (Map<String, dynamic>) containing:
  /// - id, user_id, username, profile_picture_url
  /// - category_id, category_name, location_id, location_name
  /// - content, image_url
  /// - upvote_count, downvote_count, net_score, comment_count
  /// - user_vote (current user's vote: 'upvote', 'downvote', or null)
  /// - created_at, updated_at
  Future<Map<String, dynamic>> getPost({required String postId}) async {
    final body = <String, dynamic>{
      'post_id': postId,
    };
    
    print('DEBUG getPost: Fetching post: $postId');
    
    try {
      final response = await _callFunction('get-post', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? true;
      
      if (!success) {
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to fetch post';
        throw Exception(errorMessage);
      }
      
      print('DEBUG getPost: Successfully retrieved post: ${response['post']?['id']}');
      
      return response;
    } catch (e) {
      print('ERROR getPost: Exception - $e');
      rethrow;
    }
  }

  /// Get comments for a post using the get-comments edge function
  /// 
  /// The edge function supports:
  /// - Ranked comments (default, use_ranking: true) - uses get_ranked_comments RPC
  /// - Nested comments (use_ranking: false) - uses get_post_comments RPC with nested structure
  /// 
  /// Returns: Map with success (bool), comments (List), and optionally:
  /// - ranked (bool) - indicates if ranked algorithm was used
  /// - total_comments (int) - count of top-level comments
  /// - total_replies (int) - count of replies
  /// - pagination (Map) - pagination metadata
  Future<Map<String, dynamic>> getComments({
    required String postId, 
    int limit = 50, 
    int offset = 0,
    bool useRanking = true,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
      'limit': limit,
      'offset': offset,
      'use_ranking': useRanking,
    };
    
    print('DEBUG getComments: Fetching comments for post: $postId');
    print('DEBUG getComments: Limit: $limit, Offset: $offset, Use ranking: $useRanking');
    
    try {
      final response = await _callFunction('get-comments', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? true;
      
      if (!success) {
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to fetch comments';
        throw Exception(errorMessage);
      }
      
      // Log response structure
      final comments = response['comments'] as List<dynamic>? ?? [];
      final ranked = response['ranked'] as bool? ?? false;
      print('DEBUG getComments: Retrieved ${comments.length} comments (ranked: $ranked)');
      
      if (response['total_comments'] != null) {
        print('DEBUG getComments: Total comments: ${response['total_comments']}, Total replies: ${response['total_replies']}');
      }
      
      return response;
    } catch (e) {
      // Handle errors with better messages
      final errorStr = e.toString();
      if (errorStr.contains('400') || errorStr.contains('post_id is required')) {
        throw Exception('Post ID is required to fetch comments');
      } else if (errorStr.contains('404') || errorStr.contains('Post not found')) {
        throw Exception('The post does not exist');
      } else if (errorStr.contains('500') || errorStr.contains('Failed to fetch comments')) {
        throw Exception('Failed to load comments. Please try again.');
      }
      
      // Re-throw if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch comments: $errorStr');
    }
  }

  Future<Map<String, dynamic>> createComment({required String postId, required String content, String? parentId}) async {
    final body = <String, dynamic>{
      'post_id': postId,
      'content': content,
    };
    if (parentId != null) body['parent_id'] = parentId;
    
    print('DEBUG createComment: Creating comment on post: $postId');
    print('DEBUG createComment: Content length: ${content.length}');
    if (parentId != null) print('DEBUG createComment: Parent ID: $parentId');
    
    try {
      final response = await _callFunction('create-comment', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? false;
      
      if (!success) {
        // Handle content blocked or other errors
        final errorMessage = response['message'] as String? ?? 
                            response['error'] as String? ?? 
                            'Failed to create comment';
        
        // Check if content was blocked
        if (response['error'] == 'Comment blocked' || 
            (response['details'] as Map<String, dynamic>?)?['reason'] == 'Content moderation') {
          // Extract moderation message if available
          final moderationMessage = response['message'] as String?;
          throw Exception(moderationMessage ?? 'Your comment contains inappropriate content and cannot be published. Please review our community guidelines.');
        }
        
        throw Exception(errorMessage);
      }
      
      // Log success
      print('DEBUG createComment: Comment created successfully');
      if (response['comment'] != null) {
        final comment = response['comment'] as Map<String, dynamic>?;
        print('DEBUG createComment: Comment ID: ${comment?['id']}');
      }
      
      return response;
    } catch (e) {
      // Handle errors with better error messages
      final errorStr = e.toString();
      
      // Check for specific error patterns from the edge function
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        throw Exception('You must be logged in to create a comment');
      } else if (errorStr.contains('404') || errorStr.contains('Post not found')) {
        throw Exception('The post you are commenting on no longer exists.');
      } else if (errorStr.contains('Comment not found') || errorStr.contains('Parent comment not found')) {
        throw Exception('The comment you are trying to reply to does not exist');
      } else if (errorStr.contains('Cannot reply to a reply') || errorStr.contains('Only 1-level nesting')) {
        throw Exception('You can only reply to top-level comments, not to replies');
      } else if (errorStr.contains('content is required')) {
        throw Exception('Comment content is required');
      } else if (errorStr.contains('500') && errorStr.contains('characters')) {
        throw Exception('Comment must be 500 characters or less');
      } else if (errorStr.contains('must be between 1 and 500')) {
        throw Exception('Comment must be between 1 and 500 characters');
      } else if (errorStr.contains('Rate limit exceeded')) {
        throw Exception('You are commenting too frequently. Please wait a moment before trying again.');
      } else if (errorStr.contains('Comment blocked') || errorStr.contains('inappropriate content')) {
        // Content moderation error - rethrow with original message
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Your comment contains inappropriate content and cannot be published. Please review our community guidelines.');
      }
      
      // For any other error, rethrow if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create comment: $errorStr');
    }
  }

  Future<Map<String, dynamic>> votePost({required String postId, required String voteType}) async {
    final body = {'post_id': postId, 'vote_type': voteType};
    return await _callFunction('vote-post', body: body);
  }

  Future<Map<String, dynamic>> voteComment({required String commentId, required String voteType}) async {
    final body = {'comment_id': commentId, 'vote_type': voteType};
    return await _callFunction('vote-comment', body: body);
  }

  /// Delete a post using the delete-post edge function
  /// 
  /// The edge function handles:
  /// - Authentication validation
  /// - Authorization check (only post owner or admin can delete)
  /// - Soft delete via delete_post_authorized RPC
  /// 
  /// Returns: Map with success (bool), message (String), and post_id (String)
  Future<Map<String, dynamic>> deletePost({required String postId}) async {
    final body = {'post_id': postId};
    
    print('=== DEBUG deletePost: Deleting post: $postId ===');
    
    try {
      final response = await _callFunction('delete-post', body: body);
      
      print('DEBUG deletePost: Full response: $response');
      
      // Check for success field
      final success = response['success'] as bool? ?? false;
      print('DEBUG deletePost: Success: $success');
      
      if (!success) {
        // Handle specific error cases from edge function
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to delete post';
        
        // Check for authorization errors
        if (errorMessage.toLowerCase().contains('unauthorized') ||
            errorMessage.toLowerCase().contains('not owner') ||
            errorMessage.toLowerCase().contains('only owner') ||
            errorMessage.toLowerCase().contains('cannot delete')) {
          throw Exception("You cannot delete another user's post.");
        }
        
        // Check for validation errors
        if (errorMessage.toLowerCase().contains('post_id is required') ||
            errorMessage.toLowerCase().contains('validation failed')) {
          throw Exception('Post ID is required.');
        }
        
        throw Exception(errorMessage);
      }
      
      // Log success
      print('DEBUG deletePost: Post deleted successfully');
      final message = response['message'] as String? ?? 'Post deleted successfully';
      print('DEBUG deletePost: Message: $message');
      
      return response;
    } catch (e) {
      // Handle HTTP errors that might have been caught
      final errorStr = e.toString();
      print('ERROR deletePost: Exception caught - $errorStr');
      
      // Check for specific error patterns
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        print('ERROR deletePost: Unauthorized (401)');
        throw Exception('You must be logged in to delete posts.');
      } else if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
        print('ERROR deletePost: Forbidden (403)');
        throw Exception("You cannot delete another user's post.");
      } else if (errorStr.contains('404') || errorStr.contains('not found')) {
        print('ERROR deletePost: Not found (404)');
        throw Exception('This post no longer exists.');
      } else if (errorStr.contains('400') || errorStr.contains('post_id is required') || errorStr.contains('Validation failed')) {
        print('ERROR deletePost: Bad request (400)');
        throw Exception('Post ID is required.');
      } else if (errorStr.contains('500') || errorStr.contains('Failed to delete post')) {
        print('ERROR deletePost: Server error (500)');
        throw Exception('Failed to delete post. Please try again.');
      } else if (errorStr.contains('cannot delete another user\'s post') ||
                 errorStr.contains('not owner') ||
                 errorStr.contains('only owner') ||
                 errorStr.contains('permission denied') ||
                 errorStr.contains('not authorized')) {
        print('ERROR deletePost: Permission denied');
        throw Exception("You cannot delete another user's post.");
      }
      
      // Re-throw if it's already an Exception with a good message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete post: $errorStr');
    }
  }

  /// Delete a comment using the delete-comment edge function
  /// 
  /// The edge function handles:
  /// - Authentication validation
  /// - Authorization check (only comment owner can delete)
  /// - Comment deletion via delete_comment_authorized RPC
  /// 
  /// Returns: Map with success (bool), message (String), and comment_id (String)
  Future<Map<String, dynamic>> deleteComment({required String commentId}) async {
    final body = {'comment_id': commentId};
    
    print('=== DEBUG deleteComment: Deleting comment: $commentId ===');
    
    try {
      final response = await _callFunction('delete-comment', body: body);
      
      print('DEBUG deleteComment: Full response: $response');
      
      // Check for success field
      final success = response['success'] as bool? ?? false;
      print('DEBUG deleteComment: Success: $success');
      
      if (!success) {
        // Handle specific error cases from edge function
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to delete comment';
        print('DEBUG deleteComment: Error message: $errorMessage');
        
        // Check for authorization errors
        if (errorMessage.toLowerCase().contains('unauthorized') ||
            errorMessage.toLowerCase().contains('not owner') ||
            errorMessage.toLowerCase().contains('only owner') ||
            errorMessage.toLowerCase().contains('cannot delete')) {
          throw Exception("You cannot delete another user's comment.");
        }
        
        // Check for not found errors
        if (errorMessage.toLowerCase().contains('not found') ||
            errorMessage.toLowerCase().contains('does not exist')) {
          throw Exception('This comment no longer exists.');
        }
        
        throw Exception(errorMessage);
      }
      
      // Log success
      print('DEBUG deleteComment: Comment deleted successfully');
      final message = response['message'] as String? ?? 'Comment deleted successfully';
      print('DEBUG deleteComment: Message: $message');
      
      return response;
    } catch (e) {
      // Handle HTTP errors that might have been caught
      final errorStr = e.toString();
      print('ERROR deleteComment: Exception caught - $errorStr');
      
      // Check for specific error patterns
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        print('ERROR deleteComment: Unauthorized (401)');
        throw Exception('You must be logged in to delete comments.');
      } else if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
        print('ERROR deleteComment: Forbidden (403)');
        throw Exception("You cannot delete another user's comment.");
      } else if (errorStr.contains('404') || errorStr.contains('not found')) {
        print('ERROR deleteComment: Not found (404)');
        throw Exception('This comment no longer exists.');
      } else if (errorStr.contains('400') || errorStr.contains('comment_id is required')) {
        print('ERROR deleteComment: Bad request (400)');
        throw Exception('Comment ID is required.');
      } else if (errorStr.contains('500') || errorStr.contains('Failed to delete comment')) {
        print('ERROR deleteComment: Server error (500)');
        throw Exception('Failed to delete comment. Please try again.');
      } else if (errorStr.contains('cannot delete another user\'s comment') ||
                 errorStr.contains('not owner') ||
                 errorStr.contains('only owner') ||
                 errorStr.contains('permission denied')) {
        print('ERROR deleteComment: Permission denied');
        throw Exception("You cannot delete another user's comment.");
      }
      
      // Re-throw if it's already an Exception with a good message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete comment: $errorStr');
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
    try {
      final res = await _callFunction('get-categories', body: {});
      // Normalize to Map<name, id> for the UI
      final Map<String, String> map = {};
      
      // Try multiple possible response structures
      final list = res['categories'] as List<dynamic>? ?? 
                   res['data'] as List<dynamic>? ?? 
                   (res['success'] == true ? (res['categories'] as List<dynamic>?) : null) ??
                   [];
      
      print('DEBUG getCategories: Response keys: ${res.keys.toList()}');
      print('DEBUG getCategories: Found ${list.length} categories');
      
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          // Try multiple field name variations
          final name = (item['name'] ?? 
                       item['label'] ?? 
                       item['category_name'] ?? 
                       '').toString().trim();
          final id = (item['id'] ?? 
                     item['category_id'] ?? 
                     item['categoryId'] ?? 
                     '').toString().trim();
          if (name.isNotEmpty && id.isNotEmpty) {
            map[name] = id;
            print('DEBUG getCategories: Mapped "$name" -> "$id"');
          } else {
            print('DEBUG getCategories: Skipping item with missing name/id: $item');
          }
        }
      }
      
      if (map.isEmpty) {
        print('WARNING: getCategories returned empty map. Full response: $res');
      }
      
      return map;
    } catch (e) {
      print('ERROR: getCategories failed: $e');
      // Return empty map instead of throwing to prevent cascading failures
      return {};
    }
  }

  Future<Map<String, String>> getLocations() async {
    try {
      final res = await _callFunction('get-locations', body: {});
      final Map<String, String> map = {};
      
      // Try multiple possible response structures
      final list = res['locations'] as List<dynamic>? ?? 
                   res['data'] as List<dynamic>? ?? 
                   (res['success'] == true ? (res['locations'] as List<dynamic>?) : null) ??
                   [];
      
      print('DEBUG getLocations: Response keys: ${res.keys.toList()}');
      print('DEBUG getLocations: Found ${list.length} locations');
      
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          // Try multiple field name variations
          final name = (item['name'] ?? 
                       item['label'] ?? 
                       item['location_name'] ?? 
                       '').toString().trim();
          final id = (item['id'] ?? 
                     item['location_id'] ?? 
                     item['locationId'] ?? 
                     '').toString().trim();
          if (name.isNotEmpty && id.isNotEmpty) {
            map[name] = id;
            print('DEBUG getLocations: Mapped "$name" -> "$id"');
          } else {
            print('DEBUG getLocations: Skipping item with missing name/id: $item');
          }
        }
      }
      
      if (map.isEmpty) {
        print('WARNING: getLocations returned empty map. Full response: $res');
      }
      
      return map;
    } catch (e) {
      print('ERROR: getLocations failed: $e');
      // Return empty map instead of throwing to prevent cascading failures
      return {};
    }
  }

  /// Create a new post using the create-post edge function
  /// 
  /// Parameters:
  /// - content: Post content (required, max 1000 characters)
  /// - categoryId: Optional category ID
  /// - locationId: Optional location ID
  /// - enableMonthlySpotlight: Whether to enable monthly spotlight (default: false)
  /// - imageUrl: Optional image URL
  /// 
  /// Returns: Map with success, post, message, and moderation info
  /// 
  /// Throws Exception with appropriate error message for:
  /// - Content validation errors
  /// - Content blocked by moderation
  /// - Authentication errors
  /// - Account status errors
  /// - Server errors
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? categoryId,
    String? locationId,
    bool enableMonthlySpotlight = false,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'enable_monthly_spotlight': enableMonthlySpotlight,
    };
    if (categoryId != null) body['category_id'] = categoryId;
    if (locationId != null) body['location_id'] = locationId;
    if (imageUrl != null) body['image_url'] = imageUrl;
    
    print('DEBUG createPost: Creating post with content length: ${content.length}');
    print('DEBUG createPost: Category ID: $categoryId, Location ID: $locationId');
    print('DEBUG createPost: Monthly spotlight enabled: $enableMonthlySpotlight');
    
    try {
      final response = await _callFunction('create-post', body: body);
      
      // Check for success field (should be true for successful posts)
      final success = response['success'] as bool? ?? true;
      
      if (!success) {
        // Handle content blocked or other errors
        final errorMessage = response['message'] as String? ?? 
                            response['error'] as String? ?? 
                            'Failed to create post';
        
        // Check if content was blocked
        if (response['error'] == 'Content blocked' || 
            (response['details'] as Map<String, dynamic>?)?['reason'] == 'Content moderation') {
          // Extract moderation message if available
          final moderationMessage = response['message'] as String?;
          throw Exception(moderationMessage ?? 'Your post contains inappropriate content and cannot be published. Please review our community guidelines.');
        }
        
        throw Exception(errorMessage);
      }
      
      // Log success
      print('DEBUG createPost: Post created successfully');
      if (response['moderation'] != null) {
        final moderation = response['moderation'] as Map<String, dynamic>?;
        print('DEBUG createPost: Moderation - Flagged: ${moderation?['flagged']}, Score: ${moderation?['score']}');
      }
      
      return response;
    } catch (e) {
      // Handle different error cases with user-friendly messages
      final errorStr = e.toString();
      
      // Content blocking - check for moderation-related messages
      if (errorStr.contains('Content blocked') || 
          errorStr.contains('inappropriate content') ||
          errorStr.contains('community guidelines')) {
        // Keep the original message as it's already user-friendly
        throw Exception(errorStr.replaceFirst('Exception: ', ''));
      }
      
      // Authentication errors
      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        throw Exception('You must be logged in to create a post');
      }
      
      // Account status errors
      if (errorStr.contains('403') || errorStr.contains('not active') || errorStr.contains('Account is not active')) {
        throw Exception('Your account is not active. Please contact support.');
      }
      
      // Profile errors
      if (errorStr.contains('404') || errorStr.contains('Profile not found')) {
        throw Exception('Profile not found. Please try logging out and back in.');
      }
      
      // Validation errors
      if (errorStr.contains('Content is required')) {
        throw Exception('Post content is required');
      }
      if (errorStr.contains('1000') || errorStr.contains('1000 characters')) {
        throw Exception('Post content must be 1000 characters or less');
      }
      if (errorStr.contains('Invalid category')) {
        throw Exception('Invalid category selected');
      }
      if (errorStr.contains('Invalid location')) {
        throw Exception('Invalid location selected');
      }
      
      // Monthly spotlight errors
      if (errorStr.contains('Monthly spotlight not available')) {
        throw Exception(errorStr.replaceFirst('Exception: ', ''));
      }
      
      // Rate limiting (if applicable)
      if (errorStr.contains('rate limit') || errorStr.contains('too many')) {
        throw Exception('You are posting too frequently. Please wait a moment and try again.');
      }
      
      // For other errors, preserve the original message but clean it up
      final cleanMessage = errorStr.replaceFirst('Exception: ', '');
      throw Exception(cleanMessage.isEmpty ? 'Failed to create post. Please try again.' : cleanMessage);
    }
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

  /// Get user's posts using the get-user-posts edge function
  /// 
  /// The edge function fetches posts for a specific user with full details including comments and vote counts
  /// 
  /// Parameters:
  /// - userId: User ID to fetch posts for (defaults to current user if not provided)
  /// - limit: Maximum number of posts to fetch (default: 20)
  /// - offset: Number of posts to skip (default: 0)
  /// 
  /// Returns: Map with success (bool), user_id (String), total_posts (int), and posts (List<Map<String, dynamic>>)
  Future<Map<String, dynamic>> getUserPosts({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    // Get user ID - use provided userId or current user
    String targetUserId;
    if (userId != null && userId.isNotEmpty) {
      targetUserId = userId;
    } else {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      targetUserId = currentUser.id;
    }
    
    final body = <String, dynamic>{
      'user_id': targetUserId,
      'limit': limit,
      'offset': offset,
    };
    
    print('DEBUG getUserPosts: Fetching posts for user: $targetUserId');
    print('DEBUG getUserPosts: Limit: $limit, Offset: $offset');
    
    try {
      final response = await _callFunction('get-user-posts', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? true;
      
      if (!success) {
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to fetch user posts';
        throw Exception(errorMessage);
      }
      
      final posts = response['posts'] as List<dynamic>? ?? [];
      final totalPosts = response['total_posts'] as int? ?? posts.length;
      
      print('DEBUG getUserPosts: Retrieved ${posts.length} posts (total: $totalPosts)');
      
      return response;
    } catch (e) {
      // Handle errors with better messages
      final errorStr = e.toString();
      if (errorStr.contains('400') || errorStr.contains('user_id') || errorStr.contains('Missing required field')) {
        throw Exception('User ID is required to fetch posts');
      } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        throw Exception('You must be logged in to fetch posts');
      } else if (errorStr.contains('500') || errorStr.contains('Failed to fetch user posts')) {
        throw Exception('Failed to load posts. Please try again.');
      } else if (errorStr.contains('Database function not found') || errorStr.contains('does not exist')) {
        throw Exception('Database function not available. Please contact support.');
      }
      
      // Re-throw if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch user posts: $errorStr');
    }
  }

  /// Get user badges using the get-user-badges edge function
  /// 
  /// Parameters:
  /// - userId: Optional user ID. If not provided, uses current authenticated user
  /// 
  /// Returns: Map with success, user_id, username, badges (List<String>), and details
  Future<Map<String, dynamic>> getUserBadges({String? userId}) async {
    final body = <String, dynamic>{};
    if (userId != null) {
      body['user_id'] = userId;
      print('DEBUG getUserBadges: Fetching badges for user: $userId');
    } else {
      print('DEBUG getUserBadges: Fetching badges for current user');
    }
    
    try {
      final response = await _callFunction('get-user-badges', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? false;
      if (!success) {
        final errorMessage = response['message'] as String? ?? 
                            response['error'] as String? ?? 
                            'Failed to fetch user badges';
        throw Exception(errorMessage);
      }
      
      print('DEBUG getUserBadges: Successfully fetched badges: ${response['badges']}');
      return response;
    } catch (e) {
      print('ERROR: Failed to get user badges: $e');
      rethrow;
    }
  }

  /// Get upvoted posts using the get-upvoted-posts edge function
  ///
  /// Parameters: limit (int, default 20), offset (int, default 0)
  /// Returns: Map with success (bool), total_upvoted_posts (int), and posts (List<Map<String, dynamic>>)
  Future<Map<String, dynamic>> getUpvotedPosts({int limit = 20, int offset = 0}) async {
    // Return cached data if still valid
    if (_isUpvotedPostsCacheValid) return _upvotedPostsCache!;
    // Deduplicate concurrent requests
    if (_inflightUpvotedPosts != null) return _inflightUpvotedPosts!;

    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-upvoted-posts');
    try {
      print('=== DEBUG getUpvotedPosts: Getting upvoted posts (limit: $limit, offset: $offset) ===');
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      print('DEBUG getUpvotedPosts: Has session token: ${sessionToken != null}');
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };
      if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      final uriWithParams = uri.replace(queryParameters: queryParams);
      print('DEBUG getUpvotedPosts: Request URL: $uriWithParams');

      final resp = await http.get(uriWithParams, headers: headers);

      print('DEBUG getUpvotedPosts: Status code: ${resp.statusCode}');
      print('DEBUG getUpvotedPosts: Response body: ${resp.body}');

      final parsed = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = parsed['error'] ?? parsed['message'] ?? 'Server error';
        print('ERROR getUpvotedPosts: Status ${resp.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }

      print('DEBUG getUpvotedPosts: Success - ${parsed['success']}');
      print('DEBUG getUpvotedPosts: Total upvoted posts - ${parsed['total_upvoted_posts']}');
      final posts = parsed['posts'] as List<dynamic>? ?? [];
      print('DEBUG getUpvotedPosts: Posts in response - ${posts.length}');

      // Store in cache
      _upvotedPostsCache = parsed;
      _upvotedPostsCacheTime = DateTime.now();

      return parsed;
    } catch (e) {
      print('ERROR getUpvotedPosts: Exception - $e');
      rethrow;
    }
  }

  /// Search users for @mention autocomplete
  /// 
  /// The edge function searches users by username for autocomplete functionality
  /// 
  /// Parameters:
  /// - query: Search query (can include @ symbol, will be stripped)
  /// - limit: Maximum number of results (default: 10)
  /// 
  /// Returns: Map with success (bool), users (List), and count (int)
  Future<Map<String, dynamic>> searchUsers({
    required String query,
    int limit = 10,
  }) async {
    final body = <String, dynamic>{
      'query': query,
      'limit': limit,
    };
    
    print('DEBUG searchUsers: Searching for users with query: $query');
    
    try {
      final response = await _callFunction('search-users', body: body);
      
      // Check for success field
      final success = response['success'] as bool? ?? true;
      
      if (!success) {
        final errorMessage = response['error'] as String? ?? 
                            response['message'] as String? ?? 
                            'Failed to search users';
        throw Exception(errorMessage);
      }
      
      final users = response['users'] as List<dynamic>? ?? [];
      final count = response['count'] as int? ?? users.length;
      
      print('DEBUG searchUsers: Found $count users');
      
      return response;
    } catch (e) {
      // Handle errors with better messages
      final errorStr = e.toString();
      if (errorStr.contains('400') || errorStr.contains('query is required')) {
        throw Exception('Search query is required');
      } else if (errorStr.contains('500') || errorStr.contains('Failed to search users')) {
        throw Exception('Failed to search users. Please try again.');
      }
      
      // Re-throw if it's already an Exception, otherwise wrap it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to search users: $errorStr');
    }
  }

  // ============================================================================
  // MODERATION EDGE FUNCTION METHODS
  // ============================================================================

  /// Pin a post using the pin-post edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - action: 'pin' or 'unpin'
  /// - expiresAt: Optional ISO8601 expiry (pin only, null = no expiry)
  /// 
  /// Returns: Map with success, pin_id/post_id, pinned_by/unpinned_by, etc.
  Future<Map<String, dynamic>> pinPost({
    required String postId,
    required String action,
    String? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'post_id': postId,
    };
    if (action == 'pin' && expiresAt != null) {
      body['expires_at'] = expiresAt;
    }

    print('=== DEBUG pinPost: $action post: $postId ===');

    try {
      final response = await _callFunction('pin-post', body: body);
      print('DEBUG pinPost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR pinPost: Exception - $e');
      rethrow;
    }
  }

  /// Unpin a post using the unpin-post edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post to unpin
  /// 
  /// Returns: Map with success boolean
  Future<Map<String, dynamic>> unpinPost({
    required String postId,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
    };

    print('=== DEBUG unpinPost: post: $postId ===');

    try {
      final response = await _callFunction('unpin-post', body: body);
      print('DEBUG unpinPost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR unpinPost: Exception - $e');
      rethrow;
    }
  }

  /// Mute or unmute a post using the mute-post edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - action: 'mute' or 'unmute'
  /// - reason: Required for mute (e.g., harassment, spam, etc.)
  /// - details: Optional string for mute
  /// - expiresAt: Optional ISO8601 expiry for mute (null = indefinite)
  /// 
  /// Returns: Map with success, action_id, post_id, reason, etc.
  Future<Map<String, dynamic>> mutePost({
    required String postId,
    required String action,
    String? reason,
    String? details,
    String? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'post_id': postId,
    };
    if (action == 'mute') {
      if (reason != null) body['reason'] = reason;
      if (details != null && details.isNotEmpty) body['details'] = details;
      if (expiresAt != null) body['expires_at'] = expiresAt;
    }

    print('=== DEBUG mutePost: $action post: $postId ===');

    try {
      final response = await _callFunction('mute-post', body: body);
      print('DEBUG mutePost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR mutePost: Exception - $e');
      rethrow;
    }
  }

  /// Warn or unwarn a post using the warn-post edge function (admin only)
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - action: 'warn' or 'unwarn'
  /// - reason: Required for warn (e.g., harassment, spam, etc.)
  /// - details: Optional string for warn
  /// 
  /// Returns: Map with success, action_id, post_id, reason, etc.
  Future<Map<String, dynamic>> warnPost({
    required String postId,
    required String action,
    String? reason,
    String? details,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'post_id': postId,
    };
    if (action == 'warn') {
      if (reason != null) body['reason'] = reason;
      if (details != null && details.isNotEmpty) body['details'] = details;
    }

    print('=== DEBUG warnPost: $action post: $postId ===');

    try {
      final response = await _callFunction('warn-post', body: body);
      print('DEBUG warnPost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR warnPost: Exception - $e');
      rethrow;
    }
  }

  /// Hide or unhide a post using the hide-post edge function (admin only)
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - action: 'hide' or 'unhide'
  /// - reason: Required for hide (e.g., harassment, spam, etc.)
  /// - details: Optional string for hide
  /// 
  /// Returns: Map with success, action_id, post_id, reason, etc.
  Future<Map<String, dynamic>> hidePost({
    required String postId,
    required String action,
    String? reason,
    String? details,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'post_id': postId,
    };
    if (action == 'hide') {
      if (reason != null) body['reason'] = reason;
      if (details != null && details.isNotEmpty) body['details'] = details;
    }

    print('=== DEBUG hidePost: $action post: $postId ===');

    try {
      final response = await _callFunction('hide-post', body: body);
      print('DEBUG hidePost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR hidePost: Exception - $e');
      rethrow;
    }
  }

  /// Flag a post for moderator review using the flag-post edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - reason: Optional reason string
  /// 
  /// Returns: Map with success, post_id, old_status, new_status, reason
  Future<Map<String, dynamic>> flagPost({
    required String postId,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
    };
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    print('=== DEBUG flagPost: Flagging post: $postId ===');

    try {
      final response = await _callFunction('flag-post', body: body);
      print('DEBUG flagPost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR flagPost: Exception - $e');
      rethrow;
    }
  }

  /// Escalate a post to administrator using the escalate-to-admin edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - reason: Required reason string
  /// 
  /// Returns: Map with success, post_id, promoted_user, escalated_by, escalated_at
  Future<Map<String, dynamic>> escalateToAdmin({
    required String postId,
    required String reason,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
      'reason': reason,
    };

    print('=== DEBUG escalateToAdmin: Escalating post: $postId ===');

    try {
      final response = await _callFunction('escalate-to-admin', body: body);
      print('DEBUG escalateToAdmin: Response: $response');
      return response;
    } catch (e) {
      print('ERROR escalateToAdmin: Exception - $e');
      rethrow;
    }
  }

  /// Escalate a post to moderator using the escalate-to-moderator edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - reason: Optional reason string
  /// 
  /// Returns: Map with success, post_id, user_id, username, old_role, new_role
  Future<Map<String, dynamic>> escalateToModerator({
    required String postId,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
    };
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    print('=== DEBUG escalateToModerator: Escalating post: $postId ===');

    try {
      final response = await _callFunction('escalate-to-moderator', body: body);
      print('DEBUG escalateToModerator: Response: $response');
      return response;
    } catch (e) {
      print('ERROR escalateToModerator: Exception - $e');
      rethrow;
    }
  }

  /// Nominate a post for Word of the Day using the nominate-wod edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - note: Optional nomination note
  /// 
  /// Returns: Map with success, nomination_id, post_id, nominated_by, nominated_at
  Future<Map<String, dynamic>> nominateWod({
    required String postId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
    };
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    print('=== DEBUG nominateWod: Nominating post: $postId ===');

    try {
      final response = await _callFunction('nominate-wod', body: body);
      print('DEBUG nominateWod: Response: $response');
      return response;
    } catch (e) {
      print('ERROR nominateWod: Exception - $e');
      rethrow;
    }
  }

  /// Change a post's category using the change-category edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - categorySlug: The slug of the new category
  /// 
  /// Returns: Map with success, post_id, old_category, new_category
  Future<Map<String, dynamic>> changeCategory({
    required String postId,
    required String categorySlug,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
      'category_slug': categorySlug,
    };

    print('=== DEBUG changeCategory: Changing category for post: $postId to $categorySlug ===');

    try {
      final response = await _callFunction('change-category', body: body);
      print('DEBUG changeCategory: Response: $response');
      return response;
    } catch (e) {
      print('ERROR changeCategory: Exception - $e');
      rethrow;
    }
  }

  /// Edit a post as admin using the admin-edit-post edge function
  /// 
  /// Parameters:
  /// - postId: UUID of the post
  /// - content: Updated content (max 1000 chars)
  /// - imageUrl: Optional image URL (null to clear)
  /// 
  /// Returns: Map with success, post_id, updated_by, updated_at
  Future<Map<String, dynamic>> adminEditPost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
      'content': content,
    };
    if (imageUrl != null) {
      body['image_url'] = imageUrl;
    }

    print('=== DEBUG adminEditPost: Editing post: $postId ===');

    try {
      final response = await _callFunction('admin-edit-post', body: body);
      print('DEBUG adminEditPost: Response: $response');
      return response;
    } catch (e) {
      print('ERROR adminEditPost: Exception - $e');
      rethrow;
    }
  }

  /// Fetch currently pinned posts using the get-pinned-posts edge function
  Future<List<Map<String, dynamic>>> getPinnedPosts() async {
    // Return cached data if still valid
    if (_pinnedPostsCache != null && _pinnedPostsCacheTime != null) {
      final age = DateTime.now().difference(_pinnedPostsCacheTime!);
      if (age < _pinnedPostsCacheDuration) {
        return List<Map<String, dynamic>>.from(_pinnedPostsCache!);
      }
    }

    print('=== DEBUG getPinnedPosts: Fetching pinned posts ===');

    try {
      final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-pinned-posts');
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? '';

      final httpResponse = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(httpResponse.body);
      print('DEBUG getPinnedPosts: Response: $data');

      if (data is Map && data['success'] == false) {
        throw Exception(data['error'] ?? 'Failed to fetch pinned posts');
      }

      // Extract posts from response — actual format uses 'pinned_posts' key
      List<dynamic> posts = [];
      if (data is Map) {
        if (data.containsKey('pinned_posts')) {
          posts = (data['pinned_posts'] as List?) ?? [];
        } else {
          final inner = data['data'] ?? data;
          if (inner is Map && inner.containsKey('posts')) {
            posts = (inner['posts'] as List?) ?? [];
          } else if (data.containsKey('posts')) {
            posts = (data['posts'] as List?) ?? [];
          }
        }
      } else if (data is List) {
        posts = data;
      }

      final result = posts.cast<Map<String, dynamic>>();
      // Store in cache
      _pinnedPostsCache = List<Map<String, dynamic>>.from(result);
      _pinnedPostsCacheTime = DateTime.now();
      return result;
    } catch (e) {
      print('ERROR getPinnedPosts: Exception - $e');
      rethrow;
    }
  }
}