import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService;

  bool _autoSaveToGallery = true;
  bool _hdByDefault = true;
  int _storageUsedBytes = 0;

  SettingsProvider(this._settingsService) {
    _autoSaveToGallery = _settingsService.autoSaveToGallery;
    _hdByDefault = _settingsService.hdByDefault;
    calculateStorageUsed();
  }

  bool get autoSaveToGallery => _autoSaveToGallery;
  bool get hdByDefault => _hdByDefault;
  int get storageUsedBytes => _storageUsedBytes;

  Future<void> setAutoSaveToGallery(bool value) async {
    _autoSaveToGallery = value;
    await _settingsService.setAutoSaveToGallery(value);
    notifyListeners();
  }

  Future<void> setHdByDefault(bool value) async {
    _hdByDefault = value;
    await _settingsService.setHdByDefault(value);
    notifyListeners();
  }

  Future<void> calculateStorageUsed() async {
    _storageUsedBytes = await _settingsService.calculateTotalDownloadSize();
    notifyListeners();
  }

  Future<int> clearCache() async {
    final freed = await _settingsService.clearDownloadCache();
    await calculateStorageUsed();
    return freed;
  }
}
