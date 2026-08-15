import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/usecases/save_history_usecase.dart';
import '../../services/download_engine.dart';
import '../../services/media_storage_service.dart';

class ActiveDownload {
  final String id;
  final String title;
  final String authorName;
  final String thumbnailUrl;
  final bool isVideo;
  final DownloadTask task;

  ActiveDownload({
    required this.id,
    required this.title,
    required this.authorName,
    required this.thumbnailUrl,
    required this.isVideo,
    required this.task,
  });
}

class DownloadProvider extends ChangeNotifier {
  final DownloadEngine _downloadEngine;
  final SaveHistoryUseCase _saveHistoryUseCase;

  final Map<String, ActiveDownload> _activeDownloads = {};
  VoidCallback? onDownloadCompleted;

  DownloadProvider({
    required DownloadEngine downloadEngine,
    required SaveHistoryUseCase saveHistoryUseCase,
  })  : _downloadEngine = downloadEngine,
        _saveHistoryUseCase = saveHistoryUseCase;

  List<ActiveDownload> get activeDownloads => _activeDownloads.values.toList();
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  ActiveDownload? getDownload(String id) => _activeDownloads[id];

  Future<bool> startDownload({
    required TikTokVideo video,
    required bool isVideo,
    required bool isHd,
    required BuildContext context,
  }) async {
    // 1. Request Media Permissions
    final hasPermission = await MediaStorageService.requestStoragePermission();
    if (!hasPermission && !kIsWeb) {
      // Proceed with scoped storage
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

    // Cancel existing task if already running
    if (_activeDownloads.containsKey(downloadId)) {
      return false;
    }

    // 3. Start streaming download task
    final task = _downloadEngine.startDownload(
      id: downloadId,
      url: downloadUrl,
      savePath: downloadPath,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Referer': 'https://www.tiktok.com/',
      },
    );

    final activeItem = ActiveDownload(
      id: downloadId,
      title: video.title,
      authorName: video.authorName.isNotEmpty ? video.authorName : video.authorUsername,
      thumbnailUrl: video.coverUrl,
      isVideo: isVideo,
      task: task,
    );

    _activeDownloads[downloadId] = activeItem;
    notifyListeners();

    // 4. Attach state listeners
    task.addListener(() async {
      notifyListeners();

      if (task.status == DownloadStatus.completed) {
        // Save to Android MediaStore / Gallery
        String finalSavedPath = downloadPath;
        try {
          final galleryResult = await MediaStorageService.saveToDeviceGallery(
            filePath: downloadPath,
            isVideo: isVideo,
            title: video.title,
          );
          if (galleryResult.isNotEmpty) {
            finalSavedPath = galleryResult;
          }
        } catch (_) {}

        // Save to History database
        final historyItem = DownloadItem(
          id: downloadId,
          title: video.title.isNotEmpty ? video.title : 'TikTok ${isVideo ? "Video" : "Audio"}',
          authorName: video.authorName.isNotEmpty ? video.authorName : '@${video.authorUsername}',
          thumbnailUrl: video.coverUrl,
          savedPath: finalSavedPath,
          downloadedAt: DateTime.now(),
          fileSizeBytes: task.totalBytes > 0 ? task.totalBytes : video.fileSize,
          isVideo: isVideo,
        );

        await _saveHistoryUseCase.execute(historyItem);

        _activeDownloads.remove(downloadId);
        notifyListeners();
        onDownloadCompleted?.call();
      } else if (task.status == DownloadStatus.failed || task.status == DownloadStatus.cancelled) {
        _activeDownloads.remove(downloadId);
        notifyListeners();
      }
    });

    return true;
  }

  void cancelDownload(String id) {
    if (_activeDownloads.containsKey(id)) {
      _activeDownloads[id]?.task.cancel();
      _activeDownloads.remove(id);
      notifyListeners();
    }
  }
}
