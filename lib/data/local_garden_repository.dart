import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/garden_snapshot.dart';

String encodeGardenSnapshot(GardenSnapshot snapshot) =>
    const JsonEncoder.withIndent('  ').convert(snapshot.toJson());

GardenSnapshot? decodeGardenSnapshot(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return GardenSnapshot.fromJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

class LocalGardenRepository {
  LocalGardenRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static final LocalGardenRepository instance = LocalGardenRepository();

  static const _snapshotKey = 'garden_snapshot_v1';

  final SharedPreferencesAsync _preferences;

  Future<GardenSnapshot?> load() async {
    final raw = await _preferences.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) return null;

    return decodeGardenSnapshot(raw);
  }

  Future<void> save(GardenSnapshot snapshot) =>
      _preferences.setString(_snapshotKey, encodeGardenSnapshot(snapshot));
}
