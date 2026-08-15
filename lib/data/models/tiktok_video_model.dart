import '../../core/utils/url_validator.dart';
import '../../domain/entities/tiktok_video.dart';

class TikTokVideoModel extends TikTokVideo {
  const TikTokVideoModel({
    required super.id,
    required super.url,
    required super.title,
    required super.authorName,
    required super.authorUsername,
    required super.authorAvatar,
    required super.coverUrl,
    required super.dynamicCoverUrl,
    required super.videoUrl,
    super.videoHdUrl,
    super.audioUrl,
    super.images = const [],
    required super.durationSeconds,
    required super.width,
    required super.height,
    required super.fileSize,
    required super.viewsCount,
    required super.likesCount,
    required super.commentsCount,
    required super.sharesCount,
    required super.createdAt,
    super.platform = MediaPlatform.tiktok,
    super.contentType = MediaContentType.video,
  });

  /// Robust JSON parser supporting TikWM format (videos & photo slides)
  factory TikTokVideoModel.fromTikWmJson(Map<String, dynamic> json, String originalUrl) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final author = data['author'] as Map<String, dynamic>? ?? {};

    // ID
    final id = (data['id'] ?? data['video_id'] ?? DateTime.now().millisecondsSinceEpoch).toString();

    // Title / Caption
    final title = (data['title'] ?? data['desc'] ?? 'TikTok Post').toString();

    // Author
    final authorName = (author['nickname'] ?? author['name'] ?? 'TikTok Creator').toString();
    final authorUsername = (author['unique_id'] ?? author['username'] ?? 'tiktok_user').toString();
    final authorAvatar = (author['avatar'] ?? author['avatar_thumb'] ?? '').toString();

    // Photos / Slide Carousel Check
    final List<String> imagesList = [];
    if (data['images'] is List) {
      for (final img in (data['images'] as List)) {
        if (img != null) {
          String imgUrl = img.toString();
          if (imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
            imgUrl = 'https://www.tikwm.com$imgUrl';
          }
          imagesList.add(imgUrl);
        }
      }
    }

    final isPhotoSlide = imagesList.isNotEmpty;

    // Media URLs
    final coverUrl = (data['cover'] ?? data['origin_cover'] ?? (imagesList.isNotEmpty ? imagesList.first : '')).toString();
    final dynamicCoverUrl = (data['dynamic_cover'] ?? coverUrl).toString();

    // Play URL (No watermark)
    String videoUrl = (data['play'] ?? data['wmplay'] ?? data['video_url'] ?? '').toString();
    if (videoUrl.isNotEmpty && !videoUrl.startsWith('http')) {
      videoUrl = 'https://www.tikwm.com$videoUrl';
    }

    String? videoHdUrl = data['hdplay'] != null ? data['hdplay'].toString() : null;
    if (videoHdUrl != null && videoHdUrl.isNotEmpty && !videoHdUrl.startsWith('http')) {
      videoHdUrl = 'https://www.tikwm.com$videoHdUrl';
    }

    String? audioUrl = (data['music'] ?? data['music_url'])?.toString();
    if (audioUrl != null && audioUrl.isNotEmpty && !audioUrl.startsWith('http')) {
      audioUrl = 'https://www.tikwm.com$audioUrl';
    }

    // Numbers & Metrics
    final duration = (data['duration'] is num) ? (data['duration'] as num).toInt() : 0;
    final width = (data['width'] is num) ? (data['width'] as num).toInt() : 720;
    final height = (data['height'] is num) ? (data['height'] as num).toInt() : 1280;
    final fileSize = (data['size'] is num) ? (data['size'] as num).toInt() : (data['hd_size'] is num ? (data['hd_size'] as num).toInt() : 0);

    final views = (data['play_count'] is num) ? (data['play_count'] as num).toInt() : 0;
    final likes = (data['digg_count'] is num) ? (data['digg_count'] as num).toInt() : 0;
    final comments = (data['comment_count'] is num) ? (data['comment_count'] as num).toInt() : 0;
    final shares = (data['share_count'] is num) ? (data['share_count'] as num).toInt() : 0;

