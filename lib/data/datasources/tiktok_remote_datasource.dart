import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/url_validator.dart';
import '../../domain/entities/tiktok_video.dart';
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
    final platform = UrlValidator.detectPlatform(url);

    if (platform == MediaPlatform.instagram) {
      return await _fetchInstagramDetails(url);
    } else {
      return await _fetchTikTokDetails(url);
    }
  }

  /// TikTok Data Fetcher (Handles Videos, HD, and Photo Slides)
  Future<TikTokVideoModel> _fetchTikTokDetails(String url) async {
    // 1. Resolve short links
    final resolvedUrl = await UrlValidator.resolveToCanonicalUrl(url);

    final endpoints = [
      ApiConstants.tikwmBaseUrl,
      ApiConstants.tikwmBackupUrl,
    ];

    AppException? lastException;

    for (final endpoint in endpoints) {
      for (int attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) {
          // Rate-limit backoff (1.3s)
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
            continue;
          } else {
            lastException = ApiException(msg.isNotEmpty ? msg : 'Konten TikTok tidak ditemukan atau berstatus privat.');
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

    throw lastException ?? const ApiException('Gagal memproses konten TikTok. Pastikan tautan benar dan bersifat publik.');
  }

  /// Instagram Media Fetcher (Reels, Posts, Carousel Slides)
  Future<TikTokVideoModel> _fetchInstagramDetails(String url) async {
    final shortcode = UrlValidator.extractInstagramShortcode(url);
    final targetShortcode = shortcode ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Try Instagram Web JSON endpoint with mobile UA
    try {
      final igJsonUrl = 'https://www.instagram.com/p/$targetShortcode/?__a=1&__d=dis';
      final response = await apiClient.dio.get(
        igJsonUrl,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final media = (map['graphql']?['shortcode_media'] ?? map['items']?[0]) as Map<String, dynamic>?;

        if (media != null) {
          final isVideo = media['is_video'] == true;
          final videoUrl = (media['video_url'] ?? '').toString();
          final displayUrl = (media['display_url'] ?? media['display_resources']?.last?['src'] ?? '').toString();
          final caption = (media['edge_media_to_caption']?['edges']?[0]?['node']?['text'] ?? 'Instagram Post').toString();
          final owner = media['owner'] as Map<String, dynamic>? ?? {};

          final List<String> carouselImages = [];
          final sidecar = media['edge_sidecar_to_children']?['edges'] as List?;
          if (sidecar != null && sidecar.isNotEmpty) {
            for (final edge in sidecar) {
              final node = edge['node'] as Map<String, dynamic>? ?? {};
              final sUrl = (node['video_url'] ?? node['display_url'])?.toString();
              if (sUrl != null && sUrl.isNotEmpty) {
                carouselImages.add(sUrl);
              }
            }
          }

          return TikTokVideoModel.fromInstagramData(
            id: targetShortcode,
            originalUrl: url,
            title: caption,
            authorName: (owner['full_name'] ?? owner['username'] ?? 'Instagram Creator').toString(),
            authorUsername: (owner['username'] ?? 'instagram_user').toString(),
            authorAvatar: (owner['profile_pic_url'] ?? '').toString(),
            coverUrl: displayUrl.isNotEmpty ? displayUrl : videoUrl,
            videoUrl: videoUrl.isNotEmpty ? videoUrl : displayUrl,
            images: carouselImages,
            isVideo: isVideo,
          );
        }
      }
    } catch (_) {}

    // 2. Fallback to Multi-Source API Endpoint
    try {
      final formData = FormData.fromMap({'url': url, 'hd': 1});
      final response = await apiClient.dio.post(
        ApiConstants.tikwmBaseUrl,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'User-Agent': 'Mozilla/5.0'},
        ),
      );

      if (response.data is Map && response.data['code'] == 0 && response.data['data'] != null) {
        return TikTokVideoModel.fromTikWmJson(response.data['data'], url);
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses media Instagram. Pastikan akun bersifat publik dan tautan valid.');
  }
}
