enum MediaPlatform {
  tiktok,
  instagram,
}

enum MediaContentType {
  video,
  photos,
  audio,
}

class TikTokVideo {
  final String id;
  final String url;
  final String title;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final String coverUrl;
  final String dynamicCoverUrl;
  final String videoUrl;
  final String? videoHdUrl;
  final String? audioUrl;
  final List<String> images;
  final int durationSeconds;
  final int width;
  final int height;
  final int fileSize;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final MediaPlatform platform;
  final MediaContentType contentType;

  const TikTokVideo({
    required this.id,
    required this.url,
    required this.title,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.coverUrl,
    required this.dynamicCoverUrl,
    required this.videoUrl,
    this.videoHdUrl,
    this.audioUrl,
    this.images = const [],
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.createdAt,
    this.platform = MediaPlatform.tiktok,
    this.contentType = MediaContentType.video,
  });

  String get bestVideoUrl => videoHdUrl?.isNotEmpty == true ? videoHdUrl! : videoUrl;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasHd => videoHdUrl != null && videoHdUrl!.isNotEmpty;
  bool get isSlide => images.isNotEmpty || contentType == MediaContentType.photos;
}
