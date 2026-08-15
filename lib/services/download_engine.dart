import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../domain/entities/download_item.dart';
import 'media_storage_service.dart';

typedef OnDownloadProgressCallback = void Function(
  String id,
  int receivedBytes,
  int totalBytes,
  double progress,
  double speedBytesPerSec,
);

class DownloadEngine {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadEngine({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.downloadTimeout,
                headers: ApiConstants.defaultHeaders,
              ),
            );

  /// Start streaming download to disk
  Future<String> startDownload({
    required DownloadItem item,
    required OnDownloadProgressCallback onProgress,
    bool autoSaveToGallery = true,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    int lastReceivedBytes = 0;
    DateTime lastTime = DateTime.now();

    final tempFilePath = '${item.filePath}.tmp';

    try {
      final response = await _dio.download(
        item.downloadUrl,
        tempFilePath,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final now = DateTime.now();
            final timeDiffMs = now.difference(lastTime).inMilliseconds;

            double speed = 0;
            if (timeDiffMs >= 400) {
              final bytesDiff = received - lastReceivedBytes;
              speed = (bytesDiff / (timeDiffMs / 1000.0));
              lastReceivedBytes = received;
              lastTime = now;
            }

            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(item.id, received, total, progress, speed);
          }
        },
      );

      if (response.statusCode == 200) {
        // Rename .tmp to final target file path
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          final targetFile = await tempFile.rename(item.filePath);

          // Save to device gallery if MP4 video
          if (item.isVideo && autoSaveToGallery) {
            await MediaStorageService.saveToDeviceGallery(targetFile.path);
          }

          _cancelTokens.remove(item.id);
          return targetFile.path;
        } else {
          throw const StorageException('File hasil download tidak ditemukan di penyimpanan.');
        }
      } else {
        throw DownloadException('Server mengembalikan kode status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _cancelTokens.remove(item.id);
      // Clean up partial temp file
      await MediaStorageService.deleteFile(tempFilePath);

      if (CancelToken.isCancel(e)) {
        throw const DownloadException('Pengunduhan dibatalkan oleh pengguna.');
      }
      throw DownloadException('Gagal mengunduh file: ${e.message}');
    } catch (e) {
      _cancelTokens.remove(item.id);
      await MediaStorageService.deleteFile(tempFilePath);
      if (e is AppException) rethrow;
      throw DownloadException('Terjadi kendala saat download: ${e.toString()}');
    }
  }

  /// Cancel an ongoing download
  void cancelDownload(String id) {
    if (_cancelTokens.containsKey(id)) {
      _cancelTokens[id]?.cancel('Dibatalkan oleh pengguna.');
      _cancelTokens.remove(id);
    }
  }

  /// Check if a download is actively running
  bool isDownloading(String id) {
    return _cancelTokens.containsKey(id);
  }
}
