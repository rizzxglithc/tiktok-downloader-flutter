import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaStorageService {
  static const MethodChannel _channel = MethodChannel('com.rizz.tiktok_downloader/media');

  /// Request storage permission (SDK 33+ uses Photos & Videos permission)
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await Permission.videos.request().isGranted &&
          await Permission.audio.request().isGranted) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Get base download directory
  static Future<Directory> getDownloadDirectory() async {
    Directory? baseDir;
    try {
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
      }
    } catch (_) {}
    baseDir ??= await getApplicationDocumentsDirectory();
    return baseDir;
  }

  /// Generate appropriate local save path for downloaded media
  static Future<String> generateFilePath({
    required String id,
    required String title,
    required bool isVideo,
  }) async {
    final cleanTitle = _sanitizeFileName(title);
    final ext = isVideo ? 'mp4' : 'mp3';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${cleanTitle.isNotEmpty ? cleanTitle : "tiktok_${id}"}_$timestamp.$ext';

    final baseDir = await getDownloadDirectory();
    final mediaDir = Directory('${baseDir.path}/${isVideo ? "videos" : "audios"}');

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    return '${mediaDir.path}/$fileName';
  }

  /// Save to Android MediaStore Gallery via Kotlin Native Channel
  static Future<String> saveToDeviceGallery({
    required String filePath,
    required bool isVideo,
    required String title,
  }) async {
    if (!Platform.isAndroid) return filePath;

    try {
      final result = await _channel.invokeMethod<String>('saveToGallery', {
        'filePath': filePath,
        'isVideo': isVideo,
        'title': _sanitizeFileName(title),
      });
      return result ?? filePath;
    } catch (_) {
      return filePath;
    }
  }

  /// Trigger Android MediaScanner to update gallery index
  static Future<void> scanFile(String filePath) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scanFile', {'filePath': filePath});
    } catch (_) {}
  }

  /// Delete local file safely
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await scanFile(filePath);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static String _sanitizeFileName(String input) {
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|#\n\r\t]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim()
        .takeOnly(40);
  }
}

extension _StringExt on String {
  String takeOnly(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}
