import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ─── Central App Cache ───────────────────────────────────────────────────────
///
/// A single singleton that holds short-lived, in-memory cached responses for
/// every Supabase edge-function that is called when navigating to a new screen.
///
/// Usage pattern (in a settings tile's onTap):
///   AppCache().prefetchHotPost();        // fire immediately on tap
///   Navigator.push(…HotPostScreen…);    // navigate – data arrives in parallel
///
/// Usage pattern (in a screen's initState):
///   _future = AppCache().getHotPost();  // returns cached data or waits for in-flight
///
/// ─────────────────────────────────────────────────────────────────────────────

class _CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  _CacheEntry(this.data) : cachedAt = DateTime.now();
  bool isValid(Duration ttl) => DateTime.now().difference(cachedAt) < ttl;
}

class AppCache {
  // ── Singleton ───────────────────────────────────────────────────────────────
  static final AppCache _instance = AppCache._internal();
  factory AppCache() => _instance;
  AppCache._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ── TTLs ────────────────────────────────────────────────────────────────────
  static const Duration _shortTTL  = Duration(minutes: 3);
  static const Duration _mediumTTL = Duration(minutes: 5);

  // ── Cache stores ────────────────────────────────────────────────────────────
  _CacheEntry<Map<String, dynamic>>?        _hotPost;
  _CacheEntry<Map<String, dynamic>>?        _topPost;
  _CacheEntry<Map<String, dynamic>>?        _wodPost;
  _CacheEntry<Map<String, dynamic>>?        _notificationsPage;

  // Queue screens (initial "new" tab) — posts
  _CacheEntry<Map<String, dynamic>>?        _modQueuePostsNew;
  _CacheEntry<Map<String, dynamic>>?        _jmQueuePostsNew;
  _CacheEntry<Map<String, dynamic>>?        _jmQueuePostsHistory;
  _CacheEntry<Map<String, dynamic>>?        _ccQueuePostsNew;

  // Queue screens (history tab) — posts
  _CacheEntry<Map<String, dynamic>>?        _modQueuePostsHistory;

  // Queue screens (initial "new" tab) — comments
  _CacheEntry<Map<String, dynamic>>?        _modQueueCommentsNew;
  _CacheEntry<Map<String, dynamic>>?        _jmQueueCommentsNew;
  _CacheEntry<Map<String, dynamic>>?        _jmQueueCommentsHistory;
  _CacheEntry<Map<String, dynamic>>?        _ccQueueCommentsNew;

  // Queue screens (history tab) — comments
  _CacheEntry<Map<String, dynamic>>?        _modQueueCommentsHistory;

  // Queue screens — users (new + history)
  _CacheEntry<Map<String, dynamic>>?        _modQueueUsersNew;
  _CacheEntry<Map<String, dynamic>>?        _modQueueUsersHistory;

  // Post-status screens
  _CacheEntry<Map<String, dynamic>>?        _hiddenPosts;
  _CacheEntry<Map<String, dynamic>>?        _warnedPosts;
  _CacheEntry<Map<String, dynamic>>?        _mutedPosts;
  _CacheEntry<Map<String, dynamic>>?        _duplicatedPosts;
  _CacheEntry<Map<String, dynamic>>?        _reportedPosts;
  _CacheEntry<Map<String, dynamic>>?        _flaggedPosts;

  // Account screens
  _CacheEntry<Map<String, dynamic>>?        _shadowBanUsers;
  _CacheEntry<Map<String, dynamic>>?        _bannedUsers;

  // Reviewer WOD dashboard
  _CacheEntry<Map<String, dynamic>>?        _wodDashboard;

  // ── In-flight dedup ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>>? _inflightHotPost;
  Future<Map<String, dynamic>>? _inflightTopPost;
  Future<Map<String, dynamic>>? _inflightWod;
  Future<Map<String, dynamic>>? _inflightNotifications;

