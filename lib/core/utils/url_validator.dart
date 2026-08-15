import 'dart:io';

class UrlValidator {
  static final RegExp _tiktokRegex = RegExp(
    r'(https?:\/\/)?(www\.|vt\.|vm\.|t\.|m\.)?(tiktok\.com\/[^\s]+)',
    caseSensitive: false,
  );

  /// Check if the input text contains a valid TikTok URL pattern
  static bool isValidTikTokUrl(String input) {
    if (input.trim().isEmpty) return false;
    return _tiktokRegex.hasMatch(input.trim());
  }

  /// Clean and extract the first TikTok URL from text
  static String? cleanAndExtractTikTokUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final match = _tiktokRegex.firstMatch(trimmed);
    if (match != null) {
      String rawUrl = match.group(0)!;
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
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1';
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 10));
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
