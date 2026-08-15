import '../entities/download_item.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository repository;

  GetHistoryUseCase(this.repository);

  Future<List<DownloadItem>> execute() async {
    return await repository.getHistory();
  }
}

class SaveHistoryUseCase {
  final HistoryRepository repository;

  SaveHistoryUseCase(this.repository);

  Future<void> execute(DownloadItem item) async {
    await repository.saveHistoryItem(item);
  }
}

class DeleteHistoryUseCase {
  final HistoryRepository repository;

  DeleteHistoryUseCase(this.repository);

  Future<void> execute(String id) async {
    await repository.deleteHistoryItem(id);
  }

  Future<void> clearAll() async {
    await repository.clearHistory();
  }
}
