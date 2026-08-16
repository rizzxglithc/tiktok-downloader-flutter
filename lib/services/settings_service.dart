import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Calculate total size used by downloaded files and temporary cache
  Future<int> calculateTotalDownloadSize() async {
    int total = 0;
    try {
      final dir = await MediaStorageService.getDownloadDirectory();
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final tempFiles = tempDir.listSync(recursive: true);
        for (var file in tempFiles) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
      return total;
    } catch (_) {
      return total;
    }
  }

  /// Clear all downloaded files in cache/download directory and temporary cache
  Future<void> clearDownloadCache() async {
    try {
      final dir = await MediaStorageService.getDownloadDirectory();
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final tempFiles = tempDir.listSync(recursive: true);
        for (var file in tempFiles) {
          if (file is File) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }
}
