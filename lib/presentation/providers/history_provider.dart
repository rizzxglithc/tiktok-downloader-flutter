import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/delete_history_usecase.dart';
import '../../services/media_storage_service.dart';

enum HistoryFilter { all, video, photos, audio }

class HistoryProvider extends ChangeNotifier {
  final GetHistoryUseCase _getHistoryUseCase;
  final DeleteHistoryUseCase _deleteHistoryUseCase;

  List<DownloadItem> _items = [];
  bool _isLoading = false;
  String _errorMessage = '';
  HistoryFilter _selectedFilter = HistoryFilter.all;
  String _searchQuery = '';

  HistoryProvider({
    required GetHistoryUseCase getHistoryUseCase,
    required DeleteHistoryUseCase deleteHistoryUseCase,
  })  : _getHistoryUseCase = getHistoryUseCase,
        _deleteHistoryUseCase = deleteHistoryUseCase {
    loadHistory();
  }

  List<DownloadItem> get allItems => _items;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  HistoryFilter get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  List<DownloadItem> get filteredItems {
    return _items.where((item) {
      if (_selectedFilter == HistoryFilter.video && !item.isVideo) return false;
      if (_selectedFilter == HistoryFilter.photos && !item.isPhotos) return false;
      if (_selectedFilter == HistoryFilter.audio && !item.isAudio) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchAuthor = item.author.toLowerCase().contains(query);
        return matchTitle || matchAuthor;
      }
      return true;
    }).toList();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final rawItems = await _getHistoryUseCase.execute();
      // Sync and filter items to ensure only existing files are kept
      final validItems = <DownloadItem>[];
      for (final item in rawItems) {
        if (item.filePath.isNotEmpty && File(item.filePath).existsSync()) {
          validItems.add(item);
        } else if (item.filePath.isNotEmpty) {
          // Prune missing file reference from storage
          await _deleteHistoryUseCase.execute(item.id);
        } else {
          validItems.add(item);
        }
      }
      _items = validItems;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncWithStorage() async {
    await loadHistory();
  }

  void setFilter(HistoryFilter filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final itemIndex = _items.indexWhere((element) => element.id == id);
    if (itemIndex != -1) {
      final item = _items[itemIndex];
      _items.removeAt(itemIndex);
      notifyListeners();

      if (item.filePath.isNotEmpty) {
        await MediaStorageService.deleteFile(item.filePath);
      }

      await _deleteHistoryUseCase.execute(id);
    }
  }

  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _deleteHistoryUseCase.clearAll();
  }
}
