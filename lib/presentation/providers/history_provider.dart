import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/usecases/delete_history_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../services/media_storage_service.dart';

class HistoryProvider extends ChangeNotifier {
  final GetHistoryUseCase _getHistoryUseCase;
  final DeleteHistoryUseCase _deleteHistoryUseCase;

  List<DownloadItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DownloadType? _selectedFilter;

  HistoryProvider({
    required GetHistoryUseCase getHistoryUseCase,
    required DeleteHistoryUseCase deleteHistoryUseCase,
  })  : _getHistoryUseCase = getHistoryUseCase,
        _deleteHistoryUseCase = deleteHistoryUseCase {
    loadHistory();
  }

  List<DownloadItem> get items {
    var list = _items;
    if (_selectedFilter != null) {
      list = list.where((item) => item.type == _selectedFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((item) =>
              item.title.toLowerCase().contains(q) ||
              item.author.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DownloadType? get selectedFilter => _selectedFilter;
  int get totalCount => _items.length;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _getHistoryUseCase.execute();
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(DownloadType? type) {
    _selectedFilter = type;
    notifyListeners();
  }

  Future<void> deleteItem(String id, {bool deleteFile = true}) async {
    final itemIndex = _items.indexWhere((i) => i.id == id);
    if (itemIndex != -1) {
      final item = _items[itemIndex];
      if (deleteFile && item.filePath.isNotEmpty) {
        await MediaStorageService.deleteFile(item.filePath);
      }
      await _deleteHistoryUseCase.execute(id);
      _items.removeAt(itemIndex);
      notifyListeners();
    }
  }

  Future<void> clearAll({bool deleteFiles = true}) async {
    if (deleteFiles) {
      for (var item in _items) {
        if (item.filePath.isNotEmpty) {
          await MediaStorageService.deleteFile(item.filePath);
        }
      }
    }
    await _deleteHistoryUseCase.clearAll();
    _items.clear();
    notifyListeners();
  }

  /// Open downloaded file with system media player
  Future<OpenResult> openFile(DownloadItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'File tidak ditemukan di penyimpanan perangkat.',
      );
    }
    return await OpenFilex.open(item.filePath);
  }

  /// Share file via native system share sheet
  Future<void> shareFile(DownloadItem item) async {
    final file = File(item.filePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(item.filePath)],
        text: '${item.title} (Downloaded via TikTok Downloader)',
      );
    }
  }
}
