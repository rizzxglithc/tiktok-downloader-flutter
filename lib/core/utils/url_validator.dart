class UrlValidator {
  static final RegExp _tikTokRegex = RegExp(
    r'(https?:\/\/)?(www\.|vt\.|vm\.|t\.)?tiktok\.com\/.*',
    caseSensitive: false,
  );

  /// Clean, trim, and extract direct TikTok URL from dirty text or share captions
  static String? cleanAndExtractTikTokUrl(String input) {
    if (input.trim().isEmpty) return null;

    final trimmed = input.trim();

    // Check if input contains url
    final urlMatch = RegExp(r'https?:\/\/[^\s]+').firstMatch(trimmed);
    final candidate = urlMatch != null ? urlMatch.group(0) : trimmed;

    if (candidate != null && _tikTokRegex.hasMatch(candidate)) {
      // Ensure https prefix
      if (!candidate.startsWith('http://') && !candidate.startsWith('https://')) {
        return 'https://$candidate';
      }
      return candidate;
    }

    return null;
  }

  /// Validate if the provided string is a valid TikTok link
  static bool isValidTikTokUrl(String url) {
    return cleanAndExtractTikTokUrl(url) != null;
  }
}
