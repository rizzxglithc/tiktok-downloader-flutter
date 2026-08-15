import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item_model.dart';

abstract class LocalHistoryDataSource {
  Future<List<DownloadItemModel>> getHistory();
  Future<void> saveHistoryItem(DownloadItemModel item);
  Future<void> updateHistoryItem(DownloadItemModel item);
  Future<void> deleteHistoryItem(String id);
  Future<void> clearHistory();
}

class LocalHistoryDataSourceImpl implements LocalHistoryDataSource {
  static const String _historyKey = 'tiktok_download_history_v1';
  final SharedPreferences _prefs;

  LocalHistoryDataSourceImpl(this._prefs);

  @override
  Future<List<DownloadItemModel>> getHistory() async {
    final jsonListString = _prefs.getString(_historyKey);
    if (jsonListString == null || jsonListString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonListString);
      final list = decoded
          .map((item) => DownloadItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveHistoryItem(DownloadItemModel item) async {
    final currentList = await getHistory();
    // Remove if exists then add at top
    currentList.removeWhere((existing) => existing.id == item.id);
    currentList.insert(0, item);

    final encoded = json.encode(currentList.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }

  @override
  Future<void> updateHistoryItem(DownloadItemModel item) async {
    final currentList = await getHistory();
    final index = currentList.indexWhere((existing) => existing.id == item.id);
    if (index != -1) {
      currentList[index] = item;
      final encoded = json.encode(currentList.map((e) => e.toJson()).toList());
      await _prefs.setString(_historyKey, encoded);
    } else {
      await saveHistoryItem(item);
    }
  }

  @override
  Future<void> deleteHistoryItem(String id) async {
    final currentList = await getHistory();
    currentList.removeWhere((item) => item.id == id);
    final encoded = json.encode(currentList.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }

  @override
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
