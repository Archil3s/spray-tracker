import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/garden_snapshot.dart';

const gardenBackupFileExtension = 'spraygarden';
const _gardenBackupHeader = 'SPRAY_TRACKER_GARDEN_BACKUP_V1';

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

String encodeGardenBackupFile(GardenSnapshot snapshot) {
  final json = encodeGardenSnapshot(snapshot);
  final payload = base64Url.encode(utf8.encode(json));
  return '$_gardenBackupHeader\n$payload\n';
}

GardenSnapshot? decodeGardenBackupFile(String raw) {
  final text = raw.trim();
  if (!text.startsWith(_gardenBackupHeader)) {
    return decodeGardenSnapshot(text);
  }

  try {
    final payload = text
        .substring(_gardenBackupHeader.length)
        .trim()
        .replaceAll(RegExp(r'\s+'), '');
    if (payload.isEmpty) return null;
    final json = utf8.decode(base64Url.decode(payload));
    return decodeGardenSnapshot(json);
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
