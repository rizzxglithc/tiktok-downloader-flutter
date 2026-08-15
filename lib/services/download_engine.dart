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
                followRedirects: true,
                maxRedirects: 5,
              ),
            );

  /// Start streaming download to disk (Single Media File)
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
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Referer': 'https://www.tiktok.com/',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final now = DateTime.now();
            final timeDiffMs = now.difference(lastTime).inMilliseconds;

            double speed = 0;
            if (timeDiffMs >= 350) {
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

      if (response.statusCode == 200 || response.statusCode == 206) {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists() && (await tempFile.length()) > 500) {
          final targetFile = await tempFile.rename(item.filePath);

          // Save to device gallery / MediaStore
          String savedResultPath = targetFile.path;
          if (autoSaveToGallery) {
            try {
              final mediaType = item.isPhotos
                  ? "photo"
                  : (item.isAudio ? "audio" : "video");

              final galleryPath = await MediaStorageService.saveToDeviceGallery(
                filePath: targetFile.path,
                mediaType: mediaType,
                title: item.title,
              );
              if (galleryPath.isNotEmpty) {
                savedResultPath = galleryPath;
              }
            } catch (_) {}
          }

          _cancelTokens.remove(item.id);
          return savedResultPath;
        } else {
          throw const StorageException('Ukuran file unduhan tidak valid.');
        }
      } else {
        throw DownloadException('Server mengembalikan kode status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _cancelTokens.remove(item.id);
      await MediaStorageService.deleteFile(tempFilePath);

      if (CancelToken.isCancel(e)) {
        throw const DownloadException('Pengunduhan dibatalkan.');
      }
      throw DownloadException('Gagal mengunduh: ${e.message}');
    } catch (e) {
      _cancelTokens.remove(item.id);
      await MediaStorageService.deleteFile(tempFilePath);
      if (e is AppException) rethrow;
      throw DownloadException('Kendala unduhan: ${e.toString()}');
    }
  }

  /// Download multiple photos / carousel images in batch
  Future<List<String>> downloadPhotoBatch({
    required String id,
    required String title,
    required List<String> imageUrls,
    required void Function(int index, int total, double progress) onProgress,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    final List<String> savedPaths = [];
    int completed = 0;

    for (int i = 0; i < imageUrls.length; i++) {
      if (cancelToken.isCancelled) break;

      final url = imageUrls[i];
      final filePath = await MediaStorageService.generateFilePath(
        id: '${id}_slide_${i + 1}',
        title: '${title}_${i + 1}',
        ext: 'jpg',
        subFolder: 'photos',
      );

      try {
        final res = await _dio.download(
          url,
          filePath,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ),
        );

        if (res.statusCode == 200) {
          await MediaStorageService.saveToDeviceGallery(
            filePath: filePath,
            mediaType: 'photo',
            title: '${title}_${i + 1}',
          );
          savedPaths.add(filePath);
        }
      } catch (_) {}

      completed++;
      onProgress(completed, imageUrls.length, completed / imageUrls.length);
    }

    _cancelTokens.remove(id);
    return savedPaths;
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
