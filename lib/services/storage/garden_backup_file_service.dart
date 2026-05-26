import 'package:flutter/services.dart';

class GardenBackupFileService {
  const GardenBackupFileService();

  static const instance = GardenBackupFileService();
  static const _channel = MethodChannel('spray_tracker/backup_files');

  Future<bool> saveBackupFile({
    required String fileName,
    required String content,
  }) async {
    final saved = await _channel.invokeMethod<bool>(
      'saveBackupFile',
      {
        'fileName': fileName,
        'content': content,
      },
    );
    return saved ?? false;
  }

  Future<String?> loadBackupFile() =>
      _channel.invokeMethod<String>('loadBackupFile');
}
