import 'dart:io';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/errors/app_exceptions.dart';

class MediaStorageService {
  /// Request storage / media permissions according to Android version
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.videos.request().isGranted ||
          await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  /// Get the base download directory for the app
  static Future<Directory> getDownloadDirectory() async {
    Directory? baseDir;
    if (Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
    }
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
    
    final cleanTitle = safeTitle.length > 30 ? safeTitle.substring(0, 30) : safeTitle;
    final ext = isVideo ? 'mp4' : 'mp3';
    final fileName = 'tiktok_${id}_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    return '${dir.path}/$fileName';
  }

  /// Save downloaded MP4 video directly to device public gallery
  static Future<void> saveToDeviceGallery(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const StorageException('File video tidak ditemukan di penyimpanan.');
      }

      // Check Gal permissions
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putVideo(filePath, album: 'TikTok Downloads');
    } catch (e) {
      // If gallery saving encounters issue (e.g. older Android), file is still safely in app directory
      // So don't crash, let it be accessible via in-app viewer
    }
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
