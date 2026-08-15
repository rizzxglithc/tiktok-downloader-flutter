enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
}

enum DownloadType {
  video,
  audio,
}

class DownloadItem {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String sourceUrl;
  final String downloadUrl;
  final String filePath;
  final DownloadType type;
  final int totalBytes;
  final int downloadedBytes;
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;
  final String? errorMessage;
  final DateTime createdAt;

  const DownloadItem({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.sourceUrl,
    required this.downloadUrl,
    required this.filePath,
    required this.type,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.progress,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isVideo => type == DownloadType.video;
  bool get isAudio => type == DownloadType.audio;

  DownloadItem copyWith({
    String? id,
    String? title,
    String? author,
    String? thumbnailUrl,
    String? sourceUrl,
    String? downloadUrl,
    String? filePath,
    DownloadType? type,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    DownloadStatus? status,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
