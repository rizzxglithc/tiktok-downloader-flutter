import '../repositories/history_repository.dart';

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
