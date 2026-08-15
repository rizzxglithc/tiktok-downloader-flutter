import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_history_datasource.dart';
import 'data/datasources/tiktok_remote_datasource.dart';
import 'data/repositories/history_repository_impl.dart';
import 'data/repositories/tiktok_repository_impl.dart';
import 'domain/usecases/delete_history_usecase.dart';
import 'domain/usecases/get_history_usecase.dart';
import 'domain/usecases/get_tiktok_video_usecase.dart';
import 'domain/usecases/save_history_usecase.dart';
import 'presentation/pages/main_navigation_page.dart';
import 'presentation/providers/download_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/tiktok_provider.dart';
import 'services/download_engine.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI to immersive transparent dark
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Core & Data Layer
  final apiClient = ApiClient();
  final tiktokRemoteDataSource = TikTokRemoteDataSourceImpl(apiClient: apiClient);
  final localHistoryDataSource = LocalHistoryDataSourceImpl(sharedPreferences: prefs);

  // Repositories
  final tiktokRepository = TikTokRepositoryImpl(remoteDataSource: tiktokRemoteDataSource);
  final historyRepository = HistoryRepositoryImpl(localDataSource: localHistoryDataSource);

  // Use Cases
  final getTikTokVideoUseCase = GetTikTokVideoUseCase(tiktokRepository);
  final getHistoryUseCase = GetHistoryUseCase(historyRepository);
  final saveHistoryUseCase = SaveHistoryUseCase(historyRepository);
  final deleteHistoryUseCase = DeleteHistoryUseCase(historyRepository);

  // Services
  final downloadEngine = DownloadEngine();
  final settingsService = SettingsService(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TikTokProvider(getVideoUseCase: getTikTokVideoUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadProvider(
            downloadEngine: downloadEngine,
            saveHistoryUseCase: saveHistoryUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            getHistoryUseCase: getHistoryUseCase,
            deleteHistoryUseCase: deleteHistoryUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService),
        ),
      ],
      child: const TikTokDownloaderApp(),
    ),
  );
}

class TikTokDownloaderApp extends StatelessWidget {
  const TikTokDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDownloader Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationPage(),
    );
  }
}
