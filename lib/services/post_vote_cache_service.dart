import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/post_vote_utils.dart';

/// Persists the current user's post votes locally (survives refresh / app restart).
class PostVoteCacheService {
  PostVoteCacheService._();
  static final PostVoteCacheService instance = PostVoteCacheService._();

  static const String _prefsKey = 'post_vote_cache_v1';

  Map<String, String>? _cache;

  Future<void> initialize() async {
    await _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null || stored.isEmpty) {
      _cache = {};
      return;
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map) {
        _cache = decoded.map(
          (key, value) => MapEntry(
            key.toString(),
            value?.toString() ?? '',
          ),
        );
      } else {
        _cache = {};
      }
    } catch (_) {
      _cache = {};
    }
  }

  Future<void> _persist() async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_cache));
  }

  String? getVoteSync(String postId) {
    if (_cache == null || postId.isEmpty) return null;
    return normalizeUserVoteString(_cache![postId]);
  }

  /// For feed hydration only. Prefer API when present; otherwise use cached vote.
  /// After vote-post, apply the API response directly and call [setVote] (no cache fallback).
  String? resolveVote({String? postId, String? apiVote}) {
    final fromApi = normalizeUserVoteString(apiVote);
    if (fromApi != null) return fromApi;
    if (postId == null || postId.isEmpty) return null;
    return getVoteSync(postId);
  }

  Future<void> setVote(String postId, String? vote) async {
    if (postId.isEmpty) return;
    await _ensureLoaded();
    final normalized = normalizeUserVoteString(vote);
    if (normalized == null) {
      _cache!.remove(postId);
    } else {
      _cache![postId] = normalized;
    }
    await _persist();
  }

  Future<void> clear() async {
    _cache = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
