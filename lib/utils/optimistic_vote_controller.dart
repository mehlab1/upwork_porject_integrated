/// Serializes vote API callbacks so stale responses from rapid taps are ignored.
class OptimisticVoteController {
  OptimisticVoteController({
    required void Function(Map<String, dynamic> response) applyResponse,
    required void Function(int vote, int score) revertTo,
    required void Function(Object error) onError,
  })  : _applyResponse = applyResponse,
        _revertTo = revertTo,
        _onError = onError;

  final void Function(Map<String, dynamic> response) _applyResponse;
  final void Function(int vote, int score) _revertTo;
  final void Function(Object error) _onError;

  int _generation = 0;

  /// Dispatches [apiCall]. Only the most recent dispatch may apply or revert UI.
  Future<void> dispatch({
    required int voteBeforeTap,
    required int votesBeforeTap,
    required Future<Map<String, dynamic>> Function() apiCall,
  }) async {
    final generation = ++_generation;

    try {
      final response = await apiCall();
      if (generation != _generation) return;
      _applyResponse(response);
    } catch (error) {
      if (generation != _generation) return;
      _revertTo(voteBeforeTap, votesBeforeTap);
      _onError(error);
    }
  }
}
