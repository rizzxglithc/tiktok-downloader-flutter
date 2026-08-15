import 'dart:async';
import 'package:flutter/services.dart';
import '../core/utils/url_validator.dart';

class QuickShareService {
  static const MethodChannel _channel = MethodChannel('com.rizz.tiktok_downloader/media');

  static final StreamController<String> _sharedUrlController = StreamController<String>.broadcast();
  static Stream<String> get onSharedUrlReceived => _sharedUrlController.stream;

  static bool _initialized = false;

  /// Initialize the Quick Share receiver listener
  static void initialize({required Function(String url) onUrlReceived}) {
    if (_initialized) return;
    _initialized = true;

    // Listen to MethodChannel incoming events from Android onNewIntent
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedTextReceived') {
        final rawText = call.arguments?.toString();
        if (rawText != null) {
          final cleanUrl = UrlValidator.cleanAndExtractUrl(rawText);
          if (cleanUrl != null && cleanUrl.isNotEmpty) {
            _sharedUrlController.add(cleanUrl);
            onUrlReceived(cleanUrl);
          }
        }
      }
    });

    // Check if app was launched via Share Target (Intent.ACTION_SEND)
    checkInitialSharedText(onUrlReceived);
  }

  /// Check initial shared text on app cold start
  static Future<void> checkInitialSharedText(Function(String url) onUrlReceived) async {
    try {
      final initialText = await _channel.invokeMethod<String>('getInitialSharedText');
      if (initialText != null && initialText.isNotEmpty) {
        final cleanUrl = UrlValidator.cleanAndExtractUrl(initialText);
        if (cleanUrl != null && cleanUrl.isNotEmpty) {
          _sharedUrlController.add(cleanUrl);
          onUrlReceived(cleanUrl);
        }
      }
    } catch (_) {}
  }
}
