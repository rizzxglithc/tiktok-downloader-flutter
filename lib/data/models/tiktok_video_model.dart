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

    // Photos / Slide Carousel Check (Only a slide if 2 or more images exist)
    final List<String> imagesList = [];
    if (data['images'] is List) {
      for (final img in (data['images'] as List)) {
        if (img != null) {
          String imgUrl = img.toString().trim();
          if (imgUrl.isNotEmpty && imgUrl != 'null') {
            if (!imgUrl.startsWith('http')) {
              imgUrl = 'https://www.tikwm.com$imgUrl';
            }
            imagesList.add(imgUrl);
          }
        }
      }
    }

    final isPhotoSlide = imagesList.length > 1;

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

    // Audio / Sound URL Auto-Detection
    String? audioUrl;
    final musicInfo = data['music_info'] as Map<String, dynamic>?;
    if (musicInfo != null && musicInfo['play'] != null && musicInfo['play'].toString().trim().isNotEmpty) {
      audioUrl = musicInfo['play'].toString().trim();
    } else if (data['music'] != null && data['music'].toString().trim().isNotEmpty) {
      audioUrl = data['music'].toString().trim();
    } else if (data['music_url'] != null && data['music_url'].toString().trim().isNotEmpty) {
      audioUrl = data['music_url'].toString().trim();
    }

    if (audioUrl != null && audioUrl.isNotEmpty) {
      if (!audioUrl.startsWith('http')) {
        audioUrl = 'https://www.tikwm.com$audioUrl';
      }
      if (audioUrl == 'https://www.tikwm.com' || audioUrl == 'https://www.tikwm.com/' || audioUrl == 'null') {
        audioUrl = null;
      }
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
    String? audioUrl,
    List<String> images = const [],
    bool isVideo = true,
  }) {
    final isSlide = images.length > 1;
    final contentType = isVideo ? MediaContentType.video : (isSlide ? MediaContentType.photos : MediaContentType.video);

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
      audioUrl: (audioUrl != null && audioUrl.isNotEmpty && audioUrl != 'null') ? audioUrl : (isVideo ? videoUrl : null),
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
      contentType: contentType,
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
    int fileSize = 0,
  }) {
    final isSlide = images.length > 1;
    final determinedContentType = (contentType == MediaContentType.photos && !isSlide) ? MediaContentType.video : contentType;

    String? validAudio = (audioUrl != null && audioUrl.isNotEmpty && audioUrl != 'null') ? audioUrl : null;
    if (validAudio == null && videoUrl.isNotEmpty && contentType != MediaContentType.photos) {
      validAudio = videoUrl;
    }

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
      audioUrl: validAudio,
      images: images,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      fileSize: fileSize,
      viewsCount: 0,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      createdAt: DateTime.now(),
      platform: platform,
      contentType: determinedContentType,
    );
  }
}
