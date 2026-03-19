import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetch suspended users via `get-suspended-users` edge function.
class SuspendedUsersService {
  // ── Singleton so the cache is shared across the entire app ──────────────────
  static final SuspendedUsersService _instance = SuspendedUsersService._internal();
  factory SuspendedUsersService() => _instance;
  SuspendedUsersService._internal();

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // ── In-memory cache ──────────────────────────────────────────────────────────
  static const Duration _cacheTTL = Duration(minutes: 3);
  List<Map<String, dynamic>>? _cachedUsers;
  DateTime? _cacheTime;
  Future<List<Map<String, dynamic>>>? _inflightRequest;

  bool get _isCacheValid =>
      _cachedUsers != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTTL;

  /// Fire this as soon as the screen is about to open so the network request
  /// runs during the navigation animation, not after it finishes.
  void prefetch() {
    if (_isCacheValid) return;
    if (_inflightRequest != null) return;
    _inflightRequest = _fetchFromNetwork();
  }

  /// Invalidates the cache (call after unsuspending a user).
  void invalidateCache() {
    _cachedUsers = null;
    _cacheTime = null;
    _inflightRequest = null;
  }

  static const String _baseUrl =
      'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY';

  Future<List<Map<String, dynamic>>> getSuspendedUsers({
    int limit = 50,
    int offset = 0,
  }) async {
    // 1. Return instantly if cache is still fresh.
    if (_isCacheValid) {
      debugPrint('[SuspendedUsersService] returning cached data');
      return _cachedUsers!;
    }

    // 2. Re-use an already in-flight request.
    _inflightRequest ??= _fetchFromNetwork(limit: limit, offset: offset);

    try {
      return await _inflightRequest!;
    } finally {
      _inflightRequest = null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromNetwork({
    int limit = 50,
    int offset = 0,
  }) async {
    final sessionToken = _supabaseClient.auth.currentSession?.accessToken;
    if (sessionToken == null) {
      throw Exception('No active session');
    }

    final uri = Uri.parse('$_baseUrl/get-suspended-users').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final resp = await http.get(uri, headers: <String, String>{
      'apikey': _anonKey,
      'Authorization': 'Bearer $sessionToken',
    });

    final dynamic decoded = jsonDecode(resp.body.isEmpty ? 'null' : resp.body);

    if (resp.statusCode >= 400) {
      String message = 'Failed to fetch suspended users';
      if (decoded is Map) {
        message = (decoded['message'] ?? decoded['error'] ?? message).toString();
      }
      debugPrint('[SuspendedUsersService] ${resp.statusCode}: $message');
      throw Exception(message);
    }

    // Backend may return either a raw array or a wrapper object.
    final raw = decoded is Map ? (decoded['users'] ?? decoded['data']) : decoded;
    final List<Map<String, dynamic>> result = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    _cachedUsers = result;
    _cacheTime = DateTime.now();
    return result;
  }
}