    DateTime createdTime = DateTime.now();
    if (data['create_time'] is num) {
      createdTime = DateTime.fromMillisecondsSinceEpoch((data['create_time'] as num).toInt() * 1000);
    }

    return TikTokVideoModel(
      id: id,
      url: originalUrl,
      title: title.isEmpty ? 'TikTok Post #$id' : title,
      authorName: authorName,
      authorUsername: authorUsername.startsWith('@') ? authorUsername : '@$authorUsername',
      authorAvatar: authorAvatar,
      coverUrl: coverUrl,
      dynamicCoverUrl: dynamicCoverUrl,
      videoUrl: videoUrl,
      videoHdUrl: videoHdUrl,
      audioUrl: audioUrl,
      images: imagesList,
      durationSeconds: duration,
      width: width,
      height: height,
      fileSize: fileSize,
      viewsCount: views,
      likesCount: likes,
      commentsCount: comments,
      sharesCount: shares,
      createdAt: createdTime,
      platform: MediaPlatform.tiktok,
      contentType: isPhotoSlide ? MediaContentType.photos : MediaContentType.video,
    );
  }

  /// Parser for Instagram media responses (Reels, Single Post, Carousel)
  factory TikTokVideoModel.fromInstagramData({
    required String id,
    required String originalUrl,
    required String title,
    required String authorName,
    required String authorUsername,
    required String authorAvatar,
    required String coverUrl,
    required String videoUrl,
    List<String> images = const [],
    bool isVideo = true,
  }) {
    return TikTokVideoModel(
      id: id,
      url: originalUrl,
      title: title.isNotEmpty ? title : 'Instagram Post',
      authorName: authorName.isNotEmpty ? authorName : 'Instagram User',
      authorUsername: authorUsername.startsWith('@') ? authorUsername : '@$authorUsername',
      authorAvatar: authorAvatar,
      coverUrl: coverUrl,
      dynamicCoverUrl: coverUrl,
      videoUrl: videoUrl,
      videoHdUrl: videoUrl,
      images: images,
      durationSeconds: 0,
      width: 1080,
      height: 1920,
      fileSize: 0,
      viewsCount: 0,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      createdAt: DateTime.now(),
      platform: MediaPlatform.instagram,
      contentType: isVideo ? MediaContentType.video : MediaContentType.photos,
    );
  }

  /// Universal parser for all platforms (Facebook, Twitter, YouTube, Threads, CapCut, Spotify, etc.)
  factory TikTokVideoModel.fromUniversalMedia({
    required String id,
    required String originalUrl,
    required String title,
    required String authorName,
    required String authorUsername,
    required String authorAvatar,
    required String coverUrl,
    required String videoUrl,
    String? videoHdUrl,
    String? audioUrl,
    List<String> images = const [],
    required MediaPlatform platform,
    MediaContentType contentType = MediaContentType.video,
    int durationSeconds = 0,
    int width = 1080,
    int height = 1920,
  }) {
    return TikTokVideoModel(
      id: id,
      url: originalUrl,
      title: title.isNotEmpty ? title : '${UrlValidator.getPlatformName(platform)} Post',
      authorName: authorName.isNotEmpty ? authorName : UrlValidator.getPlatformName(platform),
      authorUsername: authorUsername.isNotEmpty ? (authorUsername.startsWith('@') ? authorUsername : '@$authorUsername') : '@user',
      authorAvatar: authorAvatar,
      coverUrl: coverUrl,
      dynamicCoverUrl: coverUrl,
      videoUrl: videoUrl,
      videoHdUrl: videoHdUrl ?? videoUrl,
      audioUrl: audioUrl,
      images: images,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      fileSize: 0,
      viewsCount: 0,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      createdAt: DateTime.now(),
      platform: platform,
      contentType: contentType,
    );
  }
}
