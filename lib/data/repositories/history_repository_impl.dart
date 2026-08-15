import '../../domain/entities/download_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local_history_datasource.dart';
import '../models/download_item_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final LocalHistoryDataSource localDataSource;

  HistoryRepositoryImpl({required this.localDataSource});

  @override
  Future<List<DownloadItem>> getHistory() async {
    return await localDataSource.getHistory();
  }

  @override
  Future<void> saveHistoryItem(DownloadItem item) async {
    await localDataSource.saveHistoryItem(DownloadItemModel.fromEntity(item));
  }

  @override
  Future<void> updateHistoryItem(DownloadItem item) async {
    await localDataSource.updateHistoryItem(DownloadItemModel.fromEntity(item));
  }

  @override
  Future<void> deleteHistoryItem(String id) async {
    await localDataSource.deleteHistoryItem(id);
  }

  @override
  Future<void> clearHistory() async {
    await localDataSource.clearHistory();
  }
}
