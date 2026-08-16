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
    final cleanUrl = UrlValidator.cleanAndExtractUrl(url) ?? url.trim();
    final platform = UrlValidator.detectPlatform(cleanUrl) ?? MediaPlatform.universal;

    switch (platform) {
      case MediaPlatform.tiktok:
        return await _fetchTikTokDetails(cleanUrl);
      case MediaPlatform.instagram:
        return await _fetchInstagramDetails(cleanUrl);
      case MediaPlatform.facebook:
        return await _fetchFacebookDetails(cleanUrl);
      case MediaPlatform.twitter:
        return await _fetchTwitterDetails(cleanUrl);
      case MediaPlatform.youtube:
        return await _fetchYouTubeDetails(cleanUrl);
      case MediaPlatform.threads:
        return await _fetchThreadsDetails(cleanUrl);
      case MediaPlatform.capcut:
        return await _fetchCapCutDetails(cleanUrl);
      case MediaPlatform.spotify:
        return await _fetchSpotifyDetails(cleanUrl);
      case MediaPlatform.soundcloud:
        return await _fetchSoundCloudDetails(cleanUrl);
      case MediaPlatform.pinterest:
        return await _fetchPinterestDetails(cleanUrl);
      case MediaPlatform.douyin:
        return await _fetchDouyinDetails(cleanUrl);
      case MediaPlatform.snackvideo:
        return await _fetchSnackVideoDetails(cleanUrl);
      case MediaPlatform.kuaishou:
        return await _fetchKuaishouDetails(cleanUrl);
      case MediaPlatform.universal:
        return await _fetchUniversalDetails(cleanUrl);
    }
  }

  // ==========================================
  // 1. TikTok Handler (TikWM HD, Slides, MP3)
  // ==========================================
  Future<TikTokVideoModel> _fetchTikTokDetails(String url) async {
    final resolvedUrl = await UrlValidator.resolveToCanonicalUrl(url);

    final endpoints = [
      ApiConstants.tikwmBaseUrl,
      ApiConstants.tikwmBackupUrl,
    ];

    AppException? lastException;

    for (final endpoint in endpoints) {
      for (int attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) {
          await Future.delayed(const Duration(milliseconds: 1200));
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
                    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
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

    throw lastException ?? const ApiException('Gagal memproses konten TikTok. Pastikan tautan benar dan publik.');
  }

  // ==========================================
  // 2. CapCut Handler (3bic API & Web Scraper)
  // ==========================================
  Future<TikTokVideoModel> _fetchCapCutDetails(String url) async {
    final resolvedUrl = await UrlValidator.resolveToCanonicalUrl(url);

    // 1. User Scraper: 3bic API (https://3bic.com/api/download)
    try {
      final response = await apiClient.dio.post(
        'https://3bic.com/api/download',
        data: jsonEncode({'url': resolvedUrl}),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'Accept': 'application/json, text/plain, */*',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      final resData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data is String ? jsonDecode(response.data) as Map<String, dynamic> : <String, dynamic>{});

      final videoUrl = (resData['video_url'] ?? resData['download_url'] ?? resData['url'] ?? resData['play_url'] ?? resData['video'])?.toString();
      if (videoUrl != null && videoUrl.isNotEmpty) {
        final title = (resData['title'] ?? resData['name'] ?? 'CapCut Template').toString();
        final cover = (resData['thumbnail'] ?? resData['cover'] ?? resData['image'] ?? '').toString();
        final author = (resData['author'] ?? resData['author_name'] ?? 'CapCut Creator').toString();

        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: title,
          authorName: author,
          authorUsername: '@capcut',
          authorAvatar: '',
          coverUrl: cover,
          videoUrl: videoUrl,
          platform: MediaPlatform.capcut,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    // 2. Direct HTML Extraction
    try {
      final resp = await apiClient.dio.get(
        resolvedUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );

      final html = resp.data.toString();
      final mp4Matches = RegExp(r'https?:\/\/[^\"\s\x27]+\.mp4[^\"\s\x27]*').allMatches(html);
      String? foundMp4;
      for (final m in mp4Matches) {
        final u = m.group(0);
        if (u != null && !u.contains('landing') && !u.contains('banner')) {
          foundMp4 = u;
          break;
        }
      }
      foundMp4 ??= mp4Matches.isNotEmpty ? mp4Matches.first.group(0) : null;

      final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(html);
      final coverMatch = RegExp(r'https?:\/\/[^\"\s\x27]+\.(webp|jpg|jpeg|png)').firstMatch(html);

      if (foundMp4 != null && foundMp4.isNotEmpty) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: titleMatch?.group(1) ?? 'CapCut Template',
          authorName: 'CapCut Creator',
          authorUsername: '@capcut',
          authorAvatar: '',
          coverUrl: coverMatch?.group(0) ?? '',
          videoUrl: foundMp4,
          platform: MediaPlatform.capcut,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses template CapCut. Pastikan tautan aktif dan publik.');
  }

  // ==========================================
  // 3. Facebook Handler (GetMyFB Scraper)
  // ==========================================
  Future<TikTokVideoModel> _fetchFacebookDetails(String url) async {
    // 1. User Scraper: GetMyFB API (https://getmyfb.com/process)
    try {
      final body = 'id=${Uri.encodeComponent(url)}&locale=en';
      final response = await apiClient.dio.post(
        'https://getmyfb.com/process',
        data: body,
        options: Options(
          contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
          responseType: ResponseType.plain,
          headers: {
            'accept': 'text/html, */*; q=0.01',
            'hx-current-url': 'https://getmyfb.com/',
            'hx-request': 'true',
            'hx-target': url.contains('share') ? '#private-video-downloader' : '#target',
            'hx-trigger': 'form',
            'hx-post': '/process',
            'hx-swap': 'innerHTML',
            'origin': 'https://getmyfb.com',
            'referer': 'https://getmyfb.com/',
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      final markup = response.data.toString();
      final linkMatches = RegExp(r'href=[\"\x27](https?:\/\/[^\s\"\x27]+)[\"\x27]').allMatches(markup);
      final List<String> videoLinks = [];
      for (final m in linkMatches) {
        final href = m.group(1);
        if (href != null && (href.contains('ssscdn.io') || href.contains('.mp4') || href.contains('fbcdn'))) {
          videoLinks.add(href);
        }
      }

      if (videoLinks.isNotEmpty) {
        final hdUrl = videoLinks.first;
        final sdUrl = videoLinks.length > 1 ? videoLinks[1] : hdUrl;
        final titleMatch = RegExp(r'<p[^>]*class=[\"\x27]results-item-text[\"\x27][^>]*>(.*?)<\/p>').firstMatch(markup);

        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: titleMatch?.group(1)?.trim() ?? 'Facebook Video',
          authorName: 'Facebook Creator',
          authorUsername: '@facebook',
          authorAvatar: '',
          coverUrl: '',
          videoUrl: hdUrl,
          videoHdUrl: hdUrl,
          platform: MediaPlatform.facebook,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    // 2. Direct HTML Extraction
    try {
      final resp = await apiClient.dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );

      final html = resp.data.toString();
      final hdMatch = RegExp(r'"playable_url_quality_hd":"([^"]+)"').firstMatch(html);
      final sdMatch = RegExp(r'"playable_url":"([^"]+)"').firstMatch(html);
      final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(html);

      final hd = hdMatch?.group(1)?.replaceAll(r'\u0026', '&');
      final sd = sdMatch?.group(1)?.replaceAll(r'\u0026', '&');
      final videoUrl = hd ?? sd;

      if (videoUrl != null && videoUrl.isNotEmpty) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: titleMatch?.group(1) ?? 'Facebook Video',
          authorName: 'Facebook Creator',
          authorUsername: '@facebook',
          authorAvatar: '',
          coverUrl: '',
          videoUrl: videoUrl,
          videoHdUrl: hd,
          platform: MediaPlatform.facebook,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses video Facebook. Pastikan video bersifat publik.');
  }

  // ==========================================
  // 4. Instagram Handler (Reels, Posts, Carousel)
  // ==========================================
  Future<TikTokVideoModel> _fetchInstagramDetails(String url) async {
    final shortcode = UrlValidator.extractInstagramShortcode(url) ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Direct Web JSON with Mobile Headers
    try {
      final igJsonUrl = 'https://www.instagram.com/p/$shortcode/?__a=1&__d=dis';
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
          final isVideo = media['is_video'] == true || (media['video_url'] != null && media['video_url'].toString().isNotEmpty);
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

          final audioUrl = (media['clips_music_attribution_info']?['audio_url'] ?? media['audio_src'] ?? (isVideo ? videoUrl : null))?.toString();

          return TikTokVideoModel.fromInstagramData(
            id: shortcode,
            originalUrl: url,
            title: caption,
            authorName: (owner['full_name'] ?? owner['username'] ?? 'Instagram Creator').toString(),
            authorUsername: (owner['username'] ?? 'instagram_user').toString(),
            authorAvatar: (owner['profile_pic_url'] ?? '').toString(),
            coverUrl: displayUrl.isNotEmpty ? displayUrl : videoUrl,
            videoUrl: videoUrl.isNotEmpty ? videoUrl : displayUrl,
            audioUrl: audioUrl,
            images: carouselImages,
            isVideo: isVideo,
          );
        }
      }
    } catch (_) {}

    // 2. OpenGraph Meta Stream Parser
    try {
      final htmlResp = await apiClient.dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
            'Accept-Language': 'en-US,en;q=0.5',
          },
        ),
      );

      final html = htmlResp.data.toString();
      final titleMatch = RegExp(r'<meta\s+property=[\"\x27]og:title[\"\x27]\s+content=[\"\x27](.*?)[\"\x27]', caseSensitive: false).firstMatch(html);
      final imgMatch = RegExp(r'<meta\s+property=[\"\x27]og:image[\"\x27]\s+content=[\"\x27](.*?)[\"\x27]', caseSensitive: false).firstMatch(html);
      final vidMatch = RegExp(r'<meta\s+property=[\"\x27]og:video[\"\x27]\s+content=[\"\x27](.*?)[\"\x27]', caseSensitive: false).firstMatch(html);

      final title = titleMatch?.group(1)?.replaceAll('&amp;', '&').replaceAll('&quot;', '"') ?? 'Instagram Post';
      final cover = imgMatch?.group(1)?.replaceAll('&amp;', '&') ?? '';
      final videoStream = vidMatch?.group(1)?.replaceAll('&amp;', '&');

      return TikTokVideoModel.fromInstagramData(
        id: shortcode,
        originalUrl: url,
        title: title,
        authorName: 'Instagram User',
        authorUsername: '@instagram',
        authorAvatar: '',
        coverUrl: cover,
        videoUrl: videoStream ?? cover,
        audioUrl: videoStream,
        images: videoStream != null ? [] : [cover],
        isVideo: videoStream != null,
      );
    } catch (_) {}

    throw const ApiException('Gagal memproses media Instagram. Pastikan akun bersifat publik dan tautan valid.');
  }

  // ==========================================
  // 5. Twitter / X Handler (xdl)
  // ==========================================
  Future<TikTokVideoModel> _fetchTwitterDetails(String url) async {
    // 1. Try TwDown API
    try {
      final formData = 'URL=${Uri.encodeComponent(url)}';
      final response = await apiClient.dio.post(
        'https://twdown.net/download.php',
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
          headers: {
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      final html = response.data.toString();
      final hdMatch = RegExp(r'href=[\"\x27](https?:\/\/[^\s\"\x27]+\.mp4[^\s\"\x27]*)[\"\x27]').firstMatch(html);
      final titleMatch = RegExp(r'<p[^>]*>(.*?)<\/p>').firstMatch(html);

      if (hdMatch != null) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: titleMatch?.group(1)?.trim() ?? 'Twitter / X Media',
          authorName: 'Twitter User',
          authorUsername: '@x',
          authorAvatar: '',
          coverUrl: '',
          videoUrl: hdMatch.group(1)!,
          platform: MediaPlatform.twitter,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    // 2. Fallback
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/twitter?url=${Uri.encodeComponent(url)}');
      if (res.data is Map && res.data['url'] != null) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (res.data['title'] ?? 'Twitter / X Media').toString(),
          authorName: 'Twitter User',
          authorUsername: '@x',
          authorAvatar: '',
          coverUrl: '',
          videoUrl: res.data['url'].toString(),
          platform: MediaPlatform.twitter,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses postingan Twitter / X.');
  }

  // ==========================================
  // 6. SoundCloud Handler (downcloudme.com)
  // ==========================================
  Future<TikTokVideoModel> _fetchSoundCloudDetails(String url) async {
    try {
      // 1. Fetch DownCloud page to extract verify nonce
      final pageResp = await apiClient.dio.get(
        'https://downcloudme.com',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'user-agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'accept': 'text/html',
          },
        ),
      );

      final pageHtml = pageResp.data.toString();
      final nonceMatch = RegExp(r'name=[\"\x27]downloader_verify[\"\x27]\s+value=[\"\x27]([^\"]+)[\"\x27]').firstMatch(pageHtml);
      final nonce = nonceMatch?.group(1);

      if (nonce != null && nonce.isNotEmpty) {
        final formBody = 'url=${Uri.encodeComponent(url)}&downloader_verify=$nonce&_wp_http_referer=/download-track';
        final postResp = await apiClient.dio.post(
          'https://downcloudme.com',
          data: formBody,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
            headers: {
              'origin': 'https://downcloudme.com',
              'referer': 'https://downcloudme.com',
              'user-agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            },
          ),
        );

        final postResult = postResp.data.toString();
        final directMatch = RegExp(r'data-direct=[\"\x27](https?:\/\/[^\s\"\x27]+\.mp3[^\s\"\x27]*)[\"\x27]').firstMatch(postResult)
            ?? RegExp(r'href=[\"\x27](https?:\/\/[^\s\"\x27]+\.mp3[^\s\"\x27]*)[\"\x27]').firstMatch(postResult);

        if (directMatch != null) {
          final audioUrl = directMatch.group(1)!;
          return TikTokVideoModel.fromUniversalMedia(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            originalUrl: url,
            title: 'SoundCloud Track',
            authorName: 'SoundCloud Artist',
            authorUsername: '@soundcloud',
            authorAvatar: '',
            coverUrl: '',
            videoUrl: '',
            audioUrl: audioUrl,
            platform: MediaPlatform.soundcloud,
            contentType: MediaContentType.audio,
          );
        }
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses lagu SoundCloud.');
  }

  // ==========================================
  // 7. Spotify Handler (spotyloader & musicfab)
  // ==========================================
  Future<TikTokVideoModel> _fetchSpotifyDetails(String url) async {
    // 1. Try Spotyloader API
    try {
      final resp = await apiClient.dio.post(
        'https://spotyloader.com/api/download',
        data: jsonEncode({'url': url}),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Origin': 'https://spotyloader.com',
            'Referer': 'https://spotyloader.com/',
          },
        ),
      );

      final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data.toString()) as Map;
      final downloadUrl = (data['download_url'] ?? data['download'] ?? data['url'])?.toString();

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (data['title'] ?? data['name'] ?? 'Spotify Track').toString(),
          authorName: (data['artist'] ?? 'Spotify Artist').toString(),
          authorUsername: '@spotify',
          authorAvatar: '',
          coverUrl: (data['cover'] ?? data['image'] ?? '').toString(),
          videoUrl: '',
          audioUrl: downloadUrl,
          platform: MediaPlatform.spotify,
          contentType: MediaContentType.audio,
        );
      }
    } catch (_) {}

    // 2. Try MusicFab API
    try {
      final resp = await apiClient.dio.post(
        'https://musicfab.io/api/spotify',
        data: jsonEncode({'url': url}),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Origin': 'https://musicfab.io',
            'Referer': 'https://musicfab.io/spotify-to-mp3',
          },
        ),
      );

      final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data.toString()) as Map;
      final meta = data['data']?['metadata'] as Map?;
      final downloadUrl = meta?['download']?.toString();

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (meta?['name'] ?? 'Spotify Track').toString(),
          authorName: (meta?['artist'] ?? 'Spotify Artist').toString(),
          authorUsername: '@spotify',
          authorAvatar: '',
          coverUrl: (meta?['image'] ?? '').toString(),
          videoUrl: '',
          audioUrl: downloadUrl,
          platform: MediaPlatform.spotify,
          contentType: MediaContentType.audio,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses lagu Spotify.');
  }

  // ==========================================
  // 8. YouTube Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchYouTubeDetails(String url) async {
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/youtube?url=${Uri.encodeComponent(url)}');
      if (res.data is Map) {
        final title = (res.data['title'] ?? 'YouTube Video').toString();
        final thumb = (res.data['thumbnail'] ?? '').toString();
        final videoUrl = (res.data['mp4'] ?? res.data['url'] ?? '').toString();
        final audioUrl = (res.data['mp3'] ?? '').toString();

        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: title,
          authorName: (res.data['author'] ?? 'YouTube Channel').toString(),
          authorUsername: '@youtube',
          authorAvatar: '',
          coverUrl: thumb,
          videoUrl: videoUrl,
          audioUrl: audioUrl.isNotEmpty ? audioUrl : null,
          platform: MediaPlatform.youtube,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses video YouTube.');
  }

  // ==========================================
  // 9. Threads Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchThreadsDetails(String url) async {
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/threads?url=${Uri.encodeComponent(url)}');
      if (res.data is Map && res.data['result'] != null) {
        final result = res.data['result'] as Map<String, dynamic>;
        final videoUrl = (result['video'] ?? result['url'] ?? '').toString();
        final thumb = (result['image'] ?? result['thumbnail'] ?? '').toString();
        final isVid = videoUrl.isNotEmpty && (videoUrl.contains('.mp4') || !videoUrl.contains('.jpg'));

        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (result['description'] ?? result['caption'] ?? 'Threads Post').toString(),
          authorName: 'Threads Creator',
          authorUsername: '@threads',
          authorAvatar: '',
          coverUrl: thumb,
          videoUrl: isVid ? videoUrl : thumb,
          platform: MediaPlatform.threads,
          contentType: isVid ? MediaContentType.video : MediaContentType.photos,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses postingan Threads.');
  }

  // ==========================================
  // 10. Pinterest Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchPinterestDetails(String url) async {
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/pinterest?url=${Uri.encodeComponent(url)}');
      if (res.data is Map && res.data['result'] != null) {
        final result = res.data['result'];
        final mediaUrl = (result is String ? result : (result['url'] ?? result['image'])).toString();
        final isVid = mediaUrl.contains('.mp4');

        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: 'Pinterest Pin',
          authorName: 'Pinterest User',
          authorUsername: '@pinterest',
          authorAvatar: '',
          coverUrl: mediaUrl,
          videoUrl: mediaUrl,
          platform: MediaPlatform.pinterest,
          contentType: isVid ? MediaContentType.video : MediaContentType.photos,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses Pin Pinterest.');
  }

  // ==========================================
  // 11. Douyin Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchDouyinDetails(String url) async {
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/douyin?url=${Uri.encodeComponent(url)}');
      if (res.data is Map && res.data['result'] != null) {
        final result = res.data['result'] as Map<String, dynamic>;
        final videoUrl = (result['video'] ?? result['url'] ?? '').toString();
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (result['title'] ?? 'Douyin Video').toString(),
          authorName: (result['author'] ?? 'Douyin Creator').toString(),
          authorUsername: '@douyin',
          authorAvatar: '',
          coverUrl: (result['thumbnail'] ?? '').toString(),
          videoUrl: videoUrl,
          platform: MediaPlatform.douyin,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses video Douyin.');
  }

  // ==========================================
  // 12. SnackVideo Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchSnackVideoDetails(String url) async {
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/snackvideo?url=${Uri.encodeComponent(url)}');
      if (res.data is Map && res.data['result'] != null) {
        final result = res.data['result'] as Map<String, dynamic>;
        final videoUrl = (result['video'] ?? result['url'] ?? '').toString();
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (result['title'] ?? 'SnackVideo').toString(),
          authorName: 'Snack Creator',
          authorUsername: '@snackvideo',
          authorAvatar: '',
          coverUrl: (result['thumbnail'] ?? '').toString(),
          videoUrl: videoUrl,
          platform: MediaPlatform.snackvideo,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses video SnackVideo.');
  }

  // ==========================================
  // 13. Kuaishou Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchKuaishouDetails(String url) async {
    try {
      final res = await apiClient.dio.get('https://backend1.tioo.eu.org/kuaishou?url=${Uri.encodeComponent(url)}');
      if (res.data is Map && res.data['result'] != null) {
        final result = res.data['result'] as Map<String, dynamic>;
        final videoUrl = (result['video'] ?? result['url'] ?? '').toString();
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: (result['title'] ?? 'Kuaishou Video').toString(),
          authorName: 'Kwai Creator',
          authorUsername: '@kuaishou',
          authorAvatar: '',
          coverUrl: (result['thumbnail'] ?? '').toString(),
          videoUrl: videoUrl,
          platform: MediaPlatform.kuaishou,
          contentType: MediaContentType.video,
        );
      }
    } catch (_) {}

    throw const ApiException('Gagal memproses video Kuaishou.');
  }

  // ==========================================
  // 14. Universal Handler
  // ==========================================
  Future<TikTokVideoModel> _fetchUniversalDetails(String url) async {
    // Strategy A: TikWM universal parser
    try {
      final formData = FormData.fromMap({'url': url, 'hd': 1});
      final response = await apiClient.dio.post(
        ApiConstants.tikwmBaseUrl,
        data: formData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['code'] == 0 && response.data['data'] != null) {
        return TikTokVideoModel.fromTikWmJson(response.data['data'], url);
      }
    } catch (_) {}

    // Strategy B: OpenGraph fallback
    try {
      final resp = await apiClient.dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'facebookexternalhit/1.1'},
        ),
      );
      final html = resp.data.toString();
      final ogTitle = RegExp(r'<meta\s+property=[\"\x27]og:title[\"\x27]\s+content=[\"\x27](.*?)[\"\x27]').firstMatch(html)?.group(1);
      final ogImage = RegExp(r'<meta\s+property=[\"\x27]og:image[\"\x27]\s+content=[\"\x27](.*?)[\"\x27]').firstMatch(html)?.group(1);
      final ogVideo = RegExp(r'<meta\s+property=[\"\x27]og:video[\"\x27]\s+content=[\"\x27](.*?)[\"\x27]').firstMatch(html)?.group(1);

      if (ogVideo != null && ogVideo.isNotEmpty) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: ogTitle ?? 'Universal Video',
          authorName: 'Web Media',
          authorUsername: '@web',
          authorAvatar: '',
          coverUrl: ogImage ?? ogVideo,
          videoUrl: ogVideo,
          platform: MediaPlatform.universal,
          contentType: MediaContentType.video,
        );
      } else if (ogImage != null && ogImage.isNotEmpty) {
        return TikTokVideoModel.fromUniversalMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalUrl: url,
          title: ogTitle ?? 'Universal Image',
          authorName: 'Web Media',
          authorUsername: '@web',
          authorAvatar: '',
          coverUrl: ogImage,
          videoUrl: ogImage,
          images: [ogImage],
          platform: MediaPlatform.universal,
          contentType: MediaContentType.photos,
        );
      }
    } catch (_) {}

    throw const ApiException('Format tautan tidak didukung atau media privat.');
  }
}
