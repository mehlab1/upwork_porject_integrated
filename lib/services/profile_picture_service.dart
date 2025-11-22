import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for profile picture upload operations
/// Handles uploading profile pictures to the upload-profile-picture edge function
class ProfilePictureService {
  ProfilePictureService();

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Detect MIME type from file extension or image bytes
  String _detectMimeType(String fileName, Uint8List? imageBytes) {
    // First, try to detect from file extension
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        // If extension doesn't match, try to detect from magic numbers
        if (imageBytes != null && imageBytes.length >= 4) {
          // JPEG: FF D8 FF
          if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8 && imageBytes[2] == 0xFF) {
            return 'image/jpeg';
          }
          // PNG: 89 50 4E 47
          if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && 
              imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
            return 'image/png';
          }
          // GIF: 47 49 46 38
          if (imageBytes[0] == 0x47 && imageBytes[1] == 0x49 && 
              imageBytes[2] == 0x46 && imageBytes[3] == 0x38) {
            return 'image/gif';
          }
          // WebP: Check for RIFF...WEBP
          if (imageBytes.length >= 12 &&
              imageBytes[0] == 0x52 && imageBytes[1] == 0x49 &&
              imageBytes[2] == 0x46 && imageBytes[3] == 0x46 &&
              imageBytes[8] == 0x57 && imageBytes[9] == 0x45 &&
              imageBytes[10] == 0x42 && imageBytes[11] == 0x50) {
            return 'image/webp';
          }
        }
        // Default to JPEG if we can't detect
        return 'image/jpeg';
    }
  }

  /// Upload profile picture using multipart/form-data
  /// 
  /// Returns: Map with success (bool) and message (String)
  /// Throws Exception on error
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    final uri = Uri.parse(
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/upload-profile-picture',
    );

    try {
      print('=== DEBUG: Uploading profile picture ===');
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['apikey'] = anonKey;
      if (sessionToken != null) {
        request.headers['Authorization'] = 'Bearer $sessionToken';
      }

      // Add file to request
      final fileName = imageFile.path.split('/').last;
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName,
      );

      request.files.add(multipartFile);

      print('DEBUG: URL: $uri');
      print('DEBUG: File: $fileName (${fileLength} bytes)');
      print('DEBUG: Headers: apikey=***masked***, Authorization=Bearer ***masked***');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== RESPONSE FROM EDGE FUNCTION (upload-profile-picture) ===');
      print('Status Code: ${response.statusCode}');
      print('Response header keys: ${response.headers.keys.toList()}');
      print('Body: ${response.body}');
      print('===================================');

      final parsed = jsonDecode(response.body ?? '{}') as Map<String, dynamic>;

      if (response.statusCode >= 400) {
        final errorMessage =
            parsed['message'] ?? parsed['error'] ?? 'Server error';
        print(
          'ERROR: Function upload-profile-picture returned ${response.statusCode}: $errorMessage',
        );
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      print('ERROR: Exception while uploading profile picture - ${e.toString()}');
      rethrow;
    }
  }

  /// Upload profile picture from bytes using multipart/form-data
  /// This method is more reliable when working with image_picker XFile
  /// 
  /// Parameters:
  /// - imageBytes: The image file as Uint8List bytes
  /// - fileName: The filename to use for the upload
  /// - mimeType: Optional MIME type. If not provided, will be detected from filename or bytes
  /// 
  /// Returns: Map with success (bool) and message (String)
  /// Throws Exception on error
  Future<Map<String, dynamic>> uploadProfilePictureFromBytes(
    Uint8List imageBytes,
    String fileName, {
    String? mimeType,
  }) async {
    final uri = Uri.parse(
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/upload-profile-picture',
    );

    try {
      print('=== DEBUG: Uploading profile picture from bytes ===');
      final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
      final anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['apikey'] = anonKey;
      if (sessionToken != null) {
        request.headers['Authorization'] = 'Bearer $sessionToken';
      }

      // Detect MIME type from parameter, filename, or bytes
      final detectedMimeType = mimeType ?? _detectMimeType(fileName, imageBytes);
      
      print('DEBUG: Detected MIME type: $detectedMimeType for file: $fileName');
      
      // Create multipart file from bytes with proper content-type
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType.parse(detectedMimeType),
      );

      request.files.add(multipartFile);

      print('DEBUG: URL: $uri');
      print('DEBUG: File: $fileName (${imageBytes.length} bytes)');
      print('DEBUG: Headers: apikey=***masked***, Authorization=Bearer ***masked***');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== RESPONSE FROM EDGE FUNCTION (upload-profile-picture) ===');
      print('Status Code: ${response.statusCode}');
      print('Response header keys: ${response.headers.keys.toList()}');
      print('Body: ${response.body}');
      print('===================================');

      final parsed = jsonDecode(response.body ?? '{}') as Map<String, dynamic>;

      if (response.statusCode >= 400) {
        final errorMessage =
            parsed['message'] ?? parsed['error'] ?? 'Server error';
        print(
          'ERROR: Function upload-profile-picture returned ${response.statusCode}: $errorMessage',
        );
        throw Exception(errorMessage);
      }

      return parsed;
    } catch (e) {
      print('ERROR: Exception while uploading profile picture - ${e.toString()}');
      rethrow;
    }
  }
}

