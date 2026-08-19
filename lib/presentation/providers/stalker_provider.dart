import 'package:flutter/material.dart';
import '../../data/datasources/stalker_remote_datasource.dart';
import '../../domain/entities/stalk_models.dart';

class StalkerProvider extends ChangeNotifier {
  final StalkerRemoteDataSource _dataSource;

  StalkerProvider({StalkerRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? StalkerRemoteDataSource();

  StalkPlatform _currentPlatform = StalkPlatform.freefire;
  bool _isLoading = false;
  String? _errorMessage;

  FreeFireProfile? _freeFireResult;
  TikTokStalkProfile? _tikTokResult;
  GitHubStalkProfile? _gitHubResult;
  RobloxStalkProfile? _robloxResult;

  final Map<StalkPlatform, List<String>> _recentSearches = {
    StalkPlatform.freefire: ['123456789'],
    StalkPlatform.tiktok: ['mrbeast', 'tiktok'],
    StalkPlatform.github: ['torvalds', 'flutter'],
    StalkPlatform.roblox: ['Roblox', 'builderman'],
  };

  StalkPlatform get currentPlatform => _currentPlatform;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FreeFireProfile? get freeFireResult => _freeFireResult;
  TikTokStalkProfile? get tikTokResult => _tikTokResult;
  GitHubStalkProfile? get gitHubResult => _gitHubResult;
  RobloxStalkProfile? get robloxResult => _robloxResult;

  List<String> get recentSearches => _recentSearches[_currentPlatform] ?? [];

  void setPlatform(StalkPlatform platform) {
    _currentPlatform = platform;
    _errorMessage = null;
    notifyListeners();
  }

  void clearResult() {
    _freeFireResult = null;
    _tikTokResult = null;
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
    _freeFireResult = null;
    _tikTokResult = null;
    _gitHubResult = null;
    _robloxResult = null;
    notifyListeners();

    try {
      switch (_currentPlatform) {
        case StalkPlatform.freefire:
          _freeFireResult = await _dataSource.stalkFreeFire(cleanQuery);
          break;
        case StalkPlatform.tiktok:
          _tikTokResult = await _dataSource.stalkTikTok(cleanQuery);
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
