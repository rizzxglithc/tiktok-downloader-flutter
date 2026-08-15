import '../entities/tiktok_video.dart';
import '../repositories/tiktok_repository.dart';

class GetTikTokVideoUseCase {
  final TikTokRepository repository;

  GetTikTokVideoUseCase(this.repository);

  Future<TikTokVideo> execute(String url) async {
    return await repository.getVideoInfo(url);
  }
}
