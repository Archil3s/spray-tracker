import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/garden_snapshot.dart';

class LocalGardenRepository {
  LocalGardenRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static final LocalGardenRepository instance = LocalGardenRepository();

  static const _snapshotKey = 'garden_snapshot_v1';

  final SharedPreferencesAsync _preferences;

  Future<GardenSnapshot?> load() async {
    final raw = await _preferences.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return GardenSnapshot.fromJson(decoded);
  }

  Future<void> save(GardenSnapshot snapshot) =>
      _preferences.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
}
