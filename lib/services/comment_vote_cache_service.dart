import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/post_vote_utils.dart';

/// Persists the current user's comment votes locally (survives refresh / app restart).
class CommentVoteCacheService {
  CommentVoteCacheService._();
  static final CommentVoteCacheService instance = CommentVoteCacheService._();

  static const String _prefsKey = 'comment_vote_cache_v1';

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

  String? getVoteSync(String commentId) {
    if (_cache == null || commentId.isEmpty) return null;
    return normalizeUserVoteString(_cache![commentId]);
  }

  /// For comment hydration only. Prefer API when present; otherwise use cached vote.
  /// After vote-comment, apply the API response directly and call [setVote] (no cache fallback).
  String? resolveVote({String? commentId, String? apiVote}) {
    final fromApi = normalizeUserVoteString(apiVote);
    if (fromApi != null) return fromApi;
    if (commentId == null || commentId.isEmpty) return null;
    return getVoteSync(commentId);
  }

  int resolveUserVoteInt({required String commentId, String? apiVote}) {
    return userVoteStringToInt(
      resolveVote(commentId: commentId, apiVote: apiVote),
    );
  }

  Future<void> setVote(String commentId, String? vote) async {
    if (commentId.isEmpty) return;
    await _ensureLoaded();
    final normalized = normalizeUserVoteString(vote);
    if (normalized == null) {
      _cache!.remove(commentId);
    } else {
      _cache![commentId] = normalized;
    }
    await _persist();
  }

  Future<void> clear() async {
    _cache = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