  Future<Map<String, dynamic>>? _inflightModQueuePosts;
  Future<Map<String, dynamic>>? _inflightModQueuePostsHistory;
  Future<Map<String, dynamic>>? _inflightJmQueuePosts;
  Future<Map<String, dynamic>>? _inflightJmQueuePostsHistory;
  Future<Map<String, dynamic>>? _inflightCcQueuePosts;
  Future<Map<String, dynamic>>? _inflightModQueueComments;
  Future<Map<String, dynamic>>? _inflightModQueueCommentsHistory;
  Future<Map<String, dynamic>>? _inflightJmQueueComments;
  Future<Map<String, dynamic>>? _inflightJmQueueCommentsHistory;
  Future<Map<String, dynamic>>? _inflightCcQueueComments;
  Future<Map<String, dynamic>>? _inflightModQueueUsersNew;
  Future<Map<String, dynamic>>? _inflightModQueueUsersHistory;
  Future<Map<String, dynamic>>? _inflightHiddenPosts;
  Future<Map<String, dynamic>>? _inflightWarnedPosts;
  Future<Map<String, dynamic>>? _inflightMutedPosts;
  Future<Map<String, dynamic>>? _inflightDuplicatedPosts;
  Future<Map<String, dynamic>>? _inflightReportedPosts;
  Future<Map<String, dynamic>>? _inflightFlaggedPosts;
  Future<Map<String, dynamic>>? _inflightShadowBanUsers;
  Future<Map<String, dynamic>>? _inflightBannedUsers;
  Future<Map<String, dynamic>>? _inflightWodDashboard;

  // ══════════════════════════════════════════════════════════════════════════
  // HOT POST
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchHotPost() {
    if (_hotPost?.isValid(_shortTTL) == true) return;
    if (_inflightHotPost != null) return;
    _inflightHotPost = _fetchHotPost();
  }

  Future<Map<String, dynamic>> getHotPost() async {
    if (_hotPost?.isValid(_shortTTL) == true) return _hotPost!.data;
    _inflightHotPost ??= _fetchHotPost();
    try {
      return await _inflightHotPost!;
    } finally {
      _inflightHotPost = null;
    }
  }

  Future<Map<String, dynamic>> _fetchHotPost() async {
    try {
      final resp = await _supabase.functions.invoke(
        'get-hottest-post',
        body: {'timeframe': 'today', 'include_comparison': true},
      );
      final raw = resp.data;
      final result = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      _hotPost = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getHotPost error: $e');
      return {};
    }
  }

