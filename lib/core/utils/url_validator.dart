import 'dart:io';
import '../../domain/entities/tiktok_video.dart';

class UrlValidator {
  static final RegExp _tiktokRegex = RegExp(
    r'(https?:\/\/)?(www\.|vt\.|vm\.|t\.|m\.)?(tiktok\.com\/[^\s]+)',
    caseSensitive: false,
  );

  static final RegExp _instagramRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(p|reel|reels|stories|tv|share)\/([A-Za-z0-9_-]+)',
    caseSensitive: false,
  );

  static final RegExp _facebookRegex = RegExp(
    r'(https?:\/\/)?(www\.|m\.|fb\.|web\.)?(facebook\.com|fb\.watch|fb\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _twitterRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(twitter\.com|x\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _youtubeRegex = RegExp(
    r'(https?:\/\/)?(www\.|m\.)?(youtube\.com|youtu\.be)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _threadsRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(threads\.net|threads\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _capcutRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(capcut\.com|mobile\.capcut\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _spotifyRegex = RegExp(
    r'(https?:\/\/)?(open\.)?(spotify\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _soundcloudRegex = RegExp(
    r'(https?:\/\/)?(www\.|m\.|on\.)?(soundcloud\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _pinterestRegex = RegExp(
    r'(https?:\/\/)?(www\.|id\.|pin\.)?(pinterest\.com|pin\.it)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _appleMusicRegex = RegExp(
    r'(https?:\/\/)?(music\.)?(apple\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _teraboxRegex = RegExp(
    r'(https?:\/\/)?(www\.|1024\.|terabox\.)?(terabox\.com|1024terabox\.com|terabox\.app|teraboxlink\.com|terasharelink\.com|teraboxshare\.com|nephobox\.com|4funbox\.com|mirrobox\.com|momerybox\.com|tibibox\.com|freeterabox\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _douyinRegex = RegExp(
    r'(https?:\/\/)?(www\.|v\.)?(douyin\.com|iesdouyin\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _snackvideoRegex = RegExp(
    r'(https?:\/\/)?(www\.|sck\.)?(snackvideo\.com|sck\.io)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _kuaishouRegex = RegExp(
    r'(https?:\/\/)?(www\.|v\.)?(kuaishou\.com|kwai\.com)\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _generalHttpRegex = RegExp(
    r'https?:\/\/[^\s]+',
    caseSensitive: false,
  );

  /// Check if the input text contains a valid supported URL
  static bool isValidUrl(String input) {
    if (input.trim().isEmpty) return false;
    return detectPlatform(input) != null || _generalHttpRegex.hasMatch(input.trim());
  }

  /// Detect platform from input string
  static MediaPlatform? detectPlatform(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (_tiktokRegex.hasMatch(trimmed)) return MediaPlatform.tiktok;
    if (_instagramRegex.hasMatch(trimmed)) return MediaPlatform.instagram;
    if (_facebookRegex.hasMatch(trimmed)) return MediaPlatform.facebook;
    if (_twitterRegex.hasMatch(trimmed)) return MediaPlatform.twitter;
    if (_youtubeRegex.hasMatch(trimmed)) return MediaPlatform.youtube;
    if (_threadsRegex.hasMatch(trimmed)) return MediaPlatform.threads;
    if (_capcutRegex.hasMatch(trimmed)) return MediaPlatform.capcut;
    if (_spotifyRegex.hasMatch(trimmed)) return MediaPlatform.spotify;
    if (_soundcloudRegex.hasMatch(trimmed)) return MediaPlatform.soundcloud;
    if (_pinterestRegex.hasMatch(trimmed)) return MediaPlatform.pinterest;
    if (_appleMusicRegex.hasMatch(trimmed)) return MediaPlatform.applemusic;
    if (_teraboxRegex.hasMatch(trimmed)) return MediaPlatform.terabox;
    if (_douyinRegex.hasMatch(trimmed)) return MediaPlatform.douyin;
    if (_snackvideoRegex.hasMatch(trimmed)) return MediaPlatform.snackvideo;
    if (_kuaishouRegex.hasMatch(trimmed)) return MediaPlatform.kuaishou;

    if (_generalHttpRegex.hasMatch(trimmed)) return MediaPlatform.universal;
    return null;
  }

  /// Extract Instagram shortcode from URL
  static String? extractInstagramShortcode(String input) {
    final match = _instagramRegex.firstMatch(input.trim());
    if (match != null && match.groupCount >= 4) {
      return match.group(4);
    }
    // Fallback: extract short segment after p/ or reel/
    final parts = input.split('/');
    for (int i = 0; i < parts.length - 1; i++) {
      if (['p', 'reel', 'reels', 'tv', 'share'].contains(parts[i])) {
        final code = parts[i + 1].split('?')[0].trim();
        if (code.isNotEmpty) return code;
      }
    }
    return null;
  }

  /// Get formatted display name for detected platform
  static String getPlatformName(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.tiktok:
        return 'TikTok';
      case MediaPlatform.instagram:
        return 'Instagram';
      case MediaPlatform.facebook:
        return 'Facebook';
      case MediaPlatform.twitter:
        return 'Twitter / X';
      case MediaPlatform.youtube:
        return 'YouTube';
      case MediaPlatform.threads:
        return 'Threads';
      case MediaPlatform.capcut:
        return 'CapCut';
      case MediaPlatform.spotify:
        return 'Spotify';
      case MediaPlatform.soundcloud:
        return 'SoundCloud';
      case MediaPlatform.pinterest:
        return 'Pinterest';
      case MediaPlatform.applemusic:
        return 'Apple Music';
      case MediaPlatform.douyin:
        return 'Douyin';
      case MediaPlatform.snackvideo:
        return 'SnackVideo';
      case MediaPlatform.kuaishou:
        return 'Kuaishou';
      case MediaPlatform.universal:
        return 'Universal';
    }
  }

  /// Clean and extract URL from arbitrary user text or pasted clipboard
  static String? cleanAndExtractUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final match = _generalHttpRegex.firstMatch(trimmed);
    if (match != null) {
      String rawUrl = match.group(0)!;
      while (rawUrl.endsWith(')') || rawUrl.endsWith(']') || rawUrl.endsWith('}') || rawUrl.endsWith('.')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 1);
      }
      return rawUrl;
    }

    if (trimmed.contains('.com') || trimmed.contains('.net') || trimmed.contains('.io') || trimmed.contains('.be')) {
      return 'https://$trimmed';
    }

    return null;
  }

  /// Legacy aliases
  static String? cleanAndExtractTikTokUrl(String input) => cleanAndExtractUrl(input);
  static bool isValidTikTokUrl(String input) => _tiktokRegex.hasMatch(input.trim());
  static bool isValidInstagramUrl(String input) => _instagramRegex.hasMatch(input.trim());

  /// Resolve short links
  static Future<String> resolveToCanonicalUrl(String url) async {
    if (!url.contains('vt.tiktok.com') &&
        !url.contains('vm.tiktok.com') &&
        !url.contains('fb.watch') &&
        !url.contains('sck.io') &&
        !url.contains('pin.it') &&
        !url.contains('youtu.be')) {
      return url;
    }

    try {
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 8));
      request.followRedirects = false;
      final response = await request.close();

      if (response.isRedirect) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location != null && location.isNotEmpty) {
          client.close();
          return location;
        }
      }
      client.close();
    } catch (_) {}
    return url;
  }
}
