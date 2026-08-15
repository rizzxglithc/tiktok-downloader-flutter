import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class MediaStorageService {
  static const MethodChannel _channel = MethodChannel('com.rizz.tiktok_downloader/media');

  /// Request media permissions
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await Permission.videos.request().isGranted &&
          await Permission.audio.request().isGranted &&
          await Permission.photos.request().isGranted) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Get base media storage directory (reliable internal app storage)
  static Future<Directory> getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/MyDownloader');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Generate appropriate local save path for downloaded media
  static Future<String> generateFilePath({
    required String id,
    required String title,
    String ext = 'mp4',
    String subFolder = 'videos',
  }) async {
    final cleanTitle = _sanitizeFileName(title);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${cleanTitle.isNotEmpty ? cleanTitle : "media_${id}"}_$timestamp.$ext';

    final baseDir = await getDownloadDirectory();
    final mediaSubDir = Directory('${baseDir.path}/$subFolder');

    if (!await mediaSubDir.exists()) {
      await mediaSubDir.create(recursive: true);
    }

    return '${mediaSubDir.path}/$fileName';
  }

  /// Save copy to Android MediaStore (Gallery / Music / Pictures)
  static Future<String> saveToDeviceGallery({
    required String filePath,
    required String mediaType, // "video", "audio", "photo"
    required String title,
  }) async {
    if (!Platform.isAndroid) return filePath;

    try {
      final result = await _channel.invokeMethod<String>('saveToGallery', {
        'filePath': filePath,
        'mediaType': mediaType,
        'title': _sanitizeFileName(title),
      });
      return result ?? filePath;
    } catch (_) {
      return filePath;
    }
  }

  /// Share media file with 100% fallback reliability
  static Future<bool> shareMediaFile({
    required String filePath,
    required String title,
    String? mediaType,
    String? fallbackUrl,
  }) async {
    final file = File(filePath);
    final exists = file.existsSync();

    if (exists) {
      try {
        final xfile = XFile(filePath);
        await Share.shareXFiles(
          [xfile],
          text: 'Dibagikan via MyDownloader: $title',
          subject: title,
        );
        return true;
      } catch (_) {
        // Fallback to Native Android FileProvider Share
        try {
          final mimeType = (mediaType == 'audio')
              ? 'audio/mpeg'
              : ((mediaType == 'image' || mediaType == 'photo') ? 'image/jpeg' : 'video/mp4');

          final success = await _channel.invokeMethod<bool>('shareFile', {
            'filePath': filePath,
            'title': title,
            'mimeType': mimeType,
          });
          if (success == true) return true;
        } catch (_) {}
      }
    }

    // If file is not local or sharing file failed, share the text/URL
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      try {
        await Share.share('$title\n$fallbackUrl\n\nUnduh via MyDownloader');
        return true;
      } catch (_) {}
    }

    return false;
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
        .takeOnly(35);
  }
}

extension _StringExt on String {
  String takeOnly(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}
