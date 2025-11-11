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
      print('[POST_SERVICE] Request body: ${jsonEncode(requestBody)}');
      print('[POST_SERVICE] Has session token: ${sessionToken != null}');
      
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $sessionToken',
        },
        body: jsonEncode(requestBody),
      );

      print('[POST_SERVICE] Response status: ${resp.statusCode}');
      print('[POST_SERVICE] Response body: ${resp.body}');

      final body = jsonDecode(resp.body ?? '{}') as Map<String, dynamic>;

      if (resp.statusCode >= 400) {
        final errorMessage = body['error'] ?? body['message'] ?? 'Failed to create post';
        print('[POST_SERVICE] Error: $errorMessage');
        throw Exception(errorMessage);
      }

      print('[POST_SERVICE] Success: ${body['success']}');
      return body;
    } catch (e) {
      print('[POST_SERVICE] Exception caught: $e');
      rethrow;
    }
  }

  /// Fetch categories from the database
  /// Returns a map of category name to category ID
  Future<Map<String, String>> getCategories() async {
    try {
      print('[POST_SERVICE] Fetching categories...');
      final response = await _supabaseClient
          .from('categories')
          .select('id, name')
          .eq('is_active', true);

      print('[POST_SERVICE] Categories response type: ${response.runtimeType}');
      print('[POST_SERVICE] Categories response: $response');

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
                print('[POST_SERVICE] Added category: $name -> $id');
              }
            }
          }
        }
      }
      print('[POST_SERVICE] Final categories map: $categories');
      return categories;
    } catch (e, stackTrace) {
      print('[POST_SERVICE] Error fetching categories: $e');
      print('[POST_SERVICE] Stack trace: $stackTrace');
      // Return empty map if fetch fails
      return {};
    }
  }
}

