/// Resolves post id from feed / upvoted-posts / detail API shapes.
String? postIdFromMap(Map<String, dynamic> post) {
  final raw = post['id'] ?? post['post_id'];
  final id = raw?.toString().trim();
  if (id == null || id.isEmpty) return null;
  return id;
}

/// Parses vote fields from API payloads into a normalized user vote string.
String? parseUserVoteFromMap(Map<String, dynamic> map) {
  final raw = map['user_vote'] ??
      map['current_user_vote'] ??
      map['my_vote'] ??
      map['vote_type'];
  return normalizeUserVoteString(raw?.toString());
}

/// Normalizes API/cache vote strings to `upvote`, `downvote`, or null (no vote).
String? normalizeUserVoteString(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  if (value.isEmpty ||
      value == 'null' ||
      value == 'none' ||
      value == 'remove' ||
      value == 'neutral') {
    return null;
  }
  if (value == 'upvote' || value == 'up' || value == '1') return 'upvote';
  if (value == 'downvote' || value == 'down' || value == '-1') {
    return 'downvote';
  }
  return null;
}

/// Vote state from vote-post / vote-comment API only (do not merge with local cache).
String? userVoteFromVoteResponse(Map<String, dynamic> response) {
  final voteData = voteDataFromResponse(response);
  final raw = voteData?['user_vote'] ?? response['user_vote'];
  return normalizeUserVoteString(raw?.toString());
}

/// UI state: 1 = upvoted, -1 = downvoted, 0 = neutral.
int userVoteStringToInt(String? vote) {
  final normalized = normalizeUserVoteString(vote);
  if (normalized == 'upvote') return 1;
  if (normalized == 'downvote') return -1;
  return 0;
}

/// Nested `vote_data` from vote-post / vote-comment responses.
Map<String, dynamic>? voteDataFromResponse(Map<String, dynamic> response) {
  final raw = response['vote_data'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

int parseVoteInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

/// Normalized vote counts from API (supports top-level and `vote_data`).
({int netScore, int userVoteInt})? snapshotFromVoteResponse(
  Map<String, dynamic> response,
) {
  final voteData = voteDataFromResponse(response);
  final hasData = voteData != null ||
      response['net_score'] != null ||
      response['upvote_count'] != null;
  if (!hasData) return null;

  final upvotes =
      parseVoteInt(voteData?['upvote_count'] ?? response['upvote_count'] ?? 0);
  final downvotes = parseVoteInt(
    voteData?['downvote_count'] ?? response['downvote_count'] ?? 0,
  );
  final netScore = voteData?['net_score'] != null ||
          response['net_score'] != null
      ? parseVoteInt(voteData?['net_score'] ?? response['net_score'])
      : upvotes - downvotes;
  final userVoteRaw = voteData?['user_vote'] ?? response['user_vote'];
  final userVoteInt = userVoteStringToInt(userVoteRaw?.toString());

  return (netScore: netScore, userVoteInt: userVoteInt);
}
