import '../entities/tiktok_video.dart';

abstract class TikTokRepository {
  Future<TikTokVideo> getVideoInfo(String url);
}
