import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  OfflineCacheService._();

  static final OfflineCacheService instance = OfflineCacheService._();

  static const _prefix = 'offline_cache';

  Future<void> saveMap(String userId, String bucket, Map<String, dynamic> map) {
    return _saveJson(userId, bucket, map);
  }

  Future<Map<String, dynamic>?> readMap(String userId, String bucket) async {
    final value = await _readJson(userId, bucket);
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  Future<void> saveList(
    String userId,
    String bucket,
    List<Map<String, dynamic>> list,
  ) {
    return _saveJson(userId, bucket, list);
  }

  Future<List<Map<String, dynamic>>?> readList(
    String userId,
    String bucket,
  ) async {
    final value = await _readJson(userId, bucket);
    if (value is! List) return null;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> remove(String userId, String bucket) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, bucket));
  }

  Future<void> _saveJson(String userId, String bucket, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, bucket), jsonEncode(value));
  }

  Future<Object?> _readJson(String userId, String bucket) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, bucket));
    if (raw == null || raw.isEmpty) return null;

    try {
      return jsonDecode(raw);
    } catch (_) {
      await prefs.remove(_key(userId, bucket));
      return null;
    }
  }

  String _key(String userId, String bucket) => '$_prefix.$userId.$bucket';
}
