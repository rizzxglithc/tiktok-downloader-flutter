import '../entities/download_item.dart';

abstract class HistoryRepository {
  Future<List<DownloadItem>> getHistory();
  Future<void> saveHistoryItem(DownloadItem item);
  Future<void> updateHistoryItem(DownloadItem item);
  Future<void> deleteHistoryItem(String id);
  Future<void> clearHistory();
}
