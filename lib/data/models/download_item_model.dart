import '../../domain/entities/download_item.dart';

class DownloadItemModel extends DownloadItem {
  const DownloadItemModel({
    required super.id,
    required super.title,
    required super.author,
    required super.thumbnailUrl,
    required super.sourceUrl,
    required super.downloadUrl,
    required super.filePath,
    required super.type,
    required super.totalBytes,
    required super.downloadedBytes,
    required super.progress,
    required super.status,
    super.errorMessage,
    required super.createdAt,
  });

  factory DownloadItemModel.fromEntity(DownloadItem item) {
    return DownloadItemModel(
      id: item.id,
      title: item.title,
      author: item.author,
      thumbnailUrl: item.thumbnailUrl,
      sourceUrl: item.sourceUrl,
      downloadUrl: item.downloadUrl,
      filePath: item.filePath,
      type: item.type,
      totalBytes: item.totalBytes,
      downloadedBytes: item.downloadedBytes,
      progress: item.progress,
      status: item.status,
      errorMessage: item.errorMessage,
      createdAt: item.createdAt,
    );
  }

  factory DownloadItemModel.fromJson(Map<String, dynamic> json) {
    return DownloadItemModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'TikTok Download',
      author: json['author'] as String? ?? '@tiktok_user',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      type: (json['type'] == 'audio') ? DownloadType.audio : DownloadType.video,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 1.0,
      status: _statusFromString(json['status'] as String?),
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
      'sourceUrl': sourceUrl,
      'downloadUrl': downloadUrl,
      'filePath': filePath,
      'type': type == DownloadType.audio ? 'audio' : 'video',
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'progress': progress,
      'status': status.name,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DownloadStatus _statusFromString(String? statusStr) {
    switch (statusStr) {
      case 'downloading':
        return DownloadStatus.downloading;
      case 'failed':
        return DownloadStatus.failed;
      case 'cancelled':
        return DownloadStatus.cancelled;
      case 'queued':
        return DownloadStatus.queued;
      case 'completed':
      default:
        return DownloadStatus.completed;
    }
  }
}
