import '../../domain/entities/tiktok_video.dart';
import '../../domain/repositories/tiktok_repository.dart';
import '../datasources/tiktok_remote_datasource.dart';

class TikTokRepositoryImpl implements TikTokRepository {
  final TikTokRemoteDataSource remoteDataSource;

  TikTokRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TikTokVideo> getVideoInfo(String url) async {
    return await remoteDataSource.fetchVideoDetails(url);
  }
}
