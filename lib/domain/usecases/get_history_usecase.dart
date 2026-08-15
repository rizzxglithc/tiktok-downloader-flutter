import '../entities/download_item.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository repository;

  GetHistoryUseCase(this.repository);

  Future<List<DownloadItem>> execute() async {
    return await repository.getHistory();
  }
}
