import 'dart:convert';
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

    // 2. Try primary TikWM endpoints with auto-retry and backoff
    final endpoints = [
      ApiConstants.tikwmBaseUrl,
      ApiConstants.tikwmBackupUrl,
    ];

    AppException? lastException;

    for (final endpoint in endpoints) {
      for (int attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) {
          // Wait 1.3 seconds for TikWM 1 req/sec rate limit cooldown
          await Future.delayed(const Duration(milliseconds: 1300));
        }

        try {
          final formData = FormData.fromMap({
            'url': resolvedUrl,
            'count': 12,
            'cursor': 0,
            'web': 1,
            'hd': 1,
          });

          final response = await apiClient.dio.post(
            endpoint,
            data: formData,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              responseType: ResponseType.json,
              receiveTimeout: ApiConstants.receiveTimeout,
              sendTimeout: ApiConstants.connectTimeout,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Referer': 'https://www.tikwm.com/',
                'Origin': 'https://www.tikwm.com',
                'Accept': 'application/json, text/javascript, */*; q=0.01',
                'X-Requested-With': 'XMLHttpRequest',
              },
            ),
          );

          final Map<String, dynamic> data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : (response.data is String ? jsonDecode(response.data) as Map<String, dynamic> : <String, dynamic>{});

          final code = data['code'];
          final msg = (data['msg'] ?? '').toString();

          if (code == 0 && data.containsKey('data')) {
            final videoData = data['data'] as Map<String, dynamic>;
            return TikTokVideoModel.fromTikWmJson(videoData, resolvedUrl);
          } else if (msg.contains('Free Api Limit') || msg.contains('limit')) {
            // Rate limited, retry after delay in next attempt
            continue;
          } else {
            lastException = ApiException(msg.isNotEmpty ? msg : 'Video TikTok tidak ditemukan atau berstatus privat.');
            break;
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            lastException = const NetworkException('Koneksi internet lambat atau timeout. Silakan coba lagi.');
          } else {
            lastException = NetworkException('Kendala jaringan: ${e.message}');
          }
        } catch (e) {
          if (e is AppException) {
            lastException = e;
          } else {
            lastException = ApiException('Gagal memproses video: ${e.toString()}');
          }
        }
      }
    }

    throw lastException ?? const ApiException('Gagal memproses video TikTok. Pastikan URL benar dan video bersifat publik.');
  }
}
