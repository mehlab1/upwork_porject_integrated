import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent push payloads so Android can render grouped summaries
/// and the in-app banner can expand into a stacked list.
class PushNotificationGroupStore {
  PushNotificationGroupStore._();

  static const _storageKey = 'push_notification_group_v1';
  static const maxItems = 5;
  static const summaryNotificationId = 0;

  static Future<void> add(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readRaw(prefs);

    final id = data['id']?.toString()
        ?? data['notification_id']?.toString()
        ?? DateTime.now().millisecondsSinceEpoch.toString();

    items.removeWhere((item) => item['id']?.toString() == id);
    items.insert(0, {
      'id': id,
      'data': data,
      'stored_at': DateTime.now().millisecondsSinceEpoch,
    });

    if (items.length > maxItems) {
      items.removeRange(maxItems, items.length);
    }

    await prefs.setString(_storageKey, jsonEncode(items));
  }

  static Future<List<Map<String, dynamic>>> getRecentData() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readRaw(prefs);
    return items
        .map((item) => Map<String, dynamic>.from(item['data'] as Map))
        .toList();
  }

  static Future<int> count() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readRaw(prefs);
    return items.length;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<List<Map<String, dynamic>>> _readRaw(SharedPreferences prefs) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
