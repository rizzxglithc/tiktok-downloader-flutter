import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'media_storage_service.dart';

class SettingsService {
  static const String _autoSaveKey = 'pref_auto_save_gallery';
  static const String _hdByDefaultKey = 'pref_hd_by_default';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  bool get autoSaveToGallery => _prefs.getBool(_autoSaveKey) ?? true;
  bool get hdByDefault => _prefs.getBool(_hdByDefaultKey) ?? true;

  Future<void> setAutoSaveToGallery(bool value) async {
    await _prefs.setBool(_autoSaveKey, value);
  }

  Future<void> setHdByDefault(bool value) async {
    await _prefs.setBool(_hdByDefaultKey, value);
  }

  /// Calculate total size used by downloaded files
  Future<int> calculateTotalDownloadSize() async {
    try {
      final dir = await MediaStorageService.getDownloadDirectory();
      int total = 0;
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Clear all downloaded files in cache/download directory
  Future<void> clearDownloadCache() async {
    try {
      final dir = await MediaStorageService.getDownloadDirectory();
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (_) {}
  }
}
