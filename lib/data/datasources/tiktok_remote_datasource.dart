import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/url_validator.dart';
import '../models/tiktok_video_model.dart';

abstract class TikTokRemoteDataSource {
  Future<TikTokVideoModel> getVideoInfo(String url);
  Future<TikTokVideoModel> fetchVideoDetails(String url);
}

class TikTokRemoteDataSourceImpl implements TikTokRemoteDataSource {
  final ApiClient apiClient;

  TikTokRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<TikTokVideoModel> getVideoInfo(String url) async {
    return await fetchVideoDetails(url);
  }

  @override
  Future<TikTokVideoModel> fetchVideoDetails(String url) async {
    // 1. Resolve short links if applicable
    final resolvedUrl = await UrlValidator.resolveToCanonicalUrl(url);

    // 2. Fetch from TikWM Primary API
    try {
      final formData = FormData.fromMap({
        'url': resolvedUrl,
        'hd': 1,
      });

      final response = await apiClient.dio.post(
        ApiConstants.tikwmBaseUrl,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          receiveTimeout: ApiConstants.receiveTimeout,
          sendTimeout: ApiConstants.connectTimeout,
        ),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final code = data['code'];
      if (code == 0 && data.containsKey('data')) {
        final videoData = data['data'] as Map<String, dynamic>;
        return TikTokVideoModel.fromTikWmJson(videoData, resolvedUrl);
      } else {
        final msg = data['msg'] as String? ?? 'Gagal memproses video TikTok. Pastikan video tidak di-private.';
        throw ApiException(msg);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkException('Koneksi internet lambat atau timeout. Silakan coba lagi.');
      }
      throw NetworkException('Terjadi kendala jaringan: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Gagal mengambil data video: ${e.toString()}');
    }
  }
}
