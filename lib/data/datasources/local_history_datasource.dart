import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/download_item.dart';
import '../models/download_item_model.dart';
import '../../core/errors/app_exceptions.dart';

abstract class LocalHistoryDataSource {
  Future<List<DownloadItemModel>> getHistory();
  Future<void> saveHistoryItem(DownloadItem item);
  Future<void> updateHistoryItem(DownloadItem item);
  Future<void> deleteHistoryItem(String id);
  Future<void> clearHistory();
}

class LocalHistoryDataSourceImpl implements LocalHistoryDataSource {
  static const String _historyKey = 'tiktok_download_history_v3';
  final SharedPreferences sharedPreferences;

  LocalHistoryDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<DownloadItemModel>> getHistory() async {
    try {
      final jsonListString = sharedPreferences.getStringList(_historyKey);
      if (jsonListString == null || jsonListString.isEmpty) {
        return [];
      }

      final items = <DownloadItemModel>[];
      for (final str in jsonListString) {
        try {
          final Map<String, dynamic> map = jsonDecode(str);
          items.add(DownloadItemModel.fromJson(map));
        } catch (_) {}
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      throw StorageException('Gagal memuat riwayat: ${e.toString()}');
    }
  }

  @override
  Future<void> saveHistoryItem(DownloadItem item) async {
    try {
      final currentList = await getHistory();
      currentList.removeWhere((element) => element.id == item.id);
      currentList.insert(0, DownloadItemModel.fromEntity(item));

      final stringList = currentList.map((e) => jsonEncode(e.toJson())).toList();
      await sharedPreferences.setStringList(_historyKey, stringList);
    } catch (e) {
      throw StorageException('Gagal menyimpan ke riwayat: ${e.toString()}');
    }
  }

  @override
  Future<void> updateHistoryItem(DownloadItem item) async {
    await saveHistoryItem(item);
  }

  @override
  Future<void> deleteHistoryItem(String id) async {
    try {
      final currentList = await getHistory();
      currentList.removeWhere((element) => element.id == id);
      final stringList = currentList.map((e) => jsonEncode(e.toJson())).toList();
      await sharedPreferences.setStringList(_historyKey, stringList);
    } catch (e) {
      throw StorageException('Gagal menghapus riwayat: ${e.toString()}');
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      await sharedPreferences.remove(_historyKey);
    } catch (e) {
      throw StorageException('Gagal membersihkan riwayat: ${e.toString()}');
    }
  }
}
