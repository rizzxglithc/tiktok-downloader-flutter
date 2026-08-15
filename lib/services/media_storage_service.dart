import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/errors/app_exceptions.dart';

class MediaStorageService {
  static const MethodChannel _channel = MethodChannel('com.rizz.tiktok_downloader/media');

  /// Request storage / media permissions according to Android version
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.videos,
        Permission.audio,
        Permission.storage,
      ].request();

      if (statuses[Permission.videos]?.isGranted == true ||
          statuses[Permission.storage]?.isGranted == true) {
        return true;
      }
      return true; // Proceed with Scoped Storage fallback
    }
    return true;
  }

  /// Get the app download staging directory
  static Future<Directory> getDownloadDirectory() async {
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {}
    baseDir ??= await getApplicationDocumentsDirectory();

    final tiktokDir = Directory('${baseDir.path}/TikTokDownloader');
    if (!await tiktokDir.exists()) {
      await tiktokDir.create(recursive: true);
    }
    return tiktokDir;
  }

  /// Generate safe file path for downloading MP4 or MP3
  static Future<String> generateFilePath({
    required String id,
    required String title,
    required bool isVideo,
  }) async {
    final dir = await getDownloadDirectory();
    
    // Sanitize filename
    final safeTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    
    final cleanTitle = safeTitle.length > 25 ? safeTitle.substring(0, 25) : safeTitle;
    final ext = isVideo ? 'mp4' : 'mp3';
    final fileName = 'tiktok_${id}_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    return '${dir.path}/$fileName';
  }

  /// Save downloaded MP4/MP3 to Android MediaStore/Gallery so it appears in Photos & Gallery apps
  static Future<String> saveToDeviceGallery({
    required String filePath,
    required bool isVideo,
    required String title,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const StorageException('File tidak ditemukan di penyimpanan lokal.');
    }

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<String>('saveToGallery', {
          'filePath': filePath,
          'isVideo': isVideo,
          'title': title,
        });
        if (result != null && result.isNotEmpty) {
          return result;
        }
      } catch (e) {
        // Fallback: trigger media scanner
        try {
          await _channel.invokeMethod('scanFile', {'filePath': filePath});
        } catch (_) {}
      }
    }
    return filePath;
  }

  /// Check if a local file exists
  static Future<bool> fileExists(String path) async {
    if (path.isEmpty) return false;
    return await File(path).exists();
  }

  /// Delete a local file safely
  static Future<void> deleteFile(String path) async {
    try {
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
  }
}
