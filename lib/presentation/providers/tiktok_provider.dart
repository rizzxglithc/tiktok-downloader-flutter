import 'package:flutter/material.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/url_validator.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/usecases/get_tiktok_video_usecase.dart';
import '../../services/clipboard_service.dart';

enum TikTokState { initial, loading, success, error }

class TikTokProvider extends ChangeNotifier {
  final GetTikTokVideoUseCase _getVideoUseCase;

  final TextEditingController urlController = TextEditingController();

  TikTokState _state = TikTokState.initial;
  TikTokVideo? _currentVideo;
  String? _errorMessage;

  TikTokProvider({required GetTikTokVideoUseCase getVideoUseCase})
      : _getVideoUseCase = getVideoUseCase;

  TikTokState get state => _state;
  TikTokVideo? get currentVideo => _currentVideo;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == TikTokState.loading;

  /// Paste URL directly from clipboard
  Future<bool> pasteFromClipboard() async {
    final cleanUrl = await ClipboardService.getTikTokUrlFromClipboard();
    if (cleanUrl != null) {
      urlController.text = cleanUrl;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      final raw = await ClipboardService.getRawClipboardText();
      if (raw != null && raw.isNotEmpty) {
        urlController.text = raw.trim();
        _errorMessage = 'Tautan di clipboard bukan URL yang valid.';
      } else {
        _errorMessage = 'Clipboard kosong.';
      }
      notifyListeners();
      return false;
    }
  }

  /// Process & Fetch Video / Photos details from API
  Future<bool> fetchVideo([String? customUrl]) async {
    final inputUrl = customUrl ?? urlController.text;
    final validUrl = UrlValidator.cleanAndExtractUrl(inputUrl);

    if (validUrl == null) {
      _state = TikTokState.error;
      _errorMessage = 'Tolong masukkan URL TikTok atau Instagram yang valid';
      notifyListeners();
      return false;
    }

    _state = TikTokState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final video = await _getVideoUseCase.execute(validUrl);
      _currentVideo = video;
      _state = TikTokState.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _state = TikTokState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _state = TikTokState.error;
      _errorMessage = 'Gagal memproses media. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Alias for fetchVideo
  Future<bool> fetchVideoInfo(String url) async {
    return await fetchVideo(url);
  }

  void clearResult() {
    _state = TikTokState.initial;
    _currentVideo = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearInput() {
    urlController.clear();
    _errorMessage = null;
    if (_state == TikTokState.error) {
      _state = TikTokState.initial;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}
