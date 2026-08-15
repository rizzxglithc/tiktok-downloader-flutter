import 'package:flutter/services.dart';
import '../core/utils/url_validator.dart';

class ClipboardService {
  /// Fetch text from clipboard and return cleaned TikTok URL if valid
  static Future<String?> getTikTokUrlFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        return UrlValidator.cleanAndExtractTikTokUrl(data.text!);
      }
    } catch (_) {}
    return null;
  }

  /// Get raw clipboard text
  static Future<String?> getRawClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (_) {
      return null;
    }
  }

  /// Get clipboard text helper
  static Future<String> getClipboardText() async {
    final raw = await getRawClipboardText();
    return raw?.trim() ?? '';
  }

  /// Copy text to system clipboard
  static Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
