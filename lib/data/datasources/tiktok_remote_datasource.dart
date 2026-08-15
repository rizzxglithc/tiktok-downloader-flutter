import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/tiktok_video_model.dart';

abstract class TikTokRemoteDataSource {
  Future<TikTokVideoModel> fetchVideoDetails(String url);
}

class TikTokRemoteDataSourceImpl implements TikTokRemoteDataSource {
  final ApiClient _apiClient;

  TikTokRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<TikTokVideoModel> fetchVideoDetails(String url) async {
    try {
      // 1. Primary Attempt: TikWM API
      final formData = FormData.fromMap({
        'url': url,
        'hd': 1,
      });

      final response = await _apiClient.dio.post(
        ApiConstants.tikwmBaseUrl,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final code = data['code'];
          if (code == 0 && data['data'] != null) {
            return TikTokVideoModel.fromTikWmJson(data, url);
          } else {
            final msg = data['msg']?.toString() ?? 'Gagal memproses video TikTok.';
            throw ApiException(msg);
          }
        }
      }

      throw const ApiException('Format respon server tidak dikenali.');
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw ApiException(e.message ?? 'Gagal menghubungi server downloader.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Terjadi kendala saat memproses video: ${e.toString()}');
    }
  }
}