  void invalidateHotPost() { _hotPost = null; _inflightHotPost = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // TOP POST
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchTopPost() {
    if (_topPost?.isValid(_shortTTL) == true) return;
    if (_inflightTopPost != null) return;
    _inflightTopPost = _fetchTopPost();
  }

  Future<Map<String, dynamic>> getTopPost() async {
    if (_topPost?.isValid(_shortTTL) == true) return _topPost!.data;
    _inflightTopPost ??= _fetchTopPost();
    try {
      return await _inflightTopPost!;
    } finally {
      _inflightTopPost = null;
    }
  }

  Future<Map<String, dynamic>> _fetchTopPost() async {
    try {
      final resp = await _supabase.functions.invoke(
        'get-top-post',
        method: HttpMethod.get,
      );
      final raw = resp.data;
      final result = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      _topPost = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getTopPost error: $e');
      return {};
    }
  }

  void invalidateTopPost() { _topPost = null; _inflightTopPost = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // WOD POST
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchWod() {
    if (_wodPost?.isValid(_shortTTL) == true) return;
    if (_inflightWod != null) return;
    _inflightWod = _fetchWod();
  }

  Future<Map<String, dynamic>> getWod() async {
    if (_wodPost?.isValid(_shortTTL) == true) return _wodPost!.data;
    _inflightWod ??= _fetchWod();
    try {
      return await _inflightWod!;
    } finally {
      _inflightWod = null;
    }
  }

  Future<Map<String, dynamic>> _fetchWod() async {
    try {
      final resp = await _supabase.functions.invoke(
        'get-wod-post',
        method: HttpMethod.get,
      );
      final raw = resp.data;
      final result = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      _wodPost = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getWod error: $e');
      return {};
    }
  }

  void invalidateWod() { _wodPost = null; _inflightWod = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS PAGE
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchNotifications() {
    if (_notificationsPage?.isValid(_shortTTL) == true) return;
    if (_inflightNotifications != null) return;
    _inflightNotifications = _fetchNotifications();
  }

  Future<Map<String, dynamic>> getNotificationsPage() async {
    if (_notificationsPage?.isValid(_shortTTL) == true) return _notificationsPage!.data;
    _inflightNotifications ??= _fetchNotifications();
    try {
      return await _inflightNotifications!;
    } finally {
      _inflightNotifications = null;
    }
  }

  Future<Map<String, dynamic>> _fetchNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase
          .from('notifications_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(0, 49);
      final result = <String, dynamic>{'notifications': resp};
      _notificationsPage = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getNotifications error: $e');
      return {};
    }
  }

  void invalidateNotifications() {
    _notificationsPage = null;
    _inflightNotifications = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOD QUEUE POSTS (initial "new" tab)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchModQueuePosts() {
    if (_modQueuePostsNew?.isValid(_shortTTL) == true) return;
    if (_inflightModQueuePosts != null) return;
    _inflightModQueuePosts = _fetchModQueuePosts();
  }

  Future<Map<String, dynamic>> getModQueuePosts() async {
    if (_modQueuePostsNew?.isValid(_shortTTL) == true) return _modQueuePostsNew!.data;
    _inflightModQueuePosts ??= _fetchModQueuePosts();
    try {
      return await _inflightModQueuePosts!;
    } finally {
      _inflightModQueuePosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchModQueuePosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-moderator-queue-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'new', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _modQueuePostsNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getModQueuePosts error: $e');
      return {};
    }
  }

  void invalidateModQueuePosts() { _modQueuePostsNew = null; _inflightModQueuePosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // MOD QUEUE POSTS HISTORY
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchModQueuePostsHistory() {
    if (_modQueuePostsHistory?.isValid(_shortTTL) == true) return;
    if (_inflightModQueuePostsHistory != null) return;
    _inflightModQueuePostsHistory = _fetchModQueuePostsHistory();
  }

  Future<Map<String, dynamic>> getModQueuePostsHistory() async {
    if (_modQueuePostsHistory?.isValid(_shortTTL) == true) return _modQueuePostsHistory!.data;
    _inflightModQueuePostsHistory ??= _fetchModQueuePostsHistory();
    try {
      return await _inflightModQueuePostsHistory!;
    } finally {
      _inflightModQueuePostsHistory = null;
    }
  }

  Future<Map<String, dynamic>> _fetchModQueuePostsHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-moderator-queue-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'history', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _modQueuePostsHistory = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getModQueuePostsHistory error: $e');
      return {};
    }
  }

  void invalidateModQueuePostsHistory() { _modQueuePostsHistory = null; _inflightModQueuePostsHistory = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // JM QUEUE POSTS (initial "new" tab)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchJmQueuePosts() {
    if (_jmQueuePostsNew?.isValid(_shortTTL) == true) return;
    if (_inflightJmQueuePosts != null) return;
    _inflightJmQueuePosts = _fetchJmQueuePosts();
  }

  Future<Map<String, dynamic>> getJmQueuePosts() async {
    if (_jmQueuePostsNew?.isValid(_shortTTL) == true) return _jmQueuePostsNew!.data;
    _inflightJmQueuePosts ??= _fetchJmQueuePosts();
    try {
      return await _inflightJmQueuePosts!;
    } finally {
      _inflightJmQueuePosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchJmQueuePosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-junior-moderator-queue-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'new', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _jmQueuePostsNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getJmQueuePosts error: $e');
      return {};
    }
  }

  void invalidateJmQueuePosts() { _jmQueuePostsNew = null; _inflightJmQueuePosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // JM QUEUE POSTS HISTORY
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchJmQueuePostsHistory() {
    if (_jmQueuePostsHistory?.isValid(_shortTTL) == true) return;
    if (_inflightJmQueuePostsHistory != null) return;
    _inflightJmQueuePostsHistory = _fetchJmQueuePostsHistory();
  }

  Future<Map<String, dynamic>> getJmQueuePostsHistory() async {
    if (_jmQueuePostsHistory?.isValid(_shortTTL) == true) return _jmQueuePostsHistory!.data;
    _inflightJmQueuePostsHistory ??= _fetchJmQueuePostsHistory();
    try {
      return await _inflightJmQueuePostsHistory!;
    } finally {
      _inflightJmQueuePostsHistory = null;
    }
  }

  Future<Map<String, dynamic>> _fetchJmQueuePostsHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-junior-moderator-queue-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'history', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _jmQueuePostsHistory = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getJmQueuePostsHistory error: \$e');
      return {};
    }
  }

  void invalidateJmQueuePostsHistory() { _jmQueuePostsHistory = null; _inflightJmQueuePostsHistory = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // CC QUEUE POSTS (initial "new" tab)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchCcQueuePosts() {
    if (_ccQueuePostsNew?.isValid(_shortTTL) == true) return;
    if (_inflightCcQueuePosts != null) return;
    _inflightCcQueuePosts = _fetchCcQueuePosts();
  }

  Future<Map<String, dynamic>> getCcQueuePosts() async {
    if (_ccQueuePostsNew?.isValid(_shortTTL) == true) return _ccQueuePostsNew!.data;
    _inflightCcQueuePosts ??= _fetchCcQueuePosts();
    try {
      return await _inflightCcQueuePosts!;
    } finally {
      _inflightCcQueuePosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchCcQueuePosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-content-curator-queue-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'new', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _ccQueuePostsNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getCcQueuePosts error: $e');
      return {};
    }
  }

  void invalidateCcQueuePosts() { _ccQueuePostsNew = null; _inflightCcQueuePosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // MOD QUEUE COMMENTS (initial "new" tab)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchModQueueCommentsNew() {
    if (_modQueueCommentsNew?.isValid(_shortTTL) == true) return;
    if (_inflightModQueueComments != null) return;
    _inflightModQueueComments = _fetchModQueueCommentsNew();
  }

  Future<Map<String, dynamic>> getModQueueCommentsNew() async {
    if (_modQueueCommentsNew?.isValid(_shortTTL) == true) return _modQueueCommentsNew!.data;
    _inflightModQueueComments ??= _fetchModQueueCommentsNew();
    try {
      return await _inflightModQueueComments!;
    } finally {
      _inflightModQueueComments = null;
    }
  }

  Future<Map<String, dynamic>> _fetchModQueueCommentsNew() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-moderator-queue-comments',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'new', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _modQueueCommentsNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getModQueueCommentsNew error: \$e');
      return {};
    }
  }

  void invalidateModQueueCommentsNew() { _modQueueCommentsNew = null; _inflightModQueueComments = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // MOD QUEUE COMMENTS HISTORY
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchModQueueCommentsHistory() {
    if (_modQueueCommentsHistory?.isValid(_shortTTL) == true) return;
    if (_inflightModQueueCommentsHistory != null) return;
    _inflightModQueueCommentsHistory = _fetchModQueueCommentsHistory();
  }

  Future<Map<String, dynamic>> getModQueueCommentsHistory() async {
    if (_modQueueCommentsHistory?.isValid(_shortTTL) == true) return _modQueueCommentsHistory!.data;
    _inflightModQueueCommentsHistory ??= _fetchModQueueCommentsHistory();
    try {
      return await _inflightModQueueCommentsHistory!;
    } finally {
      _inflightModQueueCommentsHistory = null;
    }
  }

  Future<Map<String, dynamic>> _fetchModQueueCommentsHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-moderator-queue-comments',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'history', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _modQueueCommentsHistory = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getModQueueCommentsHistory error: \$e');
      return {};
    }
  }

  void invalidateModQueueCommentsHistory() { _modQueueCommentsHistory = null; _inflightModQueueCommentsHistory = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // MOD QUEUE USERS (new + history)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchModQueueUsersNew() {
    if (_modQueueUsersNew?.isValid(_shortTTL) == true) return;
    if (_inflightModQueueUsersNew != null) return;
    _inflightModQueueUsersNew = _fetchModQueueUsersNew();
  }

  Future<Map<String, dynamic>> getModQueueUsersNew() async {
    if (_modQueueUsersNew?.isValid(_shortTTL) == true) return _modQueueUsersNew!.data;
    _inflightModQueueUsersNew ??= _fetchModQueueUsersNew();
    try {
      return await _inflightModQueueUsersNew!;
    } finally {
      _inflightModQueueUsersNew = null;
    }
  }

  Future<Map<String, dynamic>> _fetchModQueueUsersNew() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-moderator-queue-users',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'new', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _modQueueUsersNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getModQueueUsersNew error: \$e');
      return {};
    }
  }

  void invalidateModQueueUsersNew() { _modQueueUsersNew = null; _inflightModQueueUsersNew = null; }

  void prefetchModQueueUsersHistory() {
    if (_modQueueUsersHistory?.isValid(_shortTTL) == true) return;
    if (_inflightModQueueUsersHistory != null) return;
    _inflightModQueueUsersHistory = _fetchModQueueUsersHistory();
  }

  Future<Map<String, dynamic>> getModQueueUsersHistory() async {
    if (_modQueueUsersHistory?.isValid(_shortTTL) == true) return _modQueueUsersHistory!.data;
    _inflightModQueueUsersHistory ??= _fetchModQueueUsersHistory();
    try {
      return await _inflightModQueueUsersHistory!;
    } finally {
      _inflightModQueueUsersHistory = null;
    }
  }

  Future<Map<String, dynamic>> _fetchModQueueUsersHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-moderator-queue-users',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'history', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _modQueueUsersHistory = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getModQueueUsersHistory error: \$e');
      return {};
    }
  }

  void invalidateModQueueUsersHistory() { _modQueueUsersHistory = null; _inflightModQueueUsersHistory = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // JM QUEUE COMMENTS (initial "new" tab)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchJmQueueCommentsNew() {
    if (_jmQueueCommentsNew?.isValid(_shortTTL) == true) return;
    if (_inflightJmQueueComments != null) return;
    _inflightJmQueueComments = _fetchJmQueueCommentsNew();
  }

  Future<Map<String, dynamic>> getJmQueueCommentsNew() async {
    if (_jmQueueCommentsNew?.isValid(_shortTTL) == true) return _jmQueueCommentsNew!.data;
    _inflightJmQueueComments ??= _fetchJmQueueCommentsNew();
    try {
      return await _inflightJmQueueComments!;
    } finally {
      _inflightJmQueueComments = null;
    }
  }

  Future<Map<String, dynamic>> _fetchJmQueueCommentsNew() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-junior-moderator-queue-comments',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'new', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _jmQueueCommentsNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getJmQueueCommentsNew error: \$e');
      return {};
    }
  }

  void invalidateJmQueueCommentsNew() { _jmQueueCommentsNew = null; _inflightJmQueueComments = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // JM QUEUE COMMENTS HISTORY
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchJmQueueCommentsHistory() {
    if (_jmQueueCommentsHistory?.isValid(_shortTTL) == true) return;
    if (_inflightJmQueueCommentsHistory != null) return;
    _inflightJmQueueCommentsHistory = _fetchJmQueueCommentsHistory();
  }

  Future<Map<String, dynamic>> getJmQueueCommentsHistory() async {
    if (_jmQueueCommentsHistory?.isValid(_shortTTL) == true) return _jmQueueCommentsHistory!.data;
    _inflightJmQueueCommentsHistory ??= _fetchJmQueueCommentsHistory();
    try {
      return await _inflightJmQueueCommentsHistory!;
    } finally {
      _inflightJmQueueCommentsHistory = null;
    }
  }

  Future<Map<String, dynamic>> _fetchJmQueueCommentsHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-junior-moderator-queue-comments',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_queue_type': 'history', 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _jmQueueCommentsHistory = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getJmQueueCommentsHistory error: \$e');
      return {};
    }
  }

  void invalidateJmQueueCommentsHistory() { _jmQueueCommentsHistory = null; _inflightJmQueueCommentsHistory = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // CC QUEUE COMMENTS (initial "new" tab)
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchCcQueueCommentsNew() {
    if (_ccQueueCommentsNew?.isValid(_shortTTL) == true) return;
    if (_inflightCcQueueComments != null) return;
    _inflightCcQueueComments = _fetchCcQueueCommentsNew();
  }

  Future<Map<String, dynamic>> getCcQueueCommentsNew() async {
    if (_ccQueueCommentsNew?.isValid(_shortTTL) == true) return _ccQueueCommentsNew!.data;
    _inflightCcQueueComments ??= _fetchCcQueueCommentsNew();
    try {
      return await _inflightCcQueueComments!;
    } finally {
      _inflightCcQueueComments = null;
    }
  }

  Future<Map<String, dynamic>> _fetchCcQueueCommentsNew() async {
    try {
      final resp = await _supabase.functions.invoke(
        'get-content-curator-queue-comments',
        method: HttpMethod.get,
        queryParameters: {'queue_type': 'new', 'limit': '20', 'offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _ccQueueCommentsNew = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getCcQueueCommentsNew error: \$e');
      return {};
    }
  }

  void invalidateCcQueueCommentsNew() { _ccQueueCommentsNew = null; _inflightCcQueueComments = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // HIDDEN POSTS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchHiddenPosts() {
    if (_hiddenPosts?.isValid(_shortTTL) == true) return;
    if (_inflightHiddenPosts != null) return;
    _inflightHiddenPosts = _fetchHiddenPosts();
  }

  Future<Map<String, dynamic>> getHiddenPosts() async {
    if (_hiddenPosts?.isValid(_shortTTL) == true) return _hiddenPosts!.data;
    _inflightHiddenPosts ??= _fetchHiddenPosts();
    try {
      return await _inflightHiddenPosts!;
    } finally {
      _inflightHiddenPosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchHiddenPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-hidden-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _hiddenPosts = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getHiddenPosts error: $e');
      return {};
    }
  }

  void invalidateHiddenPosts() { _hiddenPosts = null; _inflightHiddenPosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // WARNED POSTS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchWarnedPosts() {
    if (_warnedPosts?.isValid(_shortTTL) == true) return;
    if (_inflightWarnedPosts != null) return;
    _inflightWarnedPosts = _fetchWarnedPosts();
  }

  Future<Map<String, dynamic>> getWarnedPosts() async {
    if (_warnedPosts?.isValid(_shortTTL) == true) return _warnedPosts!.data;
    _inflightWarnedPosts ??= _fetchWarnedPosts();
    try {
      return await _inflightWarnedPosts!;
    } finally {
      _inflightWarnedPosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchWarnedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-warned-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _warnedPosts = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getWarnedPosts error: $e');
      return {};
    }
  }

  void invalidateWarnedPosts() { _warnedPosts = null; _inflightWarnedPosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // MUTED POSTS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchMutedPosts() {
    if (_mutedPosts?.isValid(_shortTTL) == true) return;
    if (_inflightMutedPosts != null) return;
    _inflightMutedPosts = _fetchMutedPosts();
  }

  Future<Map<String, dynamic>> getMutedPosts() async {
    if (_mutedPosts?.isValid(_shortTTL) == true) return _mutedPosts!.data;
    _inflightMutedPosts ??= _fetchMutedPosts();
    try {
      return await _inflightMutedPosts!;
    } finally {
      _inflightMutedPosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchMutedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-muted-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _mutedPosts = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getMutedPosts error: $e');
      return {};
    }
  }

  void invalidateMutedPosts() { _mutedPosts = null; _inflightMutedPosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // DUPLICATED POSTS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchDuplicatedPosts() {
    if (_duplicatedPosts?.isValid(_shortTTL) == true) return;
    if (_inflightDuplicatedPosts != null) return;
    _inflightDuplicatedPosts = _fetchDuplicatedPosts();
  }

  Future<Map<String, dynamic>> getDuplicatedPosts() async {
    if (_duplicatedPosts?.isValid(_shortTTL) == true) return _duplicatedPosts!.data;
    _inflightDuplicatedPosts ??= _fetchDuplicatedPosts();
    try {
      return await _inflightDuplicatedPosts!;
    } finally {
      _inflightDuplicatedPosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchDuplicatedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-duplicated-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _duplicatedPosts = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getDuplicatedPosts error: $e');
      return {};
    }
  }

  void invalidateDuplicatedPosts() { _duplicatedPosts = null; _inflightDuplicatedPosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // REPORTED POSTS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchReportedPosts() {
    if (_reportedPosts?.isValid(_shortTTL) == true) return;
    if (_inflightReportedPosts != null) return;
    _inflightReportedPosts = _fetchReportedPosts();
  }

  Future<Map<String, dynamic>> getReportedPosts() async {
    if (_reportedPosts?.isValid(_shortTTL) == true) return _reportedPosts!.data;
    _inflightReportedPosts ??= _fetchReportedPosts();
    try {
      return await _inflightReportedPosts!;
    } finally {
      _inflightReportedPosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchReportedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-reported-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _reportedPosts = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getReportedPosts error: $e');
      return {};
    }
  }

  void invalidateReportedPosts() { _reportedPosts = null; _inflightReportedPosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // FLAGGED POSTS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchFlaggedPosts() {
    if (_flaggedPosts?.isValid(_shortTTL) == true) return;
    if (_inflightFlaggedPosts != null) return;
    _inflightFlaggedPosts = _fetchFlaggedPosts();
  }

  Future<Map<String, dynamic>> getFlaggedPosts() async {
    if (_flaggedPosts?.isValid(_shortTTL) == true) return _flaggedPosts!.data;
    _inflightFlaggedPosts ??= _fetchFlaggedPosts();
    try {
      return await _inflightFlaggedPosts!;
    } finally {
      _inflightFlaggedPosts = null;
    }
  }

  Future<Map<String, dynamic>> _fetchFlaggedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-flagged-posts',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _flaggedPosts = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getFlaggedPosts error: $e');
      return {};
    }
  }

  void invalidateFlaggedPosts() { _flaggedPosts = null; _inflightFlaggedPosts = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // SHADOW BAN USERS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchShadowBanUsers() {
    if (_shadowBanUsers?.isValid(_shortTTL) == true) return;
    if (_inflightShadowBanUsers != null) return;
    _inflightShadowBanUsers = _fetchShadowBanUsers();
  }

  Future<Map<String, dynamic>> getShadowBanUsers() async {
    if (_shadowBanUsers?.isValid(_shortTTL) == true) return _shadowBanUsers!.data;
    _inflightShadowBanUsers ??= _fetchShadowBanUsers();
    try {
      return await _inflightShadowBanUsers!;
    } finally {
      _inflightShadowBanUsers = null;
    }
  }

  Future<Map<String, dynamic>> _fetchShadowBanUsers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-shadow-banned-users',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _shadowBanUsers = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getShadowBanUsers error: $e');
      return {};
    }
  }

  void invalidateShadowBanUsers() { _shadowBanUsers = null; _inflightShadowBanUsers = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // BANNED USERS
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchBannedUsers() {
    if (_bannedUsers?.isValid(_shortTTL) == true) return;
    if (_inflightBannedUsers != null) return;
    _inflightBannedUsers = _fetchBannedUsers();
  }

  Future<Map<String, dynamic>> getBannedUsers() async {
    if (_bannedUsers?.isValid(_shortTTL) == true) return _bannedUsers!.data;
    _inflightBannedUsers ??= _fetchBannedUsers();
    try {
      return await _inflightBannedUsers!;
    } finally {
      _inflightBannedUsers = null;
    }
  }

  Future<Map<String, dynamic>> _fetchBannedUsers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};
      final resp = await _supabase.functions.invoke(
        'get-banned-users',
        method: HttpMethod.get,
        queryParameters: {'p_moderator_id': userId, 'p_limit': '20', 'p_offset': '0'},
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _bannedUsers = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getBannedUsers error: $e');
      return {};
    }
  }

  void invalidateBannedUsers() { _bannedUsers = null; _inflightBannedUsers = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEWER WOD DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════
  void prefetchWodDashboard() {
    if (_wodDashboard?.isValid(_shortTTL) == true) return;
    if (_inflightWodDashboard != null) return;
    _inflightWodDashboard = _fetchWodDashboard();
  }

  Future<Map<String, dynamic>> getWodDashboard() async {
    if (_wodDashboard?.isValid(_shortTTL) == true) return _wodDashboard!.data;
    _inflightWodDashboard ??= _fetchWodDashboard();
    try {
      return await _inflightWodDashboard!;
    } finally {
      _inflightWodDashboard = null;
    }
  }

  Future<Map<String, dynamic>> _fetchWodDashboard() async {
    try {
      final resp = await _supabase.functions.invoke(
        'get-wod-dashboard',
        method: HttpMethod.get,
      );
      final result = (resp.data is Map) ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      _wodDashboard = _CacheEntry(result);
      return result;
    } catch (e) {
      debugPrint('[AppCache] getWodDashboard error: $e');
      return {};
    }
  }

  void invalidateWodDashboard() { _wodDashboard = null; _inflightWodDashboard = null; }

  // ══════════════════════════════════════════════════════════════════════════
  // GLOBAL INVALIDATION  (call on logout)
  // ══════════════════════════════════════════════════════════════════════════
  void invalidateAll() {
    _hotPost  = null; _inflightHotPost  = null;
    _topPost  = null; _inflightTopPost  = null;
    _wodPost  = null; _inflightWod      = null;
    _notificationsPage = null; _inflightNotifications = null;
    _modQueuePostsNew = null; _inflightModQueuePosts = null;
    _jmQueuePostsNew  = null; _inflightJmQueuePosts  = null;
    _ccQueuePostsNew  = null; _inflightCcQueuePosts  = null;
    _hiddenPosts      = null; _inflightHiddenPosts      = null;
    _warnedPosts      = null; _inflightWarnedPosts      = null;
    _mutedPosts       = null; _inflightMutedPosts       = null;
    _duplicatedPosts  = null; _inflightDuplicatedPosts  = null;
    _reportedPosts    = null; _inflightReportedPosts    = null;
    _flaggedPosts     = null; _inflightFlaggedPosts     = null;
    _shadowBanUsers   = null; _inflightShadowBanUsers   = null;
    _bannedUsers      = null; _inflightBannedUsers      = null;
    _wodDashboard     = null; _inflightWodDashboard     = null;
    debugPrint('[AppCache] All caches invalidated');
  }
}
