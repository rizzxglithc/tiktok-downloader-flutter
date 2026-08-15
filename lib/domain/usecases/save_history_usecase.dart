import '../entities/download_item.dart';
import '../repositories/history_repository.dart';

class SaveHistoryUseCase {
  final HistoryRepository repository;

  SaveHistoryUseCase(this.repository);

  Future<void> execute(DownloadItem item) async {
    await repository.saveHistoryItem(item);
  }
}
