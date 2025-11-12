import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PostService {
  final _supabaseClient = Supabase.instance.client;

  /// Create a post using the create-post edge function
  /// 
  /// Parameters:
  /// - content: The post content (required, max 1000 chars)
  /// - categoryId: Optional category UUID
  /// - locationId: Optional location UUID
  /// - imageUrl: Optional image URL
  /// - enableMonthlySpotlight: Optional boolean to enable monthly spotlight
  /// 
  /// Returns: Map with success, post, and message fields
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? categoryId,
    String? locationId,
    String? imageUrl,
    bool? enableMonthlySpotlight,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/create-post');
    
    try {
      // Get current session access token
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      
      if (sessionToken == null) {
        throw Exception('You must be logged in to create a post');
      }

      // Build request body
      final requestBody = <String, dynamic>{
        'content': content,
      };

      // Add optional fields only if they are not null
      if (categoryId != null) {
        requestBody['category_id'] = categoryId;
      }
      if (locationId != null) {
        requestBody['location_id'] = locationId;
      }
      if (imageUrl != null) {
        requestBody['image_url'] = imageUrl;
      }
      if (enableMonthlySpotlight != null) {
        requestBody['enable_monthly_spotlight'] = enableMonthlySpotlight;
      }

      // Make the request
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $sessionToken',
        },
        body: jsonEncode(requestBody),
      );

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to create post';
        final errorDetails = body['details'] as String? ?? '';
        final fullErrorMessage = errorDetails.isNotEmpty 
            ? '$errorMessage: $errorDetails' 
            : errorMessage;
        throw Exception(fullErrorMessage);
      }

      return body;
    } catch (e) {
      // Convert technical HTTP errors to user-friendly messages
      final errorString = e.toString();
      
      // Handle network/connection errors
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      // Handle timeout errors
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      // Re-throw the original error if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      
      // Wrap other errors
      throw Exception(errorString);
    }
  }

  /// Create a comment or reply using the create-comment edge function
  /// 
  /// Parameters:
  /// - postId: The UUID of the post (required)
  /// - content: The comment content (required, 1-500 chars)
  /// - parentId: Optional parent comment ID for replies
  /// 
  /// Returns: Map with success, comment, and message fields
  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/create-comment');
    
    try {
      print('=== DEBUG: Starting createComment function ===');
      
      // Get current session access token
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';
      
      print('DEBUG: Session token exists: ${sessionToken != null}');
      if (sessionToken != null) {
        print('DEBUG: Session token length: ${sessionToken.length}');
      }
      
      if (sessionToken == null) {
        print('ERROR: User not logged in - no session token');
        throw Exception('You must be logged in to create a comment');
      }

      // Validate content length
      print('DEBUG: Content length: ${content.trim().length}');
      if (content.trim().isEmpty) {
        print('ERROR: Content is empty');
        throw Exception('Comment cannot be empty');
      }
      
      if (content.trim().length > 500) {
        print('ERROR: Content too long - ${content.trim().length} characters');
        throw Exception('Comment must be 500 characters or less');
      }

      // Validate postId
      print('DEBUG: Post ID: "$postId"');
      print('DEBUG: Post ID length: ${postId.length}');
      if (postId.isEmpty) {
        print('ERROR: Post ID is empty');
        throw Exception('Post ID is required');
      }

      // Validate UUID format (basic check)
      if (!postId.contains('-')) {
        print('ERROR: Invalid post ID format - missing hyphens');
        throw Exception('Invalid post ID format');
      }

      // Build request body
      final requestBody = <String, dynamic>{
        'post_id': postId,
        'content': content.trim(),
      };
      
      print('DEBUG: Base request body: $requestBody');

      // Add parent_id only if it's a reply
      if (parentId != null && parentId.isNotEmpty) {
        print('DEBUG: Parent ID provided: "$parentId"');
        // Validate parent_id format
        if (!parentId.contains('-')) {
          print('ERROR: Invalid parent comment ID format - missing hyphens');
          throw Exception('Invalid parent comment ID format');
        }
        requestBody['parent_id'] = parentId;
        print('DEBUG: Request body with parent_id: $requestBody');
      } else {
        print('DEBUG: No parent ID provided (top-level comment)');
      }

      // Headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $sessionToken',
      };
      
      print('DEBUG: Request headers: $headers');

      // Log request for debugging (remove in production)
      print('=== SENDING REQUEST TO EDGE FUNCTION ===');
      print('URL: $uri');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: ${jsonEncode(requestBody)}');
      print('========================================');

      // Make the request
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('=== RESPONSE FROM EDGE FUNCTION ===');
      print('Status Code: ${resp.statusCode}');
      print('Headers: ${resp.headers}');
      print('Body: ${resp.body}');
      print('===================================');

      // Handle empty response
      if (resp.body.isEmpty) {
        print('ERROR: Empty response from server');
        throw Exception('Empty response from server');
      }

      // Try to parse JSON response
      Map<String, dynamic> body;
      try {
        body = jsonDecode(resp.body) as Map<String, dynamic>;
        print('DEBUG: Parsed response body: $body');
      } catch (parseError) {
        print('ERROR: Failed to parse JSON response: $parseError');
        print('Raw response body: "${resp.body}"');
        throw Exception('Invalid response format from server');
      }

      if (resp.statusCode >= 400) {
        print('ERROR: HTTP ${resp.statusCode} received from server');
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to create comment';
        print('ERROR: Server error message: "$errorMessage"');
        // Handle specific error cases
        if (errorMessage.toString().contains('Post not found')) {
          print('ERROR: Post not found on server');
          throw Exception('Post not found. It may have been deleted.');
        }
        throw Exception('HTTP ${resp.statusCode}: $errorMessage');
      }

      print('=== SUCCESS: Comment created successfully ===');
      return body;
    } catch (e) {
      print('=== CATCH BLOCK: Exception caught ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: ${e.toString()}');
      
      // Log error for debugging (remove in production)
      print('Create comment error: ${e.toString()}');
      
      // Convert technical HTTP errors to user-friendly messages
      final errorString = e.toString();
      
      // Handle network/connection errors
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        print('ERROR: Network connection error detected');
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      // Handle timeout errors
      if (errorString.toLowerCase().contains('timeout')) {
        print('ERROR: Timeout error detected');
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      // Re-throw the original error if it's already an Exception with a message
      if (e is Exception) {
        print('ERROR: Re-throwing original exception');
        rethrow;
      }
      
      // Wrap other errors
      print('ERROR: Wrapping unknown error type');
      throw Exception(errorString);
    }
  }

  /// Fetch categories from the database
  /// Returns a map of category name to category ID
  Future<Map<String, String>> getCategories() async {
    try {
      final response = await _supabaseClient
          .from('categories')
          .select('id, name')
          .eq('is_active', true);

      final categories = <String, String>{};
      if (response != null) {
        // Supabase returns List<Map<String, dynamic>> directly
        if (response is List) {
          for (var category in response) {
            if (category is Map<String, dynamic>) {
              final name = category['name'] as String?;
              final id = category['id'] as String?;
              if (name != null && id != null) {
                categories[name] = id;
              }
            }
          }
        }
      }
      return categories;
    } catch (e) {
      // Return empty map if fetch fails
      return {};
    }
  }

  /// Fetch locations from the database
  /// Returns a map of location name to location ID
  Future<Map<String, String>> getLocations() async {
    try {
      final response = await _supabaseClient
          .from('locations')
          .select('id, name')
          .eq('is_active', true);

      final locations = <String, String>{};
      if (response != null) {
        // Supabase returns List<Map<String, dynamic>> directly
        if (response is List) {
          for (var location in response) {
            if (location is Map<String, dynamic>) {
              final name = location['name'] as String?;
              final id = location['id'] as String?;
              if (name != null && id != null) {
                locations[name] = id;
              }
            }
          }
        }
      }
      return locations;
    } catch (e) {
      // Return empty map if fetch fails
      return {};
    }
  }

  /// Fetch feed posts using the get-feed edge function
  /// 
  /// Parameters:
  /// - sort: "hot", "top", or "latest" (default: "hot")
  /// - limit: Number of posts per page (default: 20, max: 100)
  /// - offset: Pagination offset (default: 0)
  /// - categoryId: Optional category UUID filter
  /// - locationId: Optional location UUID filter
  /// - timeFilter: Optional time filter for "top" sort ("all", "day", "week", "month")
  /// 
  /// Returns: Map with success, posts array, and pagination metadata
  Future<Map<String, dynamic>> getFeed({
    String sort = 'hot',
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String? locationId,
    String timeFilter = 'all',
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-feed');
    
    try {
      // Get current session access token (optional - feed can be viewed without auth)
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Build query parameters
      final queryParams = <String, String>{
        'sort': sort,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'time_filter': timeFilter,
      };

      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }
      if (locationId != null) {
        queryParams['location_id'] = locationId;
      }

      final uriWithParams = uri.replace(queryParameters: queryParams);

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      // Make the request
      final resp = await http.get(uriWithParams, headers: headers);

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to fetch feed';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      // Convert technical HTTP errors to user-friendly messages
      final errorString = e.toString();
      
      // Handle network/connection errors
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      // Handle timeout errors
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      // Re-throw the original error if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      
      // Wrap other errors
      throw Exception(errorString);
    }
  }

  /// Get top post using the get-top-post edge function
  /// 
  /// Parameters:
  /// - period: "all_time", "week", "month", or "year" (default: "all_time")
  /// - includeStats: Whether to include statistics (default: false)
  /// 
  /// Returns: Map with success, top_post, period, and optional stats
  Future<Map<String, dynamic>> getTopPost({
    String period = 'all_time',
    bool includeStats = false,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-top-post');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final requestBody = <String, dynamic>{
        'period': period,
        'include_stats': includeStats,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final resp = await http.post(uri, headers: headers, body: jsonEncode(requestBody));

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['message'] ?? body['error'] ?? 'Failed to fetch top post';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Get hottest post using the get-hottest-post edge function
  /// 
  /// Parameters:
  /// - timeframe: "today", "week", or "custom" (default: "today")
  /// - customHours: Required if timeframe is "custom"
  /// - includeComparison: Whether to include comparison data (default: false)
  /// 
  /// Returns: Map with success, hottest_post, timeframe, and optional comparison
  Future<Map<String, dynamic>> getHottestPost({
    String timeframe = 'today',
    int? customHours,
    bool includeComparison = false,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-hottest-post');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      final requestBody = <String, dynamic>{
        'timeframe': timeframe,
        'include_comparison': includeComparison,
      };

      if (timeframe == 'custom' && customHours != null) {
        requestBody['custom_hours'] = customHours;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final resp = await http.post(uri, headers: headers, body: jsonEncode(requestBody));

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['message'] ?? body['error'] ?? 'Failed to fetch hottest post';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Get hot topic using the get-hot-topic edge function
  /// 
  /// Parameters:
  /// - includePosts: Whether to include posts (default: false)
  /// - sort: "hot", "top", or "latest" (default: "hot")
  /// - limit: Number of posts per page if includePosts is true (default: 20)
  /// - offset: Pagination offset if includePosts is true (default: 0)
  /// 
  /// Returns: Map with success, hot_topic, and optional posts array
  Future<Map<String, dynamic>> getHotTopic({
    bool includePosts = false,
    String sort = 'hot',
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-hot-topic');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Use GET method with query parameters
      final queryParams = <String, String>{
        'include_posts': includePosts.toString(),
        'sort': sort,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final uriWithParams = uri.replace(queryParameters: queryParams);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final resp = await http.get(uriWithParams, headers: headers);

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['message'] ?? body['error'] ?? 'Failed to fetch hot topic';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Get post details using the get-post edge function
  /// 
  /// Parameters:
  /// - postId: The UUID of the post (required)
  /// 
  /// Returns: Map with success and post object
  Future<Map<String, dynamic>> getPost({
    required String postId,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-post');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Use GET method with query parameter
      final queryParams = <String, String>{
        'post_id': postId,
      };

      final uriWithParams = uri.replace(queryParameters: queryParams);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final resp = await http.get(uriWithParams, headers: headers);

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to fetch post';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Get user profile using the get-profile edge function
  /// 
  /// Parameters:
  /// - userId: Optional user ID (if null, uses current user)
  /// - includePosts: Whether to include user's posts (default: false)
  /// - limit: Number of posts per page if includePosts is true (default: 20)
  /// - offset: Pagination offset if includePosts is true (default: 0)
  /// 
  /// Returns: Map with success, profile, and optional posts array
  Future<Map<String, dynamic>> getProfile({
    String? userId,
    bool includePosts = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-profile');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Use GET method with query parameters
      final queryParams = <String, String>{
        'include_posts': includePosts.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final uriWithParams = uri.replace(queryParameters: queryParams);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final resp = await http.get(uriWithParams, headers: headers);

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['message'] ?? body['error'] ?? 'Failed to fetch profile';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Get comments for a post using the get-comments edge function
  /// 
  /// Parameters:
  /// - postId: The UUID of the post (required)
  /// - limit: Number of comments per page (default: 20)
  /// - offset: Pagination offset (default: 0)
  /// - parentId: Optional parent comment ID for nested comments
  /// 
  /// Returns: Map with success, comments array, and pagination metadata
  Future<Map<String, dynamic>> getComments({
    required String postId,
    int limit = 20,
    int offset = 0,
    String? parentId,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-comments');
    
    try {
      print('=== DEBUG: Starting getComments function ===');
      print('DEBUG: Post ID: $postId');
      print('DEBUG: Limit: $limit');
      print('DEBUG: Offset: $offset');
      print('DEBUG: Parent ID: $parentId');
      
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Build request body (POST method with JSON body as per edge function)
      final requestBody = <String, dynamic>{
        'post_id': postId,
        'limit': limit,
        'offset': offset,
      };

      if (parentId != null) {
        requestBody['parent_id'] = parentId;
      }

      print('DEBUG: Request body: $requestBody');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
      };

      if (sessionToken != null) {
        headers['Authorization'] = 'Bearer $sessionToken';
        print('DEBUG: Authorization header set with Bearer token');
      } else {
        print('DEBUG: No session token available');
      }

      print('DEBUG: Headers: $headers');
      print('DEBUG: URL: $uri');

      // Use POST method with JSON body (as per edge function implementation)
      final resp = await http.post(uri, headers: headers, body: jsonEncode(requestBody));
      
      print('=== RESPONSE FROM EDGE FUNCTION ===');
      print('Status Code: ${resp.statusCode}');
      print('Headers: ${resp.headers}');
      print('Body: ${resp.body}');
      print('===================================');

      // Handle empty response
      if (resp.body.isEmpty) {
        print('ERROR: Empty response from server');
        throw Exception('Empty response from server');
      }

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;
      print('DEBUG: Parsed response body: $body');

      if (resp.statusCode >= 400) {
        print('ERROR: HTTP ${resp.statusCode} received from server');
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to fetch comments';
        final errorDetails = body['details'] as String? ?? '';
        final fullErrorMessage = errorDetails.isNotEmpty 
            ? '$errorMessage: $errorDetails' 
            : errorMessage;
        print('ERROR: Server error message: "$errorMessage"');
        print('ERROR: Server error details: "$errorDetails"');
        throw Exception('HTTP ${resp.statusCode}: $fullErrorMessage');
      }

      print('=== SUCCESS: Comments fetched successfully ===');
      return body;
    } catch (e) {
      print('=== CATCH BLOCK: Exception caught ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: ${e.toString()}');
      
      // Log error for debugging (remove in production)
      print('Get comments error: ${e.toString()}');
      
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        print('ERROR: Network connection error detected');
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        print('ERROR: Timeout error detected');
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        print('ERROR: Re-throwing original exception');
        rethrow;
      }
      
      print('ERROR: Wrapping unknown error type');
      throw Exception(errorString);
    }
  }

  /// Vote on a post using the vote-post edge function
  /// 
  /// Parameters:
  /// - postId: The UUID of the post (required)
  /// - voteType: "upvote", "downvote", or "remove" (required)
  /// 
  /// Returns: Map with success, message, upvote_count, downvote_count, net_score, and user_vote
  Future<Map<String, dynamic>> votePost({
    required String postId,
    required String voteType,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/vote-post');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      if (sessionToken == null) {
        throw Exception('You must be logged in to vote on posts');
      }

      final requestBody = <String, dynamic>{
        'post_id': postId,
        'vote_type': voteType,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $sessionToken',
      };

      // Add logging for debugging
      print('Sending vote request:');
      print('URL: $uri');
      print('Headers: $headers');
      print('Body: $requestBody');

      final resp = await http.post(uri, headers: headers, body: jsonEncode(requestBody));

      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to vote on post';
        throw Exception('HTTP ${resp.statusCode}: $errorMessage');
      }

      return body;
    } catch (e) {
      print('Vote error: ${e.toString()}');
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Report a post using the report-post edge function
  /// 
  /// Parameters:
  /// - postId: The UUID of the post (required)
  /// - reason: The reason for reporting (required)
  /// - description: Optional additional details (10-500 characters)
  /// 
  /// Returns: Map with success, message, and report_id fields
  Future<Map<String, dynamic>> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/report-post');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      if (sessionToken == null) {
        throw Exception('You must be logged in to report posts');
      }

      final requestBody = <String, dynamic>{
        'post_id': postId,
        'reason': reason,
      };

      // Add description only if provided
      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $sessionToken',
      };

      final resp = await http.post(uri, headers: headers, body: jsonEncode(requestBody));

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to submit report';
        throw Exception(errorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }

  /// Delete a post using the delete-post edge function
  /// 
  /// Parameters:
  /// - postId: The UUID of the post to delete (required)
  /// 
  /// Returns: Map with success, message, and post_id fields
  Future<Map<String, dynamic>> deletePost({
    required String postId,
  }) async {
    final uri = Uri.parse('https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/delete-post');
    
    try {
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      if (sessionToken == null) {
        throw Exception('You must be logged in to delete posts');
      }

      final requestBody = <String, dynamic>{
        'post_id': postId,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $sessionToken',
      };

      final resp = await http.post(uri, headers: headers, body: jsonEncode(requestBody));

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to delete post';
        final errorDetails = body['details'] as String? ?? '';
        final fullErrorMessage = errorDetails.isNotEmpty 
            ? '$errorMessage: $errorDetails' 
            : errorMessage;
        throw Exception(fullErrorMessage);
      }

      return body;
    } catch (e) {
      final errorString = e.toString();
      
      if (errorString.toLowerCase().contains('xmlhttprequest') ||
          errorString.toLowerCase().contains('socketexception') ||
          errorString.toLowerCase().contains('failed host lookup') ||
          errorString.toLowerCase().contains('connection refused') ||
          errorString.toLowerCase().contains('network is unreachable')) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      
      if (errorString.toLowerCase().contains('timeout')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception(errorString);
    }
  }
}