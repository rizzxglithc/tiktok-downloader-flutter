import 'package:flutter/material.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/usecases/save_history_usecase.dart';
import '../../services/download_engine.dart';
import '../../services/media_storage_service.dart';
import 'history_provider.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadEngine _downloadEngine;
  final SaveHistoryUseCase _saveHistoryUseCase;

  // Active Downloads: id -> DownloadItem
  final Map<String, DownloadItem> _activeDownloads = {};
  final Map<String, double> _downloadSpeeds = {};

  DownloadProvider({
    required DownloadEngine downloadEngine,
    required SaveHistoryUseCase saveHistoryUseCase,
  })  : _downloadEngine = downloadEngine,
        _saveHistoryUseCase = saveHistoryUseCase;

  List<DownloadItem> get activeDownloads => _activeDownloads.values.toList();
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  DownloadItem? getItem(String id) => _activeDownloads[id];
  double getSpeed(String id) => _downloadSpeeds[id] ?? 0.0;

  /// Start downloading MP4 Video or MP3 Audio
  Future<String?> startDownload({
    required TikTokVideo video,
    required DownloadType type,
    bool isHd = true,
    bool autoSaveToGallery = true,
    HistoryProvider? historyProvider,
  }) async {
    final isVideo = type == DownloadType.video;
    final downloadUrl = isVideo
        ? (isHd && video.videoHdUrl?.isNotEmpty == true ? video.videoHdUrl! : video.videoUrl)
        : (video.audioUrl ?? video.videoUrl);

    if (downloadUrl.isEmpty) {
      throw Exception('URL media tidak tersedia untuk tipe ini.');
    }

    final taskId = '${video.id}_${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final targetPath = await MediaStorageService.generateFilePath(
      id: video.id,
      title: video.title,
      isVideo: isVideo,
    );

    final item = DownloadItem(
      id: taskId,
      title: video.title,
      author: video.authorUsername,
      thumbnailUrl: video.coverUrl,
      sourceUrl: video.url,
      downloadUrl: downloadUrl,
      filePath: targetPath,
      type: type,
      totalBytes: video.fileSize,
      downloadedBytes: 0,
      progress: 0.0,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );

    _activeDownloads[taskId] = item;
    _downloadSpeeds[taskId] = 0.0;
    notifyListeners();

    try {
      final savedPath = await _downloadEngine.startDownload(
        item: item,
        autoSaveToGallery: autoSaveToGallery,
        onProgress: (id, received, total, progress, speed) {
          if (_activeDownloads.containsKey(id)) {
            _activeDownloads[id] = _activeDownloads[id]!.copyWith(
              downloadedBytes: received,
              totalBytes: total,
              progress: progress,
            );
            _downloadSpeeds[id] = speed;
            notifyListeners();
          }
        },
      );

      // Successfully finished
      final completedItem = item.copyWith(
        filePath: savedPath,
        progress: 1.0,
        status: DownloadStatus.completed,
        downloadedBytes: item.totalBytes > 0 ? item.totalBytes : item.downloadedBytes,
      );

      _activeDownloads.remove(taskId);
      _downloadSpeeds.remove(taskId);
      notifyListeners();

      // Save to persistent history
      await _saveHistoryUseCase.execute(completedItem);
      historyProvider?.loadHistory();

      return savedPath;
    } catch (e) {
      final failedItem = item.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );

      _activeDownloads.remove(taskId);
      _downloadSpeeds.remove(taskId);
      notifyListeners();

      rethrow;
    }
  }

  /// Cancel an ongoing download
  void cancelDownload(String id) {
    if (_activeDownloads.containsKey(id)) {
      _downloadEngine.cancelDownload(id);
      _activeDownloads.remove(id);
      _downloadSpeeds.remove(id);
      notifyListeners();
    }
  }
}
