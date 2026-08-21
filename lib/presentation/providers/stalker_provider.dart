import 'package:flutter/material.dart';
import '../../data/datasources/stalker_remote_datasource.dart';
import '../../domain/entities/stalk_models.dart';

class StalkerProvider extends ChangeNotifier {
  final StalkerRemoteDataSource _dataSource;

  StalkerProvider({StalkerRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? StalkerRemoteDataSource();

  StalkPlatform _currentPlatform = StalkPlatform.tiktok;
  bool _isLoading = false;
  String? _errorMessage;

  TikTokStalkProfile? _tikTokResult;
  TwitterStalkProfile? _twitterResult;
  ThreadsStalkProfile? _threadsResult;
  InstagramStalkProfile? _instagramResult;
  YouTubeStalkProfile? _youTubeResult;
  GitHubStalkProfile? _gitHubResult;
  RobloxStalkProfile? _robloxResult;

  final Map<StalkPlatform, List<String>> _recentSearches = {
    StalkPlatform.tiktok: ['mrbeast', 'tiktok'],
    StalkPlatform.instagram: ['instagram', 'cristiano'],
    StalkPlatform.twitter: ['elonmusk', 'x'],
    StalkPlatform.threads: ['zuck', 'google'],
    StalkPlatform.youtube: ['MrBeast', 'YouTube'],
    StalkPlatform.github: ['torvalds', 'flutter'],
    StalkPlatform.roblox: ['Roblox', 'builderman'],
  };

  StalkPlatform get currentPlatform => _currentPlatform;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TikTokStalkProfile? get tikTokResult => _tikTokResult;
  TwitterStalkProfile? get twitterResult => _twitterResult;
  ThreadsStalkProfile? get threadsResult => _threadsResult;
  InstagramStalkProfile? get instagramResult => _instagramResult;
  YouTubeStalkProfile? get youTubeResult => _youTubeResult;
  GitHubStalkProfile? get gitHubResult => _gitHubResult;
  RobloxStalkProfile? get robloxResult => _robloxResult;

  List<String> get recentSearches => _recentSearches[_currentPlatform] ?? [];

  void setPlatform(StalkPlatform platform) {
    if (_currentPlatform != platform) {
      _currentPlatform = platform;
      // Otomatis clear hasil pencarian sebelumnya & error saat ganti platform
      clearResult();
    }
  }

  void clearResult() {
    _tikTokResult = null;
    _twitterResult = null;
    _threadsResult = null;
    _instagramResult = null;
    _youTubeResult = null;
    _gitHubResult = null;
    _robloxResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      _errorMessage = 'Masukkan target pencarian.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _tikTokResult = null;
    _twitterResult = null;
    _threadsResult = null;
    _instagramResult = null;
    _youTubeResult = null;
    _gitHubResult = null;
    _robloxResult = null;
    notifyListeners();

    try {
      switch (_currentPlatform) {
        case StalkPlatform.tiktok:
          _tikTokResult = await _dataSource.stalkTikTok(cleanQuery);
          break;
        case StalkPlatform.instagram:
          _instagramResult = await _dataSource.stalkInstagram(cleanQuery);
          break;
        case StalkPlatform.twitter:
          _twitterResult = await _dataSource.stalkTwitter(cleanQuery);
          break;
        case StalkPlatform.threads:
          _threadsResult = await _dataSource.stalkThreads(cleanQuery);
          break;
        case StalkPlatform.youtube:
          _youTubeResult = await _dataSource.stalkYouTube(cleanQuery);
          break;
        case StalkPlatform.github:
          _gitHubResult = await _dataSource.stalkGitHub(cleanQuery);
          break;
        case StalkPlatform.roblox:
          _robloxResult = await _dataSource.stalkRoblox(cleanQuery);
          break;
      }

      // Add to recent searches
      final recents = _recentSearches[_currentPlatform] ?? [];
      if (!recents.contains(cleanQuery)) {
        recents.insert(0, cleanQuery);
        if (recents.length > 6) recents.removeLast();
        _recentSearches[_currentPlatform] = recents;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
