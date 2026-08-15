import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/usecases/save_history_usecase.dart';
import '../../services/download_engine.dart';
import '../../services/media_storage_service.dart';

class ActiveDownloadState {
  final DownloadItem item;
  double progress;
  double speedBytesPerSec;
  int downloadedBytes;
  int totalBytes;

  ActiveDownloadState({
    required this.item,
    this.progress = 0.0,
    this.speedBytesPerSec = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  String get speedString {
    if (speedBytesPerSec < 1024) {
      return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
    } else if (speedBytesPerSec < 1024 * 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }
}

class DownloadProvider extends ChangeNotifier {
  final DownloadEngine _downloadEngine;
  final SaveHistoryUseCase _saveHistoryUseCase;

  final Map<String, ActiveDownloadState> _activeDownloads = {};
  VoidCallback? onDownloadCompleted;

  DownloadProvider({
    required DownloadEngine downloadEngine,
    required SaveHistoryUseCase saveHistoryUseCase,
  })  : _downloadEngine = downloadEngine,
        _saveHistoryUseCase = saveHistoryUseCase;

  List<ActiveDownloadState> get activeDownloads => _activeDownloads.values.toList();
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  ActiveDownloadState? getDownload(String id) => _activeDownloads[id];

  Future<bool> startDownload({
    required TikTokVideo video,
    required bool isVideo,
    required bool isHd,
    required BuildContext context,
  }) async {
    // 1. Request Media Permissions
    final hasPermission = await MediaStorageService.requestStoragePermission();
    if (!hasPermission && !kIsWeb) {
      // Proceed with Scoped Storage
    }

    final downloadUrl = isVideo
        ? (isHd && video.hasHd ? video.videoHdUrl! : video.videoUrl)
        : (video.audioUrl ?? video.videoUrl);

    if (downloadUrl.isEmpty) return false;

    // 2. Generate local file path
    final downloadPath = await MediaStorageService.generateFilePath(
      id: video.id,
      title: video.title,
      isVideo: isVideo,
    );

    final downloadId = '${video.id}_${isVideo ? (isHd ? "hd" : "sd") : "mp3"}';

    if (_activeDownloads.containsKey(downloadId)) {
      return false;
    }

    final downloadItem = DownloadItem(
      id: downloadId,
      title: video.title.isNotEmpty ? video.title : 'TikTok ${isVideo ? "Video" : "Audio"}',
      author: video.authorName.isNotEmpty ? video.authorName : '@${video.authorUsername}',
      thumbnailUrl: video.coverUrl,
      sourceUrl: video.url,
      downloadUrl: downloadUrl,
      filePath: downloadPath,
      type: isVideo ? DownloadType.video : DownloadType.audio,
      totalBytes: isVideo ? (isHd ? (video.fileSize > 0 ? video.fileSize : 0) : video.fileSize) : 0,
      downloadedBytes: 0,
      progress: 0.0,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );

    final state = ActiveDownloadState(item: downloadItem);
    _activeDownloads[downloadId] = state;
    notifyListeners();

    // 3. Launch async streaming download
    _downloadEngine.startDownload(
      item: downloadItem,
      onProgress: (id, received, total, progress, speed) {
        final current = _activeDownloads[id];
        if (current != null) {
          current.downloadedBytes = received;
          current.totalBytes = total;
          current.progress = progress;
          current.speedBytesPerSec = speed;
          notifyListeners();
        }
      },
    ).then((finalPath) async {
      // Completed successfully
      final completedItem = downloadItem.copyWith(
        filePath: finalPath,
        status: DownloadStatus.completed,
        progress: 1.0,
      );

      await _saveHistoryUseCase.execute(completedItem);

      _activeDownloads.remove(downloadId);
      notifyListeners();
      onDownloadCompleted?.call();
    }).catchError((e) {
      _activeDownloads.remove(downloadId);
      notifyListeners();
    });

    return true;
  }

  void cancelDownload(String id) {
    if (_activeDownloads.containsKey(id)) {
      _downloadEngine.cancelDownload(id);
      _activeDownloads.remove(id);
      notifyListeners();
    }
  }
}
