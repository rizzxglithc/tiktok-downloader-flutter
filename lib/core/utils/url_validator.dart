import 'dart:io';
import '../../domain/entities/tiktok_video.dart';

class UrlValidator {
  static final RegExp _tiktokRegex = RegExp(
    r'(https?:\/\/)?(www\.|vt\.|vm\.|t\.|m\.)?(tiktok\.com\/[^\s]+)',
    caseSensitive: false,
  );

  static final RegExp _instagramRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(p|reel|reels|stories|tv)\/([A-Za-z0-9_-]+)',
    caseSensitive: false,
  );

  /// Check if the input text contains a valid supported URL
  static bool isValidUrl(String input) {
    if (input.trim().isEmpty) return false;
    return isValidTikTokUrl(input) || isValidInstagramUrl(input);
  }

  /// Check if URL is TikTok
  static bool isValidTikTokUrl(String input) {
    if (input.trim().isEmpty) return false;
    return _tiktokRegex.hasMatch(input.trim());
  }

  /// Check if URL is Instagram
  static bool isValidInstagramUrl(String input) {
    if (input.trim().isEmpty) return false;
    return _instagramRegex.hasMatch(input.trim());
  }

  /// Detect platform from input string
  static MediaPlatform? detectPlatform(String input) {
    if (isValidTikTokUrl(input)) return MediaPlatform.tiktok;
    if (isValidInstagramUrl(input)) return MediaPlatform.instagram;
    return null;
  }

  /// Extract Instagram shortcode from URL
  static String? extractInstagramShortcode(String input) {
    final match = _instagramRegex.firstMatch(input.trim());
    if (match != null && match.groupCount >= 4) {
      return match.group(4);
    }
    return null;
  }

  /// Clean and extract URL from arbitrary user text or pasted clipboard
  static String? cleanAndExtractUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final igMatch = _instagramRegex.firstMatch(trimmed);
    if (igMatch != null) {
      String rawUrl = igMatch.group(0)!;
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        rawUrl = 'https://$rawUrl';
      }
      return rawUrl;
    }

    final ttMatch = _tiktokRegex.firstMatch(trimmed);
    if (ttMatch != null) {
      String rawUrl = ttMatch.group(0)!;
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        rawUrl = 'https://$rawUrl';
      }
      return rawUrl;
    }

    return null;
  }

  /// Resolve short links (vt.tiktok.com, vm.tiktok.com) to full canonical video URLs
  static Future<String> resolveToCanonicalUrl(String url) async {
    if (!url.contains('vt.tiktok.com') && !url.contains('vm.tiktok.com')) {
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
