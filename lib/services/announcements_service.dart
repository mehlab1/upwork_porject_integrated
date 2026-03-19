import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementsService {
  // ── Singleton so the cache is shared across the entire app ──────────────────
  static final AnnouncementsService _instance = AnnouncementsService._internal();
  factory AnnouncementsService() => _instance;
  AnnouncementsService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ── In-memory cache ──────────────────────────────────────────────────────────
  static const Duration _cacheTTL = Duration(minutes: 5);
  List<Map<String, dynamic>>? _cachedAnnouncements;
  DateTime? _cacheTime;
  Future<List<Map<String, dynamic>>>? _inflightRequest;

  /// Whether cached data is still fresh.
  bool get _isCacheValid =>
      _cachedAnnouncements != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTTL;

  /// Call this as soon as the user *taps* the Announcement tile so the network
  /// request starts during the navigation animation, not after it finishes.
  void prefetch() {
    if (_isCacheValid) return;         // already fresh – nothing to do
    if (_inflightRequest != null) return; // already in-flight
    _inflightRequest = _fetchFromNetwork();
  }

  /// Invalidates the cache (call after creating / updating an announcement).
  void invalidateCache() {
    _cachedAnnouncements = null;
    _cacheTime = null;
    _inflightRequest = null;
  }

  Future<List<Map<String, dynamic>>> getAnnouncements({
    int limit = 50,
    int offset = 0,
  }) async {
    // 1. Return instantly if cache is still fresh
    if (_isCacheValid) {
      debugPrint('[AnnouncementsService] returning cached data');
      return _cachedAnnouncements!;
    }

    // 2. Re-use an already in-flight request (avoids duplicate network calls)
    _inflightRequest ??= _fetchFromNetwork(limit: limit, offset: offset);

    try {
      final result = await _inflightRequest!;
      return result;
    } finally {
      _inflightRequest = null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromNetwork({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'get-announcements',
        queryParameters: {
          'limit': '$limit',
          'offset': '$offset',
        },
      );

      debugPrint('[AnnouncementsService] status=${response.status}');
      debugPrint('[AnnouncementsService] raw=${response.data}');

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to fetch announcements');
      }

      final data = response.data;
      final result = data == null ? <Map<String, dynamic>>[] : _extractList(data);

      // Store in cache
      _cachedAnnouncements = result;
      _cacheTime = DateTime.now();

      return result;
    } catch (e) {
      debugPrint('[AnnouncementsService] error: $e');
      throw Exception('Announcements error: $e');
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    // Raw list
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    // Wrapped: { data: [...] } or { success: true, data: [...] }
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) {
        return List<Map<String, dynamic>>.from(inner);
      }
      // Try 'announcements' key as fallback
      final ann = data['announcements'];
      if (ann is List) {
        return List<Map<String, dynamic>>.from(ann);
      }
    }
    return [];
  }
}